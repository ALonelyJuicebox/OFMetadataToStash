# OFMetadataToStash
Using the metadata database from DC's script, imports metadata such as the URL, post associated text, and creation date into your stash DB


# Requirements
  - Metadata database must be from DC's script
  - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
  -
  - Download a zip of the PSSQlite folder in that repo, extract it, run an Admin window of Powershell
       in that directory then run 'install-module pssqlite' followed by the command 'import-module pssqlite'
  - You MUST change the paths to both your stash db and to the OnlyFans metadata db on the first two lines of this script.
    Otherwise, it won't know what metadata to import, nor what stash database to import data to. 
    
    Cheers!
