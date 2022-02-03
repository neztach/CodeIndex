
$dt = Get-Date -Format MM-dd-yyyy_hh.mm.ss

$sour = "C:\Users\Example\Desktop\TEST-folder"
$dest = "\\path\to\some\networkShare"
$logfile = "C:\Users\Example\Desktop\logs\TEST-folder.$dt.log"


robocopy $sour $dest /E /Z /MIR /MT:32 /XD `$RECYCLE.BIN /XF Thumbs.db /R:1 /W:1 /TEE /NP /LOG:$logfile

