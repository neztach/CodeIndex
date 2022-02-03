# CodeIndex
A PowerShell module to index all your script/code files.

## Intro
I have way to many scripts in many different languages and I’m always digging through them to find out how I solved a specific issue I’ve done in the past (when google fails me!, or not!). This is a PowerShell module used to index all your script/code files into an SQLite database. This then allows you to quickly search your files for specific content. 

## Warning
This app is far from flawless, I still have some improvements/features I need to implement. There is little to none error checking :). I'm also still a PowerShell noob and some of the code might not be as clean as it should be. I'm sure there's better ways to implement some of the code. I'm also brand new to github so if there are comments or whatever, feel free to leave them. Maybe that's what issues are for? Also This has only been tested on Windows 10, PSVersion 5.1.18362.1801, but I'm sure it will work with other OS's and versions. 

## Requirements
This module is dependent on the [PSSQLite](https://www.powershellgallery.com/packages/PSSQLite/1.1.0) module to interact with the database.
Install it:
```
PS> Install-Module -Name PSSQLite
```

# Getting Started

## Install
This isn't on the gallery yet so you will have to manually install it. Download the files or zip. Check your current PowerShell Module Path: 
```
PS> $env:PSModulePath
```
Create a folder called "CodeIndex" in one of them paths, then place the files in there. Close and reopen PowerShell or import the module:
```
PS> Import-Module CodeIndex
```

## Usage
The readme in this repo is intended for highlevel info. All functions have a [comment based helper](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-7.2) so if you want granular details on the functions, use the Get-Help cmdlet. For example: 
```
PS> Get-Help New-CodeIndex
PS> Get-Help Add-CodeIndex -Full
PS> Get-Help Get-CodeIndex -Detailed
```

### Set-CodeIndex
This is simply used to set a global variable for the database path and output background color. These variables are used for all other CodeIndex functions. 

### New-CodeIndex
This is used to generate a new CodeIndex Database "codeindex.db". By default it will be placed in "$($PSScriptRoot)\db\"
It also preloads the DB with a small set of languages both include and excluded.

### Add-CodeIndex
This is used to add data to the CodeIndex. You can add files or languages. If the path is a directory, it will scan the entire directory, there are recurse options as well.
Languages are basically just languages/extensions you add to the database that are then used when adding new files, they can be used as include or exclude languages, meaning if you want to exclude a certain type of files getting indexed, you would add this language and extension with exclude = true. 

### Get-CodeIndex
This is used to search for content in the CodeIndex DB. You can search by language as well, and you have several output options such as "Block" which shows an 11 line block of code mating your search. 

## Tests
You can load in test data and get test data with the following process listed below. This does require you have a "tests" folder in the modules directory. I have provided example test data in this repo. 
```
PS> New-CodeIndex  # or use an existing one
PS> Add-CodeIndex -LoadTestData
PS> Get-CodeIndex -GetTestData
```
## Screenshots
This shows the 'New' 'Add' and 'Get' functions being used with the test data. 
![2022-02-02_17-00-22](https://user-images.githubusercontent.com/98922534/152263661-5c53b59e-9ba3-4801-85f8-92cb60c8e66f.png)
