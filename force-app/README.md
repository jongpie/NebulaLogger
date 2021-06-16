This folder is used as the default folder by SFDX specifically so that no unwanted metadata accidentally gets added to the Nebula Logger packages.

-   Any metadata in this folder (`./force-app/`) can be deployed to your scratch org, but all files are ignored in `.gitignore`
-   Any metadata that needs to be added to the unlocked package should be moved to the folder `./nebula-logger/`
