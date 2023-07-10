$servers = @()

$Credential = Get-Credential
 $Session = New-PSSession $servers -Credential $Credential 

$MemberGroup_Admin = Invoke-Command -Session $Session -ScriptBlock {

    $Private:Members_ADM = ([ADSI]"WinNT://./Administrators").psbase.invoke('Members') | %{ $_.gettype().invokemember('Name', 'getproperty',$null,$_,$null) } 
    $Private:ComputerName = $env:COMPUTERNAME
    $HashTable = @{}
    $HashTable.$ComputerName = $Members_ADM

    return $HashTable
}

$SRV = $servers -replace ".megafon.ru"

foreach ($Serv in $SRV) {
Write-Host -ForegroundColor Cyan $Serv
$MemberGroup_Admin.$Serv

$switch = Read-Host "Connect via RDP? [y/n]" 

switch($switch){
"y"
{
    $username = $Credential.UserName
    $rdppassword = $Credential.GetNetworkCredential().Passwordcmdkey 
    cmdkey /generic:TERMSRV/$Serv /user:$username /pass:$rdppassword | Out-Null
    mstsc /v:$Serv /admin
    sleep 10
    cmdkey /delete:TERMSRV/$Serv | Out-Null
} 
"n"
{"Go next"} 
} 
pause
 }
