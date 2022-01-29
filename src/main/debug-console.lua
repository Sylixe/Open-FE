local repo = "bainchild/Open-FE"


local function jdc(c)
    return game:GetService("HttpService"):JSONDecode(c)
end
local function jde(c)
    return game:GetService("HttpService"):JSONEncode(c)
end
local function getcommits(gh)
    local commits = syn.request({
    Url="https://api.github.com/repos/"..gh.."/commits";
    Method="GET";
    })
    assert(commits.Success,"Couldn't get commits for "..tostring(gh))
    return jdc(commits.Body)
end
local function getlatestcommit(gh)
    local ta = getcommits(gh)
    return ta[1]
end
local function gettree(gh,cm,aurl)
    local turl
    if not aurl then
        cm = cm or getlatestcommit(gh)
        local commit_info
        if type(cm) == "string" then 
            commit_info = syn.request({
                Url="https://api.github.com/repos/"..gh.."/commits/"..cm;
                Method="GET";
            })
            assert(commit_info.Success,"Couldn't get commit info for "..tostring(cm))
            commit_info = jdc(commit_info.Body)
        else
            commit_info=cm
        end
        turl=commit_info.commit.tree.url
    else
        turl=gh
    end
    local tree_request = syn.request({
        Url=turl;
        Method="GET";
    })
    assert(tree_request.Success,"Couldn't get tree for "..tostring(cm))
    return jdc(tree_request.Body).tree
end
repo=gettree(repo,nil,false)
for i,v in ipairs(repo) do
    if v.type == "tree" and v.path == "src" then
        repo=v.url
        break
    end
end
assert(type(repo)=="string","Couldn't find src folder!")
local ignore = {"lib"}
local chosen
while true do
    rconsolename("Loader")
    rconsoleprint("\27[38;2;100;0;100mChoose:\27[0m\n")
    local tree = gettree(repo,nil,true)
    local options = {}
    for i,v in pairs(tree) do
        if v.type == "tree" and ignore[v.path] == nil then
            table.insert(options,v)
            rconsoleprint(tostring(#options)..". ".."\27[38;2;255;0;0m"..tostring(v.path).."\27[0m\n") -- red, foreground
        end
    end
    table.insert(options,"Exit")
    rconsoleprint(tostring(#options)..". ".."Exit\n")
    rconsoleprint(">")
    local n = rconsoleinput()
    rconsoleclear()
    if tonumber(n) == nil then
        n=n:lower()
        local new
        for i,v in ipairs(options) do 
            if v == n then 
                 new=i
                 break
            end
        end
        if new == nil then 
            rconsoleprint("Not a valid option!\n")
        else
            local tree_d = gettree(options[new].url,nil,true)
            for i,v in pairs(tree_d) do
                if v.type == "blob" and v.path == "init.lua" then
                    tree_d=loadstring(game:HttpGet(v.url))
                    break
                end
            end
            assert(tree_d,"Chosen option doesn't have a init.lua file (or its invalid lua)!")
            chosen=tree_d
            break
        end
    elseif options[tonumber(n)] == nil then
        rconsoleprint("Out of range!\n")
    else
        local tree_d = gettree(options[tonumber(n)].url,nil,true)
        for i,v in pairs(tree_d) do
            if v.type == "blob" and v.path == "init.lua" then
                tree_d=loadstring(syn.crypt.base64.decode(jdc(game:HttpGet(v.url)).content))
                break
            end
        end
        assert(tree_d~=nil,"Chosen option doesn't have a init.lua file (or its invalid lua)!")
        chosen=tree_d
        break
    end
end
rconsoleclear()
rconsolename(identifyexecutor()) -- it was something like identifyexploit() or identifyexecutor()
chosen()