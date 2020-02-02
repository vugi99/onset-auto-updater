# onset-auto-updater

#### Informations
* All my packages are now compatible with onset-auto-updater , you need to download the autoupdater support manually to activate the auto updates for all my packages
* onset-auto-updater will search for updates when the server starts for each packages loaded (if they supports onset-auto-updater)
* if nothing is printed by the script , nothing was updated (on server start or when doing commands)
* You need to restart the server to apply changes (automatically stopped at start if there are new updates) WARNING : if a new file in a package is created in a new directory (it will print INVALID PATH) and you need to make the path and download the files in this path manually or modifying the version in the package.json to re-download the update 

#### Bug
* If you are the developer don't bump the version on your server if you are developping a package that supports onset-auto-updater or until the raw.githubusercontent.com is updated ~ 10 mins after git push
* If you are a user that installed an update less than 10 mins from the git push the auto-updater will revert changes because raw.githubusercontent.com take ~ 10 mins to update and will re-update it if you re-launch your server when raw.githubusercontent.com is updated

#### Admins (admins.json) commands
* /searchupdates (package that supports auto-updater optional) - if no args are given it will search updates like when you are starting your server (all changes printed in the console) you need to restart if updates were downloaded , if the package arg is given it will search for updates for the given package
* /reinstall (package that supports auto-updater optional) - if no args are given it will reinstall all packages that supports auto-updater from github (all changes printed in the console) you need to restart the server to apply changes , if the package arg is given it will reinstall the given package (you need to restart the server to apply changes)

#### How to support onset-auto-updater AUTOMATICALLY for developers
* do /searchraws (package_name) (github repo link) - the github repo link is something like https://github.com/name/repo_name , it will add and save required links (only master branch) to the package.json and print in the chat saved paths and links , please check them before releasing the support , you need to restart the server to check updates
* Don't forget to bump the version in the package.json at each release or the update won't be downloaded

#### How to support onset-auto-updater MANUALLY for developers
* To support onset-auto-updater you need to add things in the package.json
* How to get raw links : you need to go on the script on github and click on raw then copy the link
* You need to add a "auto_updater" table like (example)
```lua
"auto_updater": {
           "package.json": "https://raw.githubusercontent.com/vugi99/onset-justdrive/master/package.json",
           "server/justdrive.lua": "https://raw.githubusercontent.com/vugi99/onset-justdrive/master/server/justdrive.lua",
           "client/cl_justdrive.lua": "https://raw.githubusercontent.com/vugi99/onset-justdrive/master/client/cl_justdrive.lua"
        }
```
* It's always "file path": "raw link",
* Put the package.json path and raw first or it won't work 
* And add other scripts and files 
* Don't forget to bump the version in the package.json at each release or the update won't be downloaded
* Don't bump the version on your server if you are developping a package that supports onset-auto-updater or until the raw.githubusercontent.com is updated ~ 10 mins after git push