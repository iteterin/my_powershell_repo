$auditPath = "E:\FR2\"
#$i = 0

Get-ChildItem -Path $auditPath -Force | ?{ $_.PSIsContainer -and $_.FullName -match "maria.lazanskaya" -or $_.FullName -match "marina.r.volkova" -or $_.FullName -match "andrey.uvachev"} | %{
    #if ($i -eq "5") {break}
    #else{
        $path = $_.Fullname
        Write-Host $path -ForegroundColor Yellow
        $(Get-Acl $path).access | select @{n="Path";e={ $path }}, FileSystemRights, IdentityReference | Format-Table -Wrap -AutoSize
        #$i++
    #}
} 