local files_updates = 0

local restart_packages = {}

function string:split(sep) -- http://lua-users.org/wiki/SplitJoin
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function check_if_restart()
   if files_updates==0 then
      if restart_packages[1] == nil then
         ServerExit("Applying update for autoupdater")
      else
      print("Applying updates")
      for i,v in ipairs(restart_packages) do
         StopPackage(v)

	      Delay(500, function()
		      StartPackage(v)
	      end)
      end

   end
   end
end

function get_latest_commit(link,packagename)
   local linksplit = link:split("://")
   local protocol = linksplit[1]
   local linksplit2 = link:split("/")
   local gitname = ""
   local reponame = ""
   for i,v in ipairs(linksplit2) do
      if (i ~= 1 and i ~= 2)  then 
         if gitname == "" then
             gitname=v
         elseif reponame == "" then
            reponame=v
         end
      end
   end
   if (gitname~="" and reponame~="") then
   local r = http_create()
   http_set_resolver_protocol(r, "any")
	http_set_protocol(r, protocol)
	http_set_host(r, "api.github.com")
	http_set_port(r, 443)
	http_set_verifymode(r, "verify_peer")
	http_set_target(r, "/repos/"..gitname.."/"..reponame.."/commits")
	http_set_verb(r, "get")
	http_set_timeout(r, 30000)
	http_set_version(r, 11)
	http_set_keepalive(r, false)
   http_set_field(r, "user-agent", "Onset Server "..GetGameVersionString())
   if http_send(r, OnGetCompletecommits, "Str L", 88.88, 1337,r,packagename) == false then
      print("Url " .. link .. " not found")
      http_destroy(r)
   end
   else
       print("Can't find the latest commit for " .. link)
   end
end

function auto_updater_http(link,isjson,packagename,path,isjsonautoupdater,needtorestart,reinstall)
   local linksplit = link:split("://")
   local protocol = linksplit[1]
   local linksplit2 = link:split("/")
   local target = ""
   for i,v in ipairs(linksplit2) do
      if (i ~= 1 and i ~= 2)  then 
         target=target.."/"..v
      end
   end
   local r = http_create()
	http_set_resolver_protocol(r, "any")
	http_set_protocol(r, protocol)
	http_set_host(r, "raw.githubusercontent.com")
	http_set_port(r, 443)
	http_set_verifymode(r, "verify_peer")
	http_set_target(r, target)
	http_set_verb(r, "get")
	http_set_timeout(r, 30000)
	http_set_version(r, 11)
	http_set_keepalive(r, false)
   http_set_field(r, "user-agent", "Onset Server "..GetGameVersionString())
   if not isjsonautoupdater then
   if isjson then
      if http_send(r, OnGetCompletejson, "Str L", 88.88, 1337,r,packagename,needtorestart,reinstall,link) == false then
		   print("Url " .. link .. " not found")
         http_destroy(r)
         if needtorestart then
         files_updates=files_updates-1
         end
      end
   else
      if http_send(r, OnGetCompletefile, "Str L", 88.88, 1337,r,packagename,path,needtorestart,reinstall) == false then
		   print("Url " .. link .. " not found , update for this file failed")
         http_destroy(r)
         if needtorestart then
            files_updates=files_updates-1
            end
      end
   end
else
   if http_send(r, OnGetCompleteautoupdater, "Str L", 88.88, 1337,r,packagename) == false then
      print("Url " .. link .. " not found , update for the autoupdater failed")
      http_destroy(r)
      files_updates=0
      searchupdatesallpackages(true,false)
   end
   end
end

function OnGetCompletejson(a, b, c,http,packagename,needtorestart,reinstall,link)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      print("Invalid link for " .. packagename)
      files_updates=files_updates-1
  else
   local body = http_result_body(http)
   local httppackage = json_decode(body)
   local package = io.open("packages/"..packagename.."/package.json", 'r') 
           if (package) then
               local contents = package:read("*a")
               local pack_tbl = json_decode(contents);
               io.close(package)
               if needtorestart then
               files_updates=files_updates-1
               end
               if (pack_tbl.version ~= httppackage.version or reinstall) then
                  if not reinstall then
                  print("Updating " .. packagename .. " " .. pack_tbl.version .. " ---> " .. httppackage.version)
                  else
                     print("Reinstalling " .. packagename .. " " .. httppackage.version)
                  end
                  table.insert(restart_packages,packagename)
                  if httppackage.auto_updater then
                     local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
                  if writejson then
                     writejson:write(body)
                     print("file package.json updated")
                     io.close(writejson)
                  end
                        if httppackage.server_scripts then
                           for i,v in pairs(httppackage.server_scripts) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                  auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end
                        if httppackage.client_scripts then
                           for i,v in pairs(httppackage.client_scripts) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end
                        if httppackage.files then
                           for i,v in pairs(httppackage.files) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end 
                     else
                        print("The auto updater support is not on github , update of " .. packagename .. " update will perform with the local package.json")
                        local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
                        if writejson then
                           pack_tbl.version = httppackage.version
                            writejson:write(json_encode(pack_tbl))
                            io.close(writejson)
                            print("changed version in package.json")
                        end
                        if pack_tbl.server_scripts then
                           for i,v in pairs(pack_tbl.server_scripts) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                  auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end
                        if pack_tbl.client_scripts then
                           for i,v in pairs(pack_tbl.client_scripts) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end
                        if pack_tbl.files then
                           for i,v in pairs(pack_tbl.files) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall)
                              end
                           end
                        end
                     end
                     get_latest_commit(link,packagename)
               else
                  print("No updates for " .. packagename)
               end
           end
         end
   http_destroy(http)
end

function OnGetCompletefile(a, b, c,http,packagename,path,needtorestart,reinstall)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      print("Invalid link for " .. packagename)
      if needtorestart then
         files_updates=files_updates-1
         check_if_restart()
         end
  else
   local body = http_result_body(http)
   local pathsplit = path:split(".")
   local lasti = 0
   for i,v in ipairs(pathsplit) do
      lasti=i
   end
      if (pathsplit[lasti] == "png" or pathsplit[lasti] == "jpg" or pathsplit[lasti] == "jpeg" or pathsplit[lasti] == "gif" or pathsplit[lasti] == "wav" or pathsplit[lasti] == "mp3" or pathsplit[lasti] == "ogg" or pathsplit[lasti] == "oga" or pathsplit[lasti] == "flac" or pathsplit[lasti] == "ttf" or pathsplit[lasti] == "woff2" or pathsplit[lasti] == "pak") then
         print("file " .. path .. " : unsupported format")
      else
   local file = io.open("packages/"..packagename.."/" .. path, 'w') 
   if file then
      file:write(body)
      if not reinstall then
      print("file " .. path .. " updated")
      else
         print("file " .. path .. " reinstalled")
      end
      io.close(file)
      if needtorestart then
         files_updates=files_updates-1
         check_if_restart()
         end
   else
      print("packages/"..packagename.."/" .. path .. " INVALID PATH, Please create it manually")
      if needtorestart then
         files_updates=files_updates-1
         check_if_restart()
         end
   end
end
end
   http_destroy(http)
end

function OnGetCompleteautoupdater(a, b, c,http,packagename)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      files_updates=files_updates-1
      print("Invalid link for " .. packagename)
      searchupdatesallpackages(true,false)
  else
   local body = http_result_body(http)
   local httppackage = json_decode(body)
   local file = io.open("packages/"..packagename.."/package.json", 'r') 
   if file then
      local contents = file:read("*a")
      local pack_tbl = json_decode(contents);
      io.close(file)
      files_updates=files_updates-1
      if pack_tbl.version ~= httppackage.version then
      print("Updating " .. packagename .. " " .. pack_tbl.version .. " ---> " .. httppackage.version)
      local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
      if writejson then
         writejson:write(body)
         print("file package.json updated")
         io.close(writejson)
      end
      if httppackage.server_scripts then
         for i,v in pairs(httppackage.server_scripts) do
            if httppackage.auto_updater[v] then
               files_updates=files_updates+1
                auto_updater_http(httppackage.auto_updater[v],false,packagename,v,false,true,false)
            end
         end
      end
      if httppackage.client_scripts then
         for i,v in pairs(httppackage.client_scripts) do
            if httppackage.auto_updater[v] then
               files_updates=files_updates+1
               auto_updater_http(httppackage.auto_updater[v],false,packagename,v,false,true,false)
            end
         end
      end
      if httppackage.files then
         for i,v in pairs(httppackage.files) do
            if httppackage.auto_updater[v] then
               files_updates=files_updates+1
               auto_updater_http(httppackage.auto_updater[v],false,packagename,v,false,true,false)
            end
         end
      end
   else
      searchupdatesallpackages(true,false)
   end
   else
      files_updates=files_updates-1
      print("INVALID AUTO_UPDATER PATH")
   end
end
   http_destroy(http)
end

function OnGetCompletecommits(a,b,c,http,packagename) 
   local body = http_result_body(http)
   local httppackage = json_decode(body)
   if (http_is_error(http) or httppackage.message == "Not Found") then
       print("Can't find the latest commit")
   else
      if httppackage[1].commit.message then
         print("Last commit message for " .. packagename .. " is " .. httppackage[1].commit.message)
      end
   end
   http_destroy(http)
end

function searchupdatesallpackages(needtorestart,reinstall)
   local file = io.open("server_config.json", 'r') 
   if (file) then 
       local contents = file:read("*a")
       local server_tbl = json_decode(contents);
       io.close(file)
       local packages_tbl = server_tbl.packages
   for k,v in pairs(packages_tbl) do
      local package = io.open("packages/"..v.."/package.json", 'r') 
      if (package) then
          local contents = package:read("*a")
          local pack_tbl = json_decode(contents);
          io.close(package)
          if pack_tbl.auto_updater then
             if pack_tbl.auto_updater["package.json"] then
                files_updates=files_updates+1 
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,v,nil,nil,needtorestart,reinstall)
             end
          end
      end
  end
end
end

AddEvent("OnPackageStart",function()
           local package = io.open("packages/"..GetPackageName().."/package.json", 'r') 
           if (package) then
               local contents = package:read("*a")
               local pack_tbl = json_decode(contents);
               io.close(package)
               if pack_tbl.auto_updater then
                  if pack_tbl.auto_updater["package.json"] then
                     files_updates=files_updates+1
                     auto_updater_http(pack_tbl.auto_updater["package.json"],false,GetPackageName(),nil,true)
                  end
               end
            else
               print("Critical error , can't find the package.json of the autoupdater")
           end
end)

function searchraws_http(link,isfirstcheck,ply,packagefile,host,path,packjsonpath)
   local linksplit = link:split("://")
   local protocol = linksplit[1]
   local linksplit2 = link:split("/")
   local target = ""
   local gitname = ""
   local reponame = ""
   for i,v in ipairs(linksplit2) do
      if (i ~= 1 and i ~= 2)  then 
         target=target.."/"..v
         if gitname == "" then
            gitname=v
         elseif reponame == "" then
            reponame=v
         end
      end
   end
   if (reponame~= nil and gitname~=nil and reponame~= "" and gitname~="" and reponame~= " " and gitname~=" ") then
   local r = http_create()
	http_set_resolver_protocol(r, "any")
	http_set_protocol(r, protocol)
	http_set_host(r, host)
	http_set_port(r, 443)
	http_set_verifymode(r, "verify_peer")
	http_set_target(r, target)
	http_set_verb(r, "get")
	http_set_timeout(r, 30000)
	http_set_version(r, 11)
	http_set_keepalive(r, false)
   http_set_field(r, "user-agent", "Onset Server "..GetGameVersionString())
   if isfirstcheck then
      if http_send(r, OnGetCompletecheck, "Str L", 88.88, 1337,r,gitname,reponame,ply,packagefile,protocol,packjsonpath) == false then
		   print("Url " .. link .. " not found")
		   http_destroy(r)
      end
   else
      if http_send(r, OnGetCompletenewraw, "Str L", 88.88, 1337,r,ply,path,link,packjsonpath) == false then
		   print("Url " .. link .. " not found")
		   http_destroy(r)
      end
   end
else
   AddPlayerChat(ply,"Invalid link")
end
end

function makelink(path,gitname,reponame,ply,protocol,packjsonpath)
   local link = protocol.."://".."raw.githubusercontent.com".."/"..gitname.."/"..reponame.."/master/"..path
   searchraws_http(link,false,ply,nil,"raw.githubusercontent.com",path,packjsonpath)
end

function OnGetCompletecheck(a,b,c,http,gitname,reponame,ply,packagefile,protocol,packjsonpath)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
       AddPlayerChat(ply,"Invalid link")
   else
      makelink("package.json",gitname,reponame,ply,protocol,packjsonpath)
      if packagefile.server_scripts then
         for i,v in pairs(packagefile.server_scripts) do
            makelink(v,gitname,reponame,ply,protocol,packjsonpath) 
         end
      end
      if packagefile.client_scripts then
         for i,v in pairs(packagefile.client_scripts) do
            makelink(v,gitname,reponame,ply,protocol,packjsonpath)        
         end
      end
      if packagefile.files then
         for i,v in pairs(packagefile.files) do
            local pathsplit = v:split(".")
            local lasti = 0
            for i,v in ipairs(pathsplit) do
               lasti=i
            end
          if (pathsplit[lasti] == "html" or pathsplit[lasti] == "htm" or pathsplit[lasti] == "css" or pathsplit[lasti] == "js") then
            makelink(v,gitname,reponame,ply,protocol,packjsonpath)  
          end
         end
      end
   end
   http_destroy(http)
end

function OnGetCompletenewraw(a,b,c,http,ply,path,link,packjsonpath)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      AddPlayerChat(ply,"Error link " .. link)
  else
     local packagefilee = io.open(packjsonpath, 'r') -- reopen it every time to load changes
         if packagefilee then
            local contents = packagefilee:read("*a")
            local packagefile = json_decode(contents);
            io.close(packagefilee)
            if packagefile.auto_updater then
               packagefile.auto_updater[path] = link
            else
                packagefile.auto_updater = {}
                packagefile.auto_updater[path] = link
            end
            local file = io.open(packjsonpath, 'w')
            if file then
               local contents = json_encode(packagefile)
               file:write(contents)
               AddPlayerChat(ply,"Saved auto_updater support path : " .. path.."  ".." link found : ".. link .. " restart to check updates")
               io.close(file)
            end
         end
  end
  http_destroy(http)
end

function checkadmin(ply)
   local file = io.open("packages/"..GetPackageName().."/admins.json", 'r') 
   if (file) then 
      local contents = file:read("*a")
      local admins_tbl = json_decode(contents);
      io.close(file)
      local isadmin = false
      for i,v in ipairs(admins_tbl) do
         if v == tostring(GetPlayerSteamId(ply)) then
            isadmin=true
            return true
         end
      end
      if isadmin == false then
         return false
      end
   else
      local tbltoencode = {
         "steamid"
      }  
      local file = io.open("packages/"..GetPackageName().."/admins.json", 'w')
      if file then
         local contents = json_encode(tbltoencode)
         file:write(contents)
         AddPlayerChat(ply,"admin.json file created in " .. "packages/"..GetPackageName().." please add admins restart the server and retry the command")
         io.close(file)
      end
      return nil
   end
end

AddCommand("searchraws",function(ply,package,repolink)
   if (package~=nil and repolink~=nil and package~="" and repolink~="" and package~=" " and repolink~=" ") then
   local isadmin = checkadmin(ply)
      if (isadmin == false or isadmin == nil) then
          AddPlayerChat(ply,"You are not admin")
      else
         local packagefilee = io.open("packages/"..package.."/package.json", 'r') 
         if packagefilee then
            local contents = packagefilee:read("*a")
            local packagefile = json_decode(contents);
            io.close(packagefilee)
            if packagefile.auto_updater then
               AddPlayerChat(ply,"This package already supports auto updater")
            else
                searchraws_http(repolink,true,ply,packagefile,"github.com",nil,"packages/"..package.."/package.json")
            end
         else
            AddPlayerChat(ply,"Package not found")
         end
      end
else
   AddPlayerChat(ply,"/searchraws <packagename> <repolink>")
end
end)

AddCommand("reinstall",function(ply,packagename)
   local isadmin = checkadmin(ply)
      if (isadmin == false or isadmin == nil) then
          AddPlayerChat(ply,"You are not admin")
      else
    if (packagename ~= nil and packagename ~= "" and packagename ~= " ") then
      local package = io.open("packages/"..packagename.."/package.json", 'r') 
      if (package) then
          local contents = package:read("*a")
          local pack_tbl = json_decode(contents);
          io.close(package)
          if pack_tbl.auto_updater then
             if pack_tbl.auto_updater["package.json"] then
               AddPlayerChat(ply,"Please restart the server after that (when the server console stop printing things) to apply changes")
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,packagename,nil,false,false,true)
             end
            else
               AddPlayerChat(ply,"This package does not support auto_updater")
          end
       else
          print("Package not found")
      end
   else
      AddPlayerChat(ply,"Please restart the server after that (when the server console stop printing things) to apply changes")
      searchupdatesallpackages(false,true)
    end
   end
end)

AddCommand("searchupdates",function(ply,packagename)
   local isadmin = checkadmin(ply)
      if (isadmin == false or isadmin == nil) then
          AddPlayerChat(ply,"You are not admin")
      else
    if (packagename ~= nil and packagename ~= "" and packagename ~= " ") then
      local package = io.open("packages/"..packagename.."/package.json", 'r') 
      if (package) then
          local contents = package:read("*a")
          local pack_tbl = json_decode(contents);
          io.close(package)
          if pack_tbl.auto_updater then
             if pack_tbl.auto_updater["package.json"] then
               AddPlayerChat(ply,"Please restart the server after that (when the server console stop printing things) to apply changes (if files were updated (server console))")
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,packagename,nil,false,false,false)
             end
            else
               AddPlayerChat(ply,"This package does not support auto_updater")
          end
       else
          print("Package not found")
      end
   else
      AddPlayerChat(ply,"Please restart the server after that (when the server console stop printing things) to apply changes (if files were updated (server console))")
      searchupdatesallpackages(false,false)
    end
   end
end)