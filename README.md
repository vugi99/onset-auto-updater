# onset-auto-updater

#### Informations
* All my packages are now compatible with onset-auto-updater , you need to download the autoupdater support manually to activate the auto updates for all my packages
* onset-auto-updater will search for updates when the server starts for each packages loaded (if they supports onset-auto-updater)
* if nothing is printed by the script , nothing was updated (on server start)
* You need to restart the server to apply changes WARNING : if a new file in a package is created you need to restart the server 2 times

#### Bug
* If you are the developer don't bump the version on your server if you are developping a package that supports onset-auto-updater or until the raw.githubusercontent.com is updated ~ 10 mins after git push
* If you are a user that installed an update less than 10 mins from the git push the auto-updater will revert changes because raw.githubusercontent.com take ~ 10 mins to update and will re-update it if you re-launch your server when raw.githubusercontent.com is updated

#### How to support onset-auto-updater for developers
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