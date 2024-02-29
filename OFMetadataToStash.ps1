param ([switch]$ignorehistory, [switch]$v)
 
 <#
---OnlyFans Metadata DB to Stash PoSH Script 0.9---

AUTHOR
    JuiceBox
URL 
    https://github.com/ALonelyJuicebox/OFMetadataToStash

DESCRIPTION
    Using the metadata database from an OnlyFans scraper script, imports metadata such as the URL, post associated text, and creation date into your stash DB

REQUIREMENTS
    - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
       Download a zip of the PSSQlite folder in that repo, extract it, run an Admin window of Powershell
       in that directory then run 'install-module pssqlite' followed by the command 'import-module pssqlite'
 #>

 #Powershell Dependencies
#requires -modules PSGraphQL
#requires -modules PSSQLite
#requires -Version 7

#Import Modules now that we know we have them
Import-Module PSGraphQL
Import-Module PSSQLite

#Command Line Arguments



### Functions
#Set-Config is a wizard that walks the user through the configuration settings
function Set-Config{
    clear-host
    write-host "OnlyFans Metadata DB to Stash PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(1 of 3) Define the URL to your Stash"
    write-output "Option 1: Stash is hosted on the computer I'm using right now (localhost:9999)"
    write-output "Option 2: Stash is hosted at a different address and/or port (Ex. 192.168.1.2:6969)`n"
    do{
        do {
            $userselection = read-host "Enter your selection (1 or 2)"
        }
        while (($userselection -notmatch "[1-2]"))

        if ($userselection -eq 1){
            $StashGQL_URL = "http://localhost:9999/graphql"
        }

        #Asking the user for the Stash URL, with some error handling
        else {
            while ($null -eq $StashGQL_URL ){
                $StashGQL_URL = read-host "`nPlease enter the URL to your Stash"
                $StashGQL_URL = $StashGQL_URL + '/graphql' #Tacking on the gql endpoint
        
                while (!($StashGQL_URL.contains(":"))){
                    write-host "Error: Oops, looks like you forgot to enter the port number (Ex. <URL>:9999)." -ForegroundColor red
                    $StashGQL_URL = read-host "`nPlease enter the URL to your Stash"
                }
        
                if (!($StashGQL_URL.contains("http"))){
                    $StashGQL_URL = "http://"+$StashGQL_URL
                }
            }
        }
        do{
            write-host "`nDo you happen to have a username/password configured on your Stash?"
            $userselection = read-host "Enter your selection (Y/N)"
        }
        while(($userselection -notlike "Y" -and $userselection -notlike "N"))
        if($userselection -like "Y"){
            write-host "As you have set a username/password on your Stash, You'll need to provide this script with your API key."
            write-host "Navigate to this page in your browser to generate one in Stash"
            write-host "$StashGQL_URL/settings?tab=security"
            write-host "`n- WARNING: The API key will be stored in cleartext in the config file of this script. - "
            write-host "If someone who has access to your Stash gets access to the config file, they may be able to use it to bypass the username and password you've set."
            $StashAPIKey = read-host "`nWhat is your API key?"
        }

        #Now we can check to ensure this address is valid-- we'll use a very simple GQL query and get the Stash version
        $StashGQL_Query = 'query version{version{version}}'
        try{
            $stashversion = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
        }
        catch{
            write-host "(0) Error: Could not communicate to Stash at the provided address ($StashGQL_URL)"
            read-host "No worries, press [Enter] to start from the top"
        }
    }
    while ($null -eq $stashversion)

    clear-host
    write-host "OnlyFans Metadata DB to Stash PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(2 of 3) Define the path to your OnlyFans content`n"
    write-host "    * OnlyFans metadata database files are named 'user_data.db' and they are commonly `n      located under <performername> $directorydelimiter metadata $directorydelimiter , as defined by your OnlyFans scraper of choice"
    write-output "`n    * You have the option of linking directly to the 'user_data.db' file, `n      or you can link to the top level OnlyFans folder of several metadata databases."
    write-output "`n    * When multiple database are detected, this script can help you select one (or even import them all in batch!)`n"
    if ($null -ne $PathToOnlyFansContent){
        #If the user is coming to this function with this variable set, we set it to null so that there is better user feedback if a bad filepath is provided by the user.
        $PathToOnlyFansContent = $null
    }
    do{
        #Providing some user feedback if we tested the path and it came back as invalid
        if($null -ne $PathToOnlyFansContent){
            write-output "Oops. Invalid filepath"
        }
        if($IsWindows){
            write-output "Option 1: I want to point to a folder containing all my OnlyFans content/OnlyFans metadata databases"
            write-output "Option 2: I want to point to a single OnlyFans Metadata file (user_data.db)`n"

            do {
                $userselection = read-host "Enter your selection (1 or 2)"
            }
            while (($userselection -notmatch "[1-2]"))
         
            #If the user wants to choose a folder instead of a file there's a different Windows File Explorer prompt to bring up so we'll use this condition tree to sort that out
            if ($userselection -eq 1){
                Add-Type -AssemblyName System.Windows.Forms
                $FileBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
                $null = $FileBrowser.ShowDialog()
                $PathToOnlyFansContent = $FileBrowser.SelectedPath
            }
            else {
                Add-Type -AssemblyName System.Windows.Forms
                $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
                    Filter = 'OnlyFans Metadata Database File (*.db)|*.db'
                }
                $null = $FileBrowser.ShowDialog()
                $PathToOnlyFansContent = $FileBrowser.filename
            }
        }
        else{
            $PathToOnlyFansContent = read-host "Enter the folder containing your OnlyFans content or a direct link to your OnlyFans Metadata Database"
        }
    }
    while(!(test-path $PathToOnlyFansContent))

    clear-host
    write-host "OnlyFans Metadata DB to Stash PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(3 of 3) Define your Metadata Match Mode"
    write-output "    * When importing OnlyFans Metadata, some users may want to tailor how this script matches metadata to files"
    write-output "    * If you are an average user, just set this to 'Normal'"
    write-output "Option 1: Normal - Will match based on Filesize and the Performer name being somewhere in the file path (Recommended)"
    write-output "Option 2: Low    - Will match based only on a matching Filesize"
    write-output "Option 3: High   - Will match based on a matching path and a matching Filesize"


    $specificityselection = 0;
    do {
        $specificityselection = read-host "`nEnter selection (1-3)"
    }
    while (($specificityselection -notmatch "[1-3]"))

    #Code for parsing metadata files
    if($specificityselection -eq 1){
        $SearchSpecificity = "Normal"
    }
    elseif($specificityselection -eq 2){
        $SearchSpecificity = "Low"
    }
    else{
        $SearchSpecificity = "High"
    }

    clear-host
    write-host "OnlyFans Metadata DB to Stash PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(Summary) Review your settings`n"

    write-output "URL to Stash API:`n - $StashGQL_URL`n"
    write-output "Path to OnlyFans Content:`n - $PathToOnlyFansContent`n"
    write-output "Metadata Match Mode:`n - $SearchSpecificity`n"

    read-host "Press [Enter] to save this configuration and return to the Main Menu"


    #Now to make our configuration file
    try { 
        Out-File $PathToConfigFile
    }
    catch{
        write-output "Error - Something went wrong while trying to save the config file to the filesystem ($PathToConfigFile)" -ForegroundColor red
        read-output "Press [Enter] to exit" -ForegroundColor red
        exit
    }

    try{ 
        Add-Content -path $PathToConfigFile -value "#### OFMetadataToStash Config File v1 ####"
        Add-Content -path $PathToConfigFile -value "------------------------------------------"
        Add-Content -path $PathToConfigFile -value "## URL to the Stash GraphQL API endpoint ##"
        Add-Content -path $PathToConfigFile -value $StashGQL_URL
        Add-Content -path $PathToConfigFile -value "## Direct Path to OnlyFans Metadata Database or top level folder containing OnlyFans content ##"
        Add-Content -path $PathToConfigFile -value $PathToOnlyFansContent
        Add-Content -path $PathToConfigFile -value "## Search Specificity mode. (Normal | High | Low) ##"
        Add-Content -path $PathToConfigFile -value $SearchSpecificity
        Add-Content -path $PathToConfigFile -value "## Stash API Key (Danger!)##"
        Add-Content -path $PathToConfigFile -value $StashAPIKey
    }
    catch {
        write-output "Error - Something went wrong while trying add your configurations to the config file ($PathToConfigFile)" -ForegroundColor red
        read-output "Press [Enter] to exit" -ForegroundColor red
        exit
    }
    
} #End Set-Config

#DatabaseHasBeenImported does a check to see if a particular metadata database file actually needs to be parsed based on a history file. Returns true if this database needs to be parsed
function DatabaseHasAlreadyBeenImported{
    if ($ignorehistory -eq $true){
        return $false
    }
    else{
        #Location for the history file to be stored
        $PathToHistoryFile = "."+$directorydelimiter+"Utilities"+$directorydelimiter+"imported_dbs.sqlite"

        #Let's go ahead and create the history file if it does not exist
        if(!(test-path $pathtohistoryfile)){
            try{
                new-item $PathToHistoryFile
            }
            catch{
                write-host "Error 1h - Unable to write the history file to the filesystem. Permissions issue?" -ForegroundColor red
                read-host "Press [Enter] to exit"
                exit
            }

            #Query for defining the schema of the SQL database we're creating
            $historyquery = 'CREATE TABLE "history" ("historyID" INTEGER NOT NULL UNIQUE,"performer"	TEXT NOT NULL UNIQUE COLLATE BINARY,"import_date" TEXT NOT NULL,PRIMARY KEY("historyID" AUTOINCREMENT));'

            try{
                Invoke-SqliteQuery -Query $historyQuery -DataSource $PathToHistoryFile
            }
            catch{
                write-host "Error 2h - Unable to create a history file using SQL." -ForegroundColor red
                read-host "Press [Enter] to exit"
                exit
            }
        }

        #First let's check to see if this performer is even in the history file
        try{
            $historyQuery = 'SELECT * FROM history WHERE history.performer = "'+$performername+'"'
            $performerFromHistory = Invoke-SqliteQuery -Query $historyQuery -DataSource $PathToHistoryFile
        }
        catch{
            write-host "Error 3h - Something went wrong while trying to read from history file ($PathToHistoryFile)" -ForegroundColor red
            read-host "Press [Enter] to exit"
            exit
        }

        #If this performer DOES exist in the history file...
        if ($performerFromHistory){

            #Let's get the timestamp from the metdata database file
            $metadataLastWriteTime = get-item $currentdatabase
            $metadataLastWriteTime = $metadataLastWriteTime.LastWriteTime

            #If the metdata database for this performer has been modified since the last time we read this metadata database in, let's go ahead and parse it
            if([datetime]$metadataLastWriteTime -gt [datetime]$performerFromHistory.import_date){
                $currenttimestamp = get-date -format o
                try { 
                    $historyQuery = 'UPDATE import_date SET import_date = "'+$currenttimestamp+'" WHERE history.performer = "'+$performername+'"'
                    Invoke-SqliteQuery -Query $historyQuery -DataSource $PathToHistoryFile    
                }
                catch{
                    write-host "Error 4h - Something went wrong while trying to update the history file ($PathToHistoryFile)" -ForegroundColor red
                    read-output "Press [Enter] to exit"
                    exit
                }
                return $false
            }
            else{
                write-host "- The metadata database for $performername hasn't changed since your last import! Skipping..."
                return $true
            }
        }
        #Otherwise, this performer is entirely new to us, so let's add the performer to the history file 
        else{
            $currenttimestamp = get-date -format o
            try { 
                $historyQuery = 'INSERT INTO history(performer, import_date) VALUES ("'+$performername+'", "'+$currenttimestamp+'")'
                Invoke-SqliteQuery -Query $historyQuery -DataSource $PathToHistoryFile    
            }
            catch{
                write-host "Error 5h - Something went wrong while trying to add this performer to the history file ($PathToHistoryFile)" -ForegroundColor red
                read-output "Press [Enter] to exit"
                exit
            }
            return $false
        }
    }
} #End DatabaseHasBeenImported

#Add-MetadataUsingOFDB adds metadata to Stash using metadata databases.
function Add-MetadataUsingOFDB{
    #Playing it safe and asking the user to back up their database first
    $backupConfirmation = Read-Host "`nBefore we begin, would you like to make a backup of your Stash Database? [Y/N] (Default is 'No')"

    if (($backupConfirmation -like "Y*")) {
        $StashGQL_Query = 'mutation BackupDatabase($input: BackupDatabaseInput!) {
            backupDatabase(input: $input)
          }'
        $StashGQL_QueryVariables = '{
            "input": {}
          }' 

        try{
            Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
        }
        catch{
            write-host "(10) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
            write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
            read-host "Press [Enter] to exit"
            exit
        }
        write-output "...Done! A backup was successfully created."
    }
    else{
        write-output "OK, a backup will NOT be created." 

    }


    

    write-output "`nScanning for existing OnlyFans Metadata Database files..."

    #Finding all of our metadata databases. 
    $OFDatabaseFilesCollection = Get-ChildItem -Path $PathToOnlyFansContent -Recurse | where-object {$_.name -in "user_data.db","posts.db"}
        
    #For the discovery of a single database file
    if ($OFDatabaseFilesCollection.count -eq 1){

        #More modern OF DB schemas include the name of the performer in the profile table. If this table does not exist we will have to derive the performer name from the filepath, assuming the db is in a /metadata/ folder.
        $Query = "PRAGMA table_info(medias)"
        $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $OFDatabaseFilesCollection[0].FullName
        #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
        $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 

        $performername = $null
        if ($OFDBColumnsToCheck -match "profiles"){
            $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
            $performername =  Invoke-SqliteQuery -Query $Query -DataSource $OFDatabaseFilesCollection[0].FullName
        }

        #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
        if ($null -eq $performername){
            $performername = $OFDatabaseFilesCollection.FullName | split-path | split-path -leaf
            if ($performername -eq "metadata"){
                $performername = $OFDatabaseFilesCollection.FullName | split-path | split-path | split-path -leaf
            }
        }
        write-output "Discovered a metadata database for '$performername' "
    }

    #For the discovery of multiple database files
    elseif ($OFDatabaseFilesCollection.count -gt 1){
        
        $totalNumMetadataDatabases = $OFDatabaseFilesCollection.count
        write-host "...Discovered $totalnummetadatadatabases metadata databases."
        write-host "`nHow would you like to import metadata for these performers?"
        write-host "1 - Import metadata for all discovered performers"
        write-host "2 - Import metadata for a specific performer"
        write-host "3 - Import metadata for a range of performers"
        $selectednumberforprocess = read-host "Make your selection [Enter a number]"

        while([int]$selectednumberforprocess -notmatch "[1-3]" ){
            write-host "Invalid input"
            $selectednumberforprocess = read-host "Make your selection [Enter a number]"
        }

        if ([int]$selectednumberforprocess -eq 1){
            write-host "OK, all performers will be processed."
        }
        #Logic for handling the process for selecting a single performer
        elseif([int]$selectednumberforprocess -eq 2){
            write-host " " #Just adding a new line for a better UX
            #logic for displaying all found performers for user to select
            $i=1 # just used cosmetically
            Foreach ($OFDBdatabase in $OFDatabaseFilesCollection){
    
                #Getting the performer name from the profiles table (if it exists)
                $Query = "PRAGMA table_info(medias)"
                $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $OFDBdatabase.FullName
    
                #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
                $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 
                $performername = $null
                if ($OFDBColumnsToCheck -match "profiles"){
                    $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                    $performername =  Invoke-SqliteQuery -Query $Query -DataSource $OFDatabaseFilesCollection[0].FullName
                }
    
                #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
                if ($null -eq $performername){
                    $performername = $OFDBdatabase.FullName | split-path | split-path -leaf
                    if ($performername -eq "metadata"){
                        $performername = $OFDBdatabase.FullName | split-path | split-path | split-path -leaf
                    }
                }
              
                write-output "$i - $performername"
                $i++
            }

            
            $selectednumber = read-host "`n# Which performer would you like to select? [Enter a number]"
            #Checking for bad input
            while ($selectednumber -notmatch "^[\d\.]+$" -or ([int]$selectednumber -gt $totalNumMetadataDatabases)){
                $selectednumber = read-host "Invalid Input. Please select a number between 0 and" $totalNumMetadataDatabases".`nWhich performer would you like to select? [Enter a number]"
            }

            $selectednumber = $selectednumber-1 #Since we are dealing with a 0 based array, i'm realigning the user selection
            $performername = $OFDatabaseFilesCollection[$selectednumber].FullName | split-path | split-path -leaf
            if ($performername -eq "metadata"){
                $performername = $OFDatabaseFilesCollection[$selectednumber].FullName | split-path | split-path | split-path -leaf #Basically if we hit the metadata folder, go a folder higher and call it the performer
            }
            
            #Specifically selecting the performer the user wants to parse.
            $OFDatabaseFilesCollection = $OFDatabaseFilesCollection[$selectednumber]

            write-output "OK, the performer '$performername' will be processed."

        }

        #Logic for handling the range process
        else{

            #Logic for displaying all found performers
            $i=1 # just used cosmetically
            write-host "`nHere are all the performers that you can import metadata for:"
            Foreach ($OFDBdatabase in $OFDatabaseFilesCollection){
    
                #Getting the performer name from the profiles table (if it exists)
                $Query = "PRAGMA table_info(medias)"
                $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $OFDBdatabase.FullName
    
                #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
                $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 
                $performername = $null
                if ($OFDBColumnsToCheck -match "profiles"){
                    $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                    $performername =  Invoke-SqliteQuery -Query $Query -DataSource $OFDatabaseFilesCollection[0].FullName
                }
    
                #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
                if ($null -eq $performername){
                    $performername = $OFDBdatabase.FullName | split-path | split-path -leaf
                    if ($performername -eq "metadata"){
                        $performername = $OFDBdatabase.FullName | split-path | split-path | split-path -leaf
                    }
                }
              
                write-output "$i - $performername"
                $i++
            }

            #Some input handling/error handling for the user defined start of the range
            $StartOfRange = read-host "Which performer is the first in the range? [Enter a number]"
            $rangeInputCheck = $false

            while($rangeInputCheck -eq $false){
                if($StartOfRange -notmatch "^[\d\.]+$"){
                    write-host "`nInvalid Input: You have to enter a number"
                    $StartOfRange = read-host "Which performer is at the start of the range? [Enter a number]"
                }
                elseif($StartOfRange -le 0){
                    write-host "`nInvalid Input: You can't enter a number less than 1"
                    $StartOfRange = read-host "Which performer is at the start of the range? [Enter a number]"
                }
                elseif($StartOfRange -ge $totalNumMetadataDatabases){
                    write-host "`nInvalid Input: You can't enter a number greater than or equal to $totalNumMetadataDatabases"
                    $StartOfRange = read-host "Which performer is at the start of the range? [Enter a number]"
                }
                else{
                    $rangeInputCheck = $true
                }
            }

            #Some input handling/error handling for the user defined end of the range
            $endOfRange = Read-Host "Which performer is at the end of the range? [Enter a number]"
            $rangeInputCheck = $false

            while($rangeInputCheck -eq $false){
                if($EndOfRange -notmatch "^[\d\.]+$"){
                    write-host "`nInvalid Input: You have to enter a number"
                    $endOfRange = read-host "Which performer is at the end of the range? [Enter a number]"
                }
                elseif($EndOfRange -le 0){
                    write-host "`nInvalid Input: You can't enter a number less than 1"
                    $endOfRange = read-host "Which performer is at the end of the range? [Enter a number]"
                }
                elseif($endOfRange -gt $totalNumMetadataDatabases){
                    write-host "`nInvalid Input: You can't enter a number greater than $totalNumMetadataDatabases"
                    $endOfRange = read-host "Which performer is at the end of the range? [Enter a number]"
                }
                elseif($endOfRange -le $StartOfRange){
                    write-host "`nInvalid Input: Number has to be greater than $StartofRange"
                    $endOfRange = read-host "Which performer is at the end of the range? [Enter a number]"
                }
                else{
                    $rangeInputCheck = $true
                }
            }
            write-host "OK, all the performers between $startofrange and $endofrange will be processed."
            

            #We subtract 1 to account for us presenting the user with a 1 based start while PS arrays start at 0
            $endofrange = $endOfRange - 1 
            $StartOfRange = $StartOfRange - 1

            #Finally, let's define the new array of metadata databases based on the defined range
            $OFDatabaseFilesCollection = $OFDatabaseFilesCollection[$startofrange..$endOfRange]
            write-host $OFDatabaseFilesCollection
        }

        #Let's ask the user what type of media they want to parse
        write-host "`nWhich types of media do you want to import metadata for?"
        write-host "1 - Both Videos & Images`n2 - Only Videos`n3 - Only Images"

        $mediaToProcessSelector = 0;
        do {
            $mediaToProcessSelector = read-host "Make your selection [1-3]"
        }
        while (($mediaToProcessSelector -notmatch "[1-3]"))

        write-host "`nQuick Tips :" -ForegroundColor Cyan
        write-host "   * Be sure to run a Scan task in Stash of your OnlyFans content before running this script!`n   * Be sure your various OnlyFans metadata database(s) are located either at`n     <performername>"$directorydelimiter"user_data.db or at <performername>"$directorydelimiter"metadata"$directorydelimiter"user_data.db"
        read-host "`nPress [Enter] to begin"
    }

    #We use these values after the script finishes parsing in order to provide the user with some nice stats
    $numModified = 0
    $numUnmodified = 0
    $nummissingfiles = 0
    $scriptStartTime = get-date

    #Getting the OnlyFans Studio ID or creating it if it does not exist.
    $StashGQL_Query = '
    query FindStudios($filter: FindFilterType, $studio_filter: StudioFilterType) {
        findStudios(filter: $filter, studio_filter: $studio_filter) {
            count
            studios {
                id
                name
            }
        }
    }
    ' 
    $StashGQL_QueryVariables = '{
        "filter": {
          "q": ""
        },
        "studio_filter": {
          "name": {
            "value": "OnlyFans",
            "modifier": "EQUALS"
          }
        }
      }'
    try{
        $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
    }
    catch{
        write-host "(1) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
        write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
        read-host "Press [Enter] to exit"
        exit
    }
    $OnlyFansStudioID = $StashGQL_Result.data.findStudios.Studios[0].id

    #If Stash returns with an ID for 'OnlyFans', great. Otherwise, let's create a new studio
    if ($null -eq $OnlyFansStudioID){
        $StashGQL_Query = 'mutation StudioCreate($input: StudioCreateInput!) {
            studioCreate(input: $input) {
              name
              url
            }
          }'

        $StashGQL_QueryVariables = '{
            "input": {
                "name": "OnlyFans",
                "url": "www.onlyfans.com/"
            }    
        }'

        try{
            $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
        }
        catch{
            write-host "(9) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
            write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
            read-host "Press [Enter] to exit"
            exit
        }
        $StashGQL_Query = '
        query FindStudios($filter: FindFilterType, $studio_filter: StudioFilterType) {
            findStudios(filter: $filter, studio_filter: $studio_filter) {
                count
                studios {
                    id
                    name
                }
            }
        }
        ' 
        $StashGQL_QueryVariables = '{
        "filter": {
            "q": "OnlyFans"
        }
        }'
        try{
            $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
        }
        catch{
            write-host "(9a) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
            write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
            read-host "Press [Enter] to exit"
            exit
        }

        $OnlyFansStudioID = $StashGQL_Result.data.findStudios.Studios[0].id
        write-host "`nInfo: Added the OnlyFans studio to Stash's database" -ForegroundColor Cyan
        
    }

    $totalprogressCounter = 1 #Used for the progress UI

    foreach ($currentdatabase in $OFDatabaseFilesCollection) {
        #Let's help the user see how we are progressing through this metadata database (this is the parent progress UI, there's an additional child below as well)
        $currentTotalProgress = [int]$(($totalprogressCounter/$OFDatabaseFilesCollection.count)*100)
        Write-Progress -id 1 -Activity "Total Import Progress" -Status "$currentTotalProgress% Complete" -PercentComplete $currentTotalProgress
        $totalprogressCounter++


        #Gotta reparse the performer name as we may be parsing through a full collection of performers. 
        #Otherwise you'll end up with a whole bunch of performers having the same name
        #This is also where we will make the determination if this onlyfans database has the right tables to be used here
        #First step, let's check to ensure this OF db is valid for use
        $Query = "PRAGMA table_info(medias)"
        $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $currentdatabase.FullName

        #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
        #Then we use a match condition and a whole lot of or statements to determine if this db has all the right columns this script needs.
        $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 
        if (($OFDBColumnsToCheck -notmatch "media_id") -or ($OFDBColumnsToCheck -notmatch "post_id") -or ($OFDBColumnsToCheck -notmatch "directory") -or ($OFDBColumnsToCheck -notmatch "filename") -or ($OFDBColumnsToCheck -notmatch "size") -or ($OFDBColumnsToCheck -notmatch "media_type") -or ($OFDBColumnsToCheck -notmatch "created_at")){
            $SchemaIsValid = $false
        }
        else {
            $SchemaIsValid = $true
        }

        #If the OF metadata db is no good, tell the user and skip the rest of this very massive conditional block (I need to refactor this)
        if ((!$SchemaIsValid)){
            write-host "Error: The following OnlyFans metadata database doesn't contain the metadata in a format that this script expects." -ForegroundColor Red
            write-host "This can occur if you've scraped OnlyFans using an unsupported tool. " -ForegroundColor Red
            write-output $currentdatabase.FullName
            read-host "Press [Enter] to continue"
            
        }
        else{
            #More modern OF DB schemas include the name of the performer in the profile table. If this table does not exist we will have to derive the performer name from the filepath, assuming the db is in a /metadata/ folder.
            $performername = $null
            if ($OFDBColumnsToCheck -match "profiles"){
                $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                $performername =  Invoke-SqliteQuery -Query $Query -DataSource $currentdatabase.FullName
                
            }

            #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
            if ($null -eq $performername){
                $performername = $currentdatabase.FullName | split-path | split-path -leaf
                
                if ($performername -eq "metadata"){
                    $performername = $currentdatabase.FullName | split-path | split-path | split-path -leaf
                }
            }

            #Let's see if we can find this performer in Stash
            $StashGQL_Query = '
            query FindPerformers($filter: FindFilterType, $performer_filter: PerformerFilterType) {
               findPerformers(filter: $filter, performer_filter: $performer_filter) {
                 count
                 performers {
                   id
                   name
                 }
               }
             }
            ' 
            $StashGQL_QueryVariables = '{
                "filter": {
                    "q": "'+$performername+'"
                }
            }'
            try{
                $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
            }
            catch{
                write-host "(2) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                read-host "Press [Enter] to exit"
                exit
            }
            $PerformerID = $StashGQL_Result.data.findPerformers.performers[0].id
            
            #If we had no luck finding the performer, lets create one, then get the ID
            if($null -eq $performerID){
       
                $StashGQL_Query = 'mutation PerformerCreate($input: PerformerCreateInput!) {
                    performerCreate(input: $input) {
                        name
                        url
                    }
                  }'

                $StashGQL_QueryVariables = '{
                    "input": {
                        "name": "'+$performername+'",
                        "url": "www.onlyfans.com/'+$performername+'"
                    }    
                }' 
            
                try{
                    Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                }
                catch{
                    write-host "(3) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                    read-host "Press [Enter] to exit"
                    exit
                }
                $StashGQL_Query = '
                query FindPerformers($filter: FindFilterType, $performer_filter: PerformerFilterType) {
                   findPerformers(filter: $filter, performer_filter: $performer_filter) {
                     count
                     performers {
                       id
                       name
                     }
                   }
                 }
                ' 
                $StashGQL_QueryVariables = '{
                    "filter": {
                        "q": "'+$performername+'"
                    }
                }'
                try{
                    $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                }
                catch{
                    write-host "(22) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                    read-host "Press [Enter] to exit"
                    exit
                }
                $PerformerID = $StashGQL_Result.data.findPerformers.performers[0].id
                $creatednewperformer = $true #We'll use this later after images have been added in order to give the performer a profile picture
                $boolGetPerformerImage = $true #We'll use this to get an image to use for the profile picture
                
                
            }
            else{
                $creatednewperformer = $false 
                $boolGetPerformerImage = $false
            }

            #Let's check to see if we need to import this performer based on the history file using the DatabaseHasBeenImported function
            #The ignorehistory variable is a command line flag that the user may set if they want to have the script ignore the use of the history file
             
            if (!(DatabaseHasAlreadyBeenImported)){
                #Select all the media (except audio) and the text the performer associated to them, if available from the OFDB
                $Query = "SELECT messages.text, medias.directory, medias.filename, medias.size, medias.created_at, medias.post_id, medias.media_type FROM medias INNER JOIN messages ON messages.post_id=medias.post_id UNION SELECT posts.text, medias.directory, medias.filename, medias.size, medias.created_at, medias.post_id, medias.media_type FROM medias INNER JOIN posts ON posts.post_id=medias.post_id WHERE medias.media_type <> 'Audios'"
                $OF_DBpath = $currentdatabase.fullname 
                $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $OF_DBpath

                $progressCounter = 1 #Used for the progress UI
                foreach ($OFDBMedia in $OFDBQueryResult){

                    #Let's help the user see how we are progressing through this performer's metadata database
                    $currentProgress = [int]$(($progressCounter/$OFDBQueryResult.count)*100)
                    Write-Progress -parentId 1 -Activity "$performername Import Progress" -Status "$currentProgress% Complete" -PercentComplete $currentProgress
                    $progressCounter++
    
                    #Generating the URL for this post
                    $linktoOFpost = "https://www.onlyfans.com/"+$OFDBMedia.post_ID+"/"+$performername
                    
                    #Reformatting the date to something stash appropriate
                    $creationdatefromOF = $OFDBMedia.created_at
                    $creationdatefromOF = Get-Date $creationdatefromOF -format "yyyy-MM-dd"
                    
                    $OFDBfilesize = $OFDBMedia.size #filesize (in bytes) of the media, from the OF DB
                    $OFDBfilename = $OFDBMedia.filename #This defines filename of the media, from the OF DB
                    $OFDBdirectory = $OFDBMedia.directory #This defines the file directory of the media, from the OF DB
                    $OFDBFullFilePath = $OFDBdirectory+$directorydelimiter+$OFDBfilename #defines the full file path, using the OS appropriate delimeter
    
                    #Storing separate variants of these variables with apostrophy and backslash sanitization so they don't ruin our SQL/GQL queries
                    $OFDBfilenameForQuery = $OFDBfilename.replace("'","''") 
                    $OFDBdirectoryForQuery = $OFDBdirectory.replace("'","''") 
                    $OFDBfilenameForQuery = $OFDBfilename.replace("\","\\") 
                    $OFDBdirectoryForQuery = $OFDBdirectory.replace("\","\\") 
    
                    #Note that the OF downloader quantifies gifs as videos for some reason
                    #Since Stash doesn't (and rightfully so), we need to account for this
                    if(($OFDBMedia.media_type -eq "videos") -and ($OFDBfilename -notlike "*.gif")){
                        $mediatype = "video"
                    }
                    #Condition for images. Again, we have to add an extra condition just in case the image is a gif due to the DG database
                    elseif(($OFDBMedia.media_type -eq "images") -or ($OFDBfilename -like "*.gif")){
                        $mediatype = "image"
                    }
    
                    #Depending on the user preference, we may not want to actually process the media we're currently looking at. Let's check before continuing.
                    if (($mediaToProcessSelector -eq 2) -and ($mediatype -eq "image")){
                        #There's a scenario where because the user has not pulled any images for this performer, there will be no performer image. In that scenario, lets pull exactly one image for this purpose
                        if ($boolGetPerformerImage){
                            $boolGetPerformerImage = $false #Let's make sure we don't pull any more photos
                        }
                        else{
                            continue #Skip to the next item in this foreach, user only wants to process videos
                        }
                    }
    
                    if (($mediaToProcessSelector -eq 3) -and ($mediatype -eq "video")){
                        continue #Skip to the next item in this foreach, user only wants to process images
                    }
                    
                    #Depending on user preference, we want to be more/less specific with our SQL queries to the Stash DB here, as determined by this condition tree (defined in order of percieved popularity)
                    #Normal specificity, search for videos based on having the performer name somewhere in the path and a matching filesize
                    if ($mediatype -eq "video" -and $searchspecificity -match "normal"){
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path LIKE ''%'+$performername+'%'' AND size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'             
                    }
                    #Normal specificity, search for images based on having the performer name somewhere in the path and a matching filesize
                    elseif ($mediatype -eq "image" -and $searchspecificity -match "normal"){
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE path LIKE ''%'+$performername+'%'' AND size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'
                    }
                    #Low specificity, search for videos based on filesize only
                    elseif ($mediatype -eq "video" -and $searchspecificity -match "low"){
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'   
                    }
                    #Low specificity, search for images based on filesize only
                    elseif ($mediatype -eq "image" -and $searchspecificity -match "low"){
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'
                    }
    
                    #High specificity, search for videos based on matching file path between OnlyFans DB and Stash DB as well as matching the filesize. 
                    elseif ($mediatype -eq "video" -and $searchspecificity -match "high"){
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path ='''+$OFDBdirectoryForQuery+''' AND files.basename ='''+$OFDBfilenameForQuery+''' AND size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'
                    }
    
                    #High specificity, search for images based on matching file path between OnlyFans DB and Stash DB as well as matching the filesize. 
                    else{
                        $StashGQL_Query = 'mutation {
                            querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE path ='''+$OFDBdirectoryForQuery+''' AND files.basename ='''+$OFDBfilenameForQuery+''' AND size = '''+$OFDBfilesize+'''") {
                            rows
                          }
                        }'
                    }
    
                    #Now lets try running the GQL query and see if we have a match in the Stash DB
                    try{
                        $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                    }
                    catch{
                        write-host "(4) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                        write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                        read-host "Press [Enter] to exit"
                        exit
                    }
    
                    if ($StashGQL_Result.data.querySQL.rows.length -ne 0){
    
                        #Because of how GQL returns data, these values are just positions in the $StashGQLQuery array. Not super memorable, so I'm putting them in variables. 
                        $CurrentFileID = $StashGQL_Result.data.querySQL.rows[0][5] #This represents either the scene ID or the image ID
                        $CurrentFileTitle = $StashGQL_Result.data.querySQL.rows[0][6]
                    }
                    
                    #If our search for matching media in Stash itself comes up empty, let's check to see if the file even exists on the file system 
                    if ($StashGQL_Result.data.querySQL.rows.length -eq 0 ){
                        if (Test-Path $OFDBFullFilePath){
                            write-host "`nInfo: There's a file in this OnlyFans metadata database that we couldn't find in your Stash database but the file IS on your filesystem.`nTry running a Scan Task in Stash then re-running this script.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                        }
                        #In this case, the media isn't in Stash or on the filesystem so inform the user, log the file, and move on
                        else{
                            write-host "`nInfo: There's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the script you used to scrape this OnlyFans performer and redownloading the file.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                            Add-Content -Path $PathToMissingFilesLog -value " $OFDBFullFilePath"
                            $nummissingfiles++
                        }
                    }
                    #Otherwise we have found a match! let's process the matching result and add the metadata we've found
                    else{
                        
                        #Before processing, and for the sake of accuracy, if there are multiple filesize matches (specifically for the normal specificity mode), add a filename check to the query to see if we can match more specifically. If not, just use whatever matched that initial query.
                        if (($StashGQL_Result.data.querySQL.rows.length -gt 1) -and ($searchspecificity -match "normal") ){
                            #Search for videos based on having the performer name somewhere in the path and a matching filesize (and filename in this instance)
                            if ($mediatype -eq "video"){
                               
                                $StashGQL_Query = 'mutation {
                                    querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id path LIKE ''%'+$performername+'%'' AND files.basename ='''+$OFDBfilenameForQuery+''' AND size = '''+$OFDBfilesize+'''") {
                                    rows
                                  }
                                }'
                            }
    
                            #Search for images based on having the performer name somewhere in the path and a matching filesize (and filename in this instance)
                            elseif ($mediatype -eq "image" ){
                                
                                $StashGQL_Query = 'mutation {
                                    querySQL(sql: "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE path LIKE ''%'+$performername+'%'' AND files.basename ='''+$OFDBfilenameForQuery+''' AND size = '''+$OFDBfilesize+'''") {
                                    rows
                                  }
                                }'
                            }
    
                            #Now lets try running the GQL query and try to find the file in the Stash DB
                            try{
                                $AlternativeStashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                            }
                            catch{
                                write-host "(5) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                read-host "Press [Enter] to exit"
                                exit
                            }
    
                            #If we have a match, substitute it in and lets get that metadata into the Stash DB
                            if($StashGQL_Result_2.data.querySQL.rows -eq 1){
                                $StashGQL_Result = $AlternativeStashGQL_Result
                                $CurrentFileID = $StashGQL_Result.data.querySQL.rows[0][5] #This represents either the scene ID or the image ID
                                $CurrentFileTitle = $StashGQL_Result.data.querySQL.rows[0][6]
                            } 
                        }
    
                        #Creating the title we want for the media, and defining Stash details for this media.
                        $proposedtitle = "$performername - $creationdatefromOF"
                        $detailsToAddToStash = $OFDBMedia.text
    
                        
                        #Performers love to put links in their posts sometimes. Let's scrub those out in addition to any common HTML bits
                        $detailsToAddToStash = $detailsToAddToStash.Replace("<br />","")
                        $detailsToAddToStash = $detailsToAddToStash.Replace("<a href=","")
                        $detailsToAddToStash = $detailsToAddToStash.Replace("<a href =","")
                        $detailsToAddToStash = $detailsToAddToStash.Replace('"/',"")
                        $detailsToAddToStash = $detailsToAddToStash.Replace('">',"")
                        $detailsToAddToStash = $detailsToAddToStash.Replace("</a>"," ")
                        $detailsToAddToStash = $detailsToAddToStash.Replace('target="_blank"',"")
    
                        #For some reason the invoke-graphqlquery module doesn't quite escape single/double quotes ' " (or their curly variants) or backslashs \ very well so let's do it manually for the sake of our JSON query
                        $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                        $detailsToAddToStash = $detailsToAddToStash.replace("\","\\")
                        $detailsToAddToStash = $detailsToAddToStash.replace('"','\"')
                        $detailsToAddToStash = $detailsToAddToStash.replace('“','\"') #literally removing the curly quote entirely
                        $detailsToAddToStash = $detailsToAddToStash.replace('”','\"') #literally removing the curly quote entirely
                  
                        $proposedtitle = $proposedtitle.replace("'","''")
                        $proposedtitle = $proposedtitle.replace("\","\\")
                        $proposedtitle = $proposedtitle.replace('"','\"')
                        $proposedtitle = $proposedtitle.replace('“','\"') #literally removing the curly quote entirely
                        $proposedtitle = $proposedtitle.replace('”','\"') #literally removing the curly quote entirely
    
                        #Let's check to see if this is a file that already has metadata.
                        #For Videos, we check the title and the details
                        #For Images, we only check title (for now)
                        #If any metadata is missing, we don't bother with updating a specific column, we just update the entire row
                        if ($mediatype -eq "video"){
                            #By default we will claim this file to be unmodified (we use this for user stats at the end of the script)
                            $filewasmodified = $false
    
                            #Let's determine if this scene already has the right performer associated to it
                            $StashGQL_Query = 'query FindScene($id:ID!) {
                                findScene(id: $id){
                                    performers {
                                        id 
                                    }
                                }
                            
                            }'
                            $StashGQL_QueryVariables = '{
                                    "id": "'+$CurrentFileID+'"
                            }' 
                            
                            try{
                                $DiscoveredPerformerIDFromStash = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                            }
                            catch{
                                write-host "(6) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                read-host "Press [Enter] to exit"
                                exit
                            }
    
                            $performermatch = $false
                            if ($null -ne $DiscoveredPerformerIDFromStash.data.findscene.performers.length){
                                foreach ($performer in $DiscoveredPerformerIDFromStash.data.findscene.performers.id){
                                    if($performer -eq $performerid){  
                                        $performermatch = $true
                                        break
                                    }
                                }
                            }
                            if (!$performermatch){
                                $filewasmodified = $true
                                $StashGQL_Query = 'mutation sceneUpdate($sceneUpdateInput: SceneUpdateInput!){
                                    sceneUpdate(input: $sceneUpdateInput){
                                        id
                                        performers{
                                            id
                                        }
                                    }
                                }'
                                $StashGQL_QueryVariables = ' {
                                    "sceneUpdateInput": {
                                        "id": "'+$CurrentFileID+'",
                                        "performer_ids": "'+$performerID+'"
                                    }
                                }'
                                try{
                                    Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                                }
                                catch{
                                    write-host "(7) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                    read-host "Press [Enter] to exit"
                                    exit
                                }
                            }
    
                            #If it's necessary, update the scene by modifying the title and adding details
                            if($CurrentFileTitle -ne $proposedtitle){
                                $StashGQL_Query = 'mutation sceneUpdate($sceneUpdateInput: SceneUpdateInput!){
                                    sceneUpdate(input: $sceneUpdateInput){
                                      id
                                      title
                                      date
                                      studio {
                                        id
                                      }
                                      details
                                      urls
                                    }
                                  }'  
                                $StashGQL_QueryVariables = '{
                                    "sceneUpdateInput": {
                                        "id": "'+$CurrentFileID+'",
                                        "title": "'+$proposedtitle+'",
                                        "date": "'+$creationdatefromOF+'",
                                        "studio_id": "'+$OnlyFansStudioID+'",
                                        "details": "'+$detailsToAddToStash+'",
                                        "urls": "'+$linktoOFpost+'"
                                    }
                                }'
    
                                try{
                                    Invoke-GraphQLQuery -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -escapehandling EscapeNonAscii | out-null
                                }
                                catch{
                                    write-host "(8) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                    read-host "Press [Enter] to exit" 
                                    exit
                                }
    
                                $filewasmodified = $true
                            }
    
                            #Provide user feedback on what has occured and add to the "file modified" counter for stats later
                            if ($filewasmodified){
                                if ($v){
                                    write-output "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                }
                                $numModified++  
                            }
                            else{
                                if ($v){
                                    write-output "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                }
                                $numUnmodified++
                            }
                        }
    
                        #For images
                        else{
                            #By default we will claim this file to be unmodified (we use this for user stats at the end of the script)
                            $filewasmodified = $false
    
                            #Let's determine if this Image already has the right performer associated to it
                            $StashGQL_Query = 'query FindImage($id:ID!) {
                                findImage(id: $id){
                                    performers {
                                        id 
                                    }
                                }
                            
                            }'
                            $StashGQL_QueryVariables = '{
                                    "id": "'+$CurrentFileID+'"
                            }' 
                            
                            try{
                                $DiscoveredPerformerIDFromStash = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                            }
                            catch{
                                write-host "(6) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                read-host "Press [Enter] to exit"
                                exit
                            }
    
                            $performermatch = $false
                            if ($null -ne $DiscoveredPerformerIDFromStash.data.findimage.performers.length){
                                foreach ($performer in $DiscoveredPerformerIDFromStash.data.findimage.performers.id){
                                    if($performer -eq $performerid){       
                                        $performermatch = $true
                                        break
                                    }
                                }
                            }
                            if (!$performermatch){
                                $filewasmodified = $true
                                $StashGQL_Query = 'mutation imageUpdate($imageUpdateInput: ImageUpdateInput!){
                                    imageUpdate(input: $imageUpdateInput){
                                        id
                                        performers{
                                            id
                                        }
                                    }
                                }'
                                $StashGQL_QueryVariables = ' {
                                    "imageUpdateInput": {
                                        "id": "'+$CurrentFileID+'",
                                        "performer_ids": "'+$performerID+'"
                                    }
                                }'
                                try{
                                    Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                                }
                                catch{
                                    write-host "(7) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                    read-host "Press [Enter] to exit"
                                    exit
                                }
                                
                            }
    
                            #If it's necessary, update the image by modifying the title and adding details
                            if($CurrentFileTitle -ne $proposedtitle){
                                if ($boolSetImageDetails -eq $true){
                                    $StashGQL_Query = 'mutation imageUpdate($imageUpdateInput: ImageUpdateInput!){
                                        imageUpdate(input: $imageUpdateInput){
                                          id
                                          title
                                          date
                                          studio {
                                            id
                                          }
                                          urls
                                          details
                                        }
                                      }'  
    
                                    $StashGQL_QueryVariables = '{
                                        "imageUpdateInput": {
                                            "id": "'+$CurrentFileID+'",
                                            "title": "'+$proposedtitle+'",
                                            "date": "'+$creationdatefromOF+'",
                                            "studio_id": "'+$OnlyFansStudioID+'",
                                            "details": "'+$detailsToAddToStash+'",
                                            "urls": "'+$linktoOFpost+'"
                                        }
                                    }'
                                }
                                else{
                                    $StashGQL_Query = 'mutation imageUpdate($imageUpdateInput: ImageUpdateInput!){
                                        imageUpdate(input: $imageUpdateInput){
                                          id
                                          title
                                          date
                                          studio {
                                            id
                                          }
                                          urls
                                        }
                                      }'  
    
                                    $StashGQL_QueryVariables = '{
                                        "imageUpdateInput": {
                                            "id": "'+$CurrentFileID+'",
                                            "title": "'+$proposedtitle+'",
                                            "date": "'+$creationdatefromOF+'",
                                            "studio_id": "'+$OnlyFansStudioID+'",
                                            "urls": "'+$linktoOFpost+'"
                                        }
                                    }'
                                }
                                
                                
                                try{
                                    Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Variables $StashGQL_QueryVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                                }
                                catch{
                                    write-host "(8) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                                    write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                                    read-host "Press [Enter] to exit"
                                    exit
                                }
    
                                $filewasmodified = $true
                            }
    
                            #Provide user feedback on what has occured and add to the "file modified" counter for stats later
                            if ($filewasmodified){
                                if ($v){
                                    write-output "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                }
                                $numModified++  
                            }
                            else{
                                if ($v){
                                    write-output "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                }
                                $numUnmodified++
                            }
                        } 
                    }
                }
            }
     
            #Before we move on, if we had created a new performer, let's update that performer with a profile image.
            #The only reason we don't do it earlier is that now all the images have been added and associated and it's easy to select an image and go.
            if($creatednewperformer){
                
                #First let's look for an image where this performer has been associated and get the URL, for that image
                #Sometimes these OF downloaders pull profile/avatar photos into a specific folder. We'll look to see if we can match on that first before just choosing what we can get.

                #Using the filepath of the metadata database as our starting point, we'll go a folder up and then look for an image containing the keyword "avatar"
                $pathToAvatarImage = (get-item $currentdatabase.FullName)
                $pathToAvatarImage = split-path -parent $pathToAvatarImage
                $pathToAvatarImage = split-path -parent $pathToAvatarImage
                $pathToAvatarImage = "$pathToAvatarImage"+"$directorydelimiter"+"Profile"

                #If there's a profile folder to look into, let's do it
                if((test-path $pathToAvatarImage)){
                    $avatarfolder = "$pathToAvatarImage"+"$directorydelimiter"+"Avatars"
                    $profileimagesfolder = "$pathToAvatarImage"+"$directorydelimiter"+"images"

                    if(test-path $avatarfolder){
                        $pathToAvatarImage =  Get-ChildItem $avatarfolder | where-object{ $_.extension -in ".jpg", ".jpeg"}
                        $pathToAvatarImage = $pathToAvatarImage
                    }
                    elseif (test-path $profileimagesfolder){
                        $pathToAvatarImage =  Get-ChildItem $profileimagesfolder | where-object{ $_.extension -in ".jpg", ".jpeg"}
                        $pathToAvatarImage = $pathToAvatarImage
                    }
                    #otherwise, let's just take whatever image we can get
                    else{
                        $pathToAvatarImage = Get-ChildItem $pathToAvatarImage -recurse | where-object{ $_.extension -in ".jpg", ".jpeg"}
                    }
            
                    #Convert the image to base64. Note that this is designed for jpegs-- I don't think OnlyFans supports anything else anyway.
                    $avatarImageBase64 = [convert]::ToBase64String((Get-Content $pathToAvatarImage -AsByteStream))
                    $avatarImageBase64 = "data:image/jpeg;base64,"+$avatarImageBase64

                    $UpdatePerformerImage_GQLQuery ='mutation PerformerUpdate($input: PerformerUpdateInput!) {
                        performerUpdate(input: $input) {
                        id
                        }
                    }'
                    $UpdatePerformerImage_GQLVariables = '{
                        "input": {
                        "id": "'+$performerID+'",
                        "image": "'+$avatarImageBase64+'"
                        }
                    }'

                    try{
                        Invoke-GraphQLQuery -Query $UpdatePerformerImage_GQLQuery -Uri $StashGQL_URL -Variables $UpdatePerformerImage_GQLVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                    }
                    catch{
                        write-host "(46) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                        write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                        read-host "Press [Enter] to exit"
                        exit
                    }
                }
                
                #If we didn't find anything on the filesystem, let's just query Stash and use a random image from this performer's OF page
                else{
                    $performerimageURL_GQLQuery = 'query FindImages(
                        $filter: FindFilterType
                        $image_filter: ImageFilterType
                        $image_ids: [Int!]
                    ) {
                        findImages(
                        filter: $filter,
                        image_filter: $image_filter,
                        image_ids: $image_ids){
                        images{
                            paths{
                            image
                            }
                        }
                        }
                    }'
    
                    $performerimageURLVariables_GQLQuery = '
                    {
                        "filter": {
                        "q": "",
                        "page": 1,
                        "per_page": 1,
                        "sort": "date",
                        "direction": "DESC"
                        },
                        "image_filter": {
                        "performers": {
                            "value": [
                            "'+$performerID+'"
                            ],
                            "excludes": [],
                            "modifier": "INCLUDES_ALL"
                        }
                        }
                    }'
    
                    try{
                        $performerimageURL = Invoke-GraphQLQuery -Query $performerimageURL_GQLQuery -Uri $StashGQL_URL -Variables $performerimageURLVariables_GQLQuery -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
                        
                    }
                    catch{
                        write-host "(11) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                        write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                        read-host "Press [Enter] to exit"
                        exit
                    }
    
                    #If there are any Performer images to be used, we update the performer using the URL path.
                    if ($performerimageURL.data.findimages.images.length -ne 0){
                        $performerimageURL = $performerimageURL.data.findimages.images.paths.image
    
                        
                        $UpdatePerformerImage_GQLQuery ='mutation PerformerUpdate($input: PerformerUpdateInput!) {
                            performerUpdate(input: $input) {
                            id
                            }
                        }'
                        $UpdatePerformerImage_GQLVariables = '{
                            "input": {
                            "id": "'+$performerID+'",
                            "image": "'+$performerimageURL+'"
                            }
                        }'
    
                        try{
                            $performerimageURL = Invoke-GraphQLQuery -Query $UpdatePerformerImage_GQLQuery -Uri $StashGQL_URL -Variables $UpdatePerformerImage_GQLVariables -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }}) | out-null
                        }
                        catch{
                            write-host "(12) Error: There was an issue with the GraphQL query/mutation." -ForegroundColor red
                            write-host "Additional Error Info: `n`n$StashGQL_Query `n$StashGQL_QueryVariables"
                            read-host "Press [Enter] to exit"
                            exit
                        }
                    }
                }
            }
        }
    }

    ## Finished scan, let's let the user know what the results were
    
    if ($nummissingfiles -gt 0){
        write-host "`n- Missing Files -" -ForegroundColor Cyan
        write-output "There is available metadata for $nummissingfiles files in your OnlyFans Database that cannot be found in your Stash Database."
        write-output "    - Be sure to review the MissingFiles log."
        write-output "    - There's a good chance you may need to rescan your OnlyFans folder in Stash and/or redownload those files"
    }

    write-host "`n****** Import Complete ******"-ForegroundColor Cyan
    write-output "- Modified Scenes/Images: $numModified`n- Scenes/Images that already had metadata: $numUnmodified" 
    #Some quick date arithmetic to calculate elapsed time
    $scriptEndTime = Get-Date
    $scriptduration = ($scriptEndTime-$scriptStartTime).totalseconds
    if($scriptduration -ge 60){
        [int]$Minutes = $scriptduration / 60
        [int]$seconds = $scriptduration % 60
        if ($minutes -gt 1){
            write-output "- This script took $minutes minutes and $seconds seconds to execute"
        }
        else{
            write-output "- This script took $minutes minute and $seconds seconds to execute"
        }
    }
    else{
        write-output "- This script took $scriptduration seconds to execute"
    }
} #End Add-MetadataUsingOFDB 

function Add-MetadataWithoutOFDB{
    write-host "`n Dev here-- I haven't finished re-writing this feature yet. Sorry! - JuiceBox"
    read-host "Press [Enter] to exit"
}


#Main Script

#This script should be OS agnostic-- because Windows likes to be special, let's determine which delimeter is appropriate for file paths.
if($IsWindows){
    $directorydelimiter = '\'
}
else{
    $directorydelimiter = '/'
}

$pathtoconfigfile = "."+$directorydelimiter+"OFMetadataToStash_Config"

#If there's no configuration file, send the user to create one
if (!(Test-path $PathToConfigFile)){
    Set-Config
}
$ConfigFileVersion = (Get-Content $pathtoconfigfile)[0]
if ($ConfigFileVersion -ne "#### OFMetadataToStash Config File v1 ####"){
    Set-Config
}

## Global Variables ##
$StashGQL_URL = (Get-Content $pathtoconfigfile)[3]
$PathToOnlyFansContent = (Get-Content $pathtoconfigfile)[5]
$SearchSpecificity = (Get-Content $pathtoconfigfile)[7]
$StashAPIKey = (Get-Content $pathtoconfigfile)[9]

$PathToMissingFilesLog = "."+$directorydelimiter+"OFMetadataToStash_MissingFiles.txt"
$pathToSanitizerScript = "."+$directorydelimiter+"Utilities"+$directorydelimiter+"OFMetadataDatabase_Sanitizer.ps1"


#Before we continue, let's make sure everything in the configuration file is good to go
#This query also serves a second purpose-- as of Stash v0.24, images will support details. We'll check for that and add details if possible.
$StashGQL_Query = 'query version{version{version}}'
try{
    $StashGQL_Result = Invoke-GraphQLQuery -Query $StashGQL_Query -Uri $StashGQL_URL -Headers $(if ($StashAPIKey){ @{ApiKey = "$StashAPIKey" }})
}
catch{
    write-host "Hmm...Could not communicate to Stash using the URL in the config file ($StashGQL_URL)"
    write-host "Are you sure Stash is running?"
    read-host "If Stash is running like normal, press [Enter] to recreate the configuration file for this script"
    Set-Config
}

$boolSetImageDetails = $StashGQL_Result.data.version.version.split(".")
if(($boolSetImageDetails[0] -eq "v0") -and ($boolSetImageDetails[1] -lt 24)){ #checking for 'v0' as I assume stash will go to version 1 at some point.
    $boolSetImageDetails = $false
}
else {
    $boolSetImageDetails = $true
}

if (!(test-path $PathToOnlyFansContent)){
    #Couldn't find the path? Send the user to recreate their config file with the set-config function
    read-host "Hmm...The defined path to your OnlyFans content does not seem to exist at the location specified in your config file.`n($PathToOnlyFansContent)`n`nPress [Enter] to run through the config wizard"
    Set-Config
}

if(($SearchSpecificity -notmatch '\blow\b|\bnormal\b|\bhigh\b')){
    #Something goofy with the variable? Send the user to recreate their config file with the set-config function
    read-host "Hmm...The Metadata Match Mode parameter isn't well defined in your configuration file. No worries!`n`nPress [Enter] to run through the config wizard"
    Set-Config
}
else {
    clear-host
    write-host "- OnlyFans Metadata DB to Stash PoSH Script 0.9 - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n" -ForegroundColor cyan
    write-output "By JuiceBox`n`n----------------------------------------------------`n"
    write-output "* Path to OnlyFans Media:     $PathToOnlyFansContent"
    write-output "* Metadata Match Mode:        $searchspecificity"
    write-output "* Stash URL:                  $StashGQL_URL`n"
    if($v){
        write-host "Special Mode: Verbose Output"
    }
    if($ignorehistory){
        write-host "Special Mode: Ignore History File"
    }
    write-output "----------------------------------------------------`n"
    write-output "What would you like to do?"
    write-output " 1 - Add Metadata to my Stash using OnlyFans Metadata Database(s)"
    write-output " 2 - Add Metadata to my Stash without using OnlyFans Metadata Database(s)"
    write-output " 3 - Generate a redacted, sanitized copy of my OnlyFans Metadata Database file(s)"
    write-output " 4 - Change Settings"
}

$userscanselection = 0;
do {
    $userscanselection = read-host "`nEnter selection"
}
while (($userscanselection -notmatch "[1-4]"))

switch ($userscanselection){
    1 {Add-MetadataUsingOFDB}
    2 {Add-MetadataWithoutOFDB}
    3 {invoke-expression $pathtosanitizerscript}
    4 {Set-Config}
}
