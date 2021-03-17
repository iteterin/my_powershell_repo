$broker = ""
$name = "" #FarmName rds.local - имя фермы, по которому подключаются юзеры
$targetuser = "sardaana.g.yakovleva"

$data = Invoke-Command -ComputerName $broker -ArgumentList $name -ScriptBlock {Import-Module RemoteDesktopServices; $name_1 = $args[0]; Get-ChildItem RDS:\RDSFarms\$name_1\Servers | select name}
$data.Name |%{  
Write-Host -ForegroundColor Yellow $_;
    $server = $_
    if (Test-Connection $server -Quiet) {
            query session /server:$server | ?{ $_ -notmatch '^ SESSIONNAME' } | %{
                $item = "" | Select "Server", "Active", "SessionName", "Username", "Id", "State", "Type", "Device"
                $item.Server = $server
                #$item.Active = $_.Substring(0,1) -match '>'
                $item.SessionName = $_.Substring(1,18).Trim()
                $item.Username = $_.Substring(19,20).Trim()
                $item.Id = $_.Substring(39,9).Trim()
                $item.State = $_.Substring(48,8).Trim()
                $item.Type = $_.Substring(56,12).Trim()
                $item.Device = $_.Substring(68).Trim()
                #$item
                if ($item.Username -match $targetuser) { Write-Host -ForegroundColor Red $item.Server; $item; pause;}

            }

    }

    }
