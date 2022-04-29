# CodeIndex - A PowerShell module to index all your script/code files.
# Requirements: PSSQLite - "Install-Module -Name PSSQLite" - https://www.powershellgallery.com/packages/PSSQLite/1.1.0
# Use Get-Help <Set, New, Add, Get>-CodeIndex for more info. 


# Predefined languages with respective extensions. 
# Placing this outside of the New-CodeIndex function for ease of edits.
# The integer (SQLite boolean) at the end indicates if its an exclusion or not. 
# 0 (false) and 1 (true)
$PreLoadLangs = @(
    ("powershell", ".ps1", 0),
    ("powershell", ".psm1", 0),
    ("yaml", ".yml", 0),
    ("yaml", ".yaml", 0),
    ("batch", ".bat", 0),
    ("json", ".json", 0),
    ("python", ".py", 0),
    ("log", ".log", 1),
    ("text", ".txt", 0),
    ("csv", ".csv", 1),
    ("gunzip", ".gz", 1),
    ("tarball", ".tar", 1),
    ("targunzip", ".tgz", 1),
    ("zip", ".zip", 1),
    ("7zip", ".7z", 1),
    ("executable", ".exe", 1),
    ("mswininstaller", ".msi", 1),
    ("cabinet", ".cab", 1),
    ("msupdate", ".msu", 1),
    ("dll", ".dll", 1)
    ("excel", ".xlsx", 1),
    ("word", ".docx", 1),
    ("word", ".doc", 1),
    ("access", ".accdb", 1),
    ("access", ".laccdb", 1),
    ("pack", ".pack", 1),
    ("image", ".jpg", 1),
    ("image", ".png", 1),
    ("icon", ".ico", 1)
    ("portdocformat", ".pdf", 1),
    ("gitignore", ".gitignore", 1),
    ("database", ".db", 1),
    ("database", ".sqlite", 1),
    ("database", ".sql", 1),
    ("index", ".idx", 1)
)


# Internal Functions
Function Get-PathType {
    [CmdletBinding()]
    Param ($path)
    If (!(Test-Path -Path $path)){
        $result = 'error'
    } Else {
        If (Test-Path -Path $path -PathType Leaf)      {$result = 'file'}
        If (Test-Path -Path $path -PathType Container) {$result = 'directory'}
    }
    return $result
}

Function Get-FileData {
    [CmdletBinding()]
    Param ($Path)

    $splitPath     = $Path -split '\\'
    $fileName      = $splitPath[-1]

    $fileExtension = (Get-Item -Path $Path).Extension

    If ($fileExtension -eq '') {
        $fileLanguage = "!!UNKNOWN!!"
    } Else {
        $Query        = "SELECT language from languages WHERE extension = '$fileExtension'"
        $inqv         = Invoke-SqliteQuery -Query $Query -DataSource $CodeIndexSource
        $fileLanguage = $inqv.language
    }
    If ($null -eq $fileLanguage) {$fileLanguage = "!!NOT FOUND IN DB!!"}

    # this is likely going to be a garbage file we dont want if true, so skip
    If ($($fileLanguage -eq "!!UNKNOWN!!") -and $($fileExtension -eq "")) {
        $FileData = "skip"
        return $FileData
    }

    $fileContent = $(Get-Content -Path $Path -Raw| Out-String)

    $FileData    = [PsCustomObject]@{
        name      = $fileName
        language  = $fileLanguage
        path      = $Path
        content   = $fileContent
        extension = $fileExtension
    }
    return $FileData
}

# CodeIndex Functions
Function Set-CodeIndex{
    <#
            .SYNOPSIS
            Sets the CodeIndex database location and sets the output background color.

            .DESCRIPTION
            Sets the CodeIndex database location.
            Assigns the global variable $CodeIndexSource.
            Defaults to: "$($PSScriptRoot)\db\codeindex.db"
            
            Sets the output backgroud color.
            Assigns the global variable $whgb

            .PARAMETER Path
            Specifies the path to a DB file.

            .PARAMETER BackgroundColor
            Sets the background color for all output. Default is DarkMagenta

            .INPUTS
            None.

            .OUTPUTS
            None.

            .EXAMPLE
            PS> Set-CodeIndex
        

            .EXAMPLE
            PS> Set-CodeIndex -Path C:\users\example\dbfolder\codeindex.db
        
            .EXAMPLE
            PS> Set-CodeIndex -BackgroundColor "Black"

    #>

    [CmdletBinding()]
    Param (
        [string]$Path,
        [string]$BackgroundColor
    )
    If ($Path) {
        $global:CodeIndexSource = "$Path"
    } Else {
        $global:CodeIndexSource = "$($PSScriptRoot)\db\codeindex.db"
    }
    If ($BackgroundColor) {
        $global:whbg = "$BackgroundColor"
    } Else {
        $global:whbg = "Darkmagenta"
    }
}
Set-CodeIndex

Function Step-SpitOnScreen {
    <#
            .SYNOPSIS
            Customized - shortened Write-Host.
            .DESCRIPTION
            Makes using Write-Host more expedient and the lines shorter - If global:whbg is defined it will be used.
            .PARAMETER t
            Text you would normally pass to Write-Host.
            .PARAMETER b
            BackgroundColor - Shorthand (B = Black, C = Cyan, etc..
            .PARAMETER f
            ForegroundColor - Shorthand (R = Red, G = Green, Y = Yellow, etc..
            .PARAMETER n
            NoNewLine.
            .EXAMPLE
            Spit -t 'This is a test' -n
            Write-Host 'This is a test' -BackgroundColor $whbg -NoNewLine
            .EXAMPLE
            Spit -t 'This is a Color Test' -b B -f C -n
            Write-Host 'This is a Color Test' -BackgroundColor Black -ForegroundColor Cyan -NoNewLine
    #>
    [alias('Spit')]
    Param (
        [Parameter(Mandatory=$true,HelpMessage='Text')]
        [object]$t,       ### Object normally sent to Write-Host (text)
        [string]$b,       ### BackgroundColor
        [string]$f=$null, ### ForegroundColor
        [switch]$n        ### NoNewLine
    )

    ### Creating our Splat for Write-Host
    $colorScheme = @{Object = $t}
    
    ### Is $global:whbg defined - If-so use it, else $null
    If ([bool](Get-Variable -Name 'whbg' -Scope 'Global' -ErrorAction 'Ignore')) {
        $b = $whbg
    } Else {
        $b = $null
    }
    
    ### -BackgroundColor
    If ($b) {
        Switch ($b) {
            'B'     {$colorScheme.BackgroundColor = 'Black'}
            'DB'    {$colorScheme.BackgroundColor = 'DarkBlue'}
            'DG'    {$colorScheme.BackgroundColor = 'DarkGreen'}
            'DC'    {$colorScheme.BackgroundColor = 'DarkCyan'}
            'DR'    {$colorScheme.BackgroundColor = 'DarkRed'}
            'DM'    {$colorScheme.BackgroundColor = 'DarkMagenta'}
            'DY'    {$colorScheme.BackgroundColor = 'DarkYellow'}
            'G'     {$colorScheme.BackgroundColor = 'Gray'}
            'DA'    {$colorScheme.BackgroundColor = 'DarkGray'}
            'L'     {$colorScheme.BackgroundColor = 'Blue'}
            'G'     {$colorScheme.BackgroundColor = 'Green'}
            'C'     {$colorScheme.BackgroundColor = 'Cyan'}
            'R'     {$colorScheme.BackgroundColor = 'Red'}
            'M'     {$colorScheme.BackgroundColor = 'Magenta'}
            'Y'     {$colorScheme.BackgroundColor = 'Yellow'}
            'W'     {$colorScheme.BackgroundColor = 'White'}
            default {$colorScheme.BackgroundColor = $b}
        }
    }
    
    ### -ForegroundColor
    If ($f) {
        Switch ($f) {
            'B'     {$colorScheme.ForegroundColor = 'Black'}
            'DB'    {$colorScheme.ForegroundColor = 'DarkBlue'}
            'DG'    {$colorScheme.ForegroundColor = 'DarkGreen'}
            'DC'    {$colorScheme.ForegroundColor = 'DarkCyan'}
            'DR'    {$colorScheme.ForegroundColor = 'DarkRed'}
            'DM'    {$colorScheme.ForegroundColor = 'DarkMagenta'}
            'DY'    {$colorScheme.ForegroundColor = 'DarkYellow'}
            'G'     {$colorScheme.ForegroundColor = 'Gray'}
            'DA'    {$colorScheme.ForegroundColor = 'DarkGray'}
            'L'     {$colorScheme.ForegroundColor = 'Blue'}
            'G'     {$colorScheme.ForegroundColor = 'Green'}
            'C'     {$colorScheme.ForegroundColor = 'Cyan'}
            'R'     {$colorScheme.ForegroundColor = 'Red'}
            'M'     {$colorScheme.ForegroundColor = 'Magenta'}
            'Y'     {$colorScheme.ForegroundColor = 'Yellow'}
            'W'     {$colorScheme.ForegroundColor = 'White'}
        }
    }
        
    ### -NoNewLine
    If ($n) {
        $colorScheme.NoNewLine = $true
    }
        
    ### Output our splat of Write-Host
    Write-Host @colorScheme
}

Function New-CodeIndex{
    <#
            .SYNOPSIS
            Creates a new CodeIndex database.

            .DESCRIPTION
            Creates a new CodeIndex database.
            This will first run the Set-CodeIndex function to ensure the global
            variable is available. If a DB already exist, it will rename it then
            create the new DB. This also inserts predefined languages and extensions
            which can be find in this modules psm1 file.
            Defaults to: "$($PSScriptRoot)\db\codeindex.db"

            .PARAMETER Path
            Specifies the path to a DB file.


            .INPUTS
            None.

            .OUTPUTS
            None. Writes actions to console.

            .EXAMPLE
            PS> New-CodeIndex
        

            .EXAMPLE
            PS> New-CodeIndex -Path C:\users\example\dbfolder\codeindex.db

    #>

    [CmdletBinding()]
    Param ([string]$Path)
    
    If ($Path) {
        Set-CodeIndex -Path $Path
    } Else {
        Set-CodeIndex
        If (Test-Path -Path $CodeIndexSource) {
            Try {
                $dt = Get-Date -Format MM-dd-yyyy_hh.mm.ss
                Rename-Item -Path $CodeIndexSource -NewName "$CodeIndexSource-$dt" -ErrorAction Stop
                Spit 'Renamed current DB to: ' -n
                Spit "$CodeIndexSource-$dt" -f M
            } Catch {
                Spit 'Error: ' -n
                Spit 'DB Currently Open' -f R
                return
            }
            Set-CodeIndex
        }
    }
    
    $filesTable     = 'CREATE TABLE "files" (
        "id"	INTEGER UNIQUE,
        "name"	TEXT,
        "path"	TEXT UNIQUE,
        "language"	TEXT,
        "content"	TEXT,
        "extension"	TEXT,
        PRIMARY KEY("id" AUTOINCREMENT)
    )'
    $languagesTable = 'CREATE TABLE "languages" (
        "id"	INTEGER UNIQUE,
        "language"	TEXT,
        "extension"	TEXT UNIQUE,
        "exclude"	INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY("id" AUTOINCREMENT)
    )'
    
    Invoke-SqliteQuery -Query $filesTable -DataSource $CodeIndexSource
    Invoke-SqliteQuery -Query $languagesTable -DataSource $CodeIndexSource
    
    Spit 'Created CodeIndex DB: ' -n
    Spit "$CodeIndexSource" -f C

    $PreLoadLangs | ForEach-Object {
        $Query = "INSERT INTO languages (language, extension, exclude) VALUES (@language, @extension, @exclude)"
        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
            language  = $_[0]
            extension = $_[1]
            exclude   = $_[2]
        }
    }
}

Function Add-CodeIndex{
    <#
            .SYNOPSIS
            Adds data to the CodeIndex database.

            .DESCRIPTION
            Adds data to the CodeIndex database. Data can either be files or languages
            The path can be either a file or directory, if the path already exist in the
            database it will update the entry instead of inserting it as a new row.
            
            If a language is defined but not a path, it will add a language to the database.
            This also requires that the extension parameter be define. A language is basically
            just a language and associated extension that is referenced when uploading files to
            the database. You can specify the Exclude switch if its a language/extension that should
            be excluded, meaning files that patch that extension will not be uploaded to the DB.

        
            .PARAMETER Path
            Specifies the path to either a file or directory you want indexed.
        
            .PARAMETER Filter
            Specify a string to a path you want to filter out. Unfortunately this only supports 1 string at this time
            but will filter out all child objects 'like' the filter path.
        
            .PARAMETER Recurse
            Specifies if you would like to recursivly index a directory.
        
            .PARAMETER ValidateInclude
            Forces all files being indexed to be validated agaist the included 
            languages/extensions. Meaning if the file has an extension thats not
            in the language table and its exlcude value is false, it will not be
            added to the DB. This is good if you only want very specify file types
            to be indexed.
        
            .PARAMETER LoadTestData
            This will load in the test data from the modules test folder "$($PSScriptRoot)\tests"

            .PARAMETER Language
            Defines a language to be uploaded to the DB. This should be the name
            of a language like "python" or "powershell".
            Requires: Extension

            .PARAMETER Extension
            Defines the extensions assicated with the language. This should be
            just the extension including the period, such as ".py" or ".ps1". 
            If the period is not added, it will be added automatically.
            Requires: Language

            .PARAMETER Exclude
            Specifics if the language/extension being added to the DB should
            be flagged as an exclusion, which prevents files with this extension
            from being indexed. For example, if you dont want ".zip" files indexed, 
            you would add the language/extension with the -Exclude switch.

            .PARAMETER Verbose
            Specifies if you would like to see verbose output of the process, 0 being lowest and 7 being most verbose.
            Options:
                0 : None (default)
                1 : Insert/Update,
                2 : Insert/Update, Processing (Shows the current file its about to get data on, good for finding unexpected files)
                3 : Insert/Update, Processing, Null Lang/Ext Skip
                4 : Insert/Update, Processing, Null Lang/Ext Skip, Inclusion List
                5 : Insert/Update, Processing, Null Lang/Ext Skip, Inclusion List, Exclusion List
                6 : Insert/Update, Processing, Null Lang/Ext Skip, Inclusion List, Exclusion List, Directory 
                7 : Insert/Update, Processing, Null Lang/Ext Skip, Inclusion List, Exclusion List, Directory, Filters

            .INPUTS
            None.

            .OUTPUTS
            None. Writes actions to console.

            .EXAMPLE
            PS> Add-CodeIndex -LoadTestData
        
            .EXAMPLE
            PS> Add-CodeIndex -Path C:\users\example\path\to\file.ps1

            .EXAMPLE
            PS> Add-CodeIndex -Path C:\users\example\path\to\directory -Recurse -Verbose 3
        
            .EXAMPLE
            PS> $filter = "C:\path\to\scripts\junk"
            PS> Add-CodeIndex -Path "C:\path\to\scripts" -Filter $filter
        
            .EXAMPLE
            PS> Add-CodeIndex -Path C:\users\example\path\to\directory -Recurse -Verbose 6 -ValidateInclude
        
            .EXAMPLE
            PS> Add-CodeIndex -Language "powershell" -Extension ".ps1"

            .EXAMPLE
            PS> Add-CodeIndex -Language "zip" -Extension ".zip" -Exclude 

    #>
    
    [CmdletBinding()]
    Param(
        [string]$Path,
        [string]$Filter,
        [switch]$Recurse,
        [switch]$ValidateInclude,
        [switch]$LoadTestData,
        [string]$Language,
        [string]$Extension, 
        [switch]$Exclude,
        [ValidateSet(0, 1, 2, 3, 4, 5, 6, 7)]$Verbose = 0
    )

    If ($LoadTestData) {
        Spit "`nLoading Test Data: " -n
        $Path    = "$($PSScriptRoot)\tests"
        $Recurse = $true
        $Verbose = 5
        Spit "Add-CodeIndex -Recurse -Path $Path -Verbose 5`n`n" -f C
        Start-Sleep -Seconds 1
    }

    Set-Variable -Name UploadCounter -Option AllScope -Value 0
    If ($Path) {
        $PathType = Get-PathType -path $Path
        # 0 (false) and 1 (true)
        $EQuery           = "SELECT extension FROM languages WHERE exclude = 1"
        $ExcludeExtension = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $EQuery
        $ExcList          = $ExcludeExtension.extension

        If ($ValidateInclude) {
            $IQuery           = "SELECT extension FROM languages WHERE exclude = 0"
            $IncludeExtension = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $IQuery
            $IncList          = $IncludeExtension.extension
        }

        $PQuery   = "SELECT path FROM files"
        $AllPaths = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $PQuery

        Function DoShit {
            [CmdletBinding()]
            Param ($File)
            $type = Get-PathType -Path $File
            # check if its a file and not a directory
            If ($type -eq "file") {
                $ext = (Get-Item -Path $File).Extension
                # check if the extension is excluded
                If ($ExcList -notcontains $ext) {
                    If ($verbose -ge 2) {
                        Spit 'Processing: ' -n
                        Spit "$File" -f Y
                    }
                    # check if we are forcing validating of incldued extensions
                    If ($ValidateInclude) {
                        If ($IncList -notcontains $ext) {
                            If ($verbose -ge 4) {
                                Spit 'Skipping, extension validate include: ' -n
                                Spit "$File" -f R
                                return
                            }
                            return
                        }
                    }
                    $FileData = Get-FileData -Path $File
                    # checking if filedata returned skip, this means it doesnt have an extension
                    If ($FileData -eq "skip") {
                        If ($verbose -ge 3) {
                            Spit "Skipping 'null Lang/Ext': " -n
                            Spit "$File" -f R
                            return
                        }
                        return
                    }
                    # checking to see if the path already exist in the DB, if so then lets update it instead of inserting a new record
                    If ($AllPaths.path -contains $File) {
                        $Query = "UPDATE files SET name = (@name), language = (@language), content = (@content), extension = (@extension) WHERE path = (@path)"
                        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                            name      = $FileData.name
                            path      = $FileData.path
                            language  = $FileData.language
                            content   = $FileData.content
                            extension = $FileData.extension
                        }
                        If ($verbose -ge 1) {
                            Spit 'Updated: ' -n
                            Spit "$File" -f G
                        }
                        $UploadCounter += 1
                    }
                    # record is new, insert it
                    Else {
                        $Query = "INSERT INTO files (name, path, language, content, extension) VALUES (@name, @path, @language, @content, @extension)"
                        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                            name      = $FileData.name
                            path      = $FileData.path
                            language  = $FileData.language
                            content   = $FileData.content
                            extension = $FileData.extension
                        }
                        If ($verbose -ge 1) {
                            Spit 'Inserted: ' -n
                            Spit "$File" -f G
                        }
                        $UploadCounter += 1
                    }
                } Else {
                    If ($verbose -ge 5) {
                        Spit "Skipping extension in 'exclude': " -n
                        Spit "$File" -f R
                    }
                }
            } Else {
                If ($verbose -eq 6) {
                    Spit "Skipping type 'directory': " -n
                    Spit "$File" -f M
                }
            }
        }

        Switch ($PathType) {
            "error"     {
                Spit 'Error: ' -n
                Spit "Invalid path - $Path" -f R
                return
            }
            "file"      {
                DoShit -File $Path
                Spit "`nIndexed: " -n
                Spit "$UploadCounter" -f C
            }
            "directory" {
                If ($Recurse) {
                    If ($Filter) {
                        If (!$Filter.EndsWith("*")) {$Filter = $Filter + "*"}
                        Get-ChildItem -Path $Path -Recurse | ForEach-Object {
                            If ($_.FullName -like $Filter) {
                                If ($verbose -eq 7) {
                                    Spit 'Filtered Out: ' -n
                                    Spit "$($_.FullName)" -f R
                                }
                            } Else {
                                DoShit -File $_.FullName
                            }
                        }
                    } Else {
                        Get-ChildItem -Path $Path -Recurse | ForEach-Object {
                            DoShit -File $_.FullName
                        }
                    }
                } Else {
                    If ($Filter) {
                        If (!$Filter.EndsWith("*")) {$Filter = $Filter + "*"}
                        Get-ChildItem -Path $Path | ForEach-Object {
                            If ($_.FullName -like $Filter) {
                                If ($verbose -eq 7) {
                                    Spit 'Filtered Out: ' -n
                                    Spit "$($_.FullName)" -f R
                                }
                            } Else {
                                DoShit -File $_.FullName
                            }
                        }
                    } Else {
                        Get-ChildItem -Path $Path | ForEach-Object {
                            DoShit -File $_.FullName
                        }
                    }
                }
                Spit "`nIndexed: " -n
                Spit "$UploadCounter" -f C
            }
        }
    } ElseIf ($Language) {
        If (!$Extension) {
            Spit 'Error: ' -n
            Spit 'Extension parameter required when specifying Language.' -f R
            return
        } Else {
            # 0 (false) and 1 (true)
            If ($Exclude) {$ExBol = 1} Else {$ExBol = 0}
            $Query = "INSERT INTO languages (extension, language, exclude) VALUES (@extension, @language , @exclude)"
            Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                extension = $Extension
                language  = $Language
                exclude   = $ExBol
            }
            Spit 'Insert Language: ' -n
            Spit "$Language, $Extension" -f Y
            return
        }
    } Else {
        Spit 'Error: ' -n
        Spit 'Must define Path or Language parameter' -f R
        return
    }
}

Function Get-CodeIndex {
    <#
            .SYNOPSIS
            Gets data from the CodeIndex database.

            .DESCRIPTION
            Gets data from the CodeIndex database. This allows
            you to search all your code files for specific words/statements
            or by file ID (defined by the DB).

            .PARAMETER Content
            Specifies the content you want to search for.
        
            .PARAMETER Language
            Specifies the file language you want to search within for content.
            Alternativly set this to "!!GET" and do not specify Content to get 
            all languages in the DB. 
        
            .PARAMETER ID
            Use the ID parameter to get the entire content of a specific DB entry by ID. 
        
            .PARAMETER GetTestData
            Get test data. This is assuming you already loaded in the test data with 'Add-CodeIndex -LoadTestData'.
            This produces an example of a valid Get-CodeIndex command and output. 
        
            .PARAMETER ImFeelingLucky
            You know, like google lol. Only displays the first result found for your content search.

            .PARAMETER Output
            Defines how you want to see the output on console.
            Options:
                All: Displays all content from the file(s) found.
                None: Doesnt display any content from the file(s) found. (Default)
                Line: Displays only the line from the file(s) that contains the searched content. 
                Block: Displays an 11 line block of code, 5 above and 5 below your searched content. 
            
            .INPUTS
            None.

            .OUTPUTS
            None. Writes actions to console.

            .EXAMPLE
            PS> Get-CodeIndex -Content "while"

            .EXAMPLE
            PS> Get-CodeIndex -Content "ExpandProperty" -Output Block

            .EXAMPLE
            PS> Get-CodeIndex -Content "Invoke" -Language "powershell" -Output Line

            .EXAMPLE
            PS> Get-CodeIndex -Content "pscustomobject" -Output Block -ImFeelingLucky

            .EXAMPLE
            PS> Get-CodeIndex -ID 8

            .EXAMPLE
            PS> Get-CodeIndex -GetTestData
        

    #>

    [CmdletBinding()]
    Param (
        [string]$Content,
        [string]$Language,
        [int]$ID,
        [switch]$GetTestData,
        [switch]$ImFeelingLucky,
        [ValidateSet("All", "None", "Line", "Block")]
        $Output = "None"
    )

    If ($GetTestData) {
        $Content = "while"
        $Output  = "Block"
        Spit 'Getting Test Data: ' -n
        Spit "Get-CodeIndex -Content 'while' -Output Block`n" -f C
        Start-Sleep -Seconds 1
    }

    If ($ID) {
        $Query   = "SELECT * FROM files WHERE id = $ID"
        $Content = "!!BYID!!"
        $Output  = "All"
    } Else {
        $Query   = "SELECT * FROM files WHERE content like '%$Content%'"
    }

    If ($Language) {
        If ($Language -eq "!!GET") {
            $Query = "SELECT * FROM languages"
            $invq  = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query
            $invq | ForEach-Object {
                $lang = $_.language
                $ext  = $_.extension
                $exc  = $_.exclude
                If ($exc -eq 0) {$excl = "False"} Else {$excl = "True"}
                Spit 'Language: ' -n
                Spit "$lang" -f C -n
                Spit  Extension:  -n
                Spit "$ext" -f R -n
                Spit ' Exclude: ' -n
                Spit "$excl" -f Y
            }
            return
        } Else{
            $Query = $Query + " AND language = '$Language'"
        }
    }
    $invq  = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query
    $dbid  = $invq.id
    $Count = $dbid.Count

    Spit 'Found ' -n
    Spit "$Count" -f C -n
    Spit " result(s): `n"
    If ($Count -eq 0)    {return}
    If ($ImFeelingLucky) {$invq = $invq[0]}

    Function HighlightWord{
        [CmdletBinding()]
        Param(
            $word,
            $data
        )
        If ($word -eq "!!BYID!!") {
            Spit "$data" -f M
        } Else {
            $splitdata = $data -split ("$word")
            $counter   = $splitdata.Count
            $itter     = 1
            $splitdata | ForEach-Object {
                Spit $_ -f M -n
                If ($itter -lt $counter) {
                    Spit "$word" -f G -n
                    $itter += 1
                }
            }
        }
        Spit "`n"
    }

    $invq | ForEach-Object {
        $dbcontent = $_.content
        Spit 'ID: ' -n
        Spit "$($_.id)" -f R
        Spit 'Path: ' -n
        Spit "$($_.path)" -f Y
        Spit 'Language: ' -n
        Spit "$($_.language)" -f C

        Switch ($Output) {
            "All"   {
                Spit 'Content: ' -n
                HighlightWord -word $Content -data $($dbcontent)
            }
            "None"  {
                Spit "`n"
            }
            "Line"  {
                Spit 'Content Line: ' -n
                $splitContent = $dbcontent -split ("\n")
                $line         = $splitContent | Select-String -Pattern "$Content" | Select-Object -ExpandProperty Line
                If ($line.Count -gt 1) {
                    HighlightWord -word $Content -data $($line[0])
                } Else {
                    HighlightWord -word $Content -data $($line)
                }
            }
            "Block" {
                $indexNum     = 0
                $counter      = 0
                $splitContent = $dbcontent -split ("\n")
                $splitContent | ForEach-Object {
                    $stringContain = $_ | Select-String -Pattern "$Content"
                    If ($stringContain) {$indexNum = $counter} Else {$counter += 1}
                }
                $lowerNum = $indexNum - 5
                If ($lowerNum -lt 0) {$lowerNum = 0}

                $upperNum = $indexNum + 5
                If ($upperNum -gt $counter) {$upperNum = $counter}
                
                $block  = $splitContent[$lowerNum..$upperNum]
                $jblock = $block -join ("`n")
                Spit 'Content: ' -n
                #Write-host "$jblock`n" -BackgroundColor $whbg -ForegroundColor Magenta
                HighlightWord -word $Content -data $($jblock)
            }
        }
    }
}

Export-ModuleMember -Function Set-CodeIndex
Export-ModuleMember -Function Step-SpitOnScreen
Export-ModuleMember -Function New-CodeIndex
Export-ModuleMember -Function Add-CodeIndex
Export-ModuleMember -Function Get-CodeIndex
