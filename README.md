# OnlyFans Metadata to Stash Database Powershell Script
This Powershell script can (batch) import OnlyFans metadata into a [Stash Database](https://github.com/stashapp/stash) from a OnlyFans metadata database scraped using [DIGITALCRIMINALS's OnlyFans Scraper](https://github.com/DIGITALCRIMINALS/OnlyFans) or other compatible scraper.

<img src="/readme_assets/mainmenu.png" width=50% height=50%><img src="/readme_assets/oldtonew.png" width=46% height=46%>

### OnlyFans Metadata Database Sanitization: 

- Want to exchange your metadata database with someone else but need a sanitized version?
  This script can happily produce a database clone of your choosing with all filepaths/personal information completely redacted.

### Additional Notes: 

- If you don't have a metadata database available to you, this script can still associate performer names based on your file system.

- To be crystal clear, this script **does _not_ access the internet, download, or scrape any metadata from any website**. <br>
If you want all available metadata for a given performer, you **must** already have this metadata file in your posession.


# Requirements
  - Fully tested on Stash v0.18 using DC OnlyFans Script v7.6.1 (and other scrapers using that schema) on the following operating systems
    -  **Windows 11** with Windows Powershell 7.3.1
    -  **Linux** using Powershell Core (both ARM and x86 releases tested)
    -  **macOS** using Powershell Core
  - The Powershell module "PSSQLite" must be installed https://github.com/RamblingCookieMonster/PSSQLite
    * From the respository linked above, download a zip of the PSSQlite folder. Extract it wherever you like.
    * In the folder you extracted PSSQLite to, open a Powershell prompt (in Administrative mode) in that directory
    * Run the command `install-module pssqlite` followed by the command `import-module pssqlite`

# How to Run
- If you aren't on Windows (or are on anything older than Windows 10), install Powershell Core, available for Linux and macOS!
- Ensure you've installed PSSQLite as described in the section above
- Download the latest release of this script
- Open Powershell in the directory of this script and run the command `.\ofmetadatatostash.ps1` to be guided through the short setup configuration wizard
