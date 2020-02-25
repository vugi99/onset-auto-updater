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
         auto_updater_log("Applying updates")
      for i,v in ipairs(restart_packages) do
         StopPackage(v)

	      Delay(500, function()
		      StartPackage(v)
	      end)
      end

   end
   end
end

function auto_updater_log(msg,ply)
   print(msg)
   if ply then
      AddPlayerChat(ply,msg)
   end
   local logfile = io.open("auto_updater_logs.txt", 'r') 
   local logs = nil
   if logfile then
       logs = logfile:read("*a")
       io.close(logfile)
   end
   local lfilew = io.open("auto_updater_logs.txt", 'w') 
   local date = os.date()
   local strtowrite = ""
   if not logs then
      strtowrite = date .. " / " .. msg .. "\n"
   else
      strtowrite = logs .. date .. " / " .. msg .. "\n"
   end
   lfilew:write(strtowrite)
   io.close(lfilew)
end

function get_latest_commit(link,packagename,print_ply)
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
   if http_send(r, OnGetCompletecommits, "Str L", 88.88, 1337,r,packagename,print_ply) == false then
      auto_updater_log("Url " .. link .. " not found",print_ply)
      http_destroy(r)
   end
   else
      auto_updater_log("Can't find the latest commit for " .. link,print_ply)
   end
end

function auto_updater_http(link,isjson,packagename,path,isjsonautoupdater,needtorestart,reinstall,print_ply)
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
      if http_send(r, OnGetCompletejson, "Str L", 88.88, 1337,r,packagename,needtorestart,reinstall,link,print_ply) == false then
		   auto_updater_log("Url " .. link .. " not found",print_ply)
         http_destroy(r)
         if needtorestart then
         files_updates=files_updates-1
         end
      end
   else
      if http_send(r, OnGetCompletefile, "Str L", 88.88, 1337,r,packagename,path,needtorestart,reinstall,print_ply) == false then
		   auto_updater_log("Url " .. link .. " not found , update for this file failed",print_ply)
         http_destroy(r)
         if needtorestart then
            files_updates=files_updates-1
            end
      end
   end
else
   if http_send(r, OnGetCompleteautoupdater, "Str L", 88.88, 1337,r,packagename) == false then
      auto_updater_log("Url " .. link .. " not found , update for the autoupdater failed")
      http_destroy(r)
      files_updates=0
      searchupdatesallpackages(true,false)
   end
   end
end

function OnGetCompletejson(a, b, c,http,packagename,needtorestart,reinstall,link,print_ply)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      auto_updater_log("Invalid link for " .. packagename,print_ply)
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
                     auto_updater_log("Updating " .. packagename .. " " .. pack_tbl.version .. " ---> " .. httppackage.version,print_ply)
                  else
                     auto_updater_log("Reinstalling " .. packagename .. " " .. httppackage.version,print_ply)
                  end
                  table.insert(restart_packages,packagename)
                  if httppackage.auto_updater then
                     local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
                  if writejson then
                     writejson:write(body)
                     auto_updater_log("file package.json updated",print_ply)
                     io.close(writejson)
                  end
                        if httppackage.server_scripts then
                           for i,v in pairs(httppackage.server_scripts) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                  auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end
                        if httppackage.client_scripts then
                           for i,v in pairs(httppackage.client_scripts) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end
                        if httppackage.files then
                           for i,v in pairs(httppackage.files) do
                              if httppackage.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(httppackage.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end 
                     else
                        auto_updater_log("The auto updater support is not on github , update of " .. packagename .. " update will perform with the local package.json",print_ply)
                        local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
                        if writejson then
                           pack_tbl.version = httppackage.version
                            writejson:write(json_encode(pack_tbl))
                            io.close(writejson)
                            auto_updater_log("changed version in package.json",print_ply)
                        end
                        if pack_tbl.server_scripts then
                           for i,v in pairs(pack_tbl.server_scripts) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                  auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end
                        if pack_tbl.client_scripts then
                           for i,v in pairs(pack_tbl.client_scripts) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end
                        if pack_tbl.files then
                           for i,v in pairs(pack_tbl.files) do
                              if pack_tbl.auto_updater[v] then
                                 if needtorestart then
                                 files_updates=files_updates+1
                                 end
                                 auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v,nil,needtorestart,reinstall,print_ply)
                              end
                           end
                        end
                     end
                     get_latest_commit(link,packagename,print_ply)
               else
                  auto_updater_log("No updates for " .. packagename,print_ply)
               end
           end
         end
   http_destroy(http)
end

function OnGetCompletefile(a, b, c,http,packagename,path,needtorestart,reinstall,print_ply)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      auto_updater_log("Invalid link for " .. packagename,print_ply)
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
         auto_updater_log("file " .. path .. " : unsupported format",print_ply)
      else
   local file = io.open("packages/"..packagename.."/" .. path, 'w') 
   if file then
      file:write(body)
      if not reinstall then
         auto_updater_log("file " .. path .. " updated",print_ply)
      else
         auto_updater_log("file " .. path .. " reinstalled",print_ply)
      end
      io.close(file)
      if needtorestart then
         files_updates=files_updates-1
         check_if_restart()
         end
   else
      local path_bef = 'packages/'..packagename..'/' .. path
      local splited_path = path_bef:split("/")
      local r_path = ""
      for i,v in ipairs(splited_path) do
         if i < #splited_path then
            if i == 1 then
               r_path = v
            else
               r_path = r_path .. "/" .. v
            end
         end
      end
      auto_updater_log(r_path .. " CREATING THE PATH",print_ply)
      local path_ = '"' .. r_path .. '"'
      os.execute("mkdir " .. path_)
      OnGetCompletefile(a, b, c,http,packagename,path,needtorestart,reinstall,print_ply)
   end
end
end
   http_destroy(http)
end

function OnGetCompleteautoupdater(a, b, c,http,packagename)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      files_updates=files_updates-1
      auto_updater_log("Invalid link for " .. packagename)
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
         auto_updater_log("Updating " .. packagename .. " " .. pack_tbl.version .. " ---> " .. httppackage.version)
      local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
      if writejson then
         writejson:write(body)
         auto_updater_log("file package.json updated")
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
      auto_updater_log("INVALID AUTO_UPDATER PATH")
   end
end
   http_destroy(http)
end

function OnGetCompletecommits(a,b,c,http,packagename,print_ply) 
   local body = http_result_body(http)
   local httppackage = json_decode(body)
   if (http_is_error(http) or httppackage.message == "Not Found") then
      auto_updater_log("Can't find the latest commit",print_ply)
   else
      if httppackage[1].commit.message then
         auto_updater_log("Last commit message for " .. packagename .. " is " .. httppackage[1].commit.message,print_ply)
      end
   end
   http_destroy(http)
end

function searchupdatesallpackages(needtorestart,reinstall,print_ply)
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
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,v,nil,nil,needtorestart,reinstall,print_ply)
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
               auto_updater_log("Critical error , can't find the package.json of the autoupdater")
           end
end)

function searchraws_http(link,isfirstcheck,ply,packagefile,host,path,packjsonpath,ispredicted)
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
      if http_send(r, OnGetCompletecheck, "Str L", 88.88, 1337,r,gitname,reponame,ply,packagefile,protocol,packjsonpath,ispredicted) == false then
		   auto_updater_log("Url " .. link .. " not found")
		   http_destroy(r)
      end
   else
      if http_send(r, OnGetCompletenewraw, "Str L", 88.88, 1337,r,ply,path,link,packjsonpath,ispredicted) == false then
		   auto_updater_log("Url " .. link .. " not found")
		   http_destroy(r)
      end
   end
else
   auto_updater_log("Invalid link",ply)
end
end

function makelink(path,gitname,reponame,ply,protocol,packjsonpath,ispredicted)
   local link = protocol.."://".."raw.githubusercontent.com".."/"..gitname.."/"..reponame.."/master/"..path
   searchraws_http(link,false,ply,nil,"raw.githubusercontent.com",path,packjsonpath,ispredicted)
end

function OnGetCompletecheck(a,b,c,http,gitname,reponame,ply,packagefile,protocol,packjsonpath,ispredicted)
   if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
      auto_updater_log("Invalid link",ply)
   else
      makelink("package.json",gitname,reponame,ply,protocol,packjsonpath,ispredicted)
      if packagefile.server_scripts then
         for i,v in pairs(packagefile.server_scripts) do
            makelink(v,gitname,reponame,ply,protocol,packjsonpath,ispredicted) 
         end
      end
      if packagefile.client_scripts then
         for i,v in pairs(packagefile.client_scripts) do
            makelink(v,gitname,reponame,ply,protocol,packjsonpath,ispredicted)        
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
            makelink(v,gitname,reponame,ply,protocol,packjsonpath,ispredicted)  
          end
         end
      end
   end
   http_destroy(http)
end

function OnGetCompletenewraw(a,b,c,http,ply,path,link,packjsonpath,ispredicted)
   local canpass = false
   if ispredicted then
      canpass = true
   else
      if (http_is_error(http) or http_result_body(http)=="400: Invalid request\n" or http_result_body(http)=="404: Not Found\n") then
         auto_updater_log("Error link " .. link,ply)
      else
         canpass = true
      end
   end
   if canpass then
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
               auto_updater_log("Saved auto_updater support path : " .. path.."  ".." link found : ".. link .. " restart to check updates",ply)
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
         auto_updater_log("admin.json file created in " .. "packages/"..GetPackageName().." please add admins restart the server and retry the command",ply)
         io.close(file)
      end
      return nil
   end
end

function addraws_cmd(ply,package,repolink,cmdname,ispredicted)
   if (package~=nil and repolink~=nil and package~="" and repolink~="" and package~=" " and repolink~=" ") then
      local isadmin = checkadmin(ply)
         if (isadmin == false or isadmin == nil) then
            auto_updater_log("You are not admin",ply)
         else
            local packagefilee = io.open("packages/"..package.."/package.json", 'r') 
            if packagefilee then
               local contents = packagefilee:read("*a")
               local packagefile = json_decode(contents);
               io.close(packagefilee)
               if packagefile.auto_updater then
                  auto_updater_log("Removed last auto updater support",ply)
                  packagefile.auto_updater = nil
               end
                   searchraws_http(repolink,true,ply,packagefile,"github.com",nil,"packages/"..package.."/package.json",ispredicted)
            else
               auto_updater_log("Package not found",ply)
            end
         end
   else
      auto_updater_log("/ ".. cmdname .. " <packagename> <repolink>",ply)
   end
end

AddCommand("searchraws",function(ply,package,repolink)
    addraws_cmd(ply,package,repolink,"searchraws",false)
end)

AddCommand("predictraws",function(ply,package,repolink)
   addraws_cmd(ply,package,repolink,"predictraws",true)
end)

AddCommand("reinstall",function(ply,packagename)
   local isadmin = checkadmin(ply)
      if (isadmin == false or isadmin == nil) then
         auto_updater_log("You are not admin",ply)
      else
    if (packagename ~= nil and packagename ~= "" and packagename ~= " ") then
      local package = io.open("packages/"..packagename.."/package.json", 'r') 
      if (package) then
          local contents = package:read("*a")
          local pack_tbl = json_decode(contents);
          io.close(package)
          if pack_tbl.auto_updater then
             if pack_tbl.auto_updater["package.json"] then
               auto_updater_log("Please restart the server after that to apply changes (if files were updated)",ply)
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,packagename,nil,false,false,true,ply)
             end
            else
               auto_updater_log("This package does not support auto_updater",ply)
          end
       else
         auto_updater_log("Package not found")
      end
   else
      auto_updater_log("Please restart the server after that to apply changes (if files were updated)",ply)
      searchupdatesallpackages(false,true,ply)
    end
   end
end)

AddCommand("searchupdates",function(ply,packagename)
   local isadmin = checkadmin(ply)
      if (isadmin == false or isadmin == nil) then
         auto_updater_log("You are not admin",ply)
      else
    if (packagename ~= nil and packagename ~= "" and packagename ~= " ") then
      local package = io.open("packages/"..packagename.."/package.json", 'r') 
      if (package) then
          local contents = package:read("*a")
          local pack_tbl = json_decode(contents);
          io.close(package)
          if pack_tbl.auto_updater then
             if pack_tbl.auto_updater["package.json"] then
               auto_updater_log("Please restart the server after that to apply changes (if files were updated)",ply)
                auto_updater_http(pack_tbl.auto_updater["package.json"],true,packagename,nil,false,false,false,ply)
             end
            else
               auto_updater_log("This package does not support auto_updater",ply)
          end
       else
         auto_updater_log("Package not found",ply)
      end
   else
      auto_updater_log("Please restart the server after that to apply changes (if files were updated)",ply)
      searchupdatesallpackages(false,false,ply)
    end
   end
end)