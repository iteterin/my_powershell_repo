# Root\Microsoft\Windows\Fsrm

[System.Management.Automation.PSCredential]$Credential = Get-Credential
Write "-= ANTY Ransomeware =-`n"

Get-ADComputer -Filter * -SearchBase "" | %{

    $Server = $_.DNSHostName
    Invoke-Command -ComputerName $Server -Credential $Credential -ScriptBlock {
        $drives = Get-WmiObject -Class Win32_Volume -Filter "DriveType='3'" | ?{ $_.Name -notmatch [regex]::Escape("\\?") -and $_.Name -notmatch "C:\\" } | Sort-Object Name | Select-Object -ExpandProperty Name -Unique
        $existing_screens = Filescrn f l /Filegroup:"WNCry Ransomeware"
            if ($existing_screens -match "not found"){
                $Group = New-FsrmFileGroup -Name "WNCry Ransomeware" -IncludePattern @("*.wcry", "*.wncry", "*.wncrypt","*.wnry",'@Please_Read_Me@.txt','@WanaDecryptor@.exe','@WanaDecryptor@.exe.lnk')
                $Template = New-FsrmFileScreenTemplate "WNCry Ransomeware" -IncludeGroup "WNCry Ransomeware"
                $drives | % { 
                    $Screen = New-FsrmFileScreen -Path "$_" -Template "WNCry Ransomeware"  
                    Write "Install screen for $env:COMPUTERNAME "
                } 
             }
    }
}

