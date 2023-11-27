$auditPath = "E:\FR2\"
#$i = 0

Get-ChildItem -Path $auditPath -Force | ?{ $_.PSIsContainer -and $_.FullName -match "user.name" -or $_.FullName -match "user.name2" -or $_.FullName -match "user.name3"} | %{
    #if ($i -eq "5") {break}
    #else{
        $path = $_.Fullname
        Write-Host $path -ForegroundColor Yellow
        $(Get-Acl $path).access | select @{n="Path";e={ $path }}, FileSystemRights, IdentityReference | Format-Table -Wrap -AutoSize
        #$i++
    #}
} 