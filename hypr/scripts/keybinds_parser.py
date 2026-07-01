#!/usr/bin/env python3
#
# keybinds_parser.py — adapted for Hyprland 0.55+ Lua config syntax
#
# Lua bind format:
#   hl.bind("MODS + KEY", hl.dsp.action(...), { description = "...", ... })
#   hl.bind(mainMod .. " + KEY", hl.dsp.action(...), { description = "...", ... })
#
# Lua unbind format:
#   hl.unbind("MODS + KEY")
#
# Usage (unchanged from original):
#   python3 keybinds_parser.py file1.lua file2.lua UserKeybinds.lua
#   The last file is treated as the user overrides file.

import sys
import re
import os

# ── Known variable aliases ────────────────────────────────────────────────────
# Populated at runtime by scanning for  local mainMod = "SUPER"  patterns.
# Seeded with the most common default so single-file use works without scanning.
_DEFAULT_VAR_ALIASES = {
    'mainMod': 'SUPER',
}

# ── Regex patterns ────────────────────────────────────────────────────────────

# Matches:
#   hl.bind("COMBO", dispatcher, { opts })
#   hl.bind(var .. " + KEY", dispatcher, { opts })
_BIND_RE = re.compile(
    r'hl\.bind\s*\('
    r'\s*(?:(?P<var>\w+)\s*\.\.\s*)?'        # optional: varname ..
    r'"(?P<key>[^"]+)"'                       # the string part (full combo or suffix)
    r'\s*,\s*'
    r'(?P<disp>hl\.dsp\.[\w.]+(?:\s*\([^)]*(?:\([^)]*\)[^)]*)*\))?)'  # dispatcher expr
    r'(?:\s*,\s*(?P<opts>\{[^}]*\}))?'       # optional options table
    r'\s*\)',
    re.DOTALL,
)

# hl.unbind("COMBO") or hl.unbind(var .. " + KEY")
_UNBIND_RE = re.compile(
    r'hl\.unbind\s*\('
    r'\s*(?:(?P<var>\w+)\s*\.\.\s*)?'
    r'"(?P<key>[^"]+)"'
    r'\s*\)'
)

# local varName = "VALUE"  — to auto-detect variable aliases in each file
_VAR_DECL_RE = re.compile(r'local\s+(\w+)\s*=\s*"([^"]+)"')

# Description inside options table
_DESC_RE = re.compile(r'description\s*=\s*"(?P<desc>[^"]+)"')

# Lua line comment
_LUA_COMMENT_RE = re.compile(r'--.*$')


# ── Helpers ───────────────────────────────────────────────────────────────────

def strip_lua_comment(line: str) -> str:
    return _LUA_COMMENT_RE.sub('', line).strip()


def resolve_combo(var: str | None, key_str: str, known_vars: dict) -> str:
    """Build the full combo string from optional variable prefix + key suffix."""
    key_str = key_str.strip().lstrip('+ ').strip()
    if var:
        prefix = known_vars.get(var, var.upper())
        return f'{prefix} + {key_str}' if key_str else prefix
    return key_str


def normalize_combo(combo: str) -> str:
    """Canonical dedup key: 'SUPER + Shift + f' → 'SUPER+SHIFT+F'"""
    return '+'.join(p.strip().upper() for p in combo.split('+') if p.strip())


def describe_dispatcher(disp_expr: str) -> str:
    """Turn a dispatcher expression into a human-readable label for Rofi."""
    disp_expr = disp_expr.strip()

    m = re.match(r'hl\.dsp\.(?P<leaf>[\w.]+)\s*(?:\((?P<args>.*)\))?\s*$',
                 disp_expr, re.DOTALL)
    if not m:
        return disp_expr

    leaf = m.group('leaf')
    args = (m.group('args') or '').strip()

    # exec_cmd("command") → show the command
    cmd_m = re.search(r'"([^"]+)"', args)
    if leaf == 'exec_cmd' and cmd_m:
        return f'exec  {cmd_m.group(1)}'

    # direction = "l" / "r" / "u" / "d"
    dir_m = re.search(r'direction\s*=\s*"([^"]+)"', args)
    if dir_m:
        labels = {'l': 'left', 'r': 'right', 'u': 'up', 'd': 'down'}
        d = dir_m.group(1)
        return f'{leaf}  {labels.get(d, d)}'

    # workspace = <value>
    ws_m = re.search(r'workspace\s*=\s*([^\s,}]+)', args)
    if ws_m:
        return f'{leaf}  {ws_m.group(1)}'

    # action = "toggle" etc.
    act_m = re.search(r'action\s*=\s*"([^"]+)"', args)
    if act_m:
        return f'{leaf}  {act_m.group(1)}'

    # Bare string arg
    if cmd_m:
        return f'{leaf}  {cmd_m.group(1)}'

    return leaf


def scan_var_aliases(content: str) -> dict:
    """Return a dict of local variable names → string values found in content."""
    aliases = dict(_DEFAULT_VAR_ALIASES)
    for m in _VAR_DECL_RE.finditer(content):
        aliases[m.group(1)] = m.group(2)
    return aliases


# ── Bind record ───────────────────────────────────────────────────────────────

class BindRecord:
    __slots__ = ('combo_raw', 'combo_norm', 'disp_expr', 'description', 'source_file')

    def __init__(self, combo_raw, disp_expr, description, source_file):
        self.combo_raw   = combo_raw
        self.combo_norm  = normalize_combo(combo_raw)
        self.disp_expr   = disp_expr
        self.description = description
        self.source_file = source_file


# ── Per-file parser ───────────────────────────────────────────────────────────

def parse_lua_file(file_path: str, user_conf_path: str,
                   binding_map: dict, source_map: dict,
                   seen_any_bind: dict, default_seen: dict,
                   unbound_user: dict, user_bind_map: dict):

    is_user_file = (file_path == user_conf_path)

    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
    except Exception as e:
        sys.stderr.write(f"Error reading {file_path}: {e}\n")
        return

    known_vars = scan_var_aliases(content)

    # Walk line-by-line; buffer multi-line hl.bind() / hl.unbind() calls
    lines = content.splitlines()
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = strip_lua_comment(raw)

        has_bind   = 'hl.bind'   in stripped
        has_unbind = 'hl.unbind' in stripped

        if not has_bind and not has_unbind:
            i += 1
            continue

        # Accumulate until parentheses balance
        buf   = stripped
        depth = buf.count('(') - buf.count(')')
        j     = i + 1
        while depth > 0 and j < len(lines):
            extra = strip_lua_comment(lines[j])
            buf  += ' ' + extra
            depth += extra.count('(') - extra.count(')')
            j    += 1

        # ── unbinds ───────────────────────────────────────────────────────────
        for um in _UNBIND_RE.finditer(buf):
            var     = um.group('var')
            key_str = um.group('key')
            combo_raw  = resolve_combo(var, key_str, known_vars)
            combo_norm = normalize_combo(combo_raw)
            if is_user_file:
                unbound_user[combo_norm] = True
            binding_map.pop(combo_norm, None)
            source_map.pop(combo_norm, None)

        # ── binds ─────────────────────────────────────────────────────────────
        for bm in _BIND_RE.finditer(buf):
            var       = bm.group('var')
            key_str   = bm.group('key')
            disp_expr = bm.group('disp').strip()
            opts_str  = bm.group('opts') or ''

            desc_m      = _DESC_RE.search(opts_str)
            description = desc_m.group('desc') if desc_m else ''

            combo_raw  = resolve_combo(var, key_str, known_vars)
            combo_norm = normalize_combo(combo_raw)
            seen_any_bind[combo_norm] = True

            record = BindRecord(combo_raw, disp_expr, description, file_path)

            if not is_user_file:
                default_seen[combo_norm] = True

            # First-seen wins unless overridden by user file
            if combo_norm not in source_map:
                binding_map[combo_norm] = record
                source_map[combo_norm]  = file_path

            if is_user_file:
                user_bind_map[combo_norm] = record
                binding_map[combo_norm]   = record
                source_map[combo_norm]    = file_path

        i = j if j > i + 1 else i + 1


# ── Top-level orchestration ───────────────────────────────────────────────────

def parse_files(files: list):
    binding_map   = {}
    source_map    = {}
    user_bind_map = {}
    unbound_user  = {}
    seen_any_bind = {}
    default_seen  = {}

    if not files:
        return [], []

    user_conf_path = files[-1] if len(files) > 1 else None

    for file_path in files:
        if not os.path.exists(file_path):
            continue
        parse_lua_file(
            file_path, user_conf_path,
            binding_map, source_map,
            seen_any_bind, default_seen,
            unbound_user, user_bind_map,
        )

    raw_keybinds             = []
    missing_unbind_suggestions = []

    for combo_norm in seen_any_bind:
        record = binding_map.get(combo_norm)
        src    = source_map.get(combo_norm)

        if not record:
            continue

        raw_keybinds.append(record)

        # Suggest unbind if user overrides a default without an explicit hl.unbind()
        if (src == user_conf_path
                and combo_norm in default_seen
                and combo_norm not in unbound_user):
            missing_unbind_suggestions.append(
                f'hl.unbind("{record.combo_raw}")'
            )

    return raw_keybinds, missing_unbind_suggestions


# ── Rofi formatter ────────────────────────────────────────────────────────────

def format_for_rofi(records: list) -> list:
    formatted = []
    for record in records:
        combo_display = ' + '.join(
            p.strip() for p in record.combo_raw.split('+') if p.strip()
        )
        if record.description:
            formatted.append(f"{combo_display} — {record.description}")
        else:
            formatted.append(f"{combo_display} — {describe_dispatcher(record.disp_expr)}")
    return formatted


# ── Entry point ───────────────────────────────────────────────────────────────

def main():
    if len(sys.argv) < 2:
        sys.exit(0)

    config_files = sys.argv[1:]
    binds, suggestions = parse_files(config_files)

    if not binds:
        print("no keybinds found.")
        sys.exit(1)

    for line in format_for_rofi(binds):
        print(line)

    if suggestions:
        import tempfile
        try:
            with tempfile.NamedTemporaryFile(
                mode='w', delete=False,
                prefix='hypr-unbind-suggestions-', suffix='.lua'
            ) as tf:
                tf.write('-- Suggested hl.unbind() calls for user overrides\n')
                tf.write('\n'.join(suggestions) + '\n')
            with open('/tmp/hypr_keybind_suggestions_file', 'w') as sf:
                sf.write(tf.name)
        except Exception:
            pass


if __name__ == '__main__':
    main()