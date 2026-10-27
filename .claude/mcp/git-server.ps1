# Mini serveur MCP (stdio) en PowerShell : expose un seul outil `git_commit(message)`.
# Protocole : JSON-RPC 2.0, un message JSON par ligne sur stdin/stdout.
# Le serveur est declare sous le nom "git" dans .mcp.json -> l'outil s'appelle mcp__git__git_commit.
# stdout est reserve au protocole : tout le reste doit passer par stderr ou etre capture.
$utf8 = New-Object System.Text.UTF8Encoding $false
[Console]::InputEncoding = $utf8
[Console]::OutputEncoding = $utf8

function Send($obj) {
    [Console]::Out.WriteLine((ConvertTo-Json -InputObject $obj -Depth 10 -Compress))
    [Console]::Out.Flush()
}

$tool = @{
    name        = 'git_commit'
    description = 'Ajoute tous les changements (git add -A) et cree un commit avec le message donne.'
    inputSchema = @{
        type       = 'object'
        properties = @{ message = @{ type = 'string'; description = 'Message du commit' } }
        required   = @('message')
    }
}

while ($null -ne ($line = [Console]::In.ReadLine())) {
    if (-not $line.Trim()) { continue }
    try { $req = $line | ConvertFrom-Json } catch { continue }
    if ($null -eq $req.id) { continue }   # notification (ex: notifications/initialized) : pas de reponse

    switch ($req.method) {
        'initialize' {
            Send @{ jsonrpc = '2.0'; id = $req.id; result = @{
                protocolVersion = $req.params.protocolVersion
                capabilities    = @{ tools = @{} }
                serverInfo      = @{ name = 'git-mini'; version = '0.1.0' }
            } }
        }
        'ping' { Send @{ jsonrpc = '2.0'; id = $req.id; result = @{} } }
        'tools/list' { Send @{ jsonrpc = '2.0'; id = $req.id; result = @{ tools = @($tool) } } }
        'tools/call' {
            $isError = $false
            try {
                if ($req.params.name -ne 'git_commit') { throw "Outil inconnu : $($req.params.name)" }
                $msg = [string]$req.params.arguments.message
                # ToString() evite que PowerShell 5.1 enrobe stderr dans un ErrorRecord verbeux.
                $out = (& git add -A 2>&1 | ForEach-Object { $_.ToString() } | Out-String)
                $out += (& git commit -m $msg 2>&1 | ForEach-Object { $_.ToString() } | Out-String)
                if ($LASTEXITCODE -ne 0) { $isError = $true }
            } catch {
                $out = $_.Exception.Message
                $isError = $true
            }
            Send @{ jsonrpc = '2.0'; id = $req.id; result = @{
                content = @(@{ type = 'text'; text = $out.Trim() })
                isError = $isError
            } }
        }
        default {
            Send @{ jsonrpc = '2.0'; id = $req.id; error = @{ code = -32601; message = "Methode non supportee : $($req.method)" } }
        }
    }
}
