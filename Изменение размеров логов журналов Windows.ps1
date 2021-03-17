
$Servers = @(

) 

$Credential = Get-Credential -Message "Введите ваш логин/пароль УЗ с правами Администратора"
$SessionOption = New-PSSessionOption -IdleTimeout 60000 -OpenTimeout 15000 #; $SessionOption
$Session = New-PSSession -ComputerName $Servers -Credential $Credential -Name "Get-Logs" -SessionOption $SessionOption
$ScriptBlock = {
    Write ("maxSize "+$env:COMPUTERNAME)
    wevtutil sl "System" /ms:104857600
    wevtutil sl "Application" /ms:104857600 
    wevtutil gl "System"
    wevtutil gl "Application" 
}

$Result = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock
$Result | Select-String "maxSize"

Get-PSSession | Remove-PSSession