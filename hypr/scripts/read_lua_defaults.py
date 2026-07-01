#!/usr/bin/env python3
"""
read_lua_defaults.py — extract simple variable assignments from 01-UserDefaults.lua
Usage: python3 read_lua_defaults.py <varname> [lua_file]
Prints the value (unquoted) to stdout, exits 1 if not found.

Handles:
  term = "kitty"
  files = "dolphin"
  Search_Engine = "https://..."
  hl.env("EDITOR", "code")
"""
import re, sys, os

def extract(lua_file, varname):
    with open(lua_file) as f:
        content = f.read()

    # Plain assignment:  varname = "value"
    m = re.search(rf'^\s*{re.escape(varname)}\s*=\s*"([^"]+)"', content, re.MULTILINE)
    if m:
        return m.group(1)

    # hl.env("VARNAME", "value")
    m = re.search(rf'hl\.env\s*\(\s*"{re.escape(varname)}"\s*,\s*"([^"]+)"\s*\)', content)
    if m:
        return m.group(1)

    return None

if len(sys.argv) < 2:
    print("Usage: read_lua_defaults.py <varname> [lua_file]", file=sys.stderr)
    sys.exit(2)

varname  = sys.argv[1]
lua_file = sys.argv[2] if len(sys.argv) > 2 else \
           os.path.expanduser("~/.config/hypr/UserConfigs/01-UserDefaults.lua")

val = extract(lua_file, varname)
if val is None:
    sys.exit(1)
print(val)
