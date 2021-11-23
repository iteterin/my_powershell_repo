#Writer : Ritesh PARAB 
#AIM : To get Orphand "$NtUninstall_KB" Folder Size from Multipal Servers.. 
cls
[Float]$Total = $null
[Float]$size  = $null
$colItems = $null
$servers = Get-Content d:\Wintech\orphaned\servers.txt
	foreach ($server in $servers) {
		$Total = $null
		try {	
			$Files = Get-ChildItem \\$server\c$\windows\ -Filter '$Ntunin*' -Force -ErrorAction Stop | ? {$_.PSIsContainer -eq $True} #? { $_.LastAccessTime.Date -lt "2012-11-25" }
				foreach ($fol in $files ){
					$colItems = (Get-ChildItem $fol.fullname -Recurse -Force | Measure-Object -property length -sum)
					$size = "{0:N2}" -f ($colItems.sum / 1MB)
					#Write-Host "$server `t$fol `t$size MB" 
					$Total += $size 
					
				}
			"Total Size For Orphaned Patched(KB) on $server is $total MB"
			}
		Catch {
		"`nError Found on $server >  $_ `n" 
		# Break;  
		}
	}	
		
