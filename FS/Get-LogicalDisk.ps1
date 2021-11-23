
function Get-WmiCustom()

{

Param(

[parameter(Mandatory=$true)]

[string]$ComputerName,

[string]$Namespace = "root\cimv2",

[string]$Class,

[System.Management.Automation.PSCredential]$Credential=$null,

[int]$Timeout=15

)

    $timeoutseconds = new-timespan -seconds $timeout

    $ConnectionOptions = new-object System.Management.ConnectionOptions

    if ($Credential) {

        $ConnectionOptions.Impersonation = "Impersonate"

        $ConnectionOptions.Authentication = "Default"

        $ConnectionOptions.Username = $Credential.UserName

        $ConnectionOptions.SecurePassword = $Credential.Password

        $ConnectionOptions.Timeout = $timeoutseconds

 

    }

    $EnumerationOptions = new-object System.Management.EnumerationOptions

 

    $EnumerationOptions.set_timeout($timeoutseconds)

 

    $assembledpath = "\\" + $computername + "\" + $namespace

    # write-host $assembledpath -foregroundcolor yellow

 

    $Scope = new-object System.Management.ManagementScope $assembledpath, $ConnectionOptions

    $Scope.Connect()

 

    $querystring = "SELECT * FROM " + $class

    # write-host $querystring

 

    $query = new-object System.Management.ObjectQuery $querystring

    $searcher = new-object System.Management.ManagementObjectSearcher

    $searcher.set_options($EnumerationOptions)

    $searcher.Query = $querystring

    $searcher.Scope = $Scope

 

    trap { $_ } $result = $searcher.get()

 

    return $result

}

 

function Get-LogicalDisk {

    [CmdletBinding()]

    param(

        [Parameter(ValueFromPipeline=$true, Position=0)]

        [ValidateNotNullOrEmpty()]

        [System.String[]]

        $ComputerName=$env:COMPUTERNAME,

 

        [Parameter(Position=1)]

        [ValidateNotNullOrEmpty()]

        [ValidateSet("KB","MB","GB", "TB")]

        $Size = "GB", # KB, MB, GB, TB

 

        [Parameter(Mandatory=$false, Position=2)]

        [System.Management.Automation.PSCredential]

        $Credential=$null

    )

    begin {

        try {

            $divider = 3

            switch ($Size.ToLower()) {

                "kb" {

                    $divider = 1

                    break

                }

                "mb" {

                    $divider = 2

                    break

                }

                "gb" {

                    $divider = 3

                    break

                }

                "tb" {

                    $divider = 4

                    break

                }

                default {

                    Write-Error "-Size parameter must be KB, MB, GB or TB"

                    throw

                    break

                }

            }

 

            $results = @()

 

        } catch {

            throw

        }

    }

    process {

        try {

            foreach ($Computer in $ComputerName){

                if ($Credential) {

                    $logdisks = Get-WmiCustom -class Win32_LogicalDisk -computer $Computer -Timeout 30 -Credential $Credential

                } else {

                    $logdisks = Get-WmiCustom -class Win32_LogicalDisk -computer $Computer -Timeout 30

                }

                foreach ($logdisk in $logdisks) {

                    if ($logdisk.DriveType -eq 3) {

                        $result = New-Object PSObject -Property @{

                            ComputerName = $Computer

                            DeviceID = $logdisk.DeviceID

                            FreeSpace = [Math]::Round(($logdisk.FreeSpace/[Math]::Pow(1024, $divider)), 0)

                            Size = [Math]::Round(($logdisk.Size/[Math]::Pow(1024, $divider)), 0)

                            VolumeName = $logdisk.VolumeName

                        }

                        $results += $result | Select ComputerName, DeviceID, FreeSpace, Size, VolumeName

                    }

                }

            }

        } catch {

            throw

        }

    }

    end {

        try {

            return $results

        } catch {

            throw

        }

    }

}