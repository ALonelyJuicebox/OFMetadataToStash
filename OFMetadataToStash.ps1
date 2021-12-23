<#
---OnlyFans Metadata to Stash Database PoSH Script---

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

Clear-Host

write-host "- OnlyFans Metadata to Stash Database PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
if (!(test-path $PathToStashDatabase)){
    read-host "You have not defined a filepath for Stash's database file. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
elseif (!(test-path $pathToOF_DB_Metadata)){
    read-host "You have not defined a filepath for the OnlyFans Metadata database. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
else {
    write-host "- Path to Stash's db: $PathToStashDatabase`n- Path to OnlyFans Metadata DB: $PathToOF_DB_Metadata`n"
    
    #Since we're editing the Stash database directly, playing it safe and asking the user to back up their database
    $backupConfirmation = Read-Host "Would you like to make a backup of your Stash Database? [Y/N] Default is 'Y'"
    if (($backupConfirmation -ne 'n') -or ($backupConfirmation -ne 'n')) {
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
    else{
        write-host "OK, no backup will be created." 
    }

    read-host "Please make sure Stash is not running. `nPress [Enter] to begin the import"

    #Let's capture the name of this performer based off of the file directory
    $performername = Split-Path -parent $pathToOF_DB_Metadata
    $performername = Split-Path -parent $performername 
    $performername = Split-path $performername -leaf

    #Select all the scenes and the text the performer associated to them, if available
    $Query = "SELECT posts.post_id AS posts_postID, posts.text, posts.created_at, medias.post_id AS medias_postID, medias.size, medias.directory, medias.filename FROM medias INNER JOIN POSTS ON medias.post_id=posts.post_id WHERE medias.media_type ='Videos'"
    $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $pathToOF_DB_Metadata

    $numModified = 0
    $numUnmodified = 0

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


        #Exception handling for if we don't yet have a matching scene
        if (!$StashDBQueryResult){
            
            #Since the file DOES exist on the filesystem, let's go ahead and run a SQL query to see if it's just under a different filepath in Stash's database.
            if (Test-Path $OFDBfilename){       
                $OFDBfilename = $OFDBVideo.filename


                $Query = "SELECT id,title,path,size FROM scenes WHERE path LIKE '%"+$OFDBVideo.filename+"'"
                $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

                #If we DO find a matching filename, let's just check the filesize as well to be double sure this is the right file
                if($StashDBQueryResult){
                    if($OFDBVideo.size -eq $StashDBQueryResult.size){
                        $OFDBfilename = $StashDBQueryResult.path
                    }
                }
                #Otherwise, welp, outta luck, move on to the next video in this array
                else {
                    write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata db that we couldn't find the following file in your Stash, either by filename or full path.`nThat said, this file *is* on your filesystem.`nTry running a Scan task in Stash and then run this script again.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
                }
            }
            #If the scene is in the OnlyFans DB but not on the filesystem, it might have been moved by the user. Prompt user to perform another OF scan
            else{
                write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata database that we couldn't find in your Stash database.`nThis file also doesn't appear to be on your filesystem.`nTry rerunning the OnlyFans script and redownloading the file.`n`n - $OFDBfilename`n" -ForegroundColor Cyan
            }
        }

        #If we've found a matching scene...
        if ($StashDBQueryResult){

            #If the scene in question doesn't actually have any details from the OFDB just update everything else
            if($OFDBVideo.text -eq ""){
                if ($StashDBQueryResult.title -ne $title){
                
                    $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be
                    
                    $Query = "UPDATE scenes SET title='"+$title+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"' WHERE path='"+$OFDBfilename+"'"
                    $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                    write-host "- Added metadata to Stash's database for the following file:`n   $OFDBfilename"   
                    $numModified++
                }
            }
            #Otherwise if this scene is missing the title it's supposed to have, add all the metadata we have for this scene
            else {
                if ($StashDBQueryResult.title -ne $title){
                    
                    #Sanitizing the text for apostrophes so they don't ruin our SQL query
                    $detailsToAddToStash = $OFDBVideo.text
                    $detailsToAddToStash = $detailsToAddToStash.replace("'","''")
                    $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                    $Query = "UPDATE scenes SET title='"+$title+"', details='"+$detailsToAddToStash+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"' WHERE path='"+$OFDBfilename+"'"
                    $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
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
    write-host "`n****** Import Complete ******`n- Modified scenes: $numModified`n- Scenes that already had metadata: $numUnmodified"
}
