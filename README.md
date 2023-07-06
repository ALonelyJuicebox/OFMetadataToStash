<h1 align="center">OnlyFans Metadata to Stash Powershell Script</h1>

**OFMetadataToStash** is an OnlyFans metadata import tool for Stash, written in Powershell.

* Simple to use with a straightforward command line based UI!
* Script can auto-associate scenes/images with the appropriate OnlyFans performer(s) and studio, in batch!
* Built-in utility for completely scrubbing and sanitizing OnlyFans metadata databases
  
<img src="/readme_assets/mainmenu.png" width=50% height=50%><img src="/readme_assets/oldtonew.png" width=46% height=46%>

## 🍦 How it Works
- This script primarily relies on the SQLIte files (`user_data.db`) an OnlyFans scraper generates containing all the metadata you might want.
- This script does **not** access/scrape/download/or otherwise pull down metadata from OnlyFans or any other service.
- That said, if you don't have metadata DB files, this script _can_ try and make a good guess as your performers and associated content based on file path

## 💻 Requirements
- Stash v0.21.0 ([Released 6/13/2023](https://github.com/stashapp/stash/releases/tag/v0.21.0))
- Any major operating system (Windows/macOS/Linux) running [Microsoft Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
- The [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite) Powershell module


## 📖 Installation Guide

1. Ensure the latest version of [Microsoft Powershell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3) is installed. 
2.  The [PSSQLite](https://github.com/RamblingCookieMonster/PSSQLite) Powershell module has to be installed
    * From the respository linked above, download a zip of the PSSQlite folder. Extract it wherever you like.
    * In the folder you extracted PSSQLite to, open a Powershell prompt (in Administrative mode) in that directory
    * Run the command `install-module pssqlite` followed by the command `import-module pssqlite`
3. Download the [latest release of OFMetadataToStash](https://github.com/ALonelyJuicebox/OFMetadataToStash/releases) from this repository
4. Extract the ZIP file
5. Open a Powershell prompt in the same directory as the script and run the command `.\ofmetadatatostash.ps1` to start the short configuration wizard
