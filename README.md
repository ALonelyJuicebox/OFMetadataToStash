# OnlyFans Metadata to Stash Database PoSH Script
Using the OnlyFans metadata database from DC's script, this script imports metadata into your Stash DB such as...
- Title information based on the Performer name
- Performer URL
- Performer authored text associated with a given video
- Creation date of the post

To be clear, this script _does not download any metadata from any website_. 
You must already have this metadata file in your posession.

# Requirements
  - Metadata database must be from DC's script
  - Since Powershell cannot natively query SQLite databases, the Powershell module "PSSQLite" must first be installed https://github.com/RamblingCookieMonster/PSSQLite
    * From the respository linked above, download a zip of the PSSQlite folder. Extract it wherever you like.
    * In the folder you extracted PSSQLite to, open a Powershell prompt (in Administrative mode) in that directory
    * Run the command `install-module pssqlite` followed by the command `import-module pssqlite`
    * All set!
  - Be sure to edit the file paths for the following under `USER DEFINED VARIABLES` at the very top of this PS1 file.
    - Your Stash database (`stash-go.sqlite`)
    - The OnlyFans metadata database (`user_data.db`) for this particular performer   

# How to run
- Open Powershell, and run the command `.\ofmetadatatostash.ps1`.
    
    Cheers!
