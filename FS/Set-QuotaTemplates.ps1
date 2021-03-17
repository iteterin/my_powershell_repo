#[CmdletBinding()]
#param(
#    [parameter(Mandatory=$true)]
#    [ValidateSet("FR","FS")]
#    [string]
#    $Type
#)

if ($env:computername -notmatch "FR" -and $env:computername -notmatch "FS") { exit }
if ($env:computername -match "FS") {$Type = "FS"}
if ($env:computername -match "FR") {$Type = "FR"}

switch ($Type) {
    "FR" {
        $body1 = @'
Здравствуйте.

Пользователем [Source Io Owner] пройден порог [Quota Threshold]% лимита на ресурс размещения личных каталогов "Мои документы", "Рабочий стол", "Избранное"  и т.д. Удалите из этих каталогов неиспользуемые файлы и файлы, не относящиеся к служебным обязанностям.

Лимит: [Quota Limit MB] MB. | Использовано: [Quota Used MB] MB. ([Quota Used Percent]%) | Доступно: [Quota Free MB] MB.

Квота установлена в соответствии с (документ) и в случае производственной необходимости может быть увеличена по заявке.(указать ветку). При этом сотрудниками ИТ предварительно выполняется проверка данных на соответствие требованиям Положения. Более подробную информацию можно получить на портале: https://
'@
        $body2 = @'
Здравствуйте.

Пользователем [Source Io Owner] исчерпано [Quota Threshold]% лимита на ресурс размещения личных каталогов "Мои документы", "Рабочий стол", "Избранное"  и т.д. Удалите из этих каталогов неиспользуемые файлы и файлы, не относящиеся к служебным обязанностям.

Лимит: [Quota Limit MB] MB. | Использовано: [Quota Used MB] MB. ([Quota Used Percent]%) | Доступно: [Quota Free MB] MB.

Квота установлена в соответствии с (документ) и в случае производственной необходимости может быть увеличена по заявке.(указать ветку). При этом сотрудниками ИТ предварительно выполняется проверка данных на соответствие требованиям Положения. Более подробную информацию можно получить на портале: https://
'@
    }
    "FS" {
        $body1 = @'
Здравствуйте.

Пользователем [Source Io Owner] пройден порог [Quota Threshold]% лимита на ресурс [Quota Remote Paths]. Удалите неиспользуемые файлы и файлы, не относящиеся к служебным обязанностям

Лимит: [Quota Limit MB] MB. | Использовано: [Quota Used MB] MB. ([Quota Used Percent]%) | Доступно: [Quota Free MB] MB.

Квота установлена в соответствии с (документ) и в случае производственной необходимости может быть увеличена по заявке.(указать ветку). При этом сотрудниками ИТ предварительно выполняется проверка данных на соответствие требованиям Положения. Более подробную информацию можно получить на портале: https://
'@
        $body2 = @'
Здравствуйте.

Пользователем [Source Io Owner] исчерпано [Quota Threshold]% лимита на ресурс [Quota Remote Paths]. Удалите неиспользуемые файлы и файлы, не относящиеся к служебным обязанностям

Лимит: [Quota Limit MB] MB. | Использовано: [Quota Used MB] MB. ([Quota Used Percent]%) | Доступно: [Quota Free MB] MB.

Квота установлена в соответствии с (документ) и в случае производственной необходимости может быть увеличена по заявке.(указать ветку). При этом сотрудниками ИТ предварительно выполняется проверка данных на соответствие требованиям Положения. Более подробную информацию можно получить на портале: https://
'@
    }
}
    $subject1 = 'Пройден порог [Quota Threshold]% лимита на ресурс.'
    $subject2 = 'Исчерпано [Quota Threshold]% лимита на ресурс.'
    $mailto = '[Source Io Owner Email]'
    $fsrmAction1 = New-FsrmAction -Type Email -MailTo $mailto -Subject $subject1 -Body $body1 -RunLimitInterval 60 -Verbose
    $fsrmAction2 = New-FsrmAction -Type Email -MailTo $mailto -Subject $subject2 -Body $body2 -RunLimitInterval 60 -Verbose
    $threshold1 = New-FsrmQuotaThreshold -Percentage 95 -Action $fsrmAction1
    $threshold2 = New-FsrmQuotaThreshold -Percentage 100 -Action $fsrmAction2

    switch ($Type) {
    "FR" {
        # FR 10Gb
        New-FsrmQuotaTemplate -Name "FR 10 Gb Hard" -Size 10Gb -Threshold $threshold1,$threshold2

        # FR 15 - 50 Gb, step 5Gb
        for ($i = 15; $i -le 45; $i = $i + 5) {
            New-FsrmQuotaTemplate -Name "FR $($i) Gb TEMP" -Size ($i * 1Gb) -Threshold $threshold1,$threshold2
        }

        # FR 50 - 90 Gb, step 10Gb
        for ($i = 50; $i -le 90; $i = $i + 10) {
            New-FsrmQuotaTemplate -Name "FR $($i) Gb TEMP" -Size ($i * 1Gb) -Threshold $threshold1,$threshold2
        }

        # FR 100 - 200 Gb, step 50Gb
        for ($i = 100; $i -le 200; $i = $i + 50) {
            New-FsrmQuotaTemplate -Name "FR $($i) Gb TEMP" -Size ($i * 1Gb) -Threshold $threshold1,$threshold2
        }
    }
    "FS" {
        # FS 10 Gb Hard
        New-FsrmQuotaTemplate -Name "FS 10 Gb Hard" -Size 10Gb -Threshold $threshold1,$threshold2
    }
    }
