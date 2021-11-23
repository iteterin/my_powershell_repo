<#  Скрипт для перемещения ресурса с серевера на сервер и исправлением кракозябр при выводе в консоль #>
#Исправляем кракозябры

[CmdletBinding()] 
Param (
[Parameter (Mandatory=$true, Position=1, HelpMessage="Input SOURCE path")] [string]$src,
[Parameter (Mandatory=$true, Position=2, HelpMessage="Input DESTANATION path")] [string]$dst,
[Parameter (Mandatory=$false, Position=3, HelpMessage="Input PATH to FILE for log copy")] [string]$log = "$env:temp\log_copy"+('{0:_yyyy_MM_d}' -f $(Get-Date))+".txt"
)

[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("cp866") 

Write-Host '1. Полное копирование'
Write-Host '2. Разностное копирование'
Write-Host '3. Exit'

$selected_menu_item = Read-Host ″Выберите тип копирования″


Switch($selected_menu_item){
1{  #Полное копирование
    $Title = "Запрос подтверждения"
    $Message = "Копируем из $src в $dst логом в $log ?" 
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Будет выполнено полное копирование ресурса $src в расположение $dst"
    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Отмена копирования, выход"
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
    Write-Warning "Проверьте корректность ввода!"
    $Result = $Host.Ui.PromptForChoice($Title, $Message, $Options, 0)
    switch ($Result)
    {
        0   { robocopy "$src" "$dst" /E /ZB /COPYALL /R:1 /W:1 /MT:16 /SL /XJ /XD $RECYCLE.BIN /UNILOG:$log /TEE}
        1   { Write-Host 'Exit'; exit}
    }
     }

2{  #Разностное копирование
    $Title = "Запрос подтверждения"
    $Message = "Копируем из $src в $dst логом в $log ?"
    $Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Будет выполнено полное копирование ресурса $src в расположение $dst"
    $No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Отмена копирования, выход"
    $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Yes, $No)
    Write-Warning "Проверьте корректность ввода!"
    $Result = $Host.Ui.PromptForChoice($Title, $Message, $Options, 0)
    switch ($Result)
    {
        0   { robocopy $src $dst  /E /ZB /COPYALL /XO /PURGE /R:1 /W:1 /MT /SL /XJ /XD $RECYCLE.BIN /UNILOG+:$log /TEE }
        1   { Write-Host 'Exit'; exit}
    }
    }

3{Write-Host 'Exit'; exit }

default {Write-Host 'Выберите один из трех пунктов' -ForegroundColor Red}
}

#robocopy "K:\Towers_MOVE" "T:\Towers" /E /XO /ZB /COPYALL /R:1 /W:1 /MT:16 /SL /XJ /XD $RECYCLE.BIN /UNILOG+:"T:\fsreg-Towers.log" /TEE /X /FP /BYTES /ETA /UNICODE






