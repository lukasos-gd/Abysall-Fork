return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options
	local PlayersService = game:GetService("Players")

	local Known = {
		{ Label = "Drones Stampede", Name = "dronesstampede", Body = "A stampede of Drones is coming." },
		{ Label = "Drones", Name = "drones", Body = "Passive until you get close." },
		{ Label = "Teller", Name = "tellerentity", Body = "Blocks a door until you have the right ticket." },
		{ Label = "Bash", Name = "bashmoving", Body = "Stay alert." },
		{ Label = "Scribbles", Name = "scribbles", Body = "Stay alert." }
	}

	Groupbox:AddDivider()
	Groupbox:AddToggle("ArchivesDebugToggle", {
		Text = "Log Model Names",
		Default = false,
		Tooltip = "Prints every new model name to the console, marked MATCH or MISS."
	})
	Groupbox:AddToggle("ArchivesDiscoveryToggle", {
		Text = "Label All New Models",
		Default = false,
		Tooltip = "Highlights every new top-level model with its real name."
	})

	local Alive = {}
	local Notified = {}
	local Shown = {}
	local Discovered = {}
	local Connections = {}
	local Seen = {}

	local function Match(Name)
		local Clean = string.lower(Name)
		for _, Entry in ipairs(Known) do
			if Clean == Entry.Name then
				return Entry
			end
		end
	end

	local function ShouldShow(Label)
		if not Toggles.EntityESPToggle.Value then
			return false
		end
		local Selected = Options.EntityESPOptions.Value
		return type(Selected) == "table" and Selected[Label] == true
	end

	local function ShouldNotify(Label)
		if not Toggles.NotifyEntities.Value then
			return false
		end
		local Selected = Options.EntityList.Value
		return type(Selected) == "table" and Selected[Label] == true
	end

	local function Refresh(Object)
		local Label = Alive[Object]
		if not Label then
			return
		end
		if ShouldShow(Label) then
			Shown[Object] = true
			pcall(Functions.AddESP, {
				Object = Object,
				Text = Label,
				Color = Options.EntityESPColor.Value
			})
		elseif Shown[Object] then
			Shown[Object] = nil
			pcall(Functions.RemoveESP, Object)
		end
	end

	local function RefreshAll()
		for Object in pairs(Alive) do
			Refresh(Object)
		end
	end

	local function Consider(Object)
		if Alive[Object] then
			return
		end
		if not (Object:IsA("Model") or Object:IsA("BasePart")) then
			return
		end
		local Entry = Match(Object.Name)
		if Toggles.ArchivesDebugToggle.Value and not Seen[Object] then
			Seen[Object] = true
			print("[Abysall Fork]", Entry and "MATCH" or "MISS", Object.ClassName, Object.Name, "|", Object:GetFullName())
		end
		if not Entry then
			return
		end
		Alive[Object] = Entry.Label
		Refresh(Object)
		if not Notified[Object] and ShouldNotify(Entry.Label) then
			Notified[Object] = true
			Functions.Notify({
				Title = "Entity '" .. Entry.Label .. "' has spawned.",
				Body = Entry.Body,
				Kind = "warning",
				Time = Toggles.NotifyKeepNotifications and Toggles.NotifyKeepNotifications.Value and Object or 5
			})
		end
		Object.Destroying:Once(function()
			Alive[Object] = nil
			Notified[Object] = nil
			if Shown[Object] then
				Shown[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
		end)
	end

	local function Discover(Child)
		if not Toggles.ArchivesDiscoveryToggle.Value then
			return
		end
		if not Child:IsA("Model") or PlayersService:GetPlayerFromCharacter(Child) then
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
	end

	local function WatchLive(Live)
		for _, Child in ipairs(Live:GetChildren()) do
			Consider(Child)
		end
		table.insert(Connections, Live.ChildAdded:Connect(function(Child)
			Consider(Child)
			Discover(Child)
		end))
	end

	for _, Child in ipairs(workspace:GetChildren()) do
		Consider(Child)
	end

	table.insert(Connections, workspace.ChildAdded:Connect(function(Child)
		if Child.Name == "LiveEntities" then
			WatchLive(Child)
			return
		end
		Consider(Child)
		Discover(Child)
	end))

	local Live = workspace:FindFirstChild("LiveEntities")
	if Live then
		WatchLive(Live)
	end

	Toggles.EntityESPToggle:OnChanged(RefreshAll)
	Options.EntityESPOptions:OnChanged(RefreshAll)
	Options.EntityESPColor:OnChanged(function()
		for Object in pairs(Shown) do
			Shown[Object] = nil
			pcall(Functions.RemoveESP, Object)
		end
		RefreshAll()
	end)

	Toggles.ArchivesDiscoveryToggle:OnChanged(function(Value)
		if not Value then
			for Object in pairs(Discovered) do
				Discovered[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
		end
	end)

	Abysall.Cleanup:Add(function()
		for Object in pairs(Shown) do
			pcall(Functions.RemoveESP, Object)
		end
		for Object in pairs(Discovered) do
			pcall(Functions.RemoveESP, Object)
		end
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
	end)
end
