<#
.Synopsis
   Skript for get path for files after scaning spacesniffer, for send result FedTechSupport for del with user/
.DESCRIPTION
   Skript have next parametrs:
   -Path             Path to audit.                 Example: 'C:\Users\pushkin'
   -Extensions       Extensions to audit            Example1: "*.pst"; Example2: "*.cr2", "*.exe"; Example3: @("*.raw", "*.rar", "*.move")
   -ExportToHTML     Switch to Export in HTML file. Use -ExportHTMLPath for set direcrory to export. By default, set '.\'
   -ExportHTMLPath   Set path to export HTML file.  Example: 'C:\tmp\'
   -ExportToCSV      Switch to Export in CSV file.  Use -ExportCSVPath for set direcrory to export. By default, set '.\'
   -ExportCSVPath    Set path to export CSV file.   Example: 'S:\tmp_fs\' 
.EXAMPLE
   .\Run-AuditFiles.ps1 -Path D:\Personal -Extensions *.pst
.EXAMPLE
   .\Run-AuditFiles.ps1 -Path D:\Personal -Extensions *.pst -ExportToHTML
.EXAMPLE
   .\Run-AuditFiles.ps1 -Path D:\Personal -Extensions *.pst -ExportToHTML -ExportHTMLPath "C:\tmp4HTML\" -ExportToCSV -ExportCSVPath "C:\tmp4CSV\"
#> 

[CmdletBinding()]

    Param
    (
        # Path to audit. Example: 'C:\Users\pushkin'
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]$Path,

        # Extensions to audit Example1: "*.pst"; Example2: "*.cr2", "*.exe"; Example3: @("*.raw", "*.rar", "*.move")
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=1)]
        $Extensions,
        
        # Switch to Export in HTML file. Use -ExportHTMLPath for set direcrory to export. By default, set '.\'
        [Parameter(Mandatory=$false)]
        [switch]$ExportToHTML,

        # Path to export HTML file. Example: 'C:\tmp\audit.html'
        [Parameter(Mandatory=$false)]
        [string]$ExportHTMLPath = ".\",
        
        # Switch to Export in CSV file. Use -ExportCSVPath for set direcrory to export. By default, set '.\'
        [Parameter(Mandatory=$false)]
        [switch]$ExportToCSV,
        
        # Path to export CSV file. Example: 'C:\tmp\audit.csv' 
        [Parameter(Mandatory=$false)]
        [string]$ExportCSVPath = ".\"

    )

    Process
    {
        $Style = @"
<style>
TABLE {border-width: 1px; border-style: solid; border-color: black; border-collapse: collapse;}
TD {border-width: 1px; padding: 3px; border-style: solid; border-color: black;}
</style>
"@

        $table_name = $env:COMPUTERNAME
        $table = New-Object system.Data.DataTable "$table_name"

        $column0 = New-Object system.Data.DataColumn File,([string])
        $column1 = New-Object system.Data.DataColumn SizeMB,([string])
        $column2 = New-Object system.Data.DataColumn Extension,([string])
        $column3 = New-Object system.Data.DataColumn Path,([string])
        $column4 = New-Object system.Data.DataColumn FullPath,([string])
        $column4a = New-Object system.Data.DataColumn URI,([string])
        $column5 = New-Object system.Data.DataColumn LastAccessTime,([string])
        $column6 = New-Object system.Data.DataColumn CreationTime,([string])
        $column7 = New-Object system.Data.DataColumn LastWriteTime,([string])

        $table.columns.add($column0)
        $table.columns.add($column1)
        $table.columns.add($column2)
        $table.columns.add($column3)
        $table.columns.add($column4)
        $table.columns.add($column4a)
        $table.columns.add($column5)
        $table.columns.add($column6)
        $table.columns.add($column7) 
   
        foreach ($Extension in $Extensions){ 
           [System.IO.Directory]::EnumerateFiles($path,$Extension,"AllDirectories") | %{
              $filepath = $_
              $file = New-Object System.IO.FileInfo($filepath)
                
              $row = $table.NewRow()
                $row.File = $file.BaseName
                $row.SizeMB = $file.Length/1Mb
                $row.Extension = $file.Extension
                $row.Path = $file.Directory
                $row.FullPath = $file.FullName
                $row.URI = "coming soon"
                $row.LastAccessTime = $file.LastAccessTime
                $row.CreationTime = $file.CreationTime
                $row.LastWriteTime = $file.LastWriteTime
              $table.Rows.Add($row)

            }
         } 
           if ($ExportToHTML){
            $ExportHTMLPathName = "$('{0:yyyy_MM_dd}' -f $(Get-Date))_Audit.html"
            if (Test-Path $ExportHTMLPath ){ 
                $table | ConvertTo-Html -Property File,Extension,SizeMB,FullPath,LastAccessTime,CreationTime,LastWriteTime -As Table -Title $table_name -Head $Style  | Out-File -FilePath $($ExportHTMLPath+$ExportHTMLPathName)
            }
            else {
                New-Item -Path $ExportHTMLPath -ItemType Directory
                $table | ConvertTo-Html -Property File,Extension,SizeMB,FullPath,LastAccessTime,CreationTime,LastWriteTime -As Table -Title $table_name -Head $Style  | Out-File -FilePath $($ExportHTMLPath+$ExportHTMLPathName)
            }

        }
        if ($ExportToCSV ){
            $ExportCSVPathName = "$('{0:yyyy_MM_dd}' -f $(Get-Date))_Audit.csv"
            if (Test-Path $ExportCSVPath ){
                $table | Export-Csv -Delimiter ';' -Encoding utf8 -NoTypeInformation -Path $($ExportCSVPath+$ExportCSVPathName)
            }
            else {
                New-Item -Path $ExportCSVPath -ItemType Directory
                $table | Export-Csv -Delimiter ';' -Encoding utf8 -NoTypeInformation -Path $($ExportCSVPath+$ExportCSVPathName)
            }
        }
    $table | Sort SizeMB 
    }