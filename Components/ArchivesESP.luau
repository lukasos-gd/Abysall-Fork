return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options

	local Known = {
		{ Label = "Honcho", Pattern = "honcho" },
		{ Label = "Drone", Pattern = "drone" },
		{ Label = "Forget-Me-Not", Pattern = "forgetmenot" },
		{ Label = "Teller", Pattern = "teller" },
		{ Label = "Alma", Pattern = "alma" },
		{ Label = "Bash", Pattern = "bash" },
		{ Label = "Ransom", Pattern = "ransom" },
		{ Label = "Scribbles", Pattern = "scribbles" },
		{ Label = "Portrait", Pattern = "portrait" },
		{ Label = "Fih", Pattern = "fih" },
		{ Label = "Creak", Pattern = "creak" },
		{ Label = "Noise", Pattern = "noise" },
		{ Label = "Stem", Pattern = "stem" },
		{ Label = "Cobbler", Pattern = "cobbler" },
		{ Label = "Hijack", Pattern = "hijack" },
		{ Label = "Meld", Pattern = "meld" }
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
		Text = "Print Matched Names",
		Default = false,
		Tooltip = "Prints the in-game name of every match to the console."
	})
	Groupbox:AddDropdown("ArchivesESPOptions", {
		Text = "Archives / Stairwell Entities",
		Values = Labels,
		Default = Defaults,
		Multi = true,
		Searchable = true
	})

	local Tracked = {}
	local Connections = {}

	local function Normalize(Name)
		return (string.lower(Name):gsub("[^%a]", ""))
	end

	local function Match(Name)
		local Clean = Normalize(Name)
		for _, Entry in ipairs(Known) do
			if string.sub(Clean, 1, #Entry.Pattern) == Entry.Pattern then
				return Entry.Label
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
		if not Label then
			return
		end
		local Enabled = Options.ArchivesESPOptions.Value
		if type(Enabled) ~= "table" or not Enabled[Label] then
			return
		end
		if Toggles.ArchivesDebugToggle.Value then
			print("[Abysall Fork] match", Label, "|", Object:GetFullName())
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

	table.insert(Connections, workspace.ChildAdded:Connect(Consider))

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
