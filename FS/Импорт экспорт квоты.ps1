Get-FsrmQuota | Export-Clixml "C:\tmp\quotas.xml" -Encoding UTF8

	Import-Clixml -Path "C:\tmp\quotas.xml"| %{
    	$Quota = $_
   	New-FSRMQuota -Path $Quota.Path `
                  -Description $Quota.Description `
                  -Template $Quota.Template `
                  -Size $Quota.Size `
                  -Disabled:([System.Convert]::ToBoolean($Quota.Disabled)) `
                  -SoftLimit:([System.Convert]::ToBoolean($Quota.SoftLimit)) `
                  -Threshold $Quota.Threshold
	}	