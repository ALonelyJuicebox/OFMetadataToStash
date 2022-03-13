# OnlyFans Metadata to Stash Database Powershell Script
<img src="/readme_assets/oldtonew.png" width=60% height=60%>

Using the OnlyFans metadata database from DIGITALCRIMINALS's OnlyFans Download Scraper, this script imports metadata into your Stash DB such as:
- Title information based on the Performer name
- Performer URL
- URL of the post itself
- Details (Performer authored text associated with a given video)
- Creation date of the post
- (Image/Scene) x Performer association
- (Image/Scene) x Studio association

To be clear, this script does _not_ download any metadata from any website. 
If want all available metadata, you must already have this metadata file in your posession.

This script can associate performer names/studio based on file paths as well (if you don't have a metadata database to use)

### Additional Utilities: 

**OnlyFans Metadata Database Sanitizer** 

- Want to exchange your metadatabase with someone else but need a santized version without any potentially identifiable/unrelated information in it?
  The `OFMetadataDatabase_Sanitizer` script in the Utilities folder will happily produce a clone of the database of your choosing with filepaths/any information not relevant purely to tagging completely redacted.

# Requirements
  - Fully tested on Stash v0.11 using DC OnlyFans Script v7.6.1 on the following operating systems
    -  **Windows 10** with Windows Powershell (Built-in)
    -  **Linux** using Powershell Core (both ARM and x86 releases tested)
    -  **macOS** using Powershell Core
  - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
    * From the respository linked above, download a zip of the PSSQlite folder. Extract it wherever you like.
    * In the folder you extracted PSSQLite to, open a Powershell prompt (in Administrative mode) in that directory
    * Run the command `install-module pssqlite` followed by the command `import-module pssqlite`

# How to Run
- If you aren't on Windows (or are on anything older than Windows 10), install Powershell Core, available for Linux and macOS!
- Ensure you've installed PSSQLite as described in the section above
- Download the latest release, making sure to edit `OFMetadataToStash_Config` to define where your OnlyFans content is, as well as the location of your Stash Database file
- Open Powershell, and run the command `.\ofmetadatatostash.ps1`
