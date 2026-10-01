return function(Window)
    local Fallback = {
        "<font color='rgb(61, 220, 255)'><b>Abysall Fork</b></font>",
        "<font color='rgb(0, 255, 0)'>+ Could not load Changelog.json</font>"
    }

    local Colors = {
        add = { "rgb(0, 255, 0)", "+" },
        fix = { "rgb(255, 222, 89)", "~" },
        change = { "rgb(61, 220, 255)", "*" },
        remove = { "rgb(255, 90, 100)", "-" }
    }

    local function BuildChangelog()
        local Source = Abysall.Fetch and Abysall.Fetch("Changelog.json", 2)
        if not Source then
            return Fallback
        end
        local Success, Data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), Source)
        if not Success or type(Data) ~= "table" or type(Data.entries) ~= "table" then
            return Fallback
        end
        local Lines = {
            "<font color='rgb(61, 220, 255)'><b>v" .. tostring(Data.version) .. "</b> (" .. tostring(Data.date) .. ")</font>"
        }
        for _, Entry in ipairs(Data.entries) do
            local Style = Colors[Entry.type] or Colors.change
            table.insert(Lines, "<font color='" .. Style[1] .. "'>" .. Style[2] .. " " .. tostring(Entry.text) .. "</font>")
        end
        return Lines
    end

    local LatestChangelog = BuildChangelog()

    local function CloneReference(Object)
        if Abysall and Abysall.Environment.cloneref then
            return Abysall.Environment.cloneref(Object)
        else
            return Object
        end
    end

    local Services = setmetatable({}, {
        __index = function(self, Name)
            return CloneReference(game:GetService(Name))
        end
    })

    local Library = Abysall.Interface.Library
    local SaveManager = Abysall.Interface.SaveManager
    local ThemeManager = Abysall.Interface.ThemeManager

    local Toggles = Library.Toggles
    local Options = Library.Options

    local LocalPlayer = Services.Players.LocalPlayer
    local InfoTab = Window:AddTab("Info", "user")

    local User = InfoTab:AddLeftGroupbox("User Info")

    local ImageSize = Enum.ThumbnailSize.Size420x420
    local ImageType = Enum.ThumbnailType.HeadShot

    local Content = Services.Players:GetUserThumbnailAsync(LocalPlayer.UserId, ImageType, ImageSize)

    User:AddImage("UserIcon", {
        Image = Content
    })

    User:AddLabel("ID: " .. LocalPlayer.Name, true)
    User:AddLabel("Total Executions: " .. (Abysall.TotalExecutions and Abysall.TotalExecutions or "N/A"), true)

    local Changelog = InfoTab:AddRightGroupbox("Changelog")
    for Index, Change in pairs(LatestChangelog) do
        Changelog:AddLabel(Change, true)
    end

    local Name, Version = Abysall.Environment.identifyexecutor()
    local Executor = InfoTab:AddRightGroupbox("Executor Info")
    Executor:AddLabel("Name: " .. Name, true)
	Executor:AddLabel("Version: " .. (Version and Version or "N/A"), true)
    Executor:AddDivider()
    Executor:AddLabel("Test Result: ", true)

    for Index, Result in pairs(Abysall.Environment.Results) do
		-- fix for veloshitty 💔
		Result = Result:gsub("<", "(")
		Result = Result:gsub(">", ")")
		
        Executor:AddLabel(Result, true)
    end

    local Community = InfoTab:AddLeftGroupbox("Community")
    Community:AddButton("Copy GitHub Link", function()
	    toclipboard("https://github.com/lukasos-gd/Abysall-Fork")
	    Library:Notify("GitHub link copied.")
    end)
    Community:AddLabel("Version: " .. tostring(Abysall.Version) .. " (" .. tostring(Abysall.Ref) .. ")", true)
end
