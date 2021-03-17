Import-Module "\\url-vmware-vrm\iteterin$\Tools\JiraPS-master\JiraPS-master\JiraPS"
Set-JiraConfigServer 'https://jira.megafon.ru'

function Test-Cred {
           
    [CmdletBinding()]
    [OutputType([String])] 
       
    Param ( 
        [Parameter( 
            Mandatory = $false, 
            ValueFromPipeLine = $true, 
            ValueFromPipelineByPropertyName = $true
        )] 
        [Alias( 
            'PSCredential'
        )] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] 
        $Credentials
    )
    $Domain = $null
    $Root = $null
    $Username = $null
    $Password = $null
      
    If($Credentials -eq $null)
    {
        Try
        {
            $Credentials = Get-Credential "domain\$env:username" -ErrorAction Stop
        }
        Catch
        {
            $ErrorMsg = $_.Exception.Message
            Write-Warning "Failed to validate credentials: $ErrorMsg "
            Pause
            Break
        }
    }
      
    # Checking module
    Try
    {
        # Split username and password
        $Username = $credentials.username
        $Password = $credentials.GetNetworkCredential().password
  
        # Get Domain
        $Root = "LDAP://" + ([ADSI]'').distinguishedName
        $Domain = New-Object System.DirectoryServices.DirectoryEntry($Root,$UserName,$Password)
    }
    Catch
    {
        $_.Exception.Message
        Continue
    }
  
    If(!$domain)
    {
        Write-Warning "Something went wrong"
    }
    Else
    {
        If ($domain.name -ne $null)
        {
            return $true
        }
        Else
        {
            return $false
        }
    }
}

cd $env:TEMP

#Получаем данные от УЗ с нужными правами
do { $Credential = Get-Credential -Message "Введите имя учетной записи БЕЗ указания домена" } until (Test-Cred -Credentials $Credential)

$JiraUserName = $Credential.UserName

$WeekOfYear = $(Get-Date -UFormat %V) -as [int]
$NextWeek = $WeekOfYear+1

$Sprint = "$(Get-Date -UFormat %Y) week $WeekOfYear"
$NextSprint = "$(Get-Date -UFormat %Y) week $NextWeek"

$Sprint
$NextSprint

$QueryThisWeek = 'project = "VRM" AND assignee = "'+$JiraUserName+'" AND sprint = "'+$Sprint+'"'
$QueryNextWeek = 'project = "VRM" AND assignee = "'+$JiraUserName+'" AND sprint = "'+$NextSprint+'"'

$Style = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

$FileName = "Jira_$($Sprint -replace " ","_").html"
$CurrentPath = $PWD.Path -replace [regex]::Escape("Microsoft.PowerShell.Core\FileSystem::")

$table_name = "Задачи в Jira"
$table = New-Object system.Data.DataTable "$table_name"

$column0 = New-Object system.Data.DataColumn 'Номер задачи',([string])
$column1 = New-Object system.Data.DataColumn 'Статус',([string])
$column2 = New-Object system.Data.DataColumn 'Заголовок',([string])
$column3 = New-Object system.Data.DataColumn 'Комментарий',([string])

$table.columns.add($column0)
$table.columns.add($column1)
$table.columns.add($column2)
$table.columns.add($column3)

New-JiraSession -Credential $Credential | Out-Null

$ThisWeekTask = Get-JiraIssue -Query $QueryThisWeek

foreach ($current in $ThisWeekTask) {
    
    $TempComment = $null
    $TempComment = ($current | Get-JiraIssueComment | Select-Object -Last 1).Body


    $row = $table.NewRow()
        $row.'Номер задачи' =  $current.Key
        $row.Заголовок = $current.Summary
        $row.Статус = $current.Status
        $row.Комментарий = $TempComment
    $table.Rows.Add($row)
}

$NextWeekTask = Get-JiraIssue -Query $QueryNextWeek

$row = $table.NewRow()
$row.'Номер задачи'="Задачи следующей недели"
$table.Rows.Add($row)

foreach ($current in $NextWeekTask) {
    
    $TempComment = $null
    $TempComment = ($current | Get-JiraIssueComment | Select-Object -Last 1).Body


    $row = $table.NewRow()
        $row.'Номер задачи' =  $current.Key
        $row.Заголовок = $current.Summary
        $row.Статус = $current.Status
        $row.Комментарий = $TempComment
    $table.Rows.Add($row)
}

Get-JiraSession | Remove-JiraSession

if(Test-Path $CurrentPath\$FileName){
    Remove-Item -Path "$CurrentPath\$FileName" -Confirm:$false -Force
    $table | ConvertTo-Html -Property 'Номер задачи',Статус,Заголовок,Комментарий -As Table -Title $table_name -Head $Style  | Out-File -FilePath .\$FileName
}
else {
    $table | ConvertTo-Html -Property 'Номер задачи',Статус,Заголовок,Комментарий -As Table -Title $table_name -Head $Style  | Out-File -FilePath .\$FileName
}


Start-Process iexplore -ArgumentList "-New $CurrentPath\$FileName" 