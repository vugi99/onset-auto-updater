

function string:split(sep) -- http://lua-users.org/wiki/SplitJoin
   local sep, fields = sep or ":", {}
   local pattern = string.format("([^%s]+)", sep)
   self:gsub(pattern, function(c) fields[#fields+1] = c end)
   return fields
end

function auto_updater_http(link,isjson,packagename,path)
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
   if isjson then
      if http_send(r, OnGetCompletejson, "Str L", 88.88, 1337,r,packagename) == false then
		   print("Url " .. link .. " not found")
		   http_destroy(r)
      end
   else
      if http_send(r, OnGetCompletefile, "Str L", 88.88, 1337,r,packagename,path) == false then
		   print("Url " .. link .. " not found , update for this file failed")
		   http_destroy(r)
      end
   end
end

function OnGetCompletejson(a, b, c,http,packagename)
   if http_is_error(http) then
      print("Invalid link")
  else
   local body = http_result_body(http)
   local httppackage = json_decode(body)
   local package = io.open("packages/"..packagename.."/package.json", 'r') 
           if (package) then
               local contents = package:read("*a")
               local pack_tbl = json_decode(contents);
               io.close(package)
               if pack_tbl.version ~= httppackage.version then
                  print("Updating " .. packagename)
                  local writejson = io.open("packages/"..packagename.."/package.json", 'w') 
                  if writejson then
                     writejson:write(body)
                     print("file package.json updated")
                     io.close(writejson)
                  end
                  if pack_tbl.server_scripts then
                     for i,v in pairs(pack_tbl.server_scripts) do
                        if pack_tbl.auto_updater[v] then
                            auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v)
                        end
                     end
                  end
                  if pack_tbl.client_scripts then
                     for i,v in pairs(pack_tbl.client_scripts) do
                        if pack_tbl.auto_updater[v] then
                           auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v)
                        end
                     end
                  end
                  if pack_tbl.files then
                     for i,v in pairs(pack_tbl.files) do
                        if pack_tbl.auto_updater[v] then
                           auto_updater_http(pack_tbl.auto_updater[v],false,packagename,v)
                        end
                     end
                  end
               end
           end
         end
   http_destroy(http)
end

function OnGetCompletefile(a, b, c,http,packagename,path)
   if http_is_error(http) then
      print("Invalid link")
  else
   local body = http_result_body(http)
   local file = io.open("packages/"..packagename.."/" .. path, 'w') 
   if file then
      file:write(body)
      print("file " .. path .. " updated")
      io.close(file)
   end
end
   http_destroy(http)
end

AddEvent("OnPackageStart",function()
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
                     auto_updater_http(pack_tbl.auto_updater["package.json"],true,v)
                  end
               end
           end
       end
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
   if http_is_error(http) then
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
            makelink(v,gitname,reponame,ply,protocol,packjsonpath)         
         end
      end
   end
   http_destroy(http)
end

function OnGetCompletenewraw(a,b,c,http,ply,path,link,packjsonpath)
   if http_is_error(http) then
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

AddCommand("searchraws",function(ply,package,repolink)
   if (package~=nil and repolink~=nil and package~="" and repolink~="" and package~=" " and repolink~=" ") then
   local file = io.open("packages/"..GetPackageName().."/admins.json", 'r') 
   if (file) then 
      local contents = file:read("*a")
      local admins_tbl = json_decode(contents);
      io.close(file)
      local isadmin = false
      for i,v in ipairs(admins_tbl) do
         if v == tostring(GetPlayerSteamId(ply)) then
            isadmin=true
         end
      end
      if isadmin == false then
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

   end
else
   AddPlayerChat(ply,"/searchraws <packagename> <repolink>")
end
end)