[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
 $notification = New-Object System.Windows.Forms.NotifyIcon 
 $notification.Icon = [System.Drawing.SystemIcons]::Information
 $notification.BalloonTipTitle = "Уважаемый коллега!"
 $notification.BalloonTipIcon = "Info"
 $notification.BalloonTipText = "Информируем, что дд.мм.гггг в ЧЧ:ММ расположение некотрых ресурсов будет изменено."
 $notification.Visible = $True
 $notification.ShowBalloonTip(5000000)

 Unregister-Event -SourceIdentifier click_event -ErrorAction SilentlyContinue
 Register-ObjectEvent $notification BalloonTipClicked -sourceIdentifier click_event -Action  {

 #Start-Process iexplore -ArgumentList "-new "
 
 } | Out-Null