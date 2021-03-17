function Get-MegaACL {
#—скрипт по получению ACL на ресурсе по запросу ‘“ѕѕ
#ѕараметры: 
#-Path - путь к директории в формате \\... или %буквадиска%:\...
#-NoLocal - вывод ACL без локальных пользователей/групп/пользователей других доменов (ритеил, пбк, йота, мегалабс и т.д.)
#-NoUsers - вывод ACL без пользователей домена
#-NoGroup - вывод ACL без групп AD

    [CmdletBinding()]
    Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript( {(Test-Path $_)})]
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [string]$Paths, 
        [switch]$NoLocal,
        [switch]$NoUsers,
        [switch]$NoGroup
        )

    $data = @()
    $Paths | ForEach-Object {
        $Path = $_
        Write-Verbose $Path
        (Get-Acl -Path $Path).Access | ForEach-Object {
            $IdentityReference = $_.IdentityReference
            if ($IdentityReference -match $env:USERDOMAIN) {
                $Sam = $IdentityReference -replace "$env:USERDOMAIN\\"
                $Type = $(Get-ADObject -filter {SamAccountName -eq $Sam} |Select-Object -Property ObjectClass).ObjectClass
                Write-Verbose ("ип объекта: {0}" -f $Type)
                Write-Verbose ("ќбъект: {0}" -f $Sam)
                if ($Type -eq "user") {
                    if($NoUsers) {}
                    else {
                        Get-ADUser -Identity $Sam -Properties * | ForEach-Object { # Select Name,Description,DistinguishedName,info
                            $data_AD = $_
                            $Data_TMP = "" | Select-Object -Property Path, Name, Description, info, DistinguishedName
                            $Data_TMP.Name = $data_AD.EmailAddress
                            $Data_TMP.Description = $data_AD.Department + ", " + $data_AD.extensionAttribute10
                            $Data_TMP.DistinguishedName = $data_AD.DistinguishedName
                            $Data_TMP.info = "Enabled: " + $data_AD.Enabled
                            $Data_TMP.Path = $Path
                            $data += $Data_TMP
                        }
                    }
                }
                elseif ($Type -eq "group") {
                    if ($NoGroup) {}
                    else {
                        Get-ADGroup -Identity $Sam -Properties Description, info | Select-Object -Property Name, Description, DistinguishedName, info| ForEach-Object {
                            Write-Verbose $_
                            $data_AD = $_
                            $Data_TMP = "" | Select-Object -Property Path, Name, Description, info, DistinguishedName
                            $Data_TMP.Name = $data_AD.Name
                            $Data_TMP.Description = $data_AD.Description
                            $Data_TMP.DistinguishedName = $data_AD.DistinguishedName
                            $Data_TMP.info = $data_AD.info
                            $Data_TMP.Path = $Path
                            $data += $Data_TMP
                        }
                    }
                }

            }
            else {
                if($NoLocal){}
                else {
                    $Sam = $IdentityReference
                    $Data_TMP = "" | Select-Object -Property Path, Name, Description, info, DistinguishedName
                    $Data_TMP.Name = $Sam
                    $Data_TMP.Description = ""
                    $Data_TMP.DistinguishedName = ""
                    $Data_TMP.info = $_.FileSystemRights
                    $Data_TMP.Path = $Path
                    $data += $Data_TMP
                    }
            }
        }
    }
 return $data
}