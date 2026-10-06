return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options

	local Known = {
		{ Label = "Honcho", Patterns = { "honcho", "boss" } },
		{ Label = "Drone", Patterns = { "drone", "dronerig" } },
		{ Label = "Forget-Me-Not", Patterns = { "forgetmenot", "forgetme", "fmn" } },
		{ Label = "Teller", Patterns = { "teller", "ticketmachine" } },
		{ Label = "Alma", Patterns = { "alma" } },
		{ Label = "Bash", Patterns = { "bash", "a60" } },
		{ Label = "Ransom", Patterns = { "ransom", "a90" } },
		{ Label = "Scribbles", Patterns = { "scribbles", "scribble", "a120" } },
		{ Label = "Portrait", Patterns = { "portrait" } },
		{ Label = "Fih", Patterns = { "fih", "fish" } },
		{ Label = "Creak", Patterns = { "creak" } },
		{ Label = "Noise", Patterns = { "noise" } },
		{ Label = "Stem", Patterns = { "stem" } },
		{ Label = "Cobbler", Patterns = { "cobbler", "shoe" } },
		{ Label = "Hijack", Patterns = { "hijack" } },
		{ Label = "Meld", Patterns = { "meld" } }
	}

	local Labels = {}
	local Defaults = {}
	for _, Entry in ipairs(Known) do
		table.insert(Labels, Entry.Label)
		if Entry.Label ~= "Fih" then
			Defaults[Entry.Label] = true
		end
	end

	Groupbox:AddDivider()
	Groupbox:AddToggle("ArchivesESPToggle", {
		Text = "Archives / Stairwell ESP",
		Default = false,
		Tooltip = "Highlights entities from The Archives and The Stairwell."
	})
	Groupbox:AddToggle("ArchivesNotifyToggle", {
		Text = "Archives / Stairwell Notify",
		Default = false,
		Tooltip = "Sends a notification when one of these entities appears."
	})
	Groupbox:AddToggle("ArchivesDebugToggle", {
		Text = "Log Model Names",
		Default = false,
		Tooltip = "Prints every new model name to the console, marked MATCH or MISS."
	})
	Groupbox:AddToggle("ArchivesDiscoveryToggle", {
		Text = "Label All New Models",
		Default = false,
		Tooltip = "Highlights every new top-level model with its real name, to find entity names without the console."
	})
	Groupbox:AddDropdown("ArchivesESPOptions", {
		Text = "Archives / Stairwell Entities",
		Values = Labels,
		Multi = true,
		AllowNull = true
	})

	pcall(function()
		Options.ArchivesESPOptions:SetValue(Defaults)
	end)

	local Tracked = {}
	local Connections = {}

	local Seen = {}

	local function Normalize(Name)
		return (string.lower(Name):gsub("[^%w]", ""))
	end

	local function Match(Name)
		local Clean = Normalize(Name)
		for _, Entry in ipairs(Known) do
			for _, Pattern in ipairs(Entry.Patterns) do
				if string.sub(Clean, 1, #Pattern) == Pattern then
					return Entry.Label
				end
				if #Pattern >= 6 and string.find(Clean, Pattern, 1, true) then
					return Entry.Label
				end
			end
		end
	end

	local function Remove(Object)
		if Tracked[Object] then
			Tracked[Object] = nil
			pcall(Functions.RemoveESP, Object)
		end
	end

	local function Consider(Object)
		if Tracked[Object] or not Object:IsA("Model") then
			return
		end
		local Label = Match(Object.Name)
		if Toggles.ArchivesDebugToggle.Value and not Seen[Object.Name] then
			Seen[Object.Name] = true
			print("[Abysall Fork]", Label and "MATCH" or "MISS", Object.Name, "|", Object:GetFullName())
		end
		if not Label then
			return
		end
		local Enabled = Options.ArchivesESPOptions.Value
		if type(Enabled) ~= "table" or not Enabled[Label] then
			return
		end
		if Toggles.ArchivesESPToggle.Value then
			Tracked[Object] = Label
			pcall(Functions.AddESP, {
				Object = Object,
				Text = Label,
				Color = Options.EntityESPColor.Value
			})
		end
		if Toggles.ArchivesNotifyToggle.Value then
			Functions.Notify({
				Title = Label .. " appeared",
				Body = "Archives / Stairwell entity nearby.",
				Time = 5,
				Kind = "warning"
			})
		end
		Object.Destroying:Once(function()
			Remove(Object)
		end)
	end

	local function ClearAll()
		for Object in pairs(Tracked) do
			Remove(Object)
		end
	end

	local function Scan()
		for _, Child in ipairs(workspace:GetChildren()) do
			Consider(Child)
		end
		local Rooms = workspace:FindFirstChild("CurrentRooms")
		if Rooms then
			for _, Descendant in ipairs(Rooms:GetDescendants()) do
				if Descendant:IsA("Model") then
					Consider(Descendant)
				end
			end
		end
	end

	local Discovered = {}
	local PlayersService = game:GetService("Players")

	table.insert(Connections, workspace.ChildAdded:Connect(function(Child)
		Consider(Child)
		if not Toggles.ArchivesDiscoveryToggle.Value then
			return
		end
		if not Child:IsA("Model") or Child.Name == "CurrentRooms" or PlayersService:GetPlayerFromCharacter(Child) then
			return
		end
		Discovered[Child] = true
		pcall(Functions.AddESP, {
			Object = Child,
			Text = Child.Name,
			Color = Color3.fromRGB(255, 255, 255)
		})
		Child.Destroying:Once(function()
			Discovered[Child] = nil
			pcall(Functions.RemoveESP, Child)
		end)
	end))

	local function HookRooms(Rooms)
		table.insert(Connections, Rooms.DescendantAdded:Connect(function(Descendant)
			if Descendant:IsA("Model") then
				Consider(Descendant)
			end
		end))
	end

	local Rooms = workspace:FindFirstChild("CurrentRooms")
	if Rooms then
		HookRooms(Rooms)
	else
		table.insert(Connections, workspace.ChildAdded:Connect(function(Child)
			if Child.Name == "CurrentRooms" then
				HookRooms(Child)
			end
		end))
	end

	Toggles.ArchivesESPToggle:OnChanged(function(Value)
		if Value then
			Scan()
		else
			ClearAll()
		end
	end)

	Toggles.ArchivesDiscoveryToggle:OnChanged(function(Value)
		if not Value then
			for Object in pairs(Discovered) do
				Discovered[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
		end
	end)

	Options.ArchivesESPOptions:OnChanged(function()
		ClearAll()
		Scan()
	end)

	Options.EntityESPColor:OnChanged(function()
		if Toggles.ArchivesESPToggle.Value then
			ClearAll()
			Scan()
		end
	end)

	Abysall.Cleanup:Add(function()
		ClearAll()
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
	end)
end
