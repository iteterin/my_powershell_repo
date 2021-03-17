[CmdletBinding()]
Param(
        [ValidateNotNullOrEmpty()]
        [ValidateScript({(Test-Path $_)})]
        [Parameter(ValueFromPipeline=$True,Mandatory=$True)]
        [string[]]$Paths)

Process
{
   $data = @()
   $Paths |%{
        $Path = $_
        Write-Verbose $Path
        (Get-Acl -Path $Path).Access | Where-Object {$_.IdentityReference -match "MEGAFON"}|%{
            Write-Verbose $_
            Get-ADGroup -Identity $($_.IdentityReference -replace "MEGAFON\\") -Properties Description, info | Select Name,Description,DistinguishedName,info| %{
                Write-Verbose $_
                $data_AD = $_
                $Data_TMP = "" | Select Name,Description,DistinguishedName,info
                $Data_TMP.Name = $data_AD.Name
                $Data_TMP.Description = $data_AD.Description
                $Data_TMP.DistinguishedName = $data_AD.DistinguishedName
                $Data_TMP.info = $data_AD.info
                $data += $Data_TMP
             }
        }
   }
$data | fl
}
End
{	$data | fl
	pause
}