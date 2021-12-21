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

# USER DEFINED VARIABLES #
##########################
$PathToStashDatabase = "" #Please define the full file path. This file is probably in <filepath>/Stash/db/stash-go.sqlite
$pathToOF_DB_Metadata = "" #Please define the full file path. This file should be located in <filepath>/<performername>/metadata/user_data.db
##########################

Clear-Host
write-host "- OnlyFans Metadata to Stash Database PoSH Script`nAuthor: JuiceBox (https://github.com/ALonelyJuicebox/OFMetadataToStash)"
if (!(test-path $PathToStashDatabase)){
    read-host "You have not defined a filepath for Stash's database file. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
elseif (!(test-path $pathToOF_DB_Metadata)){
    read-host "You have not defined a filepath for the OnlyFans Metadata database. Please edit the first two lines of this .ps1 file.`nPress [Enter] to exit."
    exit
}
else {
    write-host "- Settings Check`n - Path to Stash's db:`n$PathToStashDatabase`n - Path to OnlyFans Metadata DB:`n$PathToOF_DB_Metadata`nPress [Enter] to continue"
    read-host "Please make sure Stash is not running. You may also wish to create a backup of your SQL file.`nPress [Enter] to begin the import"

    #DEBUG STUFF
    Remove-Item $PathToStashDatabase -force 
    Copy-Item "C:\Users\Chris\Box\Active Scripts\OFMetadataToStash\stash\stash-go - DEFAULT STATE.sqlite" -Destination $PathToStashDatabase

    #Let's capture the name of this performer based off of the file directory
    $performername = Split-Path -parent $pathToOF_DB_Metadata
    $performername = Split-Path -parent $performername 
    $performername = Split-path $performername -leaf

    #Select all the videos and the text the performer associated to them, if available
    $Query = "SELECT posts.post_id AS posts_postID, posts.text, posts.created_at, medias.post_id AS medias_postID, medias.directory, medias.filename FROM medias INNER JOIN POSTS ON medias.post_id=posts.post_id WHERE medias.media_type ='Videos'"
    $OFDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $pathToOF_DB_Metadata

    $numModified = 0
    $numUnmodified = 0

    foreach ($video in $OFDBQueryResult){

        #Generating the URL for this post
        $linktoperformerpage = "www.onlyfans.com/"+$video.posts_postID+"/"+$performername
        
        #Reformatting the date to something stash appropriate
        $creationdatefromOF = $video.created_at
        $creationdatefromOF = Get-Date $creationdatefromOF -format "yyyy-MM-dd"

        #This defines the full filepath of the video. These are separate columns in the OFDB so we must combine them in a separate variable.
        $OFDBfilename = $video.directory + "\" + $video.filename

        #Creating the title we want for the scene
        $title = "$performername - Onlyfans Post ($creationdatefromOF)"

        #Looking in the stash DB for the current filename we're parsing, with an additional condition that the details must be empty
        $Query = "SELECT * FROM SCENES WHERE path='"+$OFDBfilename+"'"
        $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 

        #Exception handling
        if (!$StashDBQueryResult){
            #If the scene is in the OnlyFans DB but not in stash, let the user know
            if (Test-Path $OFDBfilename){
                write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata db that we couldn't find the following file in your Stash.`nThat said, this file *is* on your filesystem.`nTry running a Scan task in Stash and then run this script again.`n - $OFDBfilename`n" -ForegroundColor Cyan

            }
            #If the scene is in the OnlyFans DB but not on the filesystem, it might have been moved by the user. Prompt user to perform another OF scan
            else{
                write-host "`n### INFO ###`nThere's a file in this OnlyFans metadata db that we couldn't find the following file in your Stash.`nThis file also doesn't appear to be where the OnlyFans Metadata db thinks it should be.`nTry repopulating the OnlyFans metadata DB.`n - $OFDBfilename`n" -ForegroundColor Cyan
            }
        }
        #If the video in question doesn't actually have any details from the OF DB
        elseif($video.details -eq ""){
            if ($StashDBQueryResult.title -ne $title){
            
                $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                $Query = "UPDATE scenes SET title='"+$title+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"' WHERE path='"+$OFDBfilename+"'"
                $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                write-host "Added metadata to Stash's database for the following file: `n- $OFDBfilename"   
                $numModified++
            }
        }
        #Otherwise let's check to see if this video needs updating in the stash DB, and if so, update accordingly
        else {
            if ($StashDBQueryResult.title -ne $title){
                
                $modtime = get-date -format yyyy-MM-ddTHH:mm:ssK #Determining what the update_at time should be

                $Query = "UPDATE scenes SET title='"+$title+"', details='"+$video.text+"', date='"+$creationdatefromOF+"', updated_at='"+$modtime+"', url='"+$linktoperformerpage+"' WHERE path='"+$OFDBfilename+"'"
                $StashDBQueryResult = Invoke-SqliteQuery -Query $Query -DataSource $PathToStashDatabase 
                write-host "Added metadata to Stash's database for the following file: `n - $OFDBfilename" 
                $numModified++  
            }
            else {
                write-host "This file already has metadata, moving on...`n - $OFDBfilename"
                $numUnmodified++
            }
        }    
    }
    write-host "`n****** Import Complete ******`n- Modified scenes: $nummodified`n- Scenes that already had metadata: $numunmodified"
}
