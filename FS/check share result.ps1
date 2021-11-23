$source = Get-Content .\fortest_result.txt
$result = @{}
$source | %{
    $result."$_" = "$(Test-Path $_)" 
    if (Test-Path $_) { Write-Host -ForegroundColor Green ("Check res: {0}" -f $_) }
    else              { Write-Host -ForegroundColor Red   ("Check res: {0}" -f $_) }
}
Pause
$result
Pause