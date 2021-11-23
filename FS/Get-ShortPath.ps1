$signature = @"
[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
public static extern uint GetShortPathName(string lpszLongPath, char[] lpszShortPath, int cchBuffer);
"@

$gspn = Add-Type -memberDefinition $signature -name "Win32ShortPath" -namespace Win32Functions -passThru
$length = $gspn::GetShortPathName($path,$null,0)
$buffer = New-Object char[] ($length-1)
[Void]$gspn::GetShortPathName($path,$buffer,$length)
cmd /c "rmdir /s/q $(-join $buffer)"
