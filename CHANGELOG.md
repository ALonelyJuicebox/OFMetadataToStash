**0.5 Release (12/7/2023)**
-  **Feature** - Total refactor! Script now uses GraphQL to communicate with Stash. No more reliance on SQL queries running afoul of Stash schemaa changes!
-  **Known Bug** - Haven't gotten around to refactoring the "No Metadata Database" mode.
-  **Known Bug** - Setting the "match" mode to "High" may result in fewer matches than it should.

**0.4 Release (1/3/2023)**
-  **Feature** - Now supports the new Stash 0.18 schema which contains significant upgrades to how files are handled in Stash (phew!)
-  **Feature** - Script now helps you build out the config file, no need to edit the config file manually unless you want to.
-  **Feature** - Script will now tell you if your Stash database is compatible, with verbose user feedback
-  **Feature** - For Windows users, script now supports the use of File Explorer when selecting DBs and folders
-  **Feature** - You can now customize how specific the script will be when it comes to matching your data! As a result, significant speed improvements!
-  **Feature** - Full Docker support (as long as you use "normal" or "low" metadata matching modes)
-  **Feature** - Script now just adds metadata to all matches rather than attempt to track duplicates as it did before
-  **Bugfix**  - No longer modifies the OF DB at any point
-  **Bugfix**  - Script now imports metadata for media that was sent to the user via a Message
-  **Bugfix**  - Database Sanitizer script now runs VACUUM command to further ensure the generated (and sanitized) copy is truly sanitized

**0.3 Release (1/5/2022)**
-  **Feature** - Includes a OnlyFans Metadata Database Sanitizer utility to generate a completely scrubbed/redacted copy of a given OnlyFans Metadata database for sharing purposes!
-  **Feature** - Image support!
-  **Feature** - Support for detecting and updating performer name/studio for files even if a metadata database isn't available!
-  **Feature** - Now updates the OnlyFans DB if Stash has a more up to date location for a given file, making future queries faster
-  **Feature** - Performer name detection is now MUCH more flexible and can handle numerous scenarios 
-  **Feature** - Added elapsed time for script duration
-  **Feature** - External config file(!) and several other additions to work towards supporting across platforms in the next release!
-  **Bugfix** - Since the DIGITALCRIMINALS script grabs GIFS as videos, this script now accounts for that and stores them as images
-  **Bugfix** - Studio and Performers weren't being properly created due to missing column information (md5 hash)
-  **Bugfix** - Speed improvements

**0.2 Release (1/5/2022)**
- Now with Batch Processing! Just set your metadata path to the parent directory of your OnlyFans databases and choose your preference within the script!
- Auto Performer/Scene association
- Auto Performer creation if name or alias cannot be found
- Auto Studio association/creation for OnlyFans
- Better auto detection for moved files that are no longer in the OnlyFans DB
- Bug fixes
- Output logs for various potentially common issues
