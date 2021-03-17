$server = "localhost"
# Export DFSN List
$dfsn = Get-DfsnRoot | %{
    $rootPath = $_.Path;
    Get-DfsnFolder "$($_.Path)\*" | %{ Get-DfsnFolderTarget $_.Path } | Sort Path |
    Select @{n="RootPath";e={ $rootPath }}, Path, TargetPath }
$dfsn | ?{$_.TargetPath -match $server} | Export-Csv -Path "C:\temp\3\DFSn_$server.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ';'
$dfsn | Export-Csv -Path "C:\temp\3\DFSn.csv" -NoTypeInformation -Encoding UTF8 -Delimiter ';'