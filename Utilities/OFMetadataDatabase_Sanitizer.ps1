<#
---OnlyFans Metadata Database Sanitizer PoSH Script 0.1---

AUTHOR
    JuiceBox
URL 
    https://github.com/ALonelyJuicebox/OFMetadataToStash

DESCRIPTION
    Scrubs any and all identifiable or otherwise unnecessary information from your OnlyFans Metadata Database, allowing you to freely share the metadata

REQUIREMENTS
    - Metadata database must be from DC's script
    - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
       Download a zip of the PSSQlite folder in that repo, extract it, run an Admin window of Powershell
       in that directory then run 'install-module pssqlite' followed by the command 'import-module pssqlite'
 #>

clear-host
write-host "- OnlyFans Metadata Database Sanitizer PoSH Script - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n"
write-host "This script generates a completely sanitized version of a given OnlyFans Metadata Database"
write-host "Your original metadata database will not be modified in any way."
write-host "`nPlease enter the file path to the OnlyFans Metadata Database (user_data.db) you want to convert"
$pathToOriginalStashdb = read-host "Enter Path"

#Later in the script we will need to merge the directory path and file name to get a single string. We need to know what deliminter to use based on OS
#Writing it this way with a second if statement avoids an error from machines that are running Windows Powershell and not Powershell Core
if($PSVersionTable.properties.name -match "os"){
    if(!($PSVersionTable.os -like "*Windows*")){
        $directorydelimiter = "/"
    }
}
else{
    $directorydelimiter = "\"
}


if (test-path $pathToOriginalStashdb){
    if((split-path $pathToOriginalStashdb -leaf) -eq "user_data.db" -or (split-path $pathToOriginalStashdb -leaf) -eq "posts.db"){

        #Determining the performer name based on the file path
        $performername = $pathToOriginalStashdb | split-path | split-path -leaf
        if ($performername -eq "metadata"){
            $performername = $pathToOriginalStashdb | split-path | split-path | split-path -leaf
        }

        $ConfirmPerformerName = read-host "`nIs '$performername' the correct OnlyFans username for this metadata database?`n`nAs an example, if the performer's OnlyFans page is 'www.onlyfans.com/JanePerformer',`nthen the username is janeperformer, NOT 'Jane Performer'.`n`nPlease enter [Y/N]"

        if($ConfirmPerformerName -eq "n" -or $ConfirmPerformerName -eq "no"){
            $performername = read-host "OK, what is the correct OnlyFans username for this metadata?"
            if ($performername -like "* *"){
                do{
                    write-host "`nOnlyFans usernames do not have spaces.`nAs an example, if the performer's OnlyFans page is 'www.onlyfans.com/janeperformer',`nthen the username is janeperformer, NOT 'Jane Performer'"
                    $performername = read-host "`nWhat is the correct OnlyFans username for this metadata?"
                }
                while ($performername -like "* *")
            }
        }
        write-host "`nA zip file named $performername.zip containing a sanitized copy of this OnlyFans metadata will be generated in the same folder as this script"
        read-host "Press [Enter] to begin"

        $pathToZipFile = $PSScriptRoot+$directorydelimiter+$performername+".zip"
        $pathtomodifiedstashdb = $PSScriptRoot+$directorydelimiter+"user_data.db"

        if (test-path $pathtomodifiedstashdb){
            write-host "Warning - Heads up, you have database file named user_data.db in the same directory as this script. If you continue, this script WILL overwrite it!" -ForegroundColor Cyan
            read-host "Press [Enter] to continue"
            read-host "You sure? Press [Enter] to continue"
        }

        if (test-path $pathToZipFile){
            write-host "Warning - Heads up, you have zip file named $performer.zip in the same directory as this script. If you continue, this script WILL overwrite it!" -ForegroundColor Cyan
            read-host "Press [Enter] to continue"
            read-host "You sure? Press [Enter] to continue"
        }
        try{
            Copy-Item $pathToOriginalStashdb -destination $PSScriptRoot -force
        }
        catch{
            write-host "Whoops, we may have had a permissions issue trying to copy the metadata database to the current folder. `nExiting..."
            exit
        }
        
        #Sanitizing the DB
        $Query = "DROP TABLE alembic_version; DROP TABLE messages; DROP TABLE others; DROP TABLE products; DROP TABLE stories; UPDATE medias SET directory = 'Z:\REDACTED\', link = 'www.onlyfans.com'; UPDATE posts SET price = 0, paid = 0, archived = 0;"
        Invoke-SqliteQuery -Query $Query -DataSource $pathtomodifiedstashdb

        #Zipping up the file
        Compress-Archive -Path $pathtomodifiedstashdb -DestinationPath $pathToZipFile -CompressionLevel NoCompression -Force
        
        #Deleting the modified db file now that its zipped
        remove-item $pathtomodifiedstashdb -force

        write-host "...Done! The metadata database was sanitized and $performername.zip was created!"
    }

    else{
        write-host "The metadata database should be defined as either user_data.db (default) or posts.db"
        write-host "If you personally used the DIGITALCRIMINALS OnlyFans Downloader, it's located under <performername>/metadata/"
    }
}
else{
    write-host "`nHmm...Looks like this is an invalid path.`nExiting..."
}