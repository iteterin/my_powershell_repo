<#
.Synopsis
   Получить список путей по имени сервера
.DESCRIPTION
   Длинное описание
.EXAMPLE
   Get-DfsnPath -Server DV-KHB-FS01
#>
[CmdletBinding()]
[Alias()]
[OutputType([int])]
    Param
    (
        # Имя сервера
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$Servers
    )

    Begin
    {
        $Assembly = ("System","System.DirectoryServices")
        $Library = @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.DirectoryServices;

namespace Library
{
public class AD
    {
	public static string GetComputerDomain()
        {
            try
            {
                return System.DirectoryServices.ActiveDirectory.Domain.GetComputerDomain().Name;
            }
            catch (Exception)
            {
                return null;
            }
        }
    public static SearchResultCollection GetDFSRootNamespaces(string s)
        {
            DirectoryEntry oDE = new DirectoryEntry(s);
            DirectorySearcher oDS = new DirectorySearcher();
            oDS.SearchRoot = oDE;

            oDS.Filter = "(&(objectClass=msDFS-Namespacev2))";
            oDS.SearchScope = SearchScope.Subtree;
            oDS.PageSize = 10000;

            SearchResultCollection oResults = oDS.FindAll();
            if (oResults != null)
            {
                return oResults;
            }
            else
            {
                return null;
            }
        }
    }
	
public class DFS
    {
        [DllImport("Netapi32.dll", CharSet = CharSet.Auto, SetLastError = true /*//Return value (NET_API_STATUS) contains error */)]
        public static extern int NetDfsEnum(
            [MarshalAs(UnmanagedType.LPWStr)]string DfsName,
            int Level,
            int PrefMaxLen,
            out IntPtr Buffer,
            [MarshalAs(UnmanagedType.I4)]out int EntriesRead,
            [MarshalAs(UnmanagedType.I4)]ref int ResumeHandle);

        const int MAX_PREFERRED_LENGTH = 0xFFFFFFF;
        const int NERR_Success = 0;
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DFS_INFO_3
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string EntryPath;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string Comment;
            public UInt32 State;
            public UInt32 NumberOfStorages;
            public IntPtr Storages;
        }
        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DFS_INFO_1
        {
            [MarshalAs(UnmanagedType.LPWStr)]
            public string EntryPath;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct DFS_STORAGE_INFO
        {
            public Int32 State;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ServerName;
            [MarshalAs(UnmanagedType.LPWStr)]
            public string ShareName;
        }
        
		public struct DFSLink
        {
            public string RootPath;
            public string Path;
            public string TargetPath;
            public DFSLink(string rootPath, string path, string targetPath)
            {
                this.RootPath = rootPath;
                this.Path = path;
                this.TargetPath = targetPath;
            }
        }

        [DllImport("Netapi32.dll", SetLastError = true)]
        static extern int NetApiBufferFree(IntPtr Buffer);

        static int sErrorNetDfsEnum = 0;

		public static List<DFSLink> GetDfsLinks(string sDFSRoot)
        {
            List<DFSLink> links = new List<DFSLink>();
            IntPtr pBuffer = new IntPtr();
            int entriesRead = 0;
            int resume = 0;
            string[] aRootPath = sDFSRoot.Split('\\');
            sErrorNetDfsEnum = 0;

            var iResult = NetDfsEnum(sDFSRoot, 3, MAX_PREFERRED_LENGTH, out pBuffer, out entriesRead, ref resume);
            if (iResult == 0)
            {
                for (int j = 0; j < entriesRead; j++)
                {
                    DFS_INFO_3 oDFSInfo = (DFS_INFO_3)Marshal.PtrToStructure(pBuffer + j * Marshal.SizeOf(typeof(DFS_INFO_3)), typeof(DFS_INFO_3));

                    for (int i = 0; i < oDFSInfo.NumberOfStorages; i++)
                    {
                        IntPtr pStorage = new IntPtr(oDFSInfo.Storages.ToInt64() + i * Marshal.SizeOf(
                           typeof(DFS_STORAGE_INFO)));
                        DFS_STORAGE_INFO oStorageInfo = (DFS_STORAGE_INFO)Marshal.PtrToStructure(pStorage,
                            typeof(DFS_STORAGE_INFO));

                        string sPath = oDFSInfo.EntryPath;
                        string[] aPathComp = sPath.Split('\\');
                        if (aPathComp.Length > 4 && !sPath.Contains(".DFSFolderLink"))
                        {
                            if (aRootPath[2].ToLower() != aPathComp[2].ToLower())
                            {
                                sPath = sPath.Replace(@"\\" + aPathComp[2] + @"\", @"\\" + aRootPath[2] + @"\");
                            }
                            string sTarget = @"\\" + oStorageInfo.ServerName + @"\" + oStorageInfo.ShareName;
                            links.Add(new DFSLink(sDFSRoot, sPath, sTarget));
                        }
                    }
                }
            }

            sErrorNetDfsEnum = iResult;
            NetApiBufferFree(pBuffer);
            return links;
        }
	}
}
"@
    }
    Process
    {
        Write-Verbose "===================================="
        write-Verbose "Compiling C# Library ..."
        try {
	        Add-Type -ReferencedAssemblies $Assembly -TypeDefinition $Library -Language CSharp -ErrorAction Stop
	        write-Verbose "Ok"
	        }
        catch {
	        Write-Warning "An error occurred attempting to add the .NET Framework namespace Library to the PowerShell session:`n"
            Write-Warning $Error[0].Exception.Message
	        write-Verbose "===================================="
	        write-Verbose "`n`n"
	        write-Verbose "Press any key to exit ..."
	        [void][System.Console]::ReadKey($true)
	        exit
	        }

        write-Verbose "Loading DFS NameSpaces List ..."
        try {
	        $sDomain = [Library.AD]::GetComputerDomain()
	        if ($sDomain.Contains(".")) {
		        $aTemp = $sDomain.Split(".")
		        $sLDAP = "LDAP://"
		        for($n=0;$n -lt $aTemp.Count;$n++) { $sLDAP = $sLDAP + "DC=" + $aTemp[$n] + "," }
		        $sLDAP = $sLDAP.TrimEnd(",")
		        }
		        else { $sLDAP = "LDAP://DC="+$sDomain }
	
	        $oNameSpaces = [Library.AD]::GetDFSRootNamespaces($sLDAP)
	        $aNameSpaces = $null
	        $oNameSpaces | ForEach-Object {
		        [string]$sTemp = (($_.Properties).name)
		        $aNameSpaces += , $sTemp
		        }
	
	        if ($aNameSpaces) { $aNameSpaces = $aNameSpaces | Sort }
	
	        write-Verbose "Ok"
	        write-Verbose "Total DFS NameSpaces: $($aNameSpaces.Count)"
	        }
        catch {
	        Write-Warning "An error occurred attempting to get the DFS NameSpaces List:`n"
            Write-Warning $Error[0].Exception.Message
	        write-Verbose "===================================="
	        write-Verbose "`n`n"
	        write-Verbose "Press any key to exit ..."
	        [void][System.Console]::ReadKey($true)
	        exit
	        }
        
        Write-Progress -Id 1 -Activity "Loading DFS NameSpaces List ..." -Status "Begin"

        $dfsns = $null
        If ($aNameSpaces) {
	        for($n=0;$n -lt $aNameSpaces.Count;$n++) {
		        $Percent = $([math]::Round($(($n/$aNameSpaces.Count)*100),0))
                Write-Progress -Id 1 -Activity "Loading DFS NameSpaces List ..." -Status "Loading \\$($sDomain)\$($aNameSpaces[$n])\ ... $Percent %" -PercentComplete $Percent
                write-Verbose ("Loading \\$($sDomain)\$($aNameSpaces[$n])\ ... ")
		        
                try {
			        $DFSLinks = $null
			        $DFSLinks = [Library.DFS]::GetDfsLinks("\\"+$sDomain+"\"+$aNameSpaces[$n])
			        $DFSLinks = $DFSLinks | Sort-Object -Property Path
			
			        $dfsns = $dfsns + $DFSLinks
			        
                    write-Verbose "`t => $($DFSLinks.Count) targets"
			        }
		        catch { Write-Warning $_.Exception }
		        }
	        }
        Write-Progress -Id 1 -Activity "Loading DFS NameSpaces List ..." -Status "Complite $Percent %" -PercentComplete $Percent -Completed:$true
        write-Verbose "`n"
        write-Verbose "Total loaded $($dfsns.Count) targets"
        write-Verbose "===================================="
        write-Verbose "`n"
        write-Verbose "`n"
    }
    End
    {
        $Result = @();

        foreach ($Server in $Servers){
            $Result += $dfsns |?{$_.TargetPath -match [regex]::Escape("$Server")}
        }
        
        Return $Result
    }
