Get-FsrmQuota | Export-Clixml "C:\tmp\q.xml" -Encoding UTF8

 $Drive = @('D','E')
 $Disks = @{  
    
    'D' = @( 'D:\', 'F:\' )
    'E' = @( 'E:\', 'H:\' )
    
 }

$Quotas = Import-Clixml -Path "C:\tmp\q.xml"

$Drive |%{
    $Letter = $_
    $Quotas |?{$_.Path -match [regex]::Escape($Letter)} | %{
        $Quota = $_
        $NewPath = $Quota.Path -replace [regex]::Escape($Disks.$Letter[0]),$Disks.$Letter[1]
        New-FSRMQuota -Path $NewPath -Description $Quota.Description -Template $Quota.Template -Size $Quota.Size -Disabled:([System.Convert]::ToBoolean($Quota.Disabled)) -SoftLimit:([System.Convert]::ToBoolean($Quota.SoftLimit)) -Threshold $Quota.Threshold 
    }

}

