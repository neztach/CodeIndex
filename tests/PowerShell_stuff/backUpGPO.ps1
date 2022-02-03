

Backup-GPO -Guid <GUID HERE> -Path C:\Temp\GPOS\Report_Exports


$repo = Import-Csv C:\path\to\GPOCheck.csv


$repo | %{

    $gname = $_.Id
    New-Item -Path "C:\Temp\GPOS\Report_Exports" -Name "$gname" -ItemType "directory"
    Backup-GPO -Guid $gname -Path "C:\Temp\GPOS\Report_Exports\$gname"
}