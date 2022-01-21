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
