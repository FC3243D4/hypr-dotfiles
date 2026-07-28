-- persistance
-- persist the number of workspaces set in UserDefaults workspaces
for i = 1, os.getenv("PERSISTENT_WORKSPACES") do
    hl.workspace_rule({
        workspace = tostring(i),
        persistent = true,
    })
end