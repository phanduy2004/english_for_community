# Export ERD from export/*.mmd (strip YAML frontmatter for CLI)
$ErrorActionPreference = "Stop"
$dir = $PSScriptRoot
$cfg = Join-Path $dir "mermaid-export-config.json"
$names = @("erd-hinh-1a-user-lop", "erd-hinh-1b-de-thi", "erd-hinh-2-hoc-tap")

foreach ($n in $names) {
    $mmd = Join-Path $dir "$n.mmd"
    $raw = Get-Content $mmd -Raw -Encoding UTF8
    $body = ($raw -replace '(?s)^---[\s\S]*?---\r?\n', '').TrimStart()
    $tmp = Join-Path $dir "$n.export.mmd"
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($tmp, $body + [Environment]::NewLine, $utf8)

    npx -y @mermaid-js/mermaid-cli@11.4.0 -c $cfg -i $tmp -o (Join-Path $dir "$n.svg") -b white | Out-Null
    npx -y @mermaid-js/mermaid-cli@11.4.0 -c $cfg -i $tmp -o (Join-Path $dir "$n.png") -b white -s 2 | Out-Null
    Remove-Item $tmp -Force
    Write-Host "OK $n"
}

Write-Host "Done"
