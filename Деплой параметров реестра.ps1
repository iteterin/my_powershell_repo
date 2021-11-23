#ѕолучить список серверов можно командой:
#Get-ADComputer -Filter * -SearchBase "" 

$servers1 = @()


$Session = New-PSSession -ComputerName $servers1

$scriptbloc = {

$reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computername ) 
        $regKey= $reg.OpenSubKey("SOFTWARE\\\Citrix\\\PNAgent",$true) 
        $regKey.SetValue("ServerURL","https://storefront/Citrix/Office/PNAgent/config.xml",[Microsoft.Win32.RegistryValueKind]::String)

$reg2 = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computername ) 
        $regKey2 = $reg2.OpenSubKey("SOFTWARE\\\Wow6432Node\\\Citrix\\\PNAgent",$true) 
        $regKey2.SetValue("ServerURL","https://storefront/Citrix/Office/PNAgent/config.xml",[Microsoft.Win32.RegistryValueKind]::String) 
}

Invoke-Command -Session $Session -ScriptBlock $scriptbloc

Get-PSSession | Disconnect-PSSession