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
function Get-PathType{
    param(
        $path
    )
    if (!(Test-Path -Path $path)){$result = 'error'}
    else{
        if (Test-Path -Path $path -PathType Leaf){$result = 'file'}
        if (Test-Path -Path $path -PathType Container){$result = 'directory'}
    }
    return $result
}

function Get-FileData{
    param(
        $Path
    )

    $splitPath = $Path -split '\\'
    $fileName = $splitPath[-1]

    $fileExtension = (Get-Item $Path).Extension

    if ($fileExtension -eq ''){
        $fileLanguage = "!!UNKNOWN!!"
    }
    else{
        $Query = "SELECT language from languages WHERE extension = '$fileExtension'"
        $inqv = Invoke-SqliteQuery -Query $Query -DataSource $CodeIndexSource
        $fileLanguage = $inqv.language
    }
    if ($null -eq $fileLanguage){$fileLanguage = "!!NOT FOUND IN DB!!"}

    # this is likely going to be a garbage file we dont want if true, so skip
    if($($fileLanguage -eq "!!UNKNOWN!!") -and $($fileExtension -eq "")){
        $FileData = "skip"
        return $FileData
    }

    $fileContent = $(Get-Content $Path -Raw| Out-String)

    $FileData = [pscustomobject]@{
        name = $fileName
        language = $fileLanguage
        path = $Path
        content = $fileContent
        extension = $fileExtension
    }
    return $FileData
}



# CodeIndex Functions
function Set-CodeIndex{
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

    param(
        [string]$Path,
        [string]$BackgroundColor
    )
    if($Path){$global:CodeIndexSource = "$Path"}
    else{$global:CodeIndexSource = "$($PSScriptRoot)\db\codeindex.db"}
    if($BackgroundColor){$global:whbg = "$BackgroundColor"}
    else{$global:whbg = "Darkmagenta"}
}
Set-CodeIndex

function New-CodeIndex{
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

    param(
        [string]$Path
    )

    if($Path){Set-CodeIndex -Path $Path}
    else{
        Set-CodeIndex
        if(Test-Path -Path $CodeIndexSource){
            
            try{
                $dt = Get-Date -Format MM-dd-yyyy_hh.mm.ss
                Rename-Item -Path $CodeIndexSource -NewName "$CodeIndexSource-$dt" -ErrorAction Stop
                Write-Host "Renamed current DB to: " -BackgroundColor $whbg -NoNewline
                Write-Host "$CodeIndexSource-$dt" -BackgroundColor $whbg -ForegroundColor Magenta
            }
            catch {
                Write-Host "Error: " -BackgroundColor $whbg -NoNewline
                write-host "DB Currently Open" -BackgroundColor $whbg -ForegroundColor Red
                return
            }
            Set-CodeIndex
        }
    }
    
    $filesTable = 'CREATE TABLE "files" (
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
    
    Write-Host "Created CodeIndex DB: " -BackgroundColor $whbg -NoNewline
    Write-Host "$CodeIndexSource" -ForegroundColor Cyan -BackgroundColor $whbg

    $PreLoadLangs | %{
        $Query = "INSERT INTO languages (language, extension, exclude) VALUES (@language, @extension, @exclude)"
        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
            language = $_[0]
            extension = $_[1]
            exclude = $_[2]
        }
    }
}

function Add-CodeIndex{
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
    
    param(
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
    if ($LoadTestData){
        Write-Host "`nLoading Test Data: " -BackgroundColor $whbg -NoNewline
        $Path = "$($PSScriptRoot)\tests"
        $Recurse = $true
        $Verbose = 5
        Write-Host "Add-CodeIndex -Recurse -Path $Path -Verbose 5`n`n" -BackgroundColor $whbg -ForegroundColor Cyan
        sleep 1
    }

    Set-Variable -Name UploadCounter -Option AllScope -Value 0
    if($Path){
        $PathType = Get-PathType -path $Path
        # 0 (false) and 1 (true)
        $EQuery = "SELECT extension FROM languages WHERE exclude = 1"
        $ExcludeExtension = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $EQuery
        $ExcList = $ExcludeExtension.extension

        if ($ValidateInclude){
            $IQuery = "SELECT extension FROM languages WHERE exclude = 0"
            $IncludeExtension = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $IQuery
            $IncList = $IncludeExtension.extension
        }

        $PQuery = "SELECT path FROM files"
        $AllPaths = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $PQuery

        function DoShit{
            param(
                $File
            )
            $type = Get-PathType -Path $File
            # check if its a file and not a directory
            if ($type -eq "file"){
                $ext = (Get-Item $File).Extension
                # check if the extension is excluded
                if ($ExcList -notcontains $ext){
                    if($verbose -ge 2){
                        Write-Host "Processing: " -BackgroundColor $whbg -NoNewline
                        Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Yellow
                    }
                    # check if we are forcing validating of incldued extensions
                    if ($ValidateInclude){
                        if ($IncList -notcontains $ext){
                            if ($verbose -ge 4){
                                Write-Host "Skipping, extension validate include: " -BackgroundColor $whbg -NoNewline
                                Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Red
                                return
                            }
                            return
                        }
                    }
                    $FileData = Get-FileData -Path $File
                    # checking if filedata returned skip, this means it doesnt have an extension
                    if ($FileData -eq "skip"){
                        if ($verbose -ge 3){
                            Write-Host "Skipping 'null Lang/Ext': " -BackgroundColor $whbg -NoNewline
                            Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Red
                            return
                        }
                        return
                    }
                    # checking to see if the path already exist in the DB, if so then lets update it instead of inserting a new record
                    if ($AllPaths.path -contains $File){
                        $Query = "UPDATE files SET name = (@name), language = (@language), content = (@content), extension = (@extension) WHERE path = (@path)"
                        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                            name = $FileData.name
                            path = $FileData.path
                            language = $FileData.language
                            content = $FileData.content
                            extension = $FileData.extension
                        }
                        if($verbose -ge 1){
                            Write-Host "Updated: " -BackgroundColor $whbg -NoNewline
                            Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Green
                        }
                        $UploadCounter += 1
                    }
                    # record is new, insert it
                    else{
                        $Query = "INSERT INTO files (name, path, language, content, extension) VALUES (@name, @path, @language, @content, @extension)"
                        Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                            name = $FileData.name
                            path = $FileData.path
                            language = $FileData.language
                            content = $FileData.content
                            extension = $FileData.extension
                        }
                        if($verbose -ge 1){
                            Write-Host "Inserted: " -BackgroundColor $whbg -NoNewline
                            Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Green
                        }
                        $UploadCounter += 1
                    }
                }
                else {
                    if ($verbose -ge 5){
                        Write-Host "Skipping extension in 'exclude': " -BackgroundColor $whbg -NoNewline
                        Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Red
                    }
                }
            }
            else {
                if ($verbose -eq 6){
                    Write-Host "Skipping type 'directory': " -BackgroundColor $whbg -NoNewline
                    Write-Host "$File" -BackgroundColor $whbg -ForegroundColor Magenta
                }
            }
        }

        switch($PathType){
            "error"{
                Write-Host "Error: " -BackgroundColor $whbg -NoNewline
                Write-Host "Invalid path - $Path" -BackgroundColor $whbg -ForegroundColor Red
                return
            }
            "file"{
                DoShit -File $Path
                Write-Host "`nIndexed: " -BackgroundColor $whbg -NoNewline
                Write-Host "$UploadCounter" -BackgroundColor $whbg -ForegroundColor Cyan
            }
            "directory"{
                if($Recurse){
                    if ($Filter){
                        if (!$Filter.EndsWith("*")){$Filter = $Filter + "*"}
                        Get-ChildItem -Path $Path -Recurse | %{
                            if ($_.FullName -like $Filter){
                                if ($verbose -eq 7){
                                    Write-Host "Filtered Out: " -BackgroundColor $whbg -NoNewline
                                    Write-Host "$($_.FullName)" -BackgroundColor $whbg -ForegroundColor Red
                                }
                            }
                            else{
                                DoShit -File $_.FullName
                            }
                        }
                    }
                    else{
                        Get-ChildItem -Path $Path -Recurse | %{
                                DoShit -File $_.FullName
                        }
                    }
                    
                }
                else{
                    if ($Filter){
                        if (!$Filter.EndsWith("*")){$Filter = $Filter + "*"}
                        Get-ChildItem -Path $Path | %{
                            if ($_.FullName -like $Filter){
                                if ($verbose -eq 7){
                                    Write-Host "Filtered Out: " -BackgroundColor $whbg -NoNewline
                                    Write-Host "$($_.FullName)" -BackgroundColor $whbg -ForegroundColor Red
                                }
                            }
                            else{
                                DoShit -File $_.FullName
                            }
                        }
                    }
                    else{
                        Get-ChildItem -Path $Path | %{
                                DoShit -File $_.FullName
                        }
                    }
                }
                Write-Host "`nIndexed: " -BackgroundColor $whbg -NoNewline
                Write-Host "$UploadCounter" -BackgroundColor $whbg -ForegroundColor Cyan
            }
        }
    }
    elseif($Language){
        if (!$Extension){
            Write-Host "Error: " -BackgroundColor $whbg -NoNewline
            Write-Host "Extension parameter required when specifying Language." -BackgroundColor $whbg -ForegroundColor Red
            return
        }
        else {
            # 0 (false) and 1 (true)
            if ($Exclude){$ExBol = 1}
            else{$ExBol = 0}
            $Query = "INSERT INTO languages (extension, language, exclude) VALUES (@extension, @language , @exclude)"
            Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query -SqlParameters @{
                extension = $Extension
                language = $Language
                exclude = $ExBol
            }
            Write-Host "Insert Language: " -BackgroundColor $whbg -NoNewline
            Write-Host "$Language, $Extension" -BackgroundColor $whbg -ForegroundColor Yellow
            return
        }
    }
    else{
        Write-Host "Error: " -BackgroundColor $whbg -NoNewline
        Write-Host "Must define Path or Language parameter" -BackgroundColor $whbg -ForegroundColor Red
        return
    }
}

function Get-CodeIndex{
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

    param(
        [string]$Content,
        [string]$Language,
        [int]$ID,
        [switch]$GetTestData,
        [switch]$ImFeelingLucky,
        [ValidateSet("All", "None", "Line", "Block")]
        $Output = "None"
    )
    
    if ($GetTestData){
        $Content = "while"
        $Output = "Block"
        Write-Host "Getting Test Data: " -BackgroundColor $whbg -NoNewline
        Write-Host "Get-CodeIndex -Content 'while' -Output Block`n" -BackgroundColor $whbg -ForegroundColor Cyan
        sleep 1
    }

    if ($ID) {
        $Query = "SELECT * FROM files WHERE id = $ID"
        $Content = "!!BYID!!"
        $Output = "All"
    }
    else{
        $Query = "SELECT * FROM files WHERE content like '%$Content%'"
    }

    if ($Language) {
        if ($Language -eq "!!GET"){
            $Query = "SELECT * FROM languages"
            $invq = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query
            $invq | %{
                $lang = $_.language
                $ext = $_.extension
                $exc = $_.exclude
                if ($exc -eq 0){$excl = "False"}
                else {$excl = "True"}
                Write-Host "Language: " -BackgroundColor $whbg -NoNewline
                Write-Host "$lang" -BackgroundColor $whbg -ForegroundColor Cyan -NoNewline
                Write-Host " Extension: " -BackgroundColor $whbg -NoNewline
                Write-Host "$ext" -BackgroundColor $whbg -ForegroundColor Red -NoNewline
                Write-Host " Exclude: "-BackgroundColor $whbg -NoNewline
                Write-Host "$excl" -BackgroundColor $whbg -ForegroundColor Yellow
            }
            return
        }
        else{
            $Query = $Query + " AND language = '$Language'"
        }
    }
    $invq = Invoke-SqliteQuery -DataSource $CodeIndexSource -Query $Query
    $dbid = $invq.id
    $Count = $dbid.Count
    
    
    Write-Host "Found " -BackgroundColor $whbg -NoNewline
    Write-Host "$Count" -BackgroundColor $whbg -ForegroundColor Cyan -NoNewline
    Write-Host " result(s): `n" -BackgroundColor $whbg
    if ($Count -eq 0){return}
    if ($ImFeelingLucky){$invq = $invq[0]}

    function HighlightWord{
        param(
            $word,
            $data
        )
        if ($word -eq "!!BYID!!"){
            Write-Host "$data" -BackgroundColor $whbg -ForegroundColor Magenta
        }
        else{
            $splitdata = $data -split ("$word")
            $counter = $splitdata.Count
            $itter = 1
            $splitdata | %{
                Write-Host $_ -BackgroundColor $whbg -ForegroundColor Magenta -NoNewline
                if ($itter -lt $counter){
                    Write-Host "$word" -ForegroundColor Green -NoNewline
                    $itter += 1
                }
            }
        }
        Write-Host "`n"
    }

    

    $invq | %{
        $dbcontent = $_.content
        Write-Host "ID: " -BackgroundColor $whbg -NoNewline
        Write-Host "$($_.id)" -BackgroundColor $whbg -ForegroundColor Red
        Write-Host "Path: " -BackgroundColor $whbg -NoNewline
        Write-host "$($_.path)" -BackgroundColor $whbg -ForegroundColor Yellow
        Write-Host "Language: " -BackgroundColor $whbg -NoNewline
        Write-host "$($_.language)" -BackgroundColor $whbg -ForegroundColor Cyan

        switch($Output){
            "All"{
                Write-Host "Content: " -BackgroundColor $whbg -NoNewline
                HighlightWord -word $Content -data $($dbcontent)
            }
            "None"{
                Write-host "`n"
            }
            "Line"{
                Write-Host "Content Line: " -BackgroundColor $whbg -NoNewline
                $splitContent = $dbcontent -split ("\n")
                $line = $splitContent | Select-String "$Content" | Select-Object -ExpandProperty Line
                if ($line.Count -gt 1){
                    HighlightWord -word $Content -data $($line[0])
                }
                else{
                    HighlightWord -word $Content -data $($line)
                }
            }
            "Block"{
                $indexNum = 0
                $counter = 0
                $splitContent = $dbcontent -split ("\n")
                $splitContent | %{
                    $stringContain = $_ | Select-String "$Content"
                    if ($stringContain){$indexNum = $counter}else{$counter += 1}
                }
                $lowerNum = $indexNum - 5
                if ($lowerNum -lt 0){$lowerNum = 0}

                $upperNum = $indexNum + 5
                if ($upperNum -gt $counter){$upperNum = $counter}
                
                $block = $splitContent[$lowerNum..$upperNum]
                $jblock = $block -join ("`n")
                Write-Host "Content: " -BackgroundColor $whbg -NoNewline
                #Write-host "$jblock`n" -BackgroundColor $whbg -ForegroundColor Magenta
                HighlightWord -word $Content -data $($jblock)
            }
        }
    }

}


Export-ModuleMember -Function Set-CodeIndex
Export-ModuleMember -Function New-CodeIndex
Export-ModuleMember -Function Add-CodeIndex
Export-ModuleMember -Function Get-CodeIndex
