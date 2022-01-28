# OnlyFans Metadata to Stash Database Powershell Script
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

Don't have an Onlyfans metadata database file? _No problem!_ This script can associate performer names/studio based on file paths as well!

**Bonus Utility**: 

The `OFMetadataDatabase_Sanitizer` script in the Utilities folder will happily scrub all tables and redact filepaths of any information not relevant purely to tagging. This makes sharing your OnlyFans Database with others **far** less potentially sensitive! 🙂

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
