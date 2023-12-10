<#
---OnlyFans Metadata Database Sanitizer PoSH Script 0.7---

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
 write-host "- OnlyFans Metadata DB to Stash PoSH Script 0.7 - `n(https://github.com/ALonelyJuicebox/OFMetadataToStash)`n" -ForegroundColor cyan
 write-host "Database Sanitization Tool"
 write-host "--------------------------------`n"
 
 write-host "- Quick Tips - "
 write-host "* Your original metadata database will NOT be modified in any way."
 write-host "* The metadata database should be defined as either user_data.db (default) or posts.db"
 write-host "* This file is (typically) located under <performername>/metadata/`n"
 
 do{
     #Providing some user feedback if we tested the path and it came back as invalid
     if($null -ne $PathToOnlyFansDB){
         write-host "Oops. Invalid filepath"
     }
     if($IsWindows){
         read-host "Press [Enter] to select a OnlyFans Metadata Database File (user_data.db)"
 
         #Using Windows File Explorer instead of forcing the user to copy/paste the path into the terminal
         Add-Type -AssemblyName System.Windows.Forms
         $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ 
            Filter = 'OnlyFans Metadata Database File (*.db)|*.db'
         }
         $null = $FileBrowser.ShowDialog()
         $PathToOnlyFansDB = $FileBrowser.filename
     }
     else{
         $PathToOnlyFansDB = read-host "Enter the location of the OnlyFans Database File (user_data.db) you want to clone and create a sanitized version of"
     }
 }
 while(!(test-path $PathToOnlyFansDB))
 
 
 
 
 
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
 
     if((split-path $PathToOnlyFansDB -leaf) -eq "user_data.db" -or (split-path $PathToOnlyFansDB -leaf) -eq "posts.db"){
 
         #Determining the performer name based on the file path
         $performername = $PathToOnlyFansDB | split-path | split-path -leaf
         if ($performername -eq "metadata"){
             $performername = $PathToOnlyFansDB | split-path | split-path | split-path -leaf
         }
 
        write-host "Is '$performername' the correct OnlyFans username for this metadata database?`n`n(As an example, if the performer's OnlyFans page is 'www.onlyfans.com/JanePerformer',`nthen the username is janeperformer, NOT 'Jane Performer')."
        do {
            $userselection = read-host "`nPlease enter [Y/N]"
        }
        while (($userselection -notlike "Y*" -and $username -notlike "N*"))

        if($ConfirmPerformerName -like "n*"){
            $performername = read-host "OK, what is the correct OnlyFans username for this metadata?"

            #We don't want spaces in our names-- lets inform the user of this
            if ($performername -like "* *"){
                do{
                    write-host "`nOnlyFans usernames do not have spaces.`nAs an example, if the performer's OnlyFans page is 'www.onlyfans.com/janeperformer',`nthen the username is janeperformer, NOT 'Jane Performer'"
                    $performername = read-host "`nWhat is the correct OnlyFans username for this metadata?"
                }
                while ($performername -like "* *")
            }
        }


         $storagelocation = $PSScriptRoot+$directorydelimiter+"Sanitized DBs"
         if (!(test-path -Path $storagelocation)){
            New-Item -Path $PSScriptRoot -Name "Sanitized DBs" -ItemType "directory" | out-null
         }
         
         $pathToZipFile = $storagelocation+$directorydelimiter+$performername+".zip"
         $sanitizedOFDB = $storagelocation+$directorydelimiter+"user_data.db"

         write-host "`nA zip file named $performername.zip containing a sanitized copy of this OnlyFans metadata will be generated in the following path"
         write-host $pathToZipFile
         read-host "`nPress [Enter] to begin"
 
         if (test-path $sanitizedOFDB){
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
             Copy-Item $PathToOnlyFansDB -destination $sanitizedOFDB -force
         }
         catch{
             write-host "Whoops, we may have had a permissions issue trying to copy the metadata database to the current folder. `nExiting..."
             exit
         }
         
         #Sanitizing the DB
         $Query = "DELETE FROM alembic_version; DELETE FROM messages; DELETE FROM others; DELETE FROM products; DELETE FROM stories; UPDATE medias SET directory = 'Z:\REDACTED\', link = 'www.onlyfans.com'; UPDATE posts SET price = 0, paid = 0, archived = 0; VACUUM"
         Invoke-SqliteQuery -Query $Query -DataSource $sanitizedOFDB
 
         #Zipping up the file because we want to keep naming it "user_data.db"
         Compress-Archive -Path $sanitizedOFDB -DestinationPath $pathToZipFile -CompressionLevel NoCompression -Force
         
         #Deleting the modified db file now that its zipped
         remove-item $sanitizedOFDB -force
 
         write-host "...Done! `nA cloned metadata database was created, sanitized and $performername.zip was created!"
     }
 
     else{
         write-host "Hmm...not quite. The metadata database should be defined as either user_data.db (default) or posts.db, "
         write-host "with a folder structure of <performername>/metadata/"
     }