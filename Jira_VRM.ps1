#dependency
#For Jira - https://www.powershellgallery.com/packages/JiraPS
#For EXCEL - https://www.powershellgallery.com/packages/PSExcel

$global:table = New-Object system.Data.DataTable "Задачи в Jira АРМ"

            $column0 = New-Object system.Data.DataColumn 'Номер задачи',([string])
            $column1 = New-Object system.Data.DataColumn 'Исполнитель',([string])
            $column2 = New-Object system.Data.DataColumn 'Статус',([string])
            $column3 = New-Object system.Data.DataColumn 'Заголовок',([string])
            $column4 = New-Object system.Data.DataColumn 'Комментарий',([string])

            $table.columns.add($column0)
            $table.columns.add($column1)
            $table.columns.add($column2)
            $table.columns.add($column3)
            $table.columns.add($column4)

$Credential = Get-Credential -Message "Введите имя учетной записи БЕЗ указания домена" -UserName $env:USERNAME

Set-JiraConfigServer 'https://jira.megafon.ru'
New-JiraSession -Credential $Credential | Out-Null

$QueryThisWeek = 'project = "VRM" AND sprint = "'+"$(Get-Date -UFormat %Y) week $(Get-Date -UFormat %V)"+'"'

$ThisWeekTask = Get-JiraIssue -Query $QueryThisWeek

foreach ($current in $ThisWeekTask) {
    
            $row = $table.NewRow()
                $row.'Номер задачи' =  $current.Key
                $row.Исполнитель = ($current.Assignee).DisplayName
                $row.Заголовок = $current.Summary
                $row.Статус = $current.Status
                $row.Комментарий = ($current.Comment | Select-Object -Last 1).Body
           $table.Rows.Add($row)
        }
        
Get-JiraSession | Remove-JiraSession 

$FileName = "Jira_$($Sprint -replace " ","_")_ARM-VDI.html"
#$FileName = "Jira_$($Sprint -replace " ","_")_ARM-VDI.csv"
#$FileName = "Jira_$($Sprint -replace " ","_")_ARM-VDI.xlsx"
$CurrentPath = $PWD.Path -replace [regex]::Escape("Microsoft.PowerShell.Core\FileSystem::")


if(Test-Path $CurrentPath\$FileName){
    Remove-Item -Path "$CurrentPath\$FileName" -Confirm:$false -Force
}

$Global:Style = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@


#Export-XLSX -Path "$CurrentPath\$FileName" -Table $table -AutoFit
#$table | Sort | Sort Исполнитель | Export-Csv -Path "$CurrentPath\$FileName" -Encoding UTF8 -Delimiter ';' -NoTypeInformation
$table | Sort | Sort Исполнитель | ConvertTo-Html -Property Test,'Номер задачи',Статус,Исполнитель,Заголовок,Комментарий -As Table -Title $table.TableName -Head $Style  | Out-File -FilePath .\$FileName
Start-Process iexplore -ArgumentList "-New $CurrentPath\$FileName" -Wait 

$msg = new-object -comobject wscript.shell 
$intAnswer = $msg.popup("Удалить фаил отчет?", ` 
0,"Jira VRM",4) 
If ($intAnswer -eq 6) { 
    Remove-Item -Path $CurrentPath\$FileName -Force -Confirm:$false
} 