$servers = Get-Content -Path '.\servers_fr.txt' 

$countserv = $servers.Count
$i = 0

while ($countserv -ne 0){ 
    $server = $servers[$i]
    $ExportCSVPath = ".\FRSize_"+$server+".csv"
    Write-Host -ForegroundColor Yellow (('{0:dd-MM-yyyy hh:mm:ss}' -f $(Get-Date)) + " Current server: " + $Server )
    if (Test-Path -Path $ExportCSVPath ) {
        Write-Host "$server : Information from this host has already been received. Go to the next host."
    }
    else {

	Write-Progress -Activity "Get data" -Status "Processing server: $server" -ID 1
        Start-Process powershell -Wait -ArgumentList "-File .\Get-FRSize.ps1", "-Server $server", "-ExportCSVPath $ExportCSVPath", "-ExportCSV"  
    }
    $countserv = $countserv - 1
    $i = $i + 1
}

$result = $null
$servers | %{
 $current_srv = $_
 $CSV_Path = ".\FRSize_"+$current_srv+".csv"
 $csv_data = Import-Csv -Delimiter ';' -Path $CSV_Path
 $result = $result + $csv_data
}
$result | Export-Csv -Delimiter ';' -Encoding UTF8 -Path '.\FRSize_result.csv' -NoTypeInformation