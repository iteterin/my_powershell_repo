 $Drive = @('D','E','F')
 $Disks = @{  
    
    'D' = @( 'D:\', 'H:\' )
    'E' = @( 'E:\', 'I:\' )
    'F' = @( 'F:\', 'J:\' )
    
 }
 
 $Drive | %{
  $CurrentDrive = $_ 
  
  Get-ChildItem $Disks.$CurrentDrive[0] -Directory | %{ 
 
  $Path = $_.Fullname; 

  $Dest = $Path -replace [regex]::Escape($Disks.$CurrentDrive[0]),$Disks.$CurrentDrive[1]
  $Param = "/E /ZB /COPYALL /XO /PURGE /R:1 /W:1 /MT /XD "+'$RECYCLE.BIN'+" /UNILOG:C:\tmp\$($Dest -replace ':',"_" -replace "\\").txt /TEE"

  Start-Process "robocopy" -ArgumentList "$Path $Dest $Param"
  }
}