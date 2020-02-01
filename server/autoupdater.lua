

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
   http_destroy(http)
end

function OnGetCompletefile(a, b, c,http,packagename,path)
   local body = http_result_body(http)
   local file = io.open("packages/"..packagename.."/" .. path, 'w') 
   if file then
      file:write(body)
      print("file " .. path .. " updated")
      io.close(file)
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