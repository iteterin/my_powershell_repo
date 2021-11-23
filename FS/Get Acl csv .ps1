cd C:\tmp\migration

$SRC = Import-Csv -Path .\src.csv -Encoding UTF8

$DataArr = @()

$SRC.Source | %{
    $Path = $_
    (Get-Acl -Path $Path).Access | Where-Object {$_.IdentityReference -match "MEGAFON"} |%{
        $DataTemp = ""|select Path, IdentityReference, FileSystemRights, AccessControlType
        $DataTemp.Path = $Path
        $DataTemp.IdentityReference = $_.IdentityReference
        $DataTemp.FileSystemRights = $_.FileSystemRights
        $DataTemp.AccessControlType = $_.AccessControlType
        $DataArr += $DataTemp
        #Get-ADGroup -Identity $($_.IdentityReference -replace "MEGAFON\\") -Properties Description | Select Name,Description,DistinguishedName | FL
    }
   
}

$DataArr | Export-CSV -Path .\ACLS.csv -Delimiter ';' -Encoding UTF8 -NoTypeInformation