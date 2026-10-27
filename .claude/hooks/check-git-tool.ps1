# Hook PreToolUse sur l'outil MCP mcp__git__git_commit : bloque un message sans numero d'issue.
# Claude Code envoie un JSON sur stdin : { "tool_input": { "repo_path": "...", "message": "..." }, ... }
# exit 2 = appel bloque, le message stderr est renvoye a l'agent.
$raw = [Console]::In.ReadToEnd()
try { $msg = ($raw | ConvertFrom-Json).tool_input.message } catch { exit 0 }

if ($msg -match '#389') { exit 0 }

[Console]::Error.WriteLine("Commit bloque : le message doit contenir un numero d'issue (ex: #123). Demande le numero a l'utilisateur.")
exit 2
