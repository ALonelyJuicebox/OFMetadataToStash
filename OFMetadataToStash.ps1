<#
---OnlyFans Metadata to Stash Database PoSH Script 0.5---

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

### Functions

#Set-Config is a wizard that walks the user through the configuration settings
 function Set-Config{
    clear-host
    write-output "OnlyFans Metadata to Stash Database PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(1 of 3) Define the path to  your Stash Database file"
    write-output "`n    * Your Stash Database file is typically located in the installation folder`n      of your Stash inside of a folder named"$directorydelimiter"db"$directorydelimiter" with a filename of 'stash-go.sqlite'`n"
    
    if ($null -ne $PathToStashDatabase){
        #If the user is coming to this function with this variable set, we set it to null so that there is better user feedback if a bad filepath is provided by the user.
        $PathToStashDatabase = $null
    }
    do{
        #Providing some user feedback if we tested the path and it came back as invalid
        if($null -ne $PathToStashDatabase){
            write-output "Oops. Invalid filepath"
        }
        if($IsWindows){
            read-host "Press [Enter] to select your Stash Database File"

            #Using Windows File Explorer instead of forcing the user to copy/paste the path into the terminal
            Add-Type -AssemblyName System.Windows.Forms
            $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
                Filter = 'SQLite Database File (*.sqlite)|*.sqlite'
            }
            $null = $FileBrowser.ShowDialog()
            $PathToStashDatabase = $FileBrowser.filename
        }
        else{
            $PathToStashDatabase = read-host "Enter the location of your Stash Database File"
        }
    }
    while(!(test-path $PathToStashDatabase))
    clear-host
    write-output "OnlyFans Metadata to Stash Database PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(2 of 3) Define the path to your OnlyFans content`n"
    write-output "    * OnlyFans metadata database files are named 'user_data.db' and they are `n      located under <performername>"$directorydelimiter"metadata"$directorydelimiter
    write-output "    * You have the option of linking directly to the 'user_data.db' file, `n      or you can link to the top level OnlyFans folder of several metadata databases."
    write-output "    * When multiple database are detected, this script can help you select one (or even import them all in batch!)`n"
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
            write-output "Option 1: I want to point to a folder containing all my OnlyFans content and databases"
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
    write-output "OnlyFans Metadata to Stash Database PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(3 of 3) Define your Metadata Match Mode"
    write-output "    * When importing OnlyFans Metadata, some users may want to tailor how this script matches metadata to files"
    write-output "    * If you are an average user, just set this to 'Normal'"
    write-output "    * If you are a Docker user, I would avoid setting this mode to 'High'`n"
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
    write-output "OnlyFans Metadata to Stash Database PoSH Script" -ForegroundColor Cyan
    write-output "Configuration Setup Wizard"
    write-output "--------------------------`n"
    write-output "(3 of 3b) Review your settings`n"

    write-output "Path to Stash Database:`n - $PathToStashDatabase`n"
    write-output "Path to OnlyFans Content:`n - $PathToOnlyFansContent`n"
    write-output "Metadata Match Mode:`n - $SearchSpecificity`n"

    read-host "Press [Enter] to save this configuration"


    #Now to make our configuration file
    Out-File $PathToConfigFile
    Add-Content -path $PathToConfigFile -value "## Direct Path to Stash Database (stash-go.sqlite) ##"
    Add-Content -path $PathToConfigFile -value $PathToStashDatabase
    Add-Content -path $PathToConfigFile -value "## Direct Path to OnlyFans Metadata Database or top level folder containing OnlyFans content ##"
    Add-Content -path $PathToConfigFile -value $PathToOnlyFansContent
    Add-Content -path $PathToConfigFile -value "## Search Specificity mode. (Normal | High | Low) ##"
    Add-Content -path $PathToConfigFile -value $SearchSpecificity

    write-output "...Done!`nRun this script again to apply the new settings"
    exit
 }



### Main Script
#We need to know what deliminter to use based on OS. Writing it this way with a second if statement avoids an error from machines that are running Windows Powershell and not Powershell Core
if($IsWindows){
    $directorydelimiter = '\'
}
else{
    $directorydelimiter = '/'
}


$pathtoconfigfile = "."+$directorydelimiter+"OFMetadataToStash_Config"
if (!(Test-path $PathToConfigFile)){
    #Couldn't find a config file? Send the user to recreate their config file with the set-config function
    Set-Config
}

## Global Variables ##
$PathToStashDatabase = (Get-Content $pathtoconfigfile)[1]
$PathToOnlyFansContent = (Get-Content $pathtoconfigfile)[3]
$SearchSpecificity = (Get-Content $pathtoconfigfile)[5]
$PathToMissingFilesLog = "."+$directorydelimiter+"OFMetadataToStash_MissingFiles.txt"
$PathToStashExampleDB = "$directorydelimeter"+"utilities"+"$directorydelimiter"+"stash_example_db.sqlite" #We use this database for schema comparison
if (!(test-path $PathToStashExampleDB)){
    write-output "Error: Could not find '$PathToStashExampleDB'. Please redownload this script from Github." -ForegroundColor red
    read-host "Press [Enter] to exit"
    exit
}

clear-host
write-output "OnlyFans Metadata to Stash Database PoSH Script" -ForegroundColor Cyan

if (!(test-path $PathToStashDatabase)){
    read-host "Hmm...The defined path to your Stash Database file (Stash-go.sqlite) does not seem to exist at the location in your config file`n($PathToStashDatabase)`n`nPress [Enter] to run through the config wizard"
    Set-Config
}

#If the Stash Database path checks out, let's confirm that the schema in the database aligns with what this script is written for. 
else{
    $Query = "SELECT version FROM schema_migrations"
    $KnownSchemaVersion = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashExampleDB
    $KnownSchemaVersion = $KnownSchemaVersion.version

    $Query = "SELECT version FROM schema_migrations"
    $StashDB_SchemaVersion = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
    $StashDB_SchemaVersion = $StashDB_SchemaVersion.version
    
    if (($StashDB_SchemaVersion -ne $KnownSchemaVersion) -or ($StashDB_SchemaVersion -notmatch '^\d+$')){
        if($StashDB_SchemaVersion -gt $KnownSchemaVersion){
            write-output "`nYour Stash database has a newer database schema than expected!"
            write-output "(Expected version $KnownSchemaVersion, your Stash database is running Stash schema version $StashDB_SchemaVersion)"
            write-output "Checking for incompatibility...`n"
            
            #Get all tables from the new database
            $Query = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%'"
            $Stash_Tables = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

            #If any crucially important tables are modified lets track that with this bool
            $IncompatibleDB = $false

            foreach ($Stash_Table in $Stash_Tables){
                $Stash_Table_Name = $Stash_Table.name
                
                #Check to see if this table exists in the Stash Example database
                $Query = "SELECT name FROM sqlite_master WHERE type ='table' AND name NOT LIKE 'sqlite_%' AND name = '"+$Stash_Table_Name+"'"
                $TableExistance = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashExampleDB

                #If the table exists in the Stash Example database, let's check each column and ensure we have matches
                if ($null -ne $TableExistance){
                    
                    #These two queries returns all columns from a given table name. We grab all columns from both the user provided Stash db and the stash example db for comparison purposes
                    $Query = "PRAGMA table_info($Stash_Table_Name)"
                    $NewerColumns = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                    $Query = "PRAGMA table_info($Stash_Table_Name)"
                    $OlderColumns = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashExampleDB

                    #We also want to track the tables that do not get modified
                    $TableWasModified = $false
                    
                    #Now we iterate through the columns of the user provided Stash DB and see if there's any columns that cannot be found in this table.
                    foreach($column in $NewerColumns.name) {
                        if ($olderColumns.name -notcontains $column) {

                            #Flip the bool so that we know that this table has been modified
                            $TableWasModified = $true
                        }
                    } 
                    #Now we check to see if there are columns in the Stash Example DB that no longer exist in the new table
                    foreach($column in $OlderColumns.name) {
                        if ($newerColumns.name -notcontains $column) {
                            
                            #Flip the bool so that we know that this table has been modified
                            $TableWasModified = $true
                        }
                    } 
                    #This is basically a list of all the tables we actually use in this script. If there's anything flagged, we need to tell the user
                    if ($TableWasModified -eq $true){
                        switch($Stash_Table_Name){
                            "scenes" {$IncompatibleDB = $True;write-output "- Hmm...The 'Scenes' table has been modified in this new db schema"}
                            "images"{$IncompatibleDB = $True;write-output "- Hmm...The 'Images' table has been modified in this new db schema"}
                            "performers"{$IncompatibleDB = $True;write-output "- Hmm...The 'Performers' table has been modified in this new db schema"}
                            "performer_aliases"{$IncompatibleDB = $True;write-output "- Hmm...The 'Performer_Aliases' table has been modified in this new db schema"}
                            "studios" {$IncompatibleDB = $True;write-output "- Hmm...The 'Studios' table has been modified in this new db schema"}
                            "folders" {$IncompatibleDB = $True;write-output "- Hmm...The 'Folders' table has been modified in this new db schema"}
                            "files" {$IncompatibleDB = $True;write-output "- Hmm...The 'Files' table has been modified in this new db schema"}
                            "performers_scenes"{$IncompatibleDB = $True;write-output "- Hmm...The 'performers_scenes' table has been modified in this new db schema"}
                            "performers_images"{$IncompatibleDB = $True;write-output "- Hmm...The 'performers_images' table has been modified in this new db schema"}
                        }
                    }
                }
            }

            
            if($IncompatibleDB -eq $true){
                
                write-output "`nFor the reason(s) mentioned above, your Stash database may be incompatible with this script" -ForegroundColor red
                write-output "Running this script may change your database in unexpected, untested ways. "

                write-output "`n1 - Press [Enter] to exit."
                write-output "2 - You may override this warning by entering the phrase 'Never tell me the odds!', then pressing [Enter]"

                $userinput = read-host "`nWhat would you like to do?"
                if($userinput -notmatch "Never tell me the odds!"){
                    write-output "Exiting..."
                    exit
                }
                #User wants to continue, so lets clear the host and make it look like we're starting fresh
                clear-host
                write-output "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
            }
            else{
                write-output "`nNo incompatibilites detected!" -ForegroundColor green
                write-output "While no incompatibilities were detected, please look for an`nupdated version of this script just to be safe."
                read-host "`nPress [Enter] to continue"
            }
        }
        elseif ($StashDB_SchemaVersion -lt $KnownSchemaVersion) {
            write-output "Your Stash database is unfortunately a bit outdated!" -ForegroundColor red
            write-output "Please upgrade your Stash instance to the latest version, then re-run this script."

            write-output "`n1 - Press [Enter] to exit."
            write-output "2 - You may override this warning by entering the phrase 'Never tell me the odds!', then pressing [Enter]"
            

            $userinput = read-host "`nWhat would you like to do?"
            if($userinput -notmatch "Never tell me the odds!"){
             write-output "Exiting..."
                exit
            }
            #User wants to continue, so lets clear the host and make it look like we're starting fresh
            clear-host
            write-output "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
        }
        else {
            write-output "Hmm... this Stash database is not of a schema that this script was expecting. " -ForegroundColor red
            read-host "Press [Enter] to exit"
            exit
        }
    }
}


if (!(test-path $PathToOnlyFansContent)){
    #Couldn't find the path? Send the user to recreate their config file with the set-config function
    read-host "Hmm...The defined path to your OnlyFans content does not seem to exist at the location specified in your config file.`n($PathToOnlyFansContent)`n`nPress [Enter] to run through the config wizard"
    Set-Config
}


if(($SearchSpecificity -notmatch '\blow\b|\bnormal\b|\bhigh\b')){
    #Something goofy with the variable? Send the user to recreate their config file with the set-config function
    read-host "Hmm...The Metadata Match Mode parameter isn't well defined in your configuration file.`n`nPress [Enter] to run through the config wizard"
    Set-Config
}
else {
    write-output "By JuiceBox`n`n----------------------------------------------------`n"
    write-output "* Metadata Match Mode:        $searchspecificity`n* Path to OnlyFans Media:     $PathToOnlyFansContent`n* Path to Stash's db:         $PathToStashDatabase`n"
    write-output "----------------------------------------------------`n"
    write-output "What would you like to do?"
    write-output " 1 - Add Metadata to my Stash using OnlyFans Metadata Database(s)"
    write-output " 2 - Add Metadata to my Stash without using OnlyFans Metadata Database(s)"
    write-output " 3 - Generate a redacted, sanitized copy of my OnlyFans Metadata Database file(s)"
    write-output " 4 - Change Settings"

    $userscanselection = 0;
    do {
        $userscanselection = read-host "`nEnter selection"
    }
    while (($userscanselection -notmatch "[1-4]"))



    #Code for parsing metadata files
    if($userscanselection -eq 1){

        #Since we're editing the Stash database directly, playing it safe and asking the user to back up their database
        $backupConfirmation = Read-Host "`nWould you like to make a backup of your Stash Database? [Y/N] (Default is Y)"
        if (($backupConfirmation -eq 'n') -or ($backupConfirmation -eq 'no')) {
            write-output "OK, no backup will be created." 
        }
        else{
            $PathToStashDatabaseBackup = Split-Path $PathToStashDatabase
            $PathToStashDatabaseBackup = $PathToStashDatabaseBackup+"\stash-go_OnlyFans_Import_BACKUP-"+$(get-date -f yyyy-MM-dd)+".sqlite"
            read-host "OK, A backup will be created at`n $PathToStashDatabaseBackup`n`nPress [Enter] to generate backup"

            try {
                Copy-Item $PathToStashDatabase -Destination $PathToStashDatabaseBackup
            }
            catch {
                read-host "Unable to make a backup! Permissions error? Press [Enter] to exit"
                exit
            }
            write-output "...Done! A backup was successfully created."
        }

        write-output "`nScanning for existing OnlyFans Metadata Database files..."

        #Finding all of our metadata databases. 
        $collectionOfDatabaseFiles = Get-ChildItem -Path $PathToOnlyFansContent -Recurse | where-object {$_.name -in "user_data.db","posts.db"}
        
        #For the discovery of a single database file
        if ($collectionOfDatabaseFiles.count -eq 1){

            #More modern OF DB schemas include the name of the performer in the profile table. If this table does not exist we will have to derive the performer name from the filepath, assuming the db is in a /metadata/ folder.
            $Query = "PRAGMA table_info(medias)"
            $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $collectionOfDatabaseFiles[0].FullName
            #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
            $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 

            $performername = $null
            if ($OFDBColumnsToCheck -match "profiles"){
                $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                $performername =  Invoke-SqliteQuery -Query $Query -DataSource $collectionOfDatabaseFiles[0].FullName
            }

            #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
            if ($null -eq $performername){
                $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path | split-path -leaf
                }
            }
            write-output "Discovered a metadata database for '$performername' "
        }

        #For the discovery of multiple database files
        elseif ($collectionOfDatabaseFiles.count -gt 1){
            
            write-output "Discovered multiple metadata databases"
            write-output "0 - Process metadata for all performers"

            $i=1 # just used cosmetically
            Foreach ($OFDBdatabase in $collectionOfDatabaseFiles){

                #Getting the performer name from the profiles table (if it exists)
                $Query = "PRAGMA table_info(medias)"
                $OFDBColumnsToCheck = Invoke-SqliteQuery -Query $Query -DataSource $OFDBdatabase.FullName

                #There's probably a faster way to do this, but I'm throwing the collection into a string, with each column result (aka table name) seperated by a space. 
                $OFDBColumnsToCheck = [string]::Join(' ',$OFDBColumnsToCheck.name) 
                $performername = $null
                if ($OFDBColumnsToCheck -match "profiles"){
                    $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                    $performername =  Invoke-SqliteQuery -Query $Query -DataSource $collectionOfDatabaseFiles[0].FullName
                }

                #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
                if ($null -eq $performername){
                    $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path -leaf
                    if ($performername -eq "metadata"){
                        $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path | split-path -leaf
                    }
                }
              
                write-output "$i - $performername"
                $i++

            }
            $selectednumber = read-host "`nWhich performer would you like to select [Enter a number]"

            #Checking for bad input
            while ($selectednumber -notmatch "^[\d\.]+$" -or ([int]$selectednumber -gt $collectionOfDatabaseFiles.Count)){
                $selectednumber = read-host "Invalid Input. Please select a number between 0 and" $collectionOfDatabaseFiles.Count".`nWhich performer would you like to select [Enter a number]"
            }

            #If the user wants to process all performers, let's let them.
            if ([int]$selectednumber -eq 0){
                write-output "OK, all performers will be processed."
            }
            else{
                $selectednumber = $selectednumber-1 #Since we are dealing with a 0 based array, i'm realigning the user selection
                $performername = $collectionOfDatabaseFiles[$selectednumber].FullName | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $collectionOfDatabaseFiles[$selectednumber].FullName | split-path | split-path | split-path -leaf #Basically if we hit the metadata folder, go a folder higher and call it the performer
                }
                
                #Specifically selecting the performer the user wants to parse.
                $collectionOfDatabaseFiles = $collectionOfDatabaseFiles[$selectednumber]

                write-output "OK, the performer '$performername' will be processed."
            }
        }

        #Only try to parse metadata from metadata database files if we've discovered a database file.
        if ($collectionOfDatabaseFiles){

            write-output "`nQuick Tips: `n   * Be sure to run a Scan task in Stash of your OnlyFans content before running this script!`n   * Be sure your various metadata database(s) are located either at`n     <performername>"$directorydelimiter"user_data.db or at <performername>"$directorydelimiter"metadata"$directorydelimiter"user_data.db"
            read-host "`nPress [Enter] to begin"

            $numModified = 0
            $numUnmodified = 0
            $nummissingfiles = 0
            $scriptStartTime = get-date

            #Getting the OnlyFans Studio ID or creating it if it does not exist.
            $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
            $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

            #If the Studio does not exist, create it
            if(!$StashDB_StudioQueryResult){

                #Creating a studio also requires a updated_at/created_at timestamp
                $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

                #The MD5 hash of the studio name "OnlyFans" is a known string. I've skipped out on generating this value
                $Query = "INSERT INTO studios (name, url, checksum, created_at, updated_at) VALUES ('OnlyFans','https://www.onlyfans.com','13954e64886e8317d2df22fec295e924', '"+$timestamp+"', '"+$timestamp+"')"
                $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                write-output "`n### INFO ###`nAdded the OnlyFans studio to Stash's database" -ForegroundColor Cyan

                $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
                $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                $OnlyFansStudioID = $StashDB_StudioQueryResult.id
            }
            #Otherwise, the studio ID can be attained from the SELECT query
            else {
                $OnlyFansStudioID = $StashDB_StudioQueryResult.id
            }
            
            foreach ($currentdatabase in $collectionOfDatabaseFiles) {
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
                    write-output "Error: The following OnlyFans metadata database doesn't contain the metadata in a format that this script expects." -ForegroundColor Red
                    write-output "This can occur if you've scraped OnlyFans using an unsupported tool. " -ForegroundColor Red
                    write-output $collectionOfDatabaseFiles[0].FullName
                    read-host "Press [Enter] to continue"
                    
                }
                else{
                    #More modern OF DB schemas include the name of the performer in the profile table. If this table does not exist we will have to derive the performer name from the filepath, assuming the db is in a /metadata/ folder.
                    $performername = $null
                    if ($OFDBColumnsToCheck -match "profiles"){
                        $Query = "SELECT username FROM profiles LIMIT 1" #I'm throwing that limit on as a precaution-- I'm not sure if multiple usernames will ever be stored in that SQL table
                        $performername =  Invoke-SqliteQuery -Query $Query -DataSource $collectionOfDatabaseFiles[0].FullName
                    }

                    #Either the query resulted in null or the profiles table didnt exist, so either way let's use the alternative directory based method.
                    if ($null -eq $performername){
                        $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path -leaf
                        if ($performername -eq "metadata"){
                            $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path | split-path -leaf
                        }
                    }
                    write-output "`nParsing media for $performername" -ForegroundColor Cyan
                    
                    #Conditional tree for finding the performer ID using either the name or the alias (or creating the performer if neither option work out)
                    $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                    if($StashDB_PerformerQueryResult){
                        $PerformerID = $StashDB_PerformerQueryResult.id
                    }
                    else{
                        #No luck using the name to track down the performer ID, let's try the alias
                        $Query = "SELECT performer_id FROM performer_aliases WHERE alias LIKE '%"+$performername+"%'"
                        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                        
                        if($StashDB_PerformerQueryResult){
                            $PerformerID = $StashDB_PerformerQueryResult.id
                        }
                        #Otherwise both options failed so let's create the performer
                        else{   
                            #Creating a performer also requires a updated_at/created_at timestamp
                            $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

                            #Creating the performer in Stash's db
                            $Query = "INSERT INTO performers (name, url, created_at, updated_at) VALUES ('"+$performername+"', 'https://www.onlyfans.com/"+$performername+"', '"+$timestamp+"', '"+$timestamp+"')"
                            Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                            write-output "`n### INFO ###`nAdded a new Performer ($performername) to Stash's database`n" -ForegroundColor Cyan

                            $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                            $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                            $PerformerID = $StashDB_PerformerQueryResult.id
                        }       
                    }
                        
                    #Select all the media (except audio) and the text the performer associated to them, if available from the OFDB
                    $Query = "SELECT messages.text, medias.directory, medias.filename, medias.size, medias.created_at, medias.post_id, medias.media_type FROM medias INNER JOIN messages ON messages.post_id=medias.post_id UNION SELECT posts.text, medias.directory, medias.filename, medias.size, medias.created_at, medias.post_id, medias.media_type FROM medias INNER JOIN posts ON posts.post_id=medias.post_id WHERE medias.media_type <> 'Audios'"
                    $OF_DBpath = $currentdatabase.fullname 
                    $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $OF_DBpath
                    foreach ($OFDBMedia in $OFDBQueryResult){

                        #Generating the URL for this post
                        $linktoperformerpage = "https://www.onlyfans.com/"+$OFDBMedia.post_ID+"/"+$performername
                        
                        #Reformatting the date to something stash appropriate
                        $creationdatefromOF = $OFDBMedia.created_at
                        $creationdatefromOF = Get-Date $creationdatefromOF -format "yyyy-MM-dd"
                        
                        $OFDBfilesize = $OFDBMedia.size #filesize (in bytes) of the media, from the OF DB
                        $OFDBfilename = $OFDBMedia.filename #This defines filename of the media, from the OF DB
                        $OFDBdirectory = $OFDBMedia.directory #This defines the file directory of the media, from the OF DB
                        $OFDBFullFilePath = $OFDBdirectory+$directorydelimiter+$OFDBfilename #defines the full file path, using the OS appropriate delimeter

                        #Storing separate variants of these variables with apostrophy sanitization so they don't ruin our SQL queries
                        $OFDBfilenameForQuery = $OFDBfilename.replace("'","''") 
                        $OFDBdirectoryForQuery = $OFDBdirectory.replace("'","''") 
            

                        #Note that the OF downloader quantifies gifs as videos for some reason
                        #Since Stash doesn't (and rightfully so), we need to account for this
                        if(($OFDBMedia.media_type -eq "videos") -and ($OFDBfilename -notlike "*.gif")){
                            $mediatype = "video"
                        }
                        #Condition for images. Again, we have to add an extra condition just in case the image is a gif due to the DG database
                        elseif(($OFDBMedia.media_type -eq "images") -or ($OFDBfilename -like "*.gif")){
                            $mediatype = "image"
                        }


                        #Depending on user preference, we want to be more/less specific with our SQL queries to the Stash DB here, as determined by this condition tree (defined in order of percieved popularity)
                        #Normal specificity, search for videos based on having the performer name somewhere in the path and a matching filesize
                        if ($mediatype -eq "video" -and $searchspecificity -match "normal"){
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path LIKE '%"+$performername+"%'  AND size ="+$OFDBfilesize
                        }

                        #Normal specificity, search for images based on having the performer name somewhere in the path and a matching filesize
                        elseif ($mediatype -eq "image" -and $searchspecificity -match "normal"){
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size ="+$OFDBfilesize+" AND path LIKE'%"+$performername+"%'"
                        }
                        #Low specificity, search for videos based on filesize only
                        elseif ($mediatype -eq "video" -and $searchspecificity -match "low"){
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE size ="+$OFDBfilesize
                        }

                        #Low specificity, search for images based on filesize only
                        elseif ($mediatype -eq "image" -and $searchspecificity -match "low"){
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size ="+$OFDBfilesize
                        }

                        #High specificity, search for videos based on matching file path between OnlyFans DB and Stash DB as well as matching the filesize. 
                        elseif ($mediatype -eq "video" -and $searchspecificity -match "high"){
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path='"+$OFDBdirectoryForQuery+"' AND files.basename ='"+$OFDBfilenameForQuery+"' AND files.size ="+$OFDBfilesize
                        }

                        #High specificity, search for images based on matching file path between OnlyFans DB and Stash DB as well as matching the filesize. 
                        else{
                            $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size ="+$OFDBfilesize+" AND path ='"+$OFDBdirectoryForQuery+"' AND files.basename ='$OFDBfilenameForQuery'"
                        }
                        
                        $StashDB_QueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
            
                        #If our search for a matching media in the Stash DB is empty let's check to see if the file exists on the file system 
                        if ($null -eq $StashDB_QueryResult){
                            if (Test-Path $OFDBFullFilePath){
                                write-output "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database but the file IS on your filesystem.`nTry running a Scan Task in Stash then re-running this script.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                            }
                            #In this case, the media isn't in Stash or on the filesystem so inform the user, log the file, and move on
                            else{
                                write-output "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the OnlyFans script and redownloading the file.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                                Add-Content -Path $PathToMissingFilesLog -value " $OFDBFullFilePath"
                                $nummissingfiles++
                            }
                        }

                        #Otherwise we have found a match! let's process each matching result and add the metadata we've found
                        else{

                            #Before processing, and for the sake of accuracy, if there are multiple filesize matches (aka modes low and normal), add a filename check to the query to see if we can match more specifically. If not, just use whatever matched that initial query.
                            if ($StashDB_QueryResult.length -gt 0){
                                #Normal specificity, search for videos based on having the performer name somewhere in the path and a matching filesize (and filename in this instance)
                                if ($mediatype -eq "video" -and $searchspecificity -match "normal"){
                                    $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path LIKE '%"+$performername+"%' AND files.basename ='"+$OFDBfilenameForQuery+"' AND files.size ="+$OFDBfilesize
                                }

                                #Normal specificity, search for images based on having the performer name somewhere in the path and a matching filesize (and filename in this instance)
                                elseif ($mediatype -eq "image" -and $searchspecificity -match "normal"){
                                    $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size ="+$OFDBfilesize+" AND path LIKE'%"+$performername+"%' AND files.basename ='"+$OFDBfilenameForQuery+"' AND files.size ="+$OFDBfilesize 
                                }
                                #Low specificity, search for videos based on filesize only (and filename in this instance)
                                elseif ($mediatype -eq "video" -and $searchspecificity -match "low"){
                                    $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE AND files.basename ='"+$OFDBfilenameForQuery+"' AND files.size ="+$OFDBfilesize
                                }

                                #Low specificity, search for images based on filesize only (and filename in this instance)
                                elseif ($mediatype -eq "image" -and $searchspecificity -match "low"){
                                    $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE AND files.basename ='"+$OFDBfilenameForQuery+"' AND files.size ="+$OFDBfilesize
                                }

                                $ExtendedStashDB_QueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

                                #If we have a match, substitute it in and lets get that metadata into the Stash DB
                                if($ExtendedStashDB_QueryResult){
                                    $StashDB_QueryResult = $ExtendedStashDB_QueryResult
                                } 
                            }
                        
                            #Creating the title we want for the media
                            $proposedtitle = "$performername - $creationdatefromOF"
                            
                            #Sanitizing the text for apostrophes so they don't ruin our SQL query
                            $detailsToAddToStash = $OFDBMedia.text
                            $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                            $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                            #Let's check to see if this is a file that already has metadata.
                            #For Videos, we check the title and the details
                            #For Images, we only check title (for now)
                            #If any metadata is missing, we don't bother with updating a specific column, we just update the entire row

                            if ($mediatype -eq "video"){
                                $filewasmodified = $false

                                #Updating scene metadata if necessary
                                if (($StashDB_QueryResult.scenes_title -ne $proposedtitle) -or ($StashDB_QueryResult.scenes_details -ne $OFDBMedia.text)){
                                    $Query = "UPDATE scenes SET title='"+$proposedtitle+"', details='"+$detailsToAddToStash+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"', studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$StashDB_QueryResult.scenes_id+"'"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }
                                
                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_scenes WHERE performer_id ="+$PerformerID+" AND scene_id ="+$StashDB_QueryResult.scenes_id
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerid+","+$StashDB_QueryResult.scenes_id+")"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Providing user feedback and adding to the modified counter if necessary
                                if ($filewasmodified){
                                    write-output "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                    $numModified++  
                                }
                                else{
                                    write-output "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                    $numUnmodified++
                                }

                                
                            }
                            else{ #For images
                                $filewasmodified = $false

                                #Updating image metadata if necessary
                                if (($StashDB_QueryResult.images_title -ne $proposedtitle)){
                                    $Query = "UPDATE images SET title='"+$proposedtitle+"', updated_at='"+$modtime+"', studio_id='"+$OnlyFansStudioID+"', url='"+$linktoperformerpage+"', date='"+$creationdatefromOF+"', WHERE id='"+$StashDB_QueryResult.images_id+"'"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_images WHERE performer_id ="+$PerformerID+" AND image_id ="+$StashDB_QueryResult.images_id
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_images (performer_id, image_id) VALUES ("+$performerid+","+$StashDB_QueryResult.images_id+")"
                                    
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Providing user feedback and adding to the modified counter if necessary
                                if ($filewasmodified){
                                    write-output "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                    $numModified++  
                                }
                                else{
                                    write-output "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                    $numUnmodified++
                                }
                            }
                        } 
                    }   
                }
            }
        }
        if ($nummissingfiles -gt 0){
            write-output "`n- Missing Files -" -ForegroundColor Cyan
            write-output "There is available metadata for $nummissingfiles files in your OnlyFans Database that cannot be found in your Stash Database."
            write-output "    - Be sure to review the MissingFiles log."
            write-output "    - There's a good chance you may need to rescan your OnlyFans folder in Stash and/or redownload those files"
        }

        write-output "`n****** Import Complete ******"-ForegroundColor Cyan
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
    }
   

###Code for the "No Metadata Database" feature
    elseif($userscanselection -eq 2){
        write-output "`n- Overview - " -ForegroundColor Cyan
        write-output "    - This script will try and determine performer names for discovered files based on file path."
        write-output "    - Files that already have metadata in Stash will be ignored."
        write-output "    - You can point this script at your top level 'OnlyFans' folder containing several performers."
        write-output "      That said, please be extra sure to NOT scan folders that do not contain OnlyFans content. "
        write-output "`n- Choose a Scan Mode - " -ForegroundColor Cyan
        write-output "1 - I am hosting Stash on this computer. [Default]"
        write-output "2 - I am hosting Stash remotely on a different computer/using Docker"

        $UserIsUsingRemoteStashSelection = 0;
        do {
            $UserIsUsingRemoteStashSelection = read-host "`nEnter selection"
        }
        while (($UserIsUsingRemoteStashSelection -notmatch "[1-2]"))

        if($UserIsUsingRemoteStashSelection -eq 2){
            write-output "`n- Additional Note - " -ForegroundColor Cyan
            write-output "     - As you are hosting Stash elsewhere, this script will match based on filename rather than a file's full filepath"
            write-output "       Please ensure your filenames are unique. (Ex. 0ergergfdser_source.mp4)"
        }

        #Since we're editing the Stash database directly, playing it safe and asking the user to back up their database
        $backupConfirmation = Read-Host "`nWould you like to make a backup of your Stash Database? [Y/N] (Default is Y)"
        if (($backupConfirmation -eq 'n') -or ($backupConfirmation -eq 'no')) {
            write-output "OK, no backup will be created." 
        }
        else{
            $PathToStashDatabaseBackup = Split-Path $PathToStashDatabase
            $PathToStashDatabaseBackup = $PathToStashDatabaseBackup+"\stash-go_OnlyFans_Import_BACKUP-"+$(get-date -f yyyy-MM-dd)+".sqlite"
            read-host "OK, A backup will be created at`n $PathToStashDatabaseBackup`n`nPress [Enter] to generate backup"

            try {
                Copy-Item $PathToStashDatabase -Destination $PathToStashDatabaseBackup
            }
            catch {
                read-host "Unable to make a backup! Permissions error? Press [Enter] to exit"
                exit
            }
            write-output "...Done! A backup was successfully created."
        }

        write-output "`nThe following path will be parsed:`n - $PathToOnlyFansContent"
        read-host "`nPress [Enter] to begin"

        #A buffer for Performer Name and Performer ID to minimize how often we reach out to the DB. 
        $performerbuffer = @('performername',0)
        
        #Because of how fast this script runs, we need a buffer to limit how often we write out to the DB to avoid db write issues
        #We use a counter to keep track of when the buffer is full
        $QueryBuffer = [Object[]]::new(20)
        $QueryBufferCounter = 0

        #Grabbing the date so we can show elapsed time later
        $scriptStartTime = get-date

        $numModified = 0
        $numUnmodified = 0

       #Getting the OnlyFans Studio ID or creating it if it does not exist.
       $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
       $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

       #If the Studio does not exist, create it
       if(!$StashDB_StudioQueryResult){

           #Creating a studio also requires a updated_at/created_at timestamp
           $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

           #The MD5 hash of the studio name "OnlyFans" is a known string. I've skipped out on generating this value
           $Query = "INSERT INTO studios (name, url, checksum, created_at, updated_at) VALUES ('OnlyFans','https://www.onlyfans.com','13954e64886e8317d2df22fec295e924', '"+$timestamp+"', '"+$timestamp+"')"
           $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
           write-output "`n### INFO ###`nAdded the OnlyFans studio to Stash's database" -ForegroundColor Cyan

           $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
           $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

           $OnlyFansStudioID = $StashDB_StudioQueryResult.id
       }
       #Otherwise, the studio ID can be attained from the SELECT query
       else {
           $OnlyFansStudioID = $StashDB_StudioQueryResult.id
       }

        $OFfilestoscan = get-childitem $pathToOnlyFansContent -file -recurse -exclude *.db 

        #Iterate through all the files we found
        for($i=0; $i -lt $OFfilestoscan.count; $i++){
            $OFFile = $OFfilestoscan[$i]

            #When we run SQL queries later, we will need the folder path and the filename split out.
            $OFmediaParentFolder = split-path $OFFile
            $OFmediaFilename = split-path $OFFile -leaf

            $mediatype = $null
            #We need to determine if we're working with an image or not
            switch ($OFFile.extension){
                '.png'{$mediatype = "image"}
                '.jpg'{$mediatype = "image"}
                '.jpeg'{$mediatype = "image"}
                '.gif'{$mediatype = "image"}
                '.webp'{$mediatype = "image"}
                '.jfif'{$mediatype = "image"}
                default {$mediatype = "video"} #When Stash finally supports audio, this binary video/image stuff will need to change.
            }
            
            #A bit hacky, but this lets us check to see whether or not our file path uses / or \ based on operating system
            #Writing it this way with a second if statement avoids an error from machines that are running Windows Powershell and not Powershell Core
            if($PSVersionTable.properties.name -match "os"){
                if(!($PSVersionTable.os -like "*Windows*")){
                    $patharray = $OFFile.tostring().Split("/")
                }
            }
            else{
                $patharray = $OFFile.tostring().Split("\")
            }


            #So the way this works is basically that we have a known list of what the filepaths for onlyfans content should look like. 
            #Therefore we can work backwards from the file itself, iterating through the path until we find something unexpected.
            #That unexpected folder name will be our performer name.
            $patharrayposition = $patharray.count-1
            $foundperformer = $false

            switch($patharray[$patharrayposition-1]){
                "videos"{$patharrayposition--}
                "images" {$patharrayposition--}
                "avatars" {$patharrayposition--}
                "headers" {$patharrayposition--}
                default {$performername = $patharray[$patharrayposition-1]; $foundperformer = $true}
            }

            if(!$foundperformer){
                switch($patharray[$patharrayposition-1]){
                    "paid"{$patharrayposition--}
                    "free" {$patharrayposition--}
                    "profile" {$patharrayposition--}
                    default {$performername = $patharray[$patharrayposition-1]; $foundperformer = $true}
                }
            }

            if(!$foundperformer){
                switch($patharray[$patharrayposition-1]){
                    "posts"{$patharrayposition--}
                    "messages" {$patharrayposition--}
                    "stories" {$patharrayposition--}
                    default {$performername = $patharray[$patharrayposition-1]; $foundperformer = $true}
                }
            }
            if(!$foundperformer){
                switch($patharray[$patharrayposition-1]){
                    "archived"{$patharrayposition--}
                    default {$performername = $patharray[$patharrayposition-1]}
                }
            }
            if(!$foundperformer){
                $performername = $patharray[$patharrayposition-1] 
            }

            #Looking in the stash DB for the current filename we're parsing (first two conditions are for local stash, second two are for remote stash)
            if(($mediatype -eq "image") -and ($UserIsUsingRemoteStashSelection -eq 1)){
                $Query = "SELECT folders.path, files.basename, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title, images.studio_id FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE path ='"+$OFmediaParentFolder+"' AND files.basename ='"+$OFmediaFilename+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.images_id
            }
            elseif(($mediatype -eq "video") -and ($UserIsUsingRemoteStashSelection -eq 1)){ 
                $Query = "SELECT folders.path, files.basename, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.studio_id FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path='"+$OFmediaParentFolder+"' AND files.basename ='"+$OFmediaFilename+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.scenes_id
            }
            if(($mediatype -eq "image") -and ($UserIsUsingRemoteStashSelection -eq 2)){
                $Query = "SELECT folders.path, files.basename, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title, images.studio_id FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE files.basename ='"+$OFmediaFilename+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.images_id
            }
            else{
                $Query = "SELECT folders.path, files.basename, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.studio_id FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE files.basename ='"+$OFmediaFilename+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.scenes_id
            }
            

            #If Stash has this file, we can work with it.
            if ($StashDBSceneQueryResult){

                #If we don't have the performer information in the buffer, look for it or create the performer
                if ($performerbuffer[0] -ne $performername){
                    $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                    #If the performer doesn't exist, try looking at aliases
                    if(!$StashDB_PerformerQueryResult){
                        $Query = "SELECT performer_id FROM performer_aliases WHERE alias LIKE '%"+$performername+"%'"
                        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                        
                        #This performer definitely does not exist so create one
                        if(!$StashDB_PerformerQueryResult){

                            #Creating a performer also requires a updated_at/created_at timestamp
                            $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

                            #Creating the performer in Stash's db
                            $Query = "INSERT INTO performers (name, url, created_at, updated_at) VALUES ('"+$performername+"', 'https://www.onlyfans.com/"+$performername+"', '"+$timestamp+"', '"+$timestamp+"');"
                            Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                            write-output "`n### INFO ###`nAdded a new Performer ($performername) to Stash's database`n" -ForegroundColor Cyan
                        }
                        #Running a select statement now that our insert is complete so that we can get the performer ID
                        $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                    }
                        $performerbuffer[0] = $performername
                        $performerbuffer[1] = $StashDB_PerformerQueryResult.id
                }
                
                #Checking to see if we have a related performer for this media
                if($mediatype -eq "image"){
                    $Query = "SELECT * FROM performers_images WHERE performer_id = "+$performerbuffer[1]+" AND image_id = $mediaid"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                }
                else {
                    $Query = "SELECT * FROM performers_scenes WHERE performer_id = "+$performerbuffer[1]+" AND scene_id = $mediaid"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                }

                #If this media doesn't have a related performer, let's go ahead and add one
                if(!$StashDB_PerformerQueryResult){
                    if($mediatype -eq "image"){
                        $QueryBuffer[$QueryBufferCounter] = "INSERT INTO performers_images (performer_id, image_id) VALUES ("+$performerbuffer[1]+","+$mediaid+");"
                        $QueryBufferCounter++
                    }
                    else{
                        $QueryBuffer[$QueryBufferCounter] = "INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerbuffer[1]+","+$mediaid+");"
                        $QueryBufferCounter++
                    }
                    write-output "- Added metadata to Stash's database for the following file:`n   $OFFile" 
                    $numModified++
                }
                else {
                    write-output "- This file already has metadata, moving on...`n   $OFFile"
                    $numUnmodified++
                }
                
                #If this media doesn't have a related studio, let's go ahead and add one.
                if($StashDBSceneQueryResult.studioID -ne $OnlyFansStudioID){
                    if($mediatype -eq "image"){
                        $QueryBuffer[$QueryBufferCounter] = "UPDATE images SET studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$mediaid+"';"
                        $QueryBufferCounter++
                    }
                    else{
                        $QueryBuffer[$QueryBufferCounter] = "UPDATE scenes SET studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$mediaid+"';"
                        $QueryBufferCounter++
                    }
                }
            }
            #If this is the last time we're going to iterate over this collection of discovered files OR if our buffer is full enough
            #Please note the number of potential queries that can execute with each loop and subtract that number from the maximum size of the array to get the number to set in order to trigger a buffer refresh. 
            #For example, two potential queries (an update and an insert) with a max array size of 20 would give you a reset trigger of 18
            if(($i -eq $OFfilestoscan.count) -or ($QueryBufferCounter -gt 18)){

                #Nested loop to look for duplicates in our Query buffer before we create the combined query that will go to Stash
                $QueryForStash = "" #Just making sure the variable is clear before creating the string
                For ($a=0; $a -le $QueryBuffer.count; $a++) {
                    $numduplicates = -1 #We set this to -1 because at least one match should be discovered (otherwise it wouldn't be an entry in the array)

                    For ($b=0; $b -le $QueryBuffer.count; $b++) {
                        if($QueryBuffer[$b] -eq $QueryBuffer[$a]){
                            $numduplicates++
                        }
                    }
                    #If there are no dupes of this query, let's add it to the larger query.
                    if($numduplicates -eq 0){
                        $QueryForStash = $QueryForStash + $QueryBuffer[$a]
                    }
                }

                #Run the query against the db, and flush the buffer
                Invoke-SqliteQuery -Query $QueryForStash -DataSource $PathToStashDatabase
                $QueryBuffer = [Object[]]::new(20)
                $QueryBufferCounter = 0
                
            }
        }

        if(($numModified -eq 0) -and ($numUnmodified -eq 0)){
            write-output "...Complete." -ForegroundColor Cyan
            write-output "This script has finished parsing the requested directory but no files were found in your Stash that match the files on your filesystem."
            write-output "Your Stash database was not modified."
            write-output "Try running this mode again, but with the 'Stash is hosted remotely' option!"
        }
        else {
            write-output "`n****** Import Complete ******"-ForegroundColor Cyan
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
        }
    }

    elseif($userscanselection -eq 3){
        $pathtosanitizerscript = "."+$directorydelimiter+"Utilities"+$directorydelimiter+"OFMetadataDatabase_Sanitizer.ps1"
        invoke-expression $pathtosanitizerscript
    }
    else{
        #User has requested to be sent to the configuration wizard
        Set-Config
    }
}