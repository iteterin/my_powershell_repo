
$token = '1482080634:AAFAECYdC2wKFSxC3ZOqz3Ov01gkJspDE9k'
$ChatLog = "D:\GitRepos\Powershell\TelegramBot\ChatLog.txt" #$PSScriptRoot/ChatLog.txt
function Convert-UnixTime ($UnixTime){
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $whatIWant = $origin.AddSeconds($UnixTime)
    $whatIWant
}
function Get-TelegramPrivateMessage
{
#Читаем последнее сообщение
$Request = Invoke-WebRequest -Uri "https://api.telegram.org/bot$token/getUpdates?offset=-1&timeout=1" -Method Get
$obj = (ConvertFrom-Json $Request.content).result.message
#Создадим структуру, в которую запихнем полученные данные и вернем
$props = [ordered]@{ 
                        ok = $content.ok
                        UpdateId = $obj.update_id
                        Message_ID = $obj.message_id
                        first_name = $obj.from.first_name
                        last_name = $obj.from.last_name
                        sender_ID = $obj.from.id
                        chat_id = $obj.chat.id
                        text = $obj.text
                        username = $obj.chat.username
                        date = (Convert-UnixTime $obj.date).Addhours(3)
                       }
$msg = New-Object -TypeName PSObject -Property $props
Return $msg
}

#В функцию передаем текст сообщения и ИД чата, в который мы его отправляем
function Send-TelegramMessage($textmsg,$сhatid)
{
#В телеграмм есть ограничение на размер сообщения в 4к байт. Мы не будем подстраиваться вплотную,
#а будем разбивать сообщение на строки и отправлять по 50 строк за одно сообщение
#попутно добавляем символ переноса строки
try
{
$sa = @();
foreach ($s in $textmsg) {$sa += ($s -replace[char](13),[char]10) + [char]10}
$payload = @{"parse_mode" = "Markdown"; "disable_web_page_preview" = "True"}
$last_step = [math]::Truncate($sa.Count / 50);
for ($i=0; $i -lt $sa.Count / 50;$i++)
{
$b = ($i*50);$e = ($i+1)*50 - 1;
$mspart = $sa[$b..$e]
$request = Invoke-WebRequest -Uri "https://api.telegram.org/bot$token/sendMessage?chat_id=$сhatid&text=$mspart" -Method Post `
 -ContentType "application/json; charset=utf-8" `
 -Body (ConvertTo-Json -Compress -InputObject $payload)}
}
catch
{
$msgtext = 'Ошибка передачи сообщения: '+$_.Exception.Message;
$request = Invoke-WebRequest -Uri "https://api.telegram.org/bot$token/sendMessage?chat_id=$сhatid&text=$msgtext" -Method Post `
 -ContentType "application/json; charset=utf-8" `
 -Body (ConvertTo-Json -Compress -InputObject $payload)}
}

function ConvertTo-Encoding ([string]$From, [string]$To){
    Begin{ $encFrom = [System.Text.Encoding]::GetEncoding($from)
           $encTo = [System.Text.Encoding]::GetEncoding($to) }
    Process{ $bytes = $encTo.GetBytes($_)
             $bytes = [System.Text.Encoding]::Convert($encFrom, $encTo, $bytes)
             $encTo.GetString($bytes) }
   }
   Write-Host -foreg Green ("$($Message.date)`t@$($Message.username)($($Message.chat_id)):$($Message.text)")
   $("[$($Message.Message_ID)] $($Message.date)`t@$($Message.username)($($Message.chat_id)):$($Message.text)") | Out-File -FilePath $ChatLog -Append
While ($true){

    $Message = Get-TelegramPrivateMessage

    $LastMSGID = $((Get-Content $ChatLog -Tail 1) -Replace '\[' -Split ']')[0]
    if(!($LastMSGID -eq $Message.Message_ID)){
        Write-Host -foreg Green ("$($Message.date)`t@$($Message.username)($($Message.chat_id)):$($Message.text)")
        $("[$($Message.Message_ID)] $($Message.date)`t@$($Message.username)($($Message.chat_id)):$($Message.text)") | Out-File -FilePath $ChatLog -Append
        Send-TelegramMessage -textmsg  "$($Message.date)`t@$($Message.username)($($Message.chat_id)):$($Message.text)" -сhatid $Message.chat_id
    }
    Start-Sleep -Seconds 1
}




