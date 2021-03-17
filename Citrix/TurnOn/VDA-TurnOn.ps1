[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="High")]
param(
    [Parameter(Mandatory=$false)]
    [string[]]
    $DesktopGroup = $(Get-BrokerRebootSchedule).DesktopGroupName
    )

function Write-Log {
        param(
            [Parameter(Position=0,Mandatory=$true)]
            [string]
            $Message,
            [Parameter(Position=1,Mandatory=$true)]
            [System.Diagnostics.Stopwatch]
            $Stopwatch,
            [Parameter(Position=1,Mandatory=$true)]
            [string]
            $File
        )
        process {
            $str = $null
            $str = "Stopwatch: $($Stopwatch.Elapsed.TotalSeconds) sec. Info: $Message"
            Write-Verbose $str
            $str | Out-File -FilePath $File -Encoding utf8 -Append -Force -Confirm:$false
        }
    }
function Clear-OldLogs {
    $today=get-date -f yyyy-MM-dd
    $shift=(Get-Date) - (New-TimeSpan -Days 30)
    Get-ChildItem -Path 'C:\ProgramData\Scripts\VDA Restart\Logs' -File | Where-Object CreationTime -le $shift | Remove-Item -Confirm:$false
}

Add-PSSnapin *citrix*

if (test-path 'C:\ProgramData\Scripts\VDA Restart\Logs') {}
else { New-Item -ItemType Directory -Name Logs -Path 'C:\ProgramData\Scripts\VDA Restart' }

$Log = "C:\ProgramData\Scripts\VDA Restart\Logs\{1}_{4}_{2:yyyyMMdd-HHmmss}.{3}" -f (Split-Path -parent $MyInvocation.MyCommand.Definition), ($MyInvocation.MyCommand.Name -replace [regex]::Escape(".ps1")), (Get-Date), "log", ("Shed" -join '_')
"Start {0:yyyy/MM/dd HH:mm:ss}" -f (Get-Date) | Out-File -FilePath $Log -Encoding utf8 -Force -Confirm:$false

$sw = [Diagnostics.Stopwatch]::StartNew()

Write-Log "Delivery Group $DesktopGroup" -Stopwatch $sw -File $Log 
Write-Log "Start raising the dead VM" -Stopwatch $sw -File $Log

for ($i = 0; $i -le 9; $i = $i + 1) {

    $Logs = Get-BrokerMachine -AdminAddress $env:COMPUTERNAME -PowerState 'off' -InMaintenanceMode $false -Filter { DesktopGroupName -in $DesktopGroup } -Property MachineName | New-BrokerHostingPowerAction -action TurnOn | Out-String
    Write-Log "$Logs" -Stopwatch $sw -File $Log
    Write-Log "Sleep 30 min.." -Stopwatch $sw -File $Log
    Start-Sleep -Seconds 1800
}

Write-Log "Start raising the dead VM.. Done!" -Stopwatch $sw -File $Log 
Write-Log "Start clear old logs.." -Stopwatch $sw -File $Log

Clear-OldLogs

Write-Log "Start clear old logs.. Done!" -Stopwatch $sw -File $Log
"Stop {0:yyyy/MM/dd HH:mm:ss}" -f (Get-Date) | Out-File -FilePath $Log -Encoding utf8 -Force -Confirm:$false -Append