$GPRESULT_FileName = "$env:USERPROFILE\$env:USERNAME"+"_"+"$env:COMPUTERNAME"+"_"+"$(Get-Date -Format _yyyyMMdd_HHmmss).html"

gpresult /H "$GPRESULT_FileName"
Start-Process iexplore -ArgumentList "file://$GPRESULT_FileName"
 
 
$Profilepath = [regex]::Escape($env:USERPROFILE)
$path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders"
 
  Push-Location
  Set-Location -Path $path
  $Data =  Get-Item . | Select-Object -ExpandProperty property |%{
     New-Object psobject -Property @{
        "Folder"=$_;
        "RedirectedLocation" = (Get-ItemProperty -Path . -Name $_).$_;
        "Check" = "";
        }
 
  } | Where-Object {$_.RedirectedLocation -notmatch "$Profilepath"} | Sort RedirectedLocation
   
  Pop-Location
 
$Data |%{$_.Check = Test-Path $_.RedirectedLocation }
$Data