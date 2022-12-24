<#
---OnlyFans Metadata to Stash Database PoSH Script 0.4---

AUTHOR
    JuiceBox
URL 
    https://github.com/ALonelyJuicebox/OFMetadataToStash

DESCRIPTION
    Using the metadata database from DC's script, imports metadata such as the URL, post associated text, and creation date into your stash DB

REQUIREMENTS
    - Metadata database must be from DC's script
    - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
       Download a zip of the PSSQlite folder in that repo, extract it, run an Admin window of Powershell
       in that directory then run 'install-module pssqlite' followed by the command 'import-module pssqlite'
 #>

### Functions

#Set-Config is a wizard that walks the user through the configuration settings
 function Set-Config{
    clear-host
    write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
    write-host "Configuration Setup Wizard"
    write-host "--------------------------`n"
    write-host "(1 of 3) Define the path to your your Stash Database file"
    write-host "`n    * Your Stash Database file is typically located in the installation folder`n      of your Stash inside of a folder named"$directorydelimiter"db"$directorydelimiter" with a filename of 'stash-go.sqlite'`n"
    
    if ($null -ne $PathToStashDatabase){
        #If the user is coming to this function with this variable set, we set it to null so that there is better user feedback if a bad filepath is provided by the user.
        $PathToStashDatabase = $null
    }
    do{
        #Providing some user feedback if we tested the path and it came back as invalid
        if($null -ne $PathToStashDatabase){
            write-host "Oops. Invalid filepath"
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
    write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
    write-host "Configuration Setup Wizard"
    write-host "--------------------------`n"
    write-host "(2 of 3) Define the path to your OnlyFans content`n"
    write-host "    * OnlyFans metadata database files are named 'user_data.db' and they are `n      located under <performername>"$directorydelimiter"metadata"$directorydelimiter
    write-host "    * You have the option of linking directly to the 'user_data.db' file `n      or you can link to the top level OnlyFans folder of several metadata databases."
    write-host "    * When multiple database are detected, this script can help you select one (or even import them all in batch!)`n"
    if ($null -ne $PathToOnlyFansContent){
        #If the user is coming to this function with this variable set, we set it to null so that there is better user feedback if a bad filepath is provided by the user.
        $PathToOnlyFansContent = $null
    }
    do{
        #Providing some user feedback if we tested the path and it came back as invalid
        if($null -ne $PathToOnlyFansContent){
            write-host "Oops. Invalid filepath"
        }
        if($IsWindows){
            write-host "Option 1: I want to point to a folder containing all my OnlyFans content and databases"
            write-host "Option 2: I want to point to a single OnlyFans Metadata file (user_data.db)`n"

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
    write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
    write-host "Configuration Setup Wizard"
    write-host "--------------------------`n"
    write-host "(3 of 3) Define your Metadata Match Specificity mode"
    write-host "    * When importing OnlyFans Metadata, some users may want to tailor how this script matches metadata to files"
    write-host "    * If you are an average user, just set this to 'Normal'"
    write-host "    * If you are a Docker user, I would avoid setting this mode to 'High'`n"
    write-host "Option 1: Normal - Will match based on Filesize and the Performer name being somewhere in the file path"
    write-host "Option 2: Low    - Will match only based on a matching Filesize"
    write-host "Option 3: High   - Will match based on a matching path AND a matching filesize"


    $specificityselection = 0;
    do {
        $specificityselection = read-host "`nEnter selection"
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
    write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
    write-host "Configuration Setup Wizard"
    write-host "--------------------------`n"
    write-host "(3 of 3b) Review your settings`n"

    write-host "Path to Stash Database:`n - $PathToStashDatabase`n"
    write-host "Path to OnlyFans Content:`n - $PathToOnlyFansContent`n"
    write-host "Search Metadata Match Specificity Mode:`n - $SearchSpecificity`n"

    read-host "Press [Enter] to save this configuration"


    #Now to make our configuration file
    Out-File $PathToConfigFile
    Add-Content -path $PathToConfigFile -value "## Direct Path to Stash Database (stash-go.sqlite) ##"
    Add-Content -path $PathToConfigFile -value $PathToStashDatabase
    Add-Content -path $PathToConfigFile -value "## Direct Path to OnlyFans Metadata Database or top level folder containing OnlyFans content ##"
    Add-Content -path $PathToConfigFile -value $PathToOnlyFansContent
    Add-Content -path $PathToConfigFile -value "## Search Specificity mode. (Normal | High | Low) ##"
    Add-Content -path $PathToConfigFile -value $SearchSpecificity

    write-host "...Done!`nRun this script again to apply the new settings"
    exit
 }



### Main Script
#We need to know what deliminter to use based on OS. Writing it this way with a second if statement avoids an error from machines that are running Windows Powershell and not Powershell Core
if($IsWindows){
    $directorydelimiter = "\"
}
else{
    $directorydelimiter = "/"
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
$StashDB_SchemaVersion = 41 #Stash DB Schema version this script is designed for. Do NOT change this value unless you know what you are doing and have validated that all SQL queries in this script will work

clear-host
write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"

if (!(test-path $PathToStashDatabase)){
    read-host "Hmm...The defined path to your Stash Database file (Stash-go.sqlite) does not seem to exist at the location in your config file`n($PathToStashDatabase)`n`nPress [Enter] to run through the config wizard"
    Set-Config
}

#If the Stash Database path checks out, let's confirm that the schema in the database aligns with what this script is written for. 
else{
    $Query = "SELECT version FROM schema_migrations"
    $StashDB_QueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
    
    if (($StashDB_QueryResult.version -ne $StashDB_SchemaVersion) -or ($StashDB_QueryResult.version -notmatch '^\d+$')){
        if($StashDB_QueryResult.version -gt $StashDB_SchemaVersion){
            write-host "This Stash Database has a database schema that is newer than what this script can handle.`nPlease check GitHub (https://github.com/ALonelyJuicebox/OFMetadataToStash) to see if there is a new version" -ForegroundColor red
            write-host $StashDB_QueryResult.version
            read-host "Press [Enter] to exit"
            exit
        }
        elseif ($StashDB_QueryResult.version -lt $StashDB_SchemaVersion) {
            write-host "The database schema that this script is written for (version $StashDB_SchemaVersion) is newer than the Stash DB you have selected. Upgrade your Stash instance to the latest version and re-run this script." -ForegroundColor red
            read-host "Press [Enter] to exit"
            exit
        }
        else {
            write-host "Hmm... this Stash database is not of a schema that this script was expecting. " -ForegroundColor red
            read-host "Press [Enter] to exit"
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
    read-host "Hmm...The Metadata Match Specificity parameter isn't well defined in your configuration file.`n`nPress [Enter] to run through the config wizard"
    Set-Config
}
else {
    write-host "* Metadata Match Specificity: $searchspecificity`n* Path to OnlyFans Media:     $PathToOnlyFansContent`n* Path to Stash's db:         $PathToStashDatabase`n"
    write-host "What would you like to do?"
    write-host " 1 - Add Metadata to my Stash using OnlyFans Metadata Database(s)"
    write-host " 2 - Add Metadata to my Stash without using OnlyFans Metadata Database(s)"
    write-host " 3 - Generate a redacted, sanitized copy of my OnlyFans Metadata Database file(s) so I can share them with others"
    write-host " 4 - Change Settings"

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
            write-host "OK, no backup will be created." 
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
            write-host "...Done! A backup was successfully created."
        }

        write-host "`nScanning for existing OnlyFans Metadata Database files..."

        #Finding all of our metadata databases. 
        $collectionOfDatabaseFiles = Get-ChildItem -Path $PathToOnlyFansContent -Recurse | where-object {$_.name -in "user_data.db","posts.db"}
        
        #For the discovery of a single database file
        if ($collectionOfDatabaseFiles.count -eq 1){
            $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path -leaf
            if ($performername -eq "metadata"){
                $performername = $collectionOfDatabaseFiles.FullName | split-path | split-path | split-path -leaf
            }
            
            write-host "Discovered a metadata database for '$performername' "
        }

        #For the discovery of multiple database files
        elseif ($collectionOfDatabaseFiles.count -gt 1){
            
            write-host "Discovered multiple metadata databases"
            write-host "0 - Process metadata for all performers"

            $i=1 # just used cosmetically
            Foreach ($OFDBdatabase in $collectionOfDatabaseFiles){
                $performername = $OFDBdatabase.FullName | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $OFDBdatabase.FullName | split-path | split-path | split-path -leaf
                }
                write-host "$i - $performername"
                $i++
            }
            $selectednumber = read-host "`nWhich performer would you like to select [Enter a number]"

            #Checking for bad input
            while ($selectednumber -notmatch "^[\d\.]+$" -or ([int]$selectednumber -gt $collectionOfDatabaseFiles.Count)){
                $selectednumber = read-host "Invalid Input. Please select a number between 0 and" $collectionOfDatabaseFiles.Count".`nWhich performer would you like to select [Enter a number]"
            }

            #If the user wants to process all performers, let's let them.
            if ([int]$selectednumber -eq 0){
                write-host "OK, all performers will be processed."
            }
            else{
                $selectednumber = $selectednumber-1 #Since we are dealing with a 0 based array, i'm realigning the user selection
                $performername = $collectionOfDatabaseFiles[$selectednumber].FullName | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $collectionOfDatabaseFiles[$selectednumber].FullName | split-path | split-path | split-path -leaf #Basically if we hit the metadata folder, go a folder higher and call it the performer
                }
                
                #Specifically selecting the performer the user wants to parse.
                $collectionOfDatabaseFiles = $collectionOfDatabaseFiles[$selectednumber]

                write-host "OK, the performer '$performername' will be processed."
            }
        }

        #Only try to parse metadata from metadata database files if we've discovered a database file.
        if ($collectionOfDatabaseFiles){

            write-host "`nQuick Tips: `n   * Be sure to run a Scan task in Stash of your OnlyFans content before running this script!`n   * Be sure your various metadata database(s) are located either at`n     <performername>"$directorydelimiter"user_data.db or at <performername>"$directorydelimiter"metadata"$directorydelimiter"user_data.db"
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
                write-host "`n### INFO ###`nAdded the OnlyFans studio to Stash's database" -ForegroundColor Cyan

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
                $performername = $currentdatabase.fullname | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $currentdatabase.fullname | split-path | split-path | split-path -leaf
                }
                write-host "`nParsing media for $performername" -ForegroundColor Cyan
            
                #Conditional tree for finding the performer ID using either the name or the alias (or creating the performer if neither option work out)
                $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                if($StashDB_PerformerQueryResult){
                    $PerformerID = $StashDB_PerformerQueryResult.id
                }
                else{
                    #No luck using the name to track down the performer ID, let's try the alias
                    $Query = "SELECT id FROM performers WHERE aliases LIKE '%"+$performername+"%'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                    
                    if($StashDB_PerformerQueryResult){
                        $PerformerID = $StashDB_PerformerQueryResult.id
                    }
                    #Otherwise both options failed so let's create the performer
                    else{   
                        #Stash's DB requires an MD5 hash of the name of the performer for performer creation
                        $stringAsStream = [System.IO.MemoryStream]::new()
                        $writer = [System.IO.StreamWriter]::new($stringAsStream)
                        $writer.write($performername)
                        $writer.Flush()
                        $stringAsStream.Position = 0
                        $performernamemd5 = Get-FileHash -Algorithm md5 -InputStream $stringAsStream | Select-Object Hash

                        #Creating a performer also requires a updated_at/created_at timestamp
                        $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

                        #Creating the performer in Stash's db
                        $Query = "INSERT INTO performers (checksum, name, url, created_at, updated_at) VALUES ('"+$performernamemd5.hash+"', '"+$performername+"', 'https://www.onlyfans.com/"+$performername+"', '"+$timestamp+"', '"+$timestamp+"')"
                        Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                        write-host "`n### INFO ###`nAdded a new Performer ($performername) to Stash's database`n" -ForegroundColor Cyan

                        $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                        $PerformerID = $StashDB_PerformerQueryResult.id
                    }       
                }
                
                #Select all the media (except audio) and the text the performer associated to them, if available from the OFDB
                $Query = "SELECT posts.post_id AS posts_postID, posts.text, posts.created_at, medias.post_id AS medias_postID, medias.size, medias.directory, medias.filename, medias.media_type FROM medias INNER JOIN POSTS ON medias.post_id=posts.post_id WHERE medias.media_type <> 'Audios'"
                $OF_DBpath = $currentdatabase.fullname 
                $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $OF_DBpath
                foreach ($OFDBMedia in $OFDBQueryResult){

                    #Generating the URL for this post
                    $linktoperformerpage = "https://www.onlyfans.com/"+$OFDBMedia.posts_postID+"/"+$performername
                    
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
         

                    #Note that the DigitalCriminals OF downloader quantifies gifs as videos for some reason
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
                        $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, scenes.id AS scenes_id, scenes.title AS scenes_title, scenes.details AS scenes_details FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN scenes_files ON files.id = scenes_files.file_id JOIN scenes ON scenes.id = scenes_files.scene_id WHERE path='"+$OFDBdirectoryForQuery+"' AND basename ='"+$OFDBfilenameForQuery+"' AND size ="+$OFDBfilesize
                    }

                    #High specificity, search for images based on matching file path between OnlyFans DB and Stash DB as well as matching the filesize. 
                    else{
                        $Query = "SELECT folders.path, files.basename, files.size, files.id AS files_id, folders.id AS folders_id, images.id AS images_id, images.title AS images_title FROM files JOIN folders ON files.parent_folder_id=folders.id JOIN images_files ON files.id = images_files.file_id JOIN images ON images.id = images_files.image_id WHERE size ="+$OFDBfilesize+" AND path ='"+$OFDBdirectoryForQuery+"' AND basename ='$OFDBfilenameForQuery'"
                    }
                    
                    $StashDB_QueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
           
                    #If our search for a matching media in the Stash DB is empty let's check to see if the file exists on the file system 
                    if ($null -eq $StashDB_QueryResult){
                         if (Test-Path $OFDBFullFilePath){
                            write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database but the file IS on your filesystem.`nTry running a Scan Task in Stash then re-running this script.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                        }
                        #In this case, the media isn't in Stash or on the filesystem so inform the user, log the file, and move on
                        else{
                            write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the OnlyFans script and redownloading the file.`n`n - $OFDBFullFilePath`n" -ForegroundColor Cyan
                            Add-Content -Path $PathToMissingFilesLog -value " $OFDBFullFilePath"
                            $nummissingfiles++
                        }
                    }

                    #Let's process each matching result and add the metadata we've found
                    else{
                        #Since we can potentially match against multiple files, we iterate through a loop, regardless of media type
                        for ($i=0; $i -lt $StashDB_QueryResult.length; $i++){

                            #Creating the title we want for the media
                            $proposedtitle = "$performername - $creationdatefromOF"
                            
                            #Sanitizing the text for apostrophes so they don't ruin our SQL query
                            $detailsToAddToStash = $OFDBMedia.text
                            $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                            $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                            #Let's check to see if this is a file that already has metadata.
                            #For Videos, we check the title and the details
                            #For Images, we only check the title (for now)
                            #If any metadata is missing, we don't both with updating a specific column, we just update the entire row

                            if ($mediatype -eq "video"){
                                $filewasmodified = $false

                                #Updating scene metadata if necessary
                                if (($StashDB_QueryResult[$i].scenes_title -ne $proposedtitle) -or ($StashDB_QueryResult[$i].scenes_details -ne $OFDBMedia.text)){
                                    $Query = "UPDATE scenes SET title='"+$proposedtitle+"', details='"+$detailsToAddToStash+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"', studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$StashDB_QueryResult[$i].scenes_id+"'"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }
                                
                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_scenes WHERE performer_id ="+$PerformerID+" AND scene_id ="+$StashDB_QueryResult[$i].scenes_id
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerid+","+$StashDB_QueryResult[$i].scenes_id+")"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Providing user feedback and adding to the modified counter if necessary
                                if ($filewasmodified){
                                    write-host "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                    $numModified++  
                                }
                                else{
                                    write-host "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                    $numUnmodified++
                                }

                                
                            }
                            else{ #For images
                                $filewasmodified = $false

                                #Updating image metadata if necessary
                                if ($StashDB_QueryResult[$i].images_title -ne $proposedtitle){
                                    $Query = "UPDATE images SET title='"+$proposedtitle+"', updated_at='"+$modtime+"', studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$StashDB_QueryResult[$i].images_id+"'"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_images WHERE performer_id ="+$PerformerID+" AND image_id ="+$StashDB_QueryResult[$i].images_id
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_images (performer_id, image_id) VALUES ("+$performerid+","+$StashDB_QueryResult[$i].images_id+")"
                                    
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                    $filewasmodified = $true
                                }

                                #Providing user feedback and adding to the modified counter if necessary
                                if ($filewasmodified){
                                    write-host "- Added metadata to Stash's database for the following file:`n   $OFDBFullFilePath" 
                                    $numModified++  
                                }
                                else{
                                    write-host "- This file already has metadata, moving on...`n   $OFDBFullFilePath"
                                    $numUnmodified++
                                }
                            }
                        }
                    } 
                }
            }
        }
        if ($nummissingfiles -gt 0){
            write-host "`n- Missing Files -" -ForegroundColor Cyan
            write-host "There is available metadata for $nummissingfiles files in your OnlyFans Database that cannot be found in your Stash Database."
            write-host "    - Be sure to review the MissingFiles log."
            write-host "    - There's a good chance you have deleted these files from your hard drive and may need to redownload"
        }

        write-host "`n****** Import Complete ******"-ForegroundColor Cyan
        write-host "- Modified Scenes/Images: $numModified`n- Scenes/Images that already had metadata: $numUnmodified" 

        #Some quick date arithmetic to calculate elapsed time
        $scriptEndTime = Get-Date
        $scriptduration = ($scriptEndTime-$scriptStartTime).totalseconds
        if($scriptduration -ge 60){
            [int]$Minutes = $scriptduration / 60
            [int]$seconds = $scriptduration % 60
            if ($minutes -gt 1){
                write-host "- This script took $minutes minutes and $seconds seconds to execute"
            }
            else{
                write-host "- This script took $minutes minute and $seconds seconds to execute"
            }
        }
        else{
            write-host "- This script took $scriptduration seconds to execute"
        }
    }
   

    #Code for auto determining performer
    elseif($userscanselection -eq 2){

        write-host "This feature is temporarily unavailable." -ForegroundColor red
        read-host "Press [Enter] to exit"
        exit

        write-host "`n- Quick Tips - " -ForegroundColor Cyan
        write-host "    - This script will try and determine a performer name for discovered files based on file path."
        write-host "    - Files that already have metadata will be ignored."
        write-host "    - Please be sure *not* to scan content that isn't OnlyFans content."

        #Since we're editing the Stash database directly, playing it safe and asking the user to back up their database
        $backupConfirmation = Read-Host "`nWould you like to make a backup of your Stash Database? [Y/N] (Default is Y)"
        if (($backupConfirmation -eq 'n') -or ($backupConfirmation -eq 'no')) {
            write-host "OK, no backup will be created." 
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
            write-host "...Done! A backup was successfully created."
        }

        read-host "`nPress [Enter] to start parsing your directory"

        #A buffer for Performer Name and Performer ID to minimize how often we reach out to the DB. 
        $performerbuffer = @('performername',0)
        
        #Because of how fast this script runs, we need a buffer to limit how often we write out to the DB to avoid db write issues
        #First object in the array is the number of "queries" that have been collected so far, and the second object is the queries themselves, as a single string
        $QueryBuffer = @(0,$null)

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
           write-host "`n### INFO ###`nAdded the OnlyFans studio to Stash's database" -ForegroundColor Cyan

           $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
           $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

           $OnlyFansStudioID = $StashDB_StudioQueryResult.id
       }
       #Otherwise, the studio ID can be attained from the SELECT query
       else {
           $OnlyFansStudioID = $StashDB_StudioQueryResult.id
       }

        $OFfilestoscan = get-childitem $pathToOnlyFansContent -file -recurse -exclude *.db 

        for($i=0; $i -lt $OFfilestoscan.count; $i++){
            $OFFile = $OFfilestoscan[$i]

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

            $patharrayposition = $patharray.count-1
            $foundperformer = $false

            #So the way this works is basically that we have a known list of what the filepaths for onlyfans content should look like. 
            #Therefore we can work backwards from the file itself, iterating through the path until we find something unexpected.
            #That unexpected folder name will be our performer name.
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

            #Looking in the stash DB for the current filename we're parsing
            if($mediatype -eq "image"){
                $Query = "SELECT id,studio_id FROM images WHERE images.path='"+$OFFile+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.id
            }
            else {
                $Query = "SELECT id,studio_id FROM SCENES WHERE scenes.path='"+$OFFile+"'"
                $StashDBSceneQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                $mediaid = $StashDBSceneQueryResult.id
            }

            #If Stash has this file, we can work with it.
            if ($StashDBSceneQueryResult){

                #If we don't have the performer information in the buffer, look for it or create the performer
                if ($performerbuffer[0] -ne $performername){
                    $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                    #If the performer doesn't exist, try looking at aliases
                    if(!$StashDB_PerformerQueryResult){
                        $Query = "SELECT id FROM performers WHERE aliases LIKE '%"+$performername+"%'"
                        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                        
                        #This performer definitely does not exist so create one
                        if(!$StashDB_PerformerQueryResult){

                            #Stash's DB requires an MD5 hash of the name of the performer for performer creation so...here's that
                            $stringAsStream = [System.IO.MemoryStream]::new()
                            $writer = [System.IO.StreamWriter]::new($stringAsStream)
                            $writer.write($performername)
                            $writer.Flush()
                            $stringAsStream.Position = 0
                            $performernamemd5 = Get-FileHash -Algorithm md5 -InputStream $stringAsStream | Select-Object Hash

                            #Creating a performer also requires a updated_at/created_at timestamp
                            $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

                            #Creating the performer in Stash's db
                            $Query = "INSERT INTO performers (checksum, name, url, created_at, updated_at) VALUES ('"+$performernamemd5.hash+"', '"+$performername+"', 'https://www.onlyfans.com/"+$performername+"', '"+$timestamp+"', '"+$timestamp+"');"
                            Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                            write-host "`n### INFO ###`nAdded a new Performer ($performername) to Stash's database`n" -ForegroundColor Cyan
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
                        $QueryBuffer[0] = $QueryBuffer[0]+1
                        $QueryBuffer[1] = $QueryBuffer[1]+"INSERT INTO performers_images (performer_id, image_id) VALUES ("+$performerbuffer[1]+","+$mediaid+");"
                    }
                    else{
                        $QueryBuffer[0] = $QueryBuffer[0]+1
                        $QueryBuffer[1] = $QueryBuffer[1]+"INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerbuffer[1]+","+$mediaid+");"
                    }
                    write-host "- Added metadata to Stash's database for the following file:`n   $OFFile" 
                    $numModified++
                }
                else {
                    write-host "- This file already has metadata, moving on...`n   $OFFile"
                    $numUnmodified++
                }
                
                #If this media doesn't have a related studio, let's go ahead and add one.
                if($StashDBSceneQueryResult.studioID -ne $OnlyFansStudioID){
                    if($mediatype -eq "image"){
                        $QueryBuffer[0] = $QueryBuffer[0]+1
                        $QueryBuffer[1] = $QueryBuffer[1]+"UPDATE images SET studio_id='"+$OnlyFansStudioID+"' WHERE path='"+$OFFile+"';"
                    }
                    else{
                        $QueryBuffer[0] = $QueryBuffer[0]+1
                        $QueryBuffer[1] = $QueryBuffer[1]+"UPDATE scenes SET studio_id='"+$OnlyFansStudioID+"' WHERE path='"+$OFFile+"';"
                    }
                }
            }
            #If this is the last time we're going to iterate over this collection of discovered files OR if our buffer is full enough
            if(($i -eq $OFfilestoscan.count) -or ($QueryBuffer[0] -gt 20)){
                #Run the query against the db, and flush the buffer
                Invoke-SqliteQuery -Query $QueryBuffer[1] -DataSource $PathToStashDatabase
                $QueryBuffer[1] = $null
                $QueryBuffer[0] = 0
            }
        }
        write-host "`n****** Import Complete ******"-ForegroundColor Cyan
        write-host "- Modified Scenes/Images: $numModified`n- Scenes/Images that already had metadata: $numUnmodified" 

        #Some quick date arithmetic to calculate elapsed time
        $scriptEndTime = Get-Date
        $scriptduration = ($scriptEndTime-$scriptStartTime).totalseconds
        if($scriptduration -ge 60){
            [int]$Minutes = $scriptduration / 60
            [int]$seconds = $scriptduration % 60
            if ($minutes -gt 1){
                write-host "- This script took $minutes minutes and $seconds seconds to execute"
            }
            else{
                write-host "- This script took $minutes minute and $seconds seconds to execute"
            }
        }
        else{
            write-host "- This script took $scriptduration seconds to execute"
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


