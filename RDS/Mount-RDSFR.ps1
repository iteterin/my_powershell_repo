#Requires -Version 2
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

#region Constant
# GPO FR 
$GPOGUID = '{0969BA51-410D-4B7D-977E-474769F01898}'
$DOCUMENTS = '{FDD39AD0-238F-46AF-ADB4-6C85480369C7}'
$diskPoint = "H"
# EventLog
$logName = "Application"
$logSource = "RDS FR"
$infoID = 1
$errorID = 100
#endregion Constants

# Get FR GPO Config
$policyContent = Get-IniContent -FilePath ("\\$($env:USERDOMAIN)\SysVol\$($env:USERDOMAIN)\Policies\" + $GPOGUID + '\User\Documents & Settings\fdeploy1.ini')
if ($?) {
    Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
    -Message "Load group policy $GPOGUID configuration for the username: $($env:USERNAME.ToLower())"
} else {
    Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
    -Message "Failed to load group policy $GPOGUID configuration for the username: $($env:USERNAME.ToLower())`r`n$($error[0].Exception)"
}
# Get Documents FR Groups SIDs
$docGroupsSIDs = $policyContent['Folder_Redirection'][$DOCUMENTS] -split ';'
# Get user Groups SIDs
$userGroupsSIDs = [Security.Principal.WindowsIdentity]::GetCurrent().Groups | Select-Object -ExpandProperty Value
$group = Compare-Object -ReferenceObject $docGroupsSIDs -DifferenceObject $userGroupsSIDs -ExcludeDifferent -IncludeEqual -PassThru | Select-Object -First 1
if ($group) {
    $mydocs = $policyContent["$($DOCUMENTS)_$($group)"].FullPath -replace '%USERNAME%', $env:USERNAME

    if (Test-Path -Path (Split-Path (Split-Path $mydocs -Parent) -Parent) -ErrorAction SilentlyContinue) {

        # Path exist if not - create dir
        if (-not (Test-Path -Path $mydocs -ErrorAction SilentlyContinue)) {
            New-Item -Path $mydocs -ItemType Directory -Force
            if ($?) {
                Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                -Message "Create directory `"$mydocs`" for the username: $($env:USERNAME.ToLower())"
            } else {
                Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                -Message "Failed to create directory `"$mydocs`" for the username: $($env:USERNAME.ToLower())`r`n$($error[0].Exception)"
            }
        } else {
            Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
            -Message "Directory `"$mydocs`" for the username: $($env:USERNAME.ToLower()) already exist"
        }

        $mountPoint = Get-PSDrive | Where-Object { $_.Name -eq $diskPoint }
        if ($mountPoint) {
            $oldRoot = Get-PSDrive -Name $diskPoint | Select-Object -ExpandProperty DisplayRoot
            if ( $oldRoot -ne $mydocs ) {
                for ($i=[byte][char]$diskPoint + 1;$i -le 90; $i++) {
                    if (-not (Get-PSDrive -Name ([char]$i) -ErrorAction SilentlyContinue) ) {
                        net use ($diskPoint + ":") /delete /y
                        if ($?) {
                            Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                            -Message ("Dismount `"{0}`" for the username: $($env:USERNAME.ToLower())" -f `
                                (Get-PSDrive -Name $diskPoint | Select-Object -ExpandProperty DisplayRoot) )
                        } else {
                            Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                            -Message ("Failed to dismount `"{0}`" for the username: $($env:USERNAME.ToLower())`r`n$LASTERRORCODE" -f `
                                (Get-PSDrive -Name $diskPoint | Select-Object -ExpandProperty DisplayRoot) )
                        }
                        if (Test-Path -Path $oldRoot -ErrorAction SilentlyContinue) {                            
                            if ( -not (Get-PSDrive -ErrorAction SilentlyContinue | Where-Object { $_.DisplayRoot -eq $oldRoot }) ) {
                                Write-Host ("Монтирование старого ресурса `"{0}`"" -f $oldRoot)
                                net use ([char]$i + ":") "$oldRoot" /Persistent:Yes /y
                                if ($?) {
                                    Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                                    -Message "Mount old network drive `"$oldRoot`" for the username: $($env:USERNAME.ToLower())"
                                } else {
                                    Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                                    -Message "Failed to mount old network drive `"$oldRoot`" for the username: $($env:USERNAME.ToLower())`r`n$LASTERRORCODE"
                                }
                            } else {
                                Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                                -Message "Old network drive `"$oldRoot`" for the username: $($env:USERNAME.ToLower()) already mounted"
                            }
                        } else {
                            Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                            -Message "Failed access to old network drive `"$oldRoot`" for the username: $($env:USERNAME.ToLower())"
                        }
                        break;
                    }                    
                }
                if ($?) {
                    net use ($diskPoint + ":") "$mydocs" /Persistent:Yes /y
                    if ($?) {
                        Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                        -Message "Mount network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower())"
                    } else {
                        Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                        -Message "Failed to mount network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower())`r`n$LASTERRORCODE"
                    }
                }
            } else {
                Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                -Message "Network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower()) already mounted"
            }
        } else {
            net use ($diskPoint + ":") "$mydocs" /Persistent:Yes /y
            if ($?) {
                Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId $infoID `
                -Message "Mount network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower())"
            } else {
                Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
                -Message "Failed to mount network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower())`r`n$LASTERRORCODE"
            }
        }
    } else {
        Write-EventLog -LogName $logName -Source $logSource -EntryType Error -EventId $errorID `
        -Message "Failed access to network drive `"$mydocs`" for the username: $($env:USERNAME.ToLower())"
    }

} else {
    Write-EventLog -LogName $logName -Source $logSource -EntryType Information -EventId 10 `
    -Message "No FR Group for the username: $($env:USERNAME.ToLower())"
}
