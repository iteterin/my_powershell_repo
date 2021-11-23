Add-Type -AssemblyName System.Windows.Forms
$global:msg = New-Object System.Windows.Forms.NotifyIcon
$msg.Icon = [System.Drawing.SystemIcons]::Warning
$msg.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning
$msg.BalloonTipText = 'Началась новая рабочая неделя! Весна близко...'
$msg.BalloonTipTitle = "Внимание $Env:USERNAME"
$msg.Visible = $true



$msg.ShowBalloonTip(100000) 
