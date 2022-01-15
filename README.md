# OnlyFans Metadata to Stash Database PoSH Script
Using the OnlyFans metadata database from DIGITALCRIMINALS's OnlyFans Download Scraper, this script imports metadata into your Stash DB such as...
- Title information based on the Performer name
- Performer URL
- URL of the post itself
- Performer authored text associated with a given video
- Creation date of the post
- (Image/Scene) x Performer association
- (Image/Scene) x Studio association

To be clear, this script _does not download any metadata from any website_. 
You must already have this metadata file in your posession.

Don't have an Onlyfans metadata database file? **No problem!** This script can associate performer names/studio based on file paths as well!

# Requirements
  - Tested on Windows 10 with Stash v11 using DC Script v7.6.1
  - Metadata database must be from DC's script
  - Since Powershell cannot natively query SQLite databases, the Powershell module "PSSQLite" must first be installed https://github.com/RamblingCookieMonster/PSSQLite
    * From the respository linked above, download a zip of the PSSQlite folder. Extract it wherever you like.
    * In the folder you extracted PSSQLite to, open a Powershell prompt (in Administrative mode) in that directory
    * Run the command `install-module pssqlite` followed by the command `import-module pssqlite`
    * All set!
  - Don't forget! Be sure to edit the first two file paths in the `OFMetadataToStash_Config` configuration file to define where your Onlyfans content is, as well as the location of your Stash database file.

# How to Run
- Download OFMetadataToStash.ps1 from this repository.
- Ensure you've followed everything in the requirements section above
- Open Powershell, and run the command `.\ofmetadatatostash.ps1`
