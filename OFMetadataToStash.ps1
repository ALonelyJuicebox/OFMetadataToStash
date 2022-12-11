<#
---OnlyFans Metadata to Stash Database PoSH Script 0.3---

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
    - Modify the config file prior to running this script
 #>

$pathtoconfigfile = ".\OFMetadataToStash_Config"
$PathToStashDatabase = (Get-Content $pathtoconfigfile)[5]
$PathToOnlyFansContent = (Get-Content $pathtoconfigfile)[8]
$PathToPotentialDuplicatesLog = (Get-Content $pathtoconfigfile)[11]
$PathToMissingFilesLog = (Get-Content $pathtoconfigfile)[14]

clear-host
write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"

#Some quick checks to make sure our config file and paths are good to go
if(!(test-path $pathtoconfigfile)){
    read-host "Please ensure the OFMetadataToStash config file is in the same directory as this script`n Press [Enter] to exit"
    exit
}
elseif ($PathToStashDatabase -eq "C:\REPLACE_ME\Stash\db\stash-go.sqlite" -or !(test-path $PathToStashDatabase)){
    read-host "Please define a valid filepath for Stash's database file in the OFMetadataToStash_config file.`nPress [Enter] to exit"
    exit
}
elseif ($PathToOnlyFansContent -eq "C:\REPLACE_ME\ONLYFANS\" -or !(test-path $PathToOnlyFansContent)){
    read-host "Please define a valid filepath for your OnlyFans content to be scanned in the OFMetadataToStash_config file.`nPress [Enter] to exit"
    exit
}
else {
    write-host "- Path to Stash's db: $PathToStashDatabase`n- Path to OnlyFans Content: $PathToOnlyFansContent`n"
    write-host "How would you like to process your content?"
    write-host " 1 - I have OnlyFans Metadata Database files (user_data.db) somewhere in the path mentioned above"
    write-host " 2 - Please try to determine OnlyFans performer names based on filepath"

    $userscanselection = 0;
    do {
        $userscanselection = read-host "`nEnter selection"
    }
    while (($userscanselection -ne 1) -and ($userscanselection -ne 2))

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

    #Code for parsing metadata files
    if($userscanselection -eq 1){


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
            
            write-host "Discovered a metadata database for '$performername' "
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
                $performername = $collectionOfDatabaseFiles[$selectednumber-1].FullName | split-path | split-path -leaf
                if ($performername -eq "metadata"){
                    $performername = $OFDBdatabase.FullName | split-path | split-path | split-path -leaf
                }
                
                #Specifically selecting the performer the user wants to parse.
                $collectionOfDatabaseFiles = $collectionOfDatabaseFiles[$selectednumber-1]

                write-host "OK, the performer '$performername' will be processed."
            }
        }

        #Only try to parse metadata from metadata database files if we've discovered a database file.
        if ($collectionOfDatabaseFiles){

            #Later in the script we will need to merge the directory path and file name to get a single string. We need to know what deliminter to use based on OS
            #Writing it this way with a second if statement avoids an error from machines that are running Windows Powershell and not Powershell Core
            if($IsWindows){
                $directorydelimiter = "\"
            }
            else{
                $directorydelimiter = "/"
            }

            write-host "`nQuick Tips: `n   - Be sure to run a Scan task in Stash of your OnlyFans content before running this script!`n   - Be sure your various metadata database(s) are located either at`n     <performername>\user_data.db or at <performername\metadata\user_data.db"
            read-host "`nPress [Enter] to begin"

            $numModified = 0
            $numUnmodified = 0
            $numDuplicates = 0
            $nummissingfiles = 0
            $scriptStartTime = get-date

            #Getting the OnlyFans Studio ID or creating it if it does not exist.
            $Query = "SELECT id FROM studios WHERE name LIKE 'OnlyFans%'"
            $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

            #If the Studio does not exist, create it
            if(!$StashDB_StudioQueryResult){

                #Stash's DB requires an MD5 hash of the name of the studio for studio creation
                $stringAsStream = [System.IO.MemoryStream]::new()
                $writer = [System.IO.StreamWriter]::new($stringAsStream)
                $writer.write("OnlyFans")
                $writer.Flush()
                $stringAsStream.Position = 0
                $studioNameMD5 = Get-FileHash -Algorithm md5 -InputStream $stringAsStream | Select-Object Hash

                #Creating a studio also requires a updated_at/created_at timestamp
                $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

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

                #Getting the Performer ID from either the name or one of the aliases, or creating it if it does not exist
                $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                if(!$StashDB_PerformerQueryResult){

                    $Query = "SELECT id FROM performers WHERE aliases LIKE '%"+$performername+"%'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                
                    if(!$StashDB_PerformerQueryResult){

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
                    }
            
                    $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
                    $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                    $PerformerID = $StashDB_PerformerQueryResult.id
                }
                else {
                    $PerformerID = $StashDB_PerformerQueryResult.id
                }
                
                #Select all the media (except audio) and the text the performer associated to them, if available
                $Query = "SELECT posts.post_id AS posts_postID, posts.text, posts.created_at, medias.post_id AS medias_postID, medias.size, medias.directory, medias.filename, medias.media_type FROM medias INNER JOIN POSTS ON medias.post_id=posts.post_id WHERE medias.media_type <> 'Audios'"
                $OF_DBpath = $currentdatabase.fullname 
                $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $OF_DBpath
                foreach ($OFDBMedia in $OFDBQueryResult){

                    #Generating the URL for this post
                    $linktoperformerpage = "https://www.onlyfans.com/"+$OFDBMedia.posts_postID+"/"+$performername
                    
                    #Reformatting the date to something stash appropriate
                    $creationdatefromOF = $OFDBMedia.created_at
                    $creationdatefromOF = Get-Date $creationdatefromOF -format "yyyy-MM-dd"

                    #This defines the full filepath of the media. These are separate columns in the OFDB so we must combine them in a separate variable.
                    $OFDBfilename = $OFDBMedia.directory +$directorydelimiter+ $OFDBMedia.filename

                    #Storing a separate variant of the filepath with apostrophy sanitization so they don't ruin our SQL queries
                    $OFDBfilenameForQuery = $OFDBfilename.replace("'","''") 
                
                    #Note that the DigitalCriminals OF downloader quantifies gifs as videos for some reason
                    #Since Stash doesn't (and rightfully so), we need to account for this
                    if(($OFDBMedia.media_type -eq "videos") -and ($OFDBfilename -notlike "*.gif")){
                        $mediatype = "video"
                    }
                    #Condition for images. Again, we have to add an extra condition just in case the image is a gif due to the DG database
                    elseif(($OFDBMedia.media_type -eq "images") -or ($OFDBfilename -like "*.gif")){
                        $mediatype = "image"
                    }
                    #Looking in the stash DB for the current filename we're parsing
                    switch ($mediatype) {
                        "video" {$Query = "SELECT id,title FROM scenes WHERE scenes.path='"+$OFDBfilenameForQuery+"'" }
                        "image" {$Query = "SELECT id,title FROM images WHERE images.path='"+$OFDBfilenameForQuery+"'"}
                    }
                    $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

                    #This block is designed to try and find the media even if the filename isn't in stash.
                    if (!$StashDBQueryResult){

                        #Let's look for a file with the right file size that has the performername in the path just in case the file was moved
						if($performername && $OFDBMedia.size){
							switch ($mediatype) {
								"video" {$Query = "SELECT id,title,path,size,details FROM scenes WHERE path LIKE '%"+$performername+"%' AND size = "+$OFDBMedia.size }
								"image" {$Query = "SELECT id,title,path,size FROM images WHERE path LIKE '%"+$performername+"%' AND size = "+$OFDBMedia.size}
							}
							$StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
						}

                        #This is a scenario where a performer may have uploaded the same media twice and the file path has changed from what stash currently expects.
                        if($StashDBQueryResult.count -gt 1){
                            $numDuplicates++
                            
                            #Adding the filepath information for the duplicates to a log
                            write-host "`n### INFO ###`nPotential duplicate discovered. See PotentialDuplicates log file for details" -ForegroundColor Cyan
                            foreach ($dupe in $StashDBQueryResult) {
                                $dupepath = $dupe.path
                                $dupesize = $dupe.size
                                write-host "    - $dupepath" -ForegroundColor Cyan
                                Add-Content -Path $PathToPotentialDuplicatesLog -value "$dupesize KB,$dupepath"
                            }   
                            $StashDBQueryResult = $null #Makes it so we don't try and parse metadata for this entry
                        }

                        #Well we tried, but couldn't find the file at all.
                        if($null -eq$StashDBQueryResult){
                            #Let's move on, the media is on the filesystem but isn't in Stash so ask the user to run a scan
                            if (Test-Path $OFDBfilename){
                                write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database but the file IS on your filesystem.`nIt could be a duplicate that Stash decided not to import, but try running a Scan Task in Stash then re-running this script.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
                            }
                            #Let's move on, the media isn't in Stash or on the filesystem so inform the user
                            else{
                                write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the OnlyFans script and redownloading the file.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
                                Add-Content -Path $PathToMissingFilesLog -value "$OFDBfilename"
                                $nummissingfiles++
                            }
                        }
                    }

                    #If we've found a matching result
                    if ($null -ne $StashDBQueryResult){

                        #Creating the title we want for the media
                        $title = "$performername - $creationdatefromOF"

                        #Quick check to see if this file already has metadata from this script
                        #Only Videos can have details (for now) so we have a condition to check for that here
                        if (($StashDBQueryResult.title -ne $title) -or (($mediatype -eq "video") -and ($StashDBQueryResult.details -ne $OFDBMedia.text))){
                                
                            #Sanitizing the text for apostrophes so they don't ruin our SQL query
                            $detailsToAddToStash = $OFDBMedia.text
                            $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                            $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be
                            
                            #Now we can process the file, based on media type
                            if(($mediatype -eq "video")){
                                $Query = "UPDATE scenes SET title='"+$title+"', details='"+$detailsToAddToStash+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"', studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$StashDBQueryResult.ID+"'"
                                Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_scenes WHERE performer_id ="+$PerformerID+" AND scene_id ="+$StashDBQueryResult.ID
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerid+","+$StashDBQueryResult.ID+")"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                }
                                write-host "- Added metadata to Stash's database for the following file:`n   $OFDBfilename" 
                                $numModified++  
                            }

                            elseif($mediatype -eq "image"){
                                $Query = "UPDATE images SET title='"+$title+"', updated_at='"+$modtime+"', studio_id='"+$OnlyFansStudioID+"' WHERE id='"+$StashDBQueryResult.ID+"'"
                                Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                                #Updating Stash with the performer for this media if one is not already associated
                                $Query = "SELECT * FROM performers_images WHERE performer_id ="+$PerformerID+" AND image_id ="+$StashDBQueryResult.ID
                                $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                                if(!$StashDB_PerformerUpdateResult){
                                    $Query = "INSERT INTO performers_images (performer_id, image_id) VALUES ("+$performerid+","+$StashDBQueryResult.ID+")"
                                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                                }
                                write-host "- Added metadata to Stash's database for the following file:`n   $OFDBfilename" 
                                $numModified++  
                            }
                        }
                        else {
                            write-host "- This file already has metadata, moving on...`n   $OFDBfilename"
                            $numUnmodified++
                        }
                    } 
                }
            }
        }
        if ($numDuplicates -gt 0){
            #Because every single duplicate (if found) will add an extra entry to the log, we just want to quickly delete the extras.
            Get-Content $PathToPotentialDuplicatesLog | Select-Object -Unique | Set-Content $PathToPotentialDuplicatesLog

            write-host "`n- Potential Duplicates -" -ForegroundColor Cyan
            write-host "There are $numDuplicates files in your OnlyFans Database that have filepaths that`ndo not align with anything in your Stash Database."
            write-host "Based on filesize and performer name, we found *multiple* potential files that`nmay be the right file for the metadata" 
            write-host "`nThis can occur if an OnlyFans performer has uploaded the same file twice."
            write-host "There wasn't enough data to associate the right metadata to the right file,`nso nothing was altered in Stash for these files."
            write-host "    - Be sure to review the PotentialDuplicates log and delete the duplicate files both from Stash & your hard drive."
        }
        if ($nummissingfiles -gt 0){
            write-host "`n- Missing Files -" -ForegroundColor Cyan
            write-host "There is available metadata for $nummissingfiles files in your OnlyFans Database that cannot be found in your Stash Database."
            write-host "Further, there is nothing in your Stash Database that aligns with the filesize for those files is based on their performer."
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
    else{
        write-host "`n- Quick Tips - " -ForegroundColor Cyan
        write-host "    - This script will try and determine a performer name for discovered files based on file path."
        write-host "    - Files that already have metadata will be ignored."
        write-host "    - Please be sure *not* to scan content that isn't OnlyFans content."
        read-host "`nPress [Enter] to start"

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

        if(!$StashDB_StudioQueryResult){

            #Stash's DB requires an MD5 hash of the name of the studio for studio creation
            $stringAsStream = [System.IO.MemoryStream]::new()
            $writer = [System.IO.StreamWriter]::new($stringAsStream)
            $writer.write("OnlyFans")
            $writer.Flush()
            $stringAsStream.Position = 0
            $studioNameMD5 = Get-FileHash -Algorithm md5 -InputStream $stringAsStream | Select-Object Hash

            #Creating a studio also requires a updated_at/created_at timestamp
            $timestamp = get-date -format yyyy-MM-ddTHH:mm:ssK

            $Query = "INSERT INTO studios (name, url, checksum, created_at, updated_at) VALUES ('OnlyFans','https://www.onlyfans.com','"+$studioNameMD5.hash+"', '"+$timestamp+"', '"+$timestamp+"');"
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
}