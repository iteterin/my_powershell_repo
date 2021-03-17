#dependency
#https://www.powershellgallery.com/packages/JiraPS

function Get-JiraData {

    Import-Module JiraPS

    Set-JiraConfigServer 'https://jira.megafon.ru'

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
    
    @("alexander.alpatov",
    "alexander.se.borisov",
    "ilya.teterin",
    "Vadim.Zhirov",
    "Artem.Sadovsky",
    "Yuri.Tsvetkov",
    "alexey.koshelev",
    "evgeny.rzhavin",
    "maxim.kabanov",
    "alexey.grebenuk") | %{

        $Username = $_

        $QueryThisWeek = 'project = "VRM" AND assignee = "'+$UserName+'" AND sprint = "'+"$(Get-Date -UFormat %Y) week $(Get-Date -UFormat %V)"+'"'

        New-JiraSession -Credential $Credential | Out-Null

        $ThisWeekTask = Get-JiraIssue -Query $QueryThisWeek

        foreach ($current in $ThisWeekTask) {
    
            $TempComment = $null
            $TempComment = ($current | Get-JiraIssueComment | Select-Object -Last 1).Body


            $row = $table.NewRow()
                $row.'Номер задачи' =  $current.Key
                $row.Исполнитель = $UserName
                $row.Заголовок = $current.Summary
                $row.Статус = $current.Status
                $row.Комментарий = $TempComment
            $table.Rows.Add($row)
        }
    }
    $Out_null = Get-JiraSession | Remove-JiraSession

    $Global:Style = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

}

$FileName = "Jira_$($Sprint -replace " ","_").html"
$CurrentPath = $PWD.Path -replace [regex]::Escape("Microsoft.PowerShell.Core\FileSystem::")

Get-JiraData

if(Test-Path $CurrentPath\$FileName){
    Remove-Item -Path "$CurrentPath\$FileName" -Confirm:$false -Force
    $table | ConvertTo-Html -Property 'Номер задачи',Статус,Исполнитель,Заголовок,Комментарий -As Table -Title $table.TableName -Head $Style  | Out-File -FilePath .\$FileName
}
else {
    $table | ConvertTo-Html -Property 'Номер задачи',Статус,Исполнитель,Заголовок,Комментарий -As Table -Title $table.TableName -Head $Style  | Out-File -FilePath .\$FileName
}


Start-Process iexplore -ArgumentList "-New $CurrentPath\$FileName" 