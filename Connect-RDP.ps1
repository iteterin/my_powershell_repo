function Connect-RDP {
	param( 
        [Parameter(Mandatory = $true)]
        [Alias('Server')]
        [ValidateNotNull()]
        [string]$srv,

        [Parameter(Mandatory = $false)] 
        [switch]$Admin = $false, 

        [Parameter(Mandatory = $true, ValueFromPipeLine = $true, ValueFromPipelineByPropertyName = $true)] 
        [Alias('PSCredential')] 
        [ValidateNotNull()] 
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()] 
        $Credentials
     )
	
	
	If ( $Credentials -ne $null )
		{
		If ($srv)
			{
			$usr = $Credentials.GetNetworkCredential().UserName
			$pwd = $Credentials.GetNetworkCredential().Password
			$sTemp = cmdkey /generic:TERMSRV/$srv /user:$usr /pass:$pwd
			If ($Admin)
				{
				Start-Process "mstsc.exe" -ArgumentList "/admin /v:$srv" -NoNewWindow
				}
				else
					{
					Start-Process "mstsc.exe" -ArgumentList "/admin /v:$srv" -NoNewWindow
					}
			sleep 7
			$sTemp = cmdkey /delete:TERMSRV/$srv
			}
			else { Write-Host ("Target Server is not defined") }
		}
	}