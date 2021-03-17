[CmdletBinding()]
param (
    [Parameter(Position=0,
        Mandatory=$True,
        ValueFromPipeline=$true)]
    [string[]]$Path,
    [Parameter(Position=1,
        Mandatory=$True,
        ParameterSetName='ExpDays')]
    [int]$ExpiredDays=-1,
    [Parameter(Position=2,
        Mandatory=$True,
        ParameterSetName='ExpHours')]
    [int]$ExpiredHours=-1,
    [Parameter(Position=3,
        Mandatory=$True,
        ParameterSetName='ExpMinutes')]
    [int]$ExpiredMinutes=-1,
    [Parameter(Position=4,
        Mandatory=$false)]
    [switch]$Recurse,
    [Parameter(Position=5,
        Mandatory=$false)]
    [string]$Filter,
    [Parameter(Position=6,
        Mandatory=$false)]
    [string[]]$Include,
    [Parameter(Position=7,
        Mandatory=$false)]
    [string[]]$Exclude
)
begin {
    Filter Filter-Age ([int]$Days=-1,[int]$Hours=-1,[int]$Minutes=-1) {
        if ($Days -ge 0) { $date = (Get-Date).AddDays($Days * -1) } 
        elseif ($Hours -ge 0) { $date = (Get-Date).AddHours($Hours * -1) } 
        elseif ($Minutes -ge 0) { $date = (Get-Date).AddMinutes($Minutes * -1) }
        if ($_.CreationTime -le $date) { $_ } 
        elseif ($_.LastWriteTime -le $date) { $_ } 
        elseif ($_.LastAccessTime -le $date) { $_ }
    }
}

process{
    if ($Recurse) {
        if ($ExpiredDays -ge 0) {
            #Write-Host ExpiredDays
            $deleteItems = Get-ChildItem -Path $Path -Recurse -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Days $ExpiredDays | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        } elseif ($ExpiredHours -ge 0) {
            #Write-Host ExpiredHours
            $deleteItems = Get-ChildItem -Path $Path -Recurse -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Hours $ExpiredHours | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        } elseif ($ExpiredMinutes -ge 0) {
            #Write-Host ExpiredMinutes
            $deleteItems = Get-ChildItem -Path $Path -Recurse -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Minutes $ExpiredMinutes | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        }
    } else {
        if ($ExpiredDays -ge 0) { 
            #Write-Host ExpiredDays
            $deleteItems = Get-ChildItem -Path $Path -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Days $ExpiredDays | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        } elseif ($ExpiredHours -ge 0) {
            #Write-Host ExpiredHours
            $deleteItems = Get-ChildItem -Path $Path -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Hours $ExpiredHours | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        } elseif ($ExpiredMinutes -ge 0) {
            #Write-Host ExpiredMinutes
            $deleteItems = Get-ChildItem -Path $Path -Filter $Filter -Include $Include -Exclude $Exclude -Force -ErrorAction SilentlyContinue | Filter-Age -Minutes $ExpiredMinutes | Sort-Object @{Expression={$_.FullName.Length}; Ascending=$false}
        }
    }
    # Delete a files first
    $deleteItems | ?{-not $_.PSIsContainer} | Remove-Item -Confirm:$false -ErrorAction SilentlyContinue -Force -Verbose
    # Then delete empty folders
    $deleteItems | ?{$_.PSIsContainer} | ?{ (Get-ChildItem -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue) -eq $null } | Remove-Item -Confirm:$false -ErrorAction SilentlyContinue -Force -Verbose
}