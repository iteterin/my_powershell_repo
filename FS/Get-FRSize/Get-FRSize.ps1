[CmdletBinding()]
param(
    [parameter(Mandatory=$false)]
    [string]
    $Server,
	
    [parameter(Mandatory=$false)]     
    [string]
    $ExportCSVPath="FRSize.csv",

    [parameter(Mandatory=$false)]     
    [switch]
    $ExportCSV

)
 

function Get-RemoteDriveInfo ($ComputerName, $drive_dir) {
 
           $scriptToExecute = {
                $drive_dir = $args[0]
                $robo = robocopy $drive_dir "C:\Windows\Temp" /L /xj /e /nfl /ndl /njh /bytes /r:0
                $robo
                }                    

           $MyConnect = Invoke-Command -ComputerName $ComputerName -ArgumentList $drive_dir -ScriptBlock $scriptToExecute      

    return $MyConnect
}

function Get-ShadowCopyStats
    {
     <# https://gallery.technet.microsoft.com/scriptcenter/Get-Shadow-Copy-Statistics-79e05a57 #>

    Param(
	    $ServerName,
	    [Int32]$TimeOut = 500,
	    [switch]$ShowAllVolumes
    )
    Begin
    {	
        $script:CurrentErrorActionPreference = $ErrorActionPreference
	    $ErrorActionPreference = "SilentlyContinue"

	    $ShadowCopyStats = @()

	    Function GetShadowCopyStats{
    	    Param($Computer)
    
    	    If(!$Computer){
                Write-Warning "You need to provide a computer to query!"; 
                Return
            }
		    If($Computer.GetType().Name -match "ADComputer"){
                 If($Computer.dnsHostName -ne $Null){
                        $Computer = $Computer.dnsHostName
                    }
                 Else{
                    $Computer = $Computer.Name
                 }
            }
		
            Write-Progress -Activity "Retrieving snapshot statistics." -Status "Processing server: $Computer" -ID 1
		    $bOnline = $bWMIConnection = $False
		
            If($Computer -ne "."){
        	    $Ping = New-Object system.Net.NetworkInformation.Ping
			
                If(($Ping.Send($Computer, $TimeOut)).Status -eq 'Success'){}
            
                Else{
                    Write-Warning "$Computer is not pingable..."; return
                }
		    }
		    $WMITarget = "$Computer"
		    Get-WmiObject -Class "Win32_ComputerSystem" -Property "Name" -ComputerName $WMITarget | out-null
		    If ($? -eq $False){	
            
                $bWMIConnection = $False
			    $WMITarget = "$Computer."
			    Get-WmiObject -Class "Win32_ComputerSystem" -Property "Name" -ComputerName $WMITarget | out-null
			
                If($? -eq $False){
                    $bWMIConnection = $False
                }
                Else{
                    $bWMIConnection = $True
                }
		    }
		    Else{$bWMIConnection = $True}
		
            If($bWMIConnection){
        	    Write-Progress -Activity "Retrieving computer volumes..." -Status "....." -ID 2 -ParentID 1
			    $Volumes = gwmi Win32_Volume -Property SystemName,DriveLetter,DeviceID,Capacity,FreeSpace -Filter "DriveType=3" -ComputerName $WMITarget |
				    Select SystemName,@{n="DriveLetter";e={$_.DriveLetter.ToUpper()}},DeviceID,@{n="CapacityGB";e={([math]::Round([int64]($_.Capacity)/1GB,2))}},@{n="FreeSpaceGB";e={([math]::Round([int64]($_.FreeSpace)/1GB,2))}} | Sort DriveLetter
			    Write-Progress -Activity "Retrieving shadow storage areas..." -Status "....." -ID 2 -ParentID 1
			    $ShadowStorage = gwmi Win32_ShadowStorage -Property AllocatedSpace,DiffVolume,MaxSpace,UsedSpace,Volume -ComputerName $WMITarget |
				    Select @{n="Volume";e={$_.Volume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
				    @{n="DiffVolume";e={$_.DiffVolume.Replace("\\","\").Replace("Win32_Volume.DeviceID=","").Replace("`"","")}},
				    @{n="AllocatedSpaceGB";e={([math]::Round([int64]($_.AllocatedSpace)/1GB,2))}},
				    @{n="MaxSpaceGB";e={([math]::Round([int64]($_.MaxSpace)/1GB,2))}},
				    @{n="UsedSpaceGB";e={([math]::Round([int64]($_.UsedSpace)/1GB,2))}}
			    Write-Progress -Activity "Retrieving shadow copies..." -Status "....." -ID 2 -ParentID 1
			    $ShadowCopies = gwmi Win32_ShadowCopy -Property VolumeName,InstallDate,Count -ComputerName $WMITarget |
				    Select VolumeName,InstallDate,Count,
				    @{n="CreationDate";e={$_.ConvertToDateTime($_.InstallDate)}}
			    Write-Progress -Activity "Retrieving shares..." -Status "....." -ID 2 -ParentID 1
			    $Shares = gwmi win32_share -Property Name,Path -ComputerName $WMITarget | Select Name,@{n="Path";e={$_.Path.ToUpper()}}
			    If($Volumes){
				    $Output = @()
				    ForEach($Volume in $Volumes){
					    $VolumeShares = $VolumeShadowStorage = $DiffVolume = $VolumeShadowCopies = $Null
					    If($Volume.DriveLetter -ne $Null){[array]$VolumeShares = $Shares | ?{$_.Path.StartsWith($Volume.DriveLetter)}}
					    $VolumeShadowStorage = $ShadowStorage | ?{$_.Volume -eq $Volume.DeviceID}
					    If($VolumeShadowStorage){$DiffVolume = $Volumes | ?{$_.DeviceID -eq $VolumeShadowStorage.DiffVolume}}
					    $VolumeShadowCopies = $ShadowCopies | ?{$_.VolumeName -eq $Volume.DeviceID} | Sort InstallDate
					    $Object = New-Object psobject
					    $Object | Add-Member NoteProperty SystemName $Volume.SystemName -PassThru | Add-Member NoteProperty DriveLetter $Volume.DriveLetter -PassThru |
						    Add-Member NoteProperty CapacityGB $Volume.CapacityGB -PassThru | Add-Member NoteProperty FreeSpaceGB $Volume.FreeSpaceGB -PassThru |
						    Add-Member NoteProperty ShareCount "" -PassThru | Add-Member NoteProperty Shares "" -PassThru |
						    Add-Member NoteProperty ShadowAllocatedSpaceGB "" -PassThru | Add-Member NoteProperty ShadowUsedSpaceGB "" -PassThru |
						    Add-Member NoteProperty ShadowMaxSpaceGB "" -PassThru | Add-Member NoteProperty DiffVolumeDriveLetter "" -PassThru |
						    Add-Member NoteProperty DiffVolumeCapacityGB "" -PassThru | Add-Member NoteProperty DiffVolumeFreeSpaceGB "" -PassThru |
						    Add-Member NoteProperty ShadowCopyCount "" -PassThru | Add-Member NoteProperty OldestShadowCopy "" -PassThru |
						    Add-Member NoteProperty LatestShadowCopy "" -PassThru | Add-Member NoteProperty ShadowAverageSizeGB "" -PassThru | Add-Member NoteProperty ShadowAverageSizeMB ""
					    If($VolumeShares){
                    	    $Object.ShareCount = $VolumeShares.Count
						    If($VolumeShares.Count -eq 1){$Object.Shares = $VolumeShares[0].Name}
						    Else{$Object.Shares = [string]::join(", ", ($VolumeShares | Select Name)).Replace("@{Name=", "").Replace("}", "")}
					    }
					    If($VolumeShadowStorage){	
                            $Object.ShadowAllocatedSpaceGB = $VolumeShadowStorage.AllocatedSpaceGB
						    $Object.ShadowUsedSpaceGB = $VolumeShadowStorage.UsedSpaceGB
						    $Object.ShadowMaxSpaceGB = $VolumeShadowStorage.MaxSpaceGB
						    If($DiffVolume){
                                $Object.DiffVolumeDriveLetter = $DiffVolume.DriveLetter
							    $Object.DiffVolumeCapacityGB = $DiffVolume.CapacityGB
							    $Object.DiffVolumeFreeSpaceGB = $DiffVolume.FreeSpaceGB
						    }
					    }
					    If($VolumeShadowCopies){
                    	    $Object.ShadowCopyCount = (($VolumeShadowCopies | Measure-Object -Property Count -Sum).Sum)
						    $Object.OldestShadowCopy = (($VolumeShadowCopies | Select -First 1).CreationDate)
						    $Object.LatestShadowCopy = (($VolumeShadowCopies | Select -Last 1).CreationDate)
						    If($VolumeShadowStorage.UsedSpaceGB -gt 0 -And $Object.ShadowCopyCount -gt 0){
                        	    $Object.ShadowAverageSizeGB = ([math]::Round($VolumeShadowStorage.UsedSpaceGB/$Object.ShadowCopyCount,2))
							    $Object.ShadowAverageSizeMB = ([math]::Round(($VolumeShadowStorage.UsedSpaceGB*1KB)/$Object.ShadowCopyCount,2))
						    }
					    }
					    If($VolumeShadowStorage -Or $ShowAllVolumes){$Output += $Object}
				    }
				    $Output
			    }
			    Else{Write-Warning "$Computer didn't return any volumes. That's just weird..."; return}
		    }
		    Else{Write-Warning "$Computer is not contactable over WMI..."; return}
	    }
    }
    Process{	
        If($ServerName){
                ForEach($Server in $ServerName){
                    $ShadowCopyStats += GetShadowCopyStats $Server
                }
            }
	        Else
	        {$ShadowCopyStats += GetShadowCopyStats $_}
        }
    End{
	    $ErrorActionPreference = $script:CurrentErrorActionPreference
	    return $ShadowCopyStats
    }
}

$table_name = "Р—Р°РЅСЏС‚РѕРµ РїСЂРѕСЃС‚СЂР°РЅСЃС‚РІРѕ"
$table = New-Object system.Data.DataTable "$table_name"

$column0 = New-Object system.Data.DataColumn Host,([string])
$column1 = New-Object system.Data.DataColumn Drive,([string])
$column2 = New-Object system.Data.DataColumn Folder,([string])
$column3 = New-Object system.Data.DataColumn Files,([string])
$column4 = New-Object system.Data.DataColumn SizeMB,([string])
$column5 = New-Object system.Data.DataColumn SizeGB,([string]) 
$column6 = New-Object system.Data.DataColumn Quota_AutoQuota,([string])
$column7 = New-Object system.Data.DataColumn Quota_TemplateName,([string])
$column8 = New-Object system.Data.DataColumn Quota_SizeGB,([string])
$column9 = New-Object system.Data.DataColumn Quota_SoftLimit,([string])
$column10 = New-Object system.Data.DataColumn Shadow_ShadowAllocatedSpaceGB,([string])
$column11 = New-Object system.Data.DataColumn Shadow_ShadowUsedSpaceGB,([string])
$column12 = New-Object system.Data.DataColumn Shadow_ShadowMaxSpaceGB,([string])
$column13 = New-Object system.Data.DataColumn Shadow_DiffVolumeDriveLetter,([string])
$column14 = New-Object system.Data.DataColumn Shadow_DiffVolumeCapacityGB,([string])
$column15 = New-Object system.Data.DataColumn Shadow_DiffVolumeFreeSpaceGB,([string])
$column16 = New-Object system.Data.DataColumn Shadow_ShadowCopyCount,([string])
$column17 = New-Object system.Data.DataColumn Shadow_OldestShadowCopy,([string])
$column18 = New-Object system.Data.DataColumn Shadow_LatestShadowCopy,([string])
$column19 = New-Object system.Data.DataColumn Shadow_ShadowAverageSizeGB,([string])
$column20 = New-Object system.Data.DataColumn Shadow_ShadowAverageSizeMB,([string])


$table.columns.add($column0)
$table.columns.add($column1)
$table.columns.add($column2)
$table.columns.add($column3)
$table.columns.add($column4)
$table.columns.add($column5)
$table.columns.add($column6)
$table.columns.add($column7)
$table.columns.add($column8)
$table.columns.add($column9)
$table.columns.add($column10)
$table.columns.add($column11)
$table.columns.add($column12)
$table.columns.add($column13)
$table.columns.add($column14)
$table.columns.add($column15)
$table.columns.add($column16)
$table.columns.add($column17)
$table.columns.add($column18)
$table.columns.add($column19)
$table.columns.add($column20)


$ScriptBlock_autoquota = { 
    $remote_dir2 = $args[0]
    #Get-FsrmQuota -Path $remote_dir2
    Get-FsrmAutoQuota
               }
$FsrmAutoQuota = Invoke-Command -ComputerName $Server -ScriptBlock $ScriptBlock_autoquota -ArgumentList $remote_dir

$ShadowCopyStats = Get-ShadowCopyStats -ServerName $Server -ShowAllVolumes

$drives = Get-WmiObject -Class Win32_Volume -ComputerName $Server -Filter "DriveType='3'" `
    | ?{ $_.Name -notmatch [regex]::Escape("\\?") } | Sort Name | Select -ExpandProperty Name -Unique | Where-Object { $_ -ne "C:\" }  

    Write-Host -ForegroundColor Yellow (('{0:dd-MM-yyyy hh:mm:ss}' -f $(Get-Date)) + " Current server: " + $Server )
   
        foreach($drive in $drives)
        {   
               $Get_remote_dir_list = {
                    $remote_drive = $args[0]
                    $dir_list = Get-ChildItem $remote_drive | where {$_.psIscontainer}
                    $dir_list.FullName
               }
        
            Write-Progress -Activity "Retrieving occupied disk space statistics on $server." -Status "Processing disk: $drive" -ID 1

            $RemoteDriveDirList = Invoke-Command -ComputerName $Server -ArgumentList $drive -ScriptBlock $Get_remote_dir_list
            $RemoteDriveDirList | %{                
            
                $remote_dir = $_

                Write-Progress -Activity "Getting the statistics of the disk space occupied by the directory...." -Status "Processing directory: $remote_dir" -ID 2 -ParentID 1
                
                $trigger_set_false = $true

                Write-Host -Foregroundcolor Cyan (('{0:dd-MM-yyyy hh:mm:ss}' -f $(Get-Date)) + " Current drive: " + $drive +" Current dir: " + $remote_dir )               
                $r = Get-RemoteDriveInfo $Server $remote_dir              
                #$data = $r -match "(Р¤Р°Р№Р»РѕРІ|Р‘Р°Р№С‚)" -replace "\s+(Р¤Р°Р№Р»РѕРІ|Р‘Р°Р№С‚)\s+:\s+" | Foreach {$_.split(" ")[0]} #RU 
                $data = $r -match "(Files|Bytes)" -replace "\s+(Files|Bytes)\s+:\s+" | Foreach {$_.split(" ")[0]} #EN
              
                $row = $table.NewRow()
                $row.Drive = $drive
                $row.Folder = $remote_dir
                $row.Files = $data[0]
                $row.SizeMB = $data[1]/1mb
                $row.SizeGB = $data[1]/1gb 
                $row.Host = $Server
                $FsrmAutoQuota | %{  
                    if ($_.Path -eq $remote_dir) {
                        $quota_data = $_
                        $row.Quota_AutoQuota = "True";"True"
                        $row.Quota_TemplateName = $quota_data.Template
                        $row.Quota_SizeGB = $quota_data.Size/1gb
                        $row.Quota_SoftLimit = $quota_data.SoftLimit
                        $trigger_set_false = $false
                    }
                }
                if ($trigger_set_false) {
                    $row.Quota_AutoQuota = "False"
                }
                
                $ShadowCopyStats | Where-Object {  $_.DriveLetter -eq $($drive -replace "\\") } | %{
                    $ShadowCopyStatsData = $_
                    if ($_.DriveLetter -eq $($drive -replace "\\")) { 
                        $row.Shadow_ShadowAllocatedSpaceGB = $ShadowCopyStatsData.ShadowAllocatedSpaceGB
                        $row.Shadow_ShadowUsedSpaceGB = $ShadowCopyStatsData.ShadowUsedSpaceGB
                        $row.Shadow_ShadowMaxSpaceGB = $ShadowCopyStatsData.ShadowMaxSpaceGB
                        $row.Shadow_DiffVolumeDriveLetter = $ShadowCopyStatsData.DiffVolumeDriveLetter
                        $row.Shadow_DiffVolumeCapacityGB = $ShadowCopyStatsData.DiffVolumeCapacityGB
                        $row.Shadow_DiffVolumeFreeSpaceGB = $ShadowCopyStatsData.DiffVolumeFreeSpaceGB
                        $row.Shadow_ShadowCopyCount = $ShadowCopyStatsData.ShadowCopyCount
                        $row.Shadow_OldestShadowCopy = $ShadowCopyStatsData.OldestShadowCopy
                        $row.Shadow_LatestShadowCopy = $ShadowCopyStatsData.LatestShadowCopy 
                        $row.Shadow_ShadowAverageSizeGB = $ShadowCopyStatsData.ShadowAverageSizeGB
                        $row.Shadow_ShadowAverageSizeMB = $ShadowCopyStatsData.ShadowAverageSizeMB
                    }
                }

                $table.Rows.Add($row)
            }
        }

 

 

if ($ExportCSV) {
    $table | Export-Csv -Delimiter ';' -Encoding UTF8 -Path $ExportCSVPath -NoTypeInformation
    $table | format-table -AutoSize
}

else {
    $table | format-table -AutoSize #| Select-Object -Property * | ft #
}