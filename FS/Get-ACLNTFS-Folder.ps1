
$auditPath = "\\megafon.ru\netlogon\"

Get-ChildItem -Path $auditPath -Force | ?{ $_.PSIsContainer } | %{

    $path = $_.Fullname

    Write-Host $path -ForegroundColor YellowWrite-Host $path -ForegroundColor Yellow

    $(Get-Acl $path).access | select @{n="Path";e={ $path }}, FileSystemRights, IdentityReference | Format-Table -Wrap -AutoSize

} 