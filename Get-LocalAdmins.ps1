$servers = @('url-file-prof01.megafon.ru',
 'url-dfs-fr01.megafon.ru',
 'url-file-dfs03.megafon.ru',
 'url-file-dfs01.megafon.ru',
 'url-dml-dfs.megafon.ru',
 'url-file-dfs02.megafon.ru',
 'url-vmware-vrm.megafon.ru',
 'url-dfs-fs01.megafon.ru',
 'url-dfs-fr04.megafon.ru',
 'url-dfs-fr03.megafon.ru',
 'url-dfs-fr02.megafon.ru',
 'url-xa-ps02.megafon.ru',
 'url-xa-ps01.megafon.ru',
 'url-xa-ps06.megafon.ru',
 'url-xa-ps05.megafon.ru',
 'url-xa-ps03.megafon.ru',
 'url-xa-ps04.megafon.ru',
 'url-dfs-upm02.megafon.ru',
 'url-dfs-upm01.megafon.ru',
 'url-appo-pub02.megafon.ru',
 'url-appo-pub01.megafon.ru',
 'url-appo-pvs02.megafon.ru',
 'url-appo-pvs01.megafon.ru')

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
