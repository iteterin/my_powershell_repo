[CmdletBinding()]

Function Get-IniContent {
    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_) -and ((Get-Item $_ -Force).Extension -eq ".ini")})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string]$FilePath
    )
    Begin
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}
    Process
    {
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"
        $ini = @{}
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$" # Section
            {
                $section = $matches[1]
                $ini[$section] = @{}
                $CommentCount = 0
            }
            "^(;.*)$" # Comment
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $ini[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)" # Key
            {
                if (!($section))
                {
                    $section = "No-Section"
                    $ini[$section] = @{}
                }
                $name,$value = $matches[1..2]
                $ini[$section][$name] = $value
            }
        }
        Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"
        Return $ini
    }
    End
        {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}
}


$key = Read-Host "1 - Regedit; 2 - GPO"

switch ($key){
    1{
        
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
        pause; exit;
        }
    2{
        $TestUserName = $env:USERNAME
        $select_gpo = Read-Host "1: GLB-VDI-FolderRedirection-New`n2: MSK-Users-fr-new`n3: Input GPO GUID`n?"
        
        switch ($select_gpo){
            1 {$GPOGUID = $GPOGUID1 = '{0969BA51-410D-4B7D-977E-474769F01898}'}
            2 {$GPOGUID = $GPOGUID2 = '{F99339C8-D36F-42F8-8D3C-E825A5773108}'}
            3 {$GPOGUID = Read-Host "Input GPO GUID (Example: {F99339C8-D36F-42F8-8D3C-E825A5773108})`n?"}
        }

        $policyContent = Get-IniContent -FilePath ('\\Megafon.ru\SysVol\Megafon.ru\Policies\' + $GPOGUID + '\User\Documents & Settings\fdeploy1.ini')
 
        $DOCUMENTS = '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}'
        $DESKTOP   = '{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}'
        $FAVORITES = '{1777F761-68AD-4D8A-87BD-30B759FA33DD}'
        $DOWNLOADS = '{374DE290-123F-4565-9164-39C4925E467B}'
        $LINKS     = '{BFB9D5E0-C6A9-404C-B2B2-AE6DB6AF4968}'
        
        $GroupsSIDs = $policyContent['Folder_Redirection'][$DOCUMENTS] -split ';' 
        $userGroupsSIDs = [Security.Principal.WindowsIdentity]::GetCurrent().Groups | Select-Object -ExpandProperty Value
        $group = Compare-Object -ReferenceObject $GroupsSIDs -DifferenceObject $userGroupsSIDs -ExcludeDifferent -IncludeEqual -PassThru | Select-Object -First 1
        
        
        $DataArray = @()           
            $Result = "" | Select USERNAME, DOCUMENTS, DESKTOP, FAVORITES, DOWNLOADS, LINKS
            $Result.USERNAME  = $TestUserName 
            $Result.DOCUMENTS = Test-Path $($policyContent["$($DOCUMENTS)_$($group)"].FullPath -replace '%USERNAME%', $Result.Username)
            $Result.DESKTOP   = Test-Path $($policyContent["$($DESKTOP)_$($group)"].FullPath -replace '%USERNAME%', $Result.Username)
            $Result.FAVORITES = Test-Path $($policyContent["$($FAVORITES)_$($group)"].FullPath -replace '%USERNAME%', $Result.Username)
            $Result.DOWNLOADS = Test-Path $($policyContent["$($DOWNLOADS)_$($group)"].FullPath -replace '%USERNAME%', $Result.Username)
            $Result.LINKS     = Test-Path $($policyContent["$($LINKS)_$($group)"].FullPath -replace '%USERNAME%', $Result.Username)

            
            "`nIn Policy Paths:`n"
            $policyContent["$($DOCUMENTS)_$($group)"].FullPath
            $policyContent["$($DESKTOP)_$($group)"].FullPath
            $policyContent["$($FAVORITES)_$($group)"].FullPath
            $policyContent["$($DOWNLOADS)_$($group)"].FullPath
            $policyContent["$($LINKS)_$($group)"].FullPath

            $DataArray += $Result
        
        
        "`nTest-Path"
        $DataArray | FT;
pause; exit;
    }
}
