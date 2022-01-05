# USER DEFINED VARIABLES #
##########################
#Required Paths
$PathToStashDatabase = "" #Please define the full file path. This file is probably in <SomeFilePath>/Stash/db/stash-go.sqlite
$pathToOnlyFansMetadata = "" #You may define a top level folder that contains all your OnlyFans metadata databases from various performers or you may just define the direct path to user_data.db (<performername>/metadata/user_data.db)

#Optional Paths 
$PathToPotentialDuplicatesLog =".\PotentialDuplicates.log" #Log of files that we can't precisely find in your Stash database that of the same size as each other
$PathToMissingFilesLog = ".\MissingFiles.log" #Log of files that are in your OnlyFans database but cannot be found in Stash either by path or by searching filesize/performer
##########################

<#
---OnlyFans Metadata to Stash Database PoSH Script 0.2---

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
    - Change the paths to both your stash db and to the OnlyFans metadata db on the first two lines of this script
 #>

clear-host
write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
if (!(test-path $PathToStashDatabase)){
    read-host "You have not defined a filepath for Stash's database file. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
elseif (!(test-path $pathToOnlyFansMetadata)){
    read-host "You have not defined anything for the OnlyFans Metadata database. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
else {
    write-host "- Path to Stash's db: $PathToStashDatabase`n- Path to OnlyFans Metadata: $pathToOnlyFansMetadata`n"

    #Since we're editing the Stash database directly, playing it safe and asking the user to back up their database
    $backupConfirmation = Read-Host "Would you like to make a backup of your Stash Database? [Y/N] Default is 'Y'"
    if (($backupConfirmation -eq 'n') -or ($backupConfirmation -eq 'no')) {
        write-host "OK, no backup will be created." 
    }
    else{
        $PathToStashDatabaseBackup = Split-Path $PathToStashDatabase
        $PathToStashDatabaseBackup = $PathToStashDatabaseBackup+"\stash-go_OnlyFans_Import_BACKUP-"+$(get-date -f yyyy-MM-dd)+".sqlite"
        read-host "OK, A backup will be created at $PathToStashDatabaseBackup`nPress [Enter] to generate backup"

        try {
            Copy-Item $PathToStashDatabase -Destination $PathToStashDatabaseBackup
        }
        catch {
            read-host "Unable to make a backup! Permissions error? Press [Enter] to exit"
            exit
        }
        write-host "...Done! A backup was successfully created."
    }

    write-host "`nScanning for OnlyFans Metadata..."

    #Finding all of our metadata databases. 
    $collectionOfDatabaseFiles = Get-ChildItem -Path $pathToOnlyFansMetadata -Recurse | where-object {$_.name -in "user_data.db","posts.db"}
    
    if ($collectionOfDatabaseFiles -eq 0){
        write-host "No databases were found in the provided path. Press [Enter] to exit"
        exit
    }
    elseif ($collectionOfDatabaseFiles -eq 1){

        $performername = Split-Path -parent $collectionOfDatabaseFiles[0].FullName
        $performername = Split-Path -parent $performername 
        $performername = Split-path $performername -leaf

        write-host "OK, the performer '$performername' will be processed."
    }
    else{
        $i=1
        write-host "0 - Process metadata for all performers"

        Foreach ($OFDBdatabase in $collectionOfDatabaseFiles){
            $performername = Split-Path -parent $OFDBdatabase.FullName
            $performername = Split-Path -parent $performername 
            $performername = Split-path $performername -leaf
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
            $performername = Split-Path -parent $collectionOfDatabaseFiles[$selectednumber-1].FullName
            $performername = Split-Path -parent $performername 
            $performername = Split-path $performername -leaf

            #Specifically selecting the performer the user wants to parse.
            $collectionOfDatabaseFiles = $collectionOfDatabaseFiles[$selectednumber-1]

            write-host "OK, the performer '$performername' will be processed."
        }
    }
    read-host "`nQuick Tips: `n    - Be sure to run a Scan task in Stash of your OnlyFans content before running this script!`n    - Since we are editing the SQLite database directly, please make sure Stash is not currently running. `n`nPress [Enter] to begin"

    $numModified = 0
    $numUnmodified = 0
    $numDuplicates = 0
    $nummissingfiles = 0
    #Getting the OnlyFans Studio ID or creating it if it does not exist.
    $Query = "SELECT id FROM studios WHERE name LIKE 'onlyfans'"
    $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
    if(!$StashDB_StudioQueryResult){
        $Query = "INSERT INTO studios (name, url) VALUES ('Onlyfans','https://www.onlyfans.com')"
        $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
        write-host "`n### INFO ###`nAdded the OnlyFans studio ($performername) to Stash's database" -ForegroundColor Cyan

        $Query = "SELECT id FROM studios WHERE name LIKE 'onlyfans'"
        $StashDB_StudioQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

        $OnlyFansStudioID = $StashDB_StudioQueryResult.id
    }
    else {
        $OnlyFansStudioID = $StashDB_StudioQueryResult.id
    }
    
    foreach ($currentdatabase in $collectionOfDatabaseFiles) {

        #Gotta reparse the performer name as we may be parsing through a full collection of performers. 
        #Otherwise you'll end up with a whole bunch of performers having the same name
        $performername = Split-Path -parent $currentdatabase.fullname
        $performername = Split-Path -parent $performername 
        $performername = Split-path $performername -leaf

        #Getting the Performer ID from either the name or one of the aliases, or creating it if it does not exist
        $Query = "SELECT id FROM performers WHERE name LIKE '"+$performername+"'"
        $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
        if(!$StashDB_PerformerQueryResult){

            $Query = "SELECT id FROM performers WHERE aliases LIKE '%"+$performername+"%'"
            $StashDB_PerformerQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
           
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
                $Query = "INSERT INTO performers (checksum, name, url, created_at, updated_at) VALUES ('"+$performernamemd5+"', '"+$performername+"', 'https://www.onlyfans.com/"+$performername+"', '"+$timestamp+"', '"+$timestamp+"')"
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
        
        #Select all the scenes and the text the performer associated to them, if available
        $Query = "SELECT posts.post_id AS posts_postID, posts.text, posts.created_at, medias.post_id AS medias_postID, medias.size, medias.directory, medias.filename FROM medias INNER JOIN POSTS ON medias.post_id=posts.post_id WHERE medias.media_type ='Videos' AND medias.filename NOT LIKE '%.gif'"
        $OF_DBpath = $currentdatabase.fullname 
        $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $OF_DBpath
        foreach ($OFDBVideo in $OFDBQueryResult){

            #Generating the URL for this post
            $linktoperformerpage = "https://www.onlyfans.com/"+$OFDBVideo.posts_postID+"/"+$performername
            
            #Reformatting the date to something stash appropriate
            $creationdatefromOF = $OFDBVideo.created_at
            $creationdatefromOF = Get-Date $creationdatefromOF -format "yyyy-MM-dd"

            #This defines the full filepath of the scene. These are separate columns in the OFDB so we must combine them in a separate variable.
            $OFDBfilename = $OFDBVideo.directory + "\" + $OFDBVideo.filename

            #Sanitizing the path for apostrophes so they don't ruin our SQL query
            $OFDBfilename = $OFDBfilename.replace("'","''")

            #Creating the title we want for the scene
            $title = "$performername - $creationdatefromOF"

            #Looking in the stash DB for the current filename we're parsing
            $Query = "SELECT id,title FROM SCENES WHERE scenes.path='"+$OFDBfilename+"'"
            $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

            #This block is designed to try and find the scene even if the filename isn't in stash.
            if (!$StashDBQueryResult){

                #Let's look for a file with the right file size that has the performername in the path just in case the file was moved
                $Query = "SELECT id,title,path,size FROM scenes WHERE path LIKE '%"+$performername+"%' AND size = "+$OFDBVideo.size
                $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

                #This is a scenario where a performer may have uploaded the same video twice and the file path has changed from what stash currently expects.
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
                elseif($StashDBQueryResult){
                    $OFDBfilename = $StashDBQueryResult.path #We change the filename to match what we found in the stash database
                    $OFDBfilename = $OFDBfilename.replace("'","''") #Sanitizing the path for apostrophes so they don't ruin our SQL query
                }
                
                #Well we tried, but couldn't find the file at all.
                else{
                    #Let's move on, the scene is on the filesystem but isn't in Stash so ask the user to run a scan
                    if (Test-Path $OFDBfilename){
                        write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database but the file IS on your filesystem.`nTry running a Scan Task in Stash then re-running this script.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
                    }
                    #Let's move on, the scene isn't in Stash or on the filesystem so inform the user
                    else{
                        write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the OnlyFans script and redownloading the file.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
                        Add-Content -Path $PathToMissingFilesLog -value "$OFDBfilename"
                        $nummissingfiles++
                    }
                }
            }

            #If we've found a matching result
            if ($null -ne $StashDBQueryResult){

                #Quick check to see if this file already has metadata from this script
                if ($StashDBQueryResult.title -ne $title){
                        
                    #Sanitizing the text for apostrophes so they don't ruin our SQL query
                    $detailsToAddToStash = $OFDBVideo.text
                    $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                    $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                    #Updating Stash with the appropriate metadata for this scene
                    $Query = "UPDATE scenes SET title='"+$title+"', details='"+$detailsToAddToStash+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"', studio_id='"+$OnlyFansStudioID+"' WHERE path='"+$OFDBfilename+"'"
                    Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

                    #Updating Stash with the performer for this scene if one is not already associated
                    $Query = "SELECT * FROM performers_scenes WHERE performer_id ="+$PerformerID+" AND scene_id ="+$StashDBQueryResult.ID
                    $StashDB_PerformerUpdateResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase

                    if(!$StashDB_PerformerUpdateResult){
                        $Query = "INSERT INTO performers_scenes (performer_id, scene_id) VALUES ("+$performerid+","+$StashDBQueryResult.ID+")"
                        Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase
                    }

                    write-host "- Added metadata to Stash's database for the following file:`n   $OFDBfilename" 
                    $numModified++  
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

    write-host "`nNote: Potential Duplicates`n    There are $numDuplicates files in your OnlyFans Database that have filepaths that do not align with anything in your Stash Database."
    write-host "    Based on filesize and performer name, we found *multiple* potential files that may be the right file for the metadata" 
    write-host "`n    This can occur if an OnlyFans performer has uploaded the same file twice."
    write-host "    There wasn't enough data to associate the right metadata to the right file, so nothing was altered in Stash for these files."
    write-host "        - Be sure to review the PotentialDuplicates log and delete the duplicate files both from Stash & your hard drive."
}
if ($nummissingfiles -gt 0){
    write-host "`nNote: Missing Files`n    There is available metadata for $nummissingfiles files in your OnlyFans Database that cannot be found in your Stash Database."
    write-host "    Further, there is nothing in your Stash Database that aligns with the filesize for those files is based on their performer."
    write-host "        - Be sure to review the MissingFiles log."
    write-host "        - There's a good chance you have deleted these files from your hard drive and may need to redownload"
}

write-host "`n****** Import Complete ******`n- Modified scenes: $numModified`n- Scenes that already had metadata: $numUnmodified" -ForegroundColor Cyan