if getgenv().Abysall then
    return
end

local GameList = {
    [2440500124] = "Doors"
}

local Ref = getgenv().AbysallRef or "refs/heads/main"
local BaseUrl = "https://raw.githubusercontent.com/lukasos-gd/Abysall-Fork/" .. Ref .. "/"

local Abysall = {
    Legit = true,
    Version = "1.1.0",
    Ref = Ref,
    BaseUrl = BaseUrl
}
getgenv().Abysall = Abysall

function Abysall.FetchUrl(Url, Tries)
    local LastError = "empty response"
    for Attempt = 1, Tries or 3 do
        local Success, Result = pcall(game.HttpGet, game, Url)
        if Success and type(Result) == "string" and #Result > 0 then
            return Result
        end
        LastError = tostring(Result)
        task.wait(Attempt * 0.75)
    end
    return nil, LastError
end

function Abysall.Fetch(Path, Tries)
    return Abysall.FetchUrl(BaseUrl .. Path, Tries)
end

function Abysall.LoadUrl(Url, Name)
    local Source, FetchError = Abysall.FetchUrl(Url)
    if not Source then
        error("Abysall Fork: failed to download " .. (Name or Url) .. " (" .. FetchError .. ")", 0)
    end
    local Chunk, CompileError = loadstring(Source, "=" .. (Name or Url))
    if not Chunk then
        error("Abysall Fork: failed to compile " .. (Name or Url) .. " (" .. tostring(CompileError) .. ")", 0)
    end
    return Chunk()
end

function Abysall.Load(Path)
    return Abysall.LoadUrl(BaseUrl .. Path, Path)
end

local Splash
pcall(function()
    Splash = Abysall.Load("Components/Splash.luau").new()
end)

local function Step(Progress, Text)
    if Splash then
        pcall(Splash.Set, Splash, Progress, Text)
    end
end

local function Boot()
    Step(0.1, "Loading environment")
    Abysall.Environment = Abysall.Load("Components/Environment.luau")

    Step(0.3, "Loading ESP")
    Abysall.ESPLibrary = Abysall.Load("Components/ESP.luau")
    Abysall.Cleanup = Abysall.Load("Components/Cleanup.luau")

    local HttpService = game:GetService("HttpService")
    if Abysall.Environment.writefile and Abysall.Environment.readfile then
        if not Abysall.Environment.isfile("Abysall/UserData.json") then
            Abysall.Environment.writefile("Abysall/UserData.json", HttpService:JSONEncode({
                TotalExecutions = 0,
                UILibrary = "Obsidian"
            }))
        end

        local Decoded = HttpService:JSONDecode(Abysall.Environment.readfile("Abysall/UserData.json"))
        Decoded.TotalExecutions = (Decoded.TotalExecutions or 0) + 1
        Decoded.UILibrary = Decoded.UILibrary or "Obsidian"

        Abysall.TotalExecutions = Decoded.TotalExecutions
        Abysall.UILibrary = Decoded.UILibrary

        Abysall.Environment.writefile("Abysall/UserData.json", HttpService:JSONEncode(Decoded))
    end

    Step(0.55, "Loading interface")
    Abysall.Interface = Abysall.Load("Components/Interface.luau")

    Step(0.8, "Loading game")
    local CurrentGame = GameList[game.GameId]
    if CurrentGame then
        Abysall.Load("Games/" .. CurrentGame .. "/Loader.luau")
    else
        Abysall.Load("Games/Universal/Loader.luau")
    end
end

local Success, Err = pcall(Boot)

if Splash then
    pcall(Splash.Close, Splash)
end

if not Success then
    getgenv().Abysall = nil
    warn("[Abysall Fork] " .. tostring(Err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "Abysall Fork",
            Text = "Failed to load. Check the console for details.",
            Duration = 8
        })
    end)
end
