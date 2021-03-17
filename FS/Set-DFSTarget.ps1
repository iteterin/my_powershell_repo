$dfserver = ""
$dfs_config = Import-Csv -Path 'C:\Temp\C2004903_Targets.csv' -Delimiter ';'

$dfs_config | Where-Object {$_.New} | ForEach-Object{
    $dfsPath = $_.DFSn
    $oldTargetPath = $_.Old
    $newTargetPath = $_.New
    if ($newTargetPath -notmatch "\.$([regex]::Escape($env:USERDNSDOMAIN.ToLower()))") {
        $newTargetPath = $newTargetPath -replace [regex]::Escape(($newTargetPath -replace '\\\\' -split '\\')[0]), "$(($newTargetPath -replace '\\\\' -split '\\')[0]).$($env:USERDNSDOMAIN.ToLower())"
    }
    $dfsnObj = Get-DfsnFolder -Path $dfsPath
    if (@($dfsnObj | Get-DfsnFolderTarget -TargetPath $newTargetPath -ea 0).Count -le 0) {
        $dfsnObj | New-DfsnFolderTarget -TargetPath $newTargetPath -State Offline 
        if ($?) {Write-Host ("DFS Target {0} for {1} folder created" -f $newTargetPath, $dfsnObj.Path) -ForegroundColor Green}
    } else {
        if ($newTargetPath -match "^\\($dfserver\\|$dfserver\.)") {
            Write-Host ("Toggle DFS Target state for {0} on target {1}" -f $dfsnObj.Path, $newTargetPath) -ForegroundColor Yellow
            $dfsnObj | Get-DfsnFolderTarget -TargetPath $newTargetPath | ForEach-Object { Set-DfsnFolderTarget -Path $_.Path -TargetPath $_.TargetPath -State Online -ReferralPriorityClass ($_.ReferralPriorityClass -replace '-') -ReferralPriorityRank $_.ReferralPriorityRank -WhatIf }
            $dfsnObj | Get-DfsnFolderTarget -TargetPath $oldTargetPath | ForEach-Object { Set-DfsnFolderTarget -Path $_.Path -TargetPath $_.TargetPath -State Offline -ReferralPriorityClass  ($_.ReferralPriorityClass -replace '-') -ReferralPriorityRank $_.ReferralPriorityRank -WhatIf}
            # Комментируем 3 верхних строчки и раскоментируем 1 снизу для удаление всех target $dfserver
            #$dfsnObj | Get-DfsnFolderTarget -TargetPath $newTargetPath | Remove-DfsnFolderTarget -Force -Verbose
        } else {
            $dfsnObj | Get-DfsnFolderTarget -TargetPath $newTargetPath
            $dfsnObj | Get-DfsnFolderTarget -TargetPath $oldTargetPath
        }
    }
}
