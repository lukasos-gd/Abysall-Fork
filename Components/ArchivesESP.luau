return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local Handled = Env.Handled
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options
	local PlayersService = game:GetService("Players")
	local CollectionService = game:GetService("CollectionService")

	local Known = {
		{ Label = "Drones Stampede", Name = "dronesstampede", Body = "A stampede of Drones is coming.", Hitbox = { "Main", "Segment1", "Segment2", "Segment3" } },
		{ Label = "Drones", Name = "drones", Body = "Passive until you get close.", Hitbox = { "Root" } },
		{ Label = "Teller", Name = "tellerentity", Body = "Blocks a door until you have the right ticket.", NoESP = true },
		{ Label = "Teller", Name = "tellerrig", NoNotify = true },
		{ Label = "Bash", Name = "bashmoving", Body = "Stay alert.", Hitbox = { "Main" } },
		{ Label = "Scribbles", Name = "scribbles", Body = "Stay alert." },
		{ Label = "Alma", Name = "alma", Body = "Stay alert." },
		{ Label = "Creak", Name = "creak", Body = "Stay alert." },
		{ Label = "Ransom", Name = "ransom", Body = "Stay alert.", NoESP = true },
		{ Label = "Bramble", Name = "liveentitybramble", Body = "Stay alert.", NoESP = true }
	}

	Groupbox:AddDivider()
	Groupbox:AddToggle("ArchivesUnlistedToggle", {
		Text = "Highlight Other Threats",
		Default = false,
		Tooltip = "With Entities ESP on, also highlights anything tagged as a scanner threat that isn't in the lists, including ones without a hitbox."
	})
	Groupbox:AddToggle("ArchivesHitboxToggle", {
		Text = "Show Hitbox on New Entities",
		Default = true,
		Tooltip = "Makes the invisible hitbox of the new entities visible to the ESP, like the older entities."
	})
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
	local LastNotify = {}
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

	local Originals = {}
	local HitboxWatchers = {}

	local function HitboxParts(Object, Entry)
		local Parts = {}
		if Object:IsA("BasePart") then
			table.insert(Parts, Object)
		end
		for _, Descendant in ipairs(Object:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				table.insert(Parts, Descendant)
			end
		end
		if Entry and Entry.Hitbox then
			local Listed = {}
			for _, Part in ipairs(Parts) do
				if table.find(Entry.Hitbox, Part.Name) then
					table.insert(Listed, Part)
				end
			end
			if #Listed > 0 then
				return Listed
			end
		end
		local Named = {}
		for _, Part in ipairs(Parts) do
			if string.find(string.lower(Part.Name), "hitbox", 1, true) then
				table.insert(Named, Part)
			end
		end
		if #Named > 0 then
			return Named
		end
		if Object:IsA("Model") and Object.PrimaryPart then
			return { Object.PrimaryPart }
		end
		local Best
		local BestVolume = 0
		for _, Part in ipairs(Parts) do
			local Volume = Part.Size.X * Part.Size.Y * Part.Size.Z
			if Part.Transparency >= 0.99 and Volume > BestVolume then
				Best = Part
				BestVolume = Volume
			end
		end
		return Best and { Best } or {}
	end

	local function ApplyHitbox(Object)
		Originals[Object] = Originals[Object] or {}
		for _, Part in ipairs(HitboxParts(Object, Alive[Object])) do
			if Part.Transparency >= 0.99 and not Originals[Object][Part] then
				Originals[Object][Part] = { Part.Transparency, Part.Material }
				Part.Transparency = 0.999
				Part.Material = Enum.Material.Plastic
			end
		end
		if not HitboxWatchers[Object] then
			HitboxWatchers[Object] = Object.DescendantAdded:Connect(function(Descendant)
				if Descendant:IsA("BasePart") then
					task.defer(ApplyHitbox, Object)
				end
			end)
		end
	end

	local function RestoreHitbox(Object)
		if HitboxWatchers[Object] then
			HitboxWatchers[Object]:Disconnect()
			HitboxWatchers[Object] = nil
		end
		local Saved = Originals[Object]
		if Saved then
			for Part, Values in pairs(Saved) do
				pcall(function()
					Part.Transparency = Values[1]
					Part.Material = Values[2]
				end)
			end
			Originals[Object] = nil
		end
	end

	local function ShouldShow(Entry)
		if Entry.NoESP or not Toggles.EntityESPToggle.Value then
			return false
		end
		if Entry.Unlisted then
			return Toggles.ArchivesUnlistedToggle.Value
		end
		local Selected = Options.EntityESPOptions.Value
		return type(Selected) == "table" and Selected[Entry.Label] == true
	end

	local function ShouldNotify(Entry)
		if Entry.Unlisted or Entry.NoNotify or not Toggles.NotifyEntities.Value then
			return false
		end
		local Selected = Options.EntityList.Value
		return type(Selected) == "table" and Selected[Entry.Label] == true
	end

	local function Refresh(Object)
		local Entry = Alive[Object]
		if not Entry then
			return
		end
		if ShouldShow(Entry) then
			Shown[Object] = true
			if Toggles.ArchivesHitboxToggle.Value then
				pcall(ApplyHitbox, Object)
			else
				RestoreHitbox(Object)
			end
			pcall(Functions.AddESP, {
				Object = Object,
				Text = Entry.Label,
				Color = Options.EntityESPColor.Value
			})
		elseif Shown[Object] then
			Shown[Object] = nil
			RestoreHitbox(Object)
			pcall(Functions.RemoveESP, Object)
		end
	end

	local function RefreshAll()
		for Object in pairs(Alive) do
			Refresh(Object)
		end
	end

	local function Track(Object, Entry)
		Alive[Object] = Entry
		Refresh(Object)
		if not Notified[Object] and ShouldNotify(Entry) then
			Notified[Object] = true
			local Now = os.clock()
			if not LastNotify[Entry.Label] or Now - LastNotify[Entry.Label] >= 8 then
				LastNotify[Entry.Label] = Now
				Functions.Notify({
					Title = "Entity '" .. Entry.Label .. "' has spawned.",
					Body = Entry.Body,
					Kind = "warning",
					Time = Toggles.NotifyKeepNotifications and Toggles.NotifyKeepNotifications.Value and Object or 5
				})
			end
		end
		Object.Destroying:Once(function()
			Alive[Object] = nil
			Notified[Object] = nil
			if Shown[Object] then
				Shown[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
			RestoreHitbox(Object)
		end)
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
		if Entry then
			Track(Object, Entry)
		end
	end

	local function ConsiderTagged(Object)
		if Alive[Object] then
			return
		end
		if not (Object:IsA("Model") or Object:IsA("BasePart")) then
			return
		end
		if Match(Object.Name) then
			Consider(Object)
			return
		end
		if Handled(Object.Name) or PlayersService:GetPlayerFromCharacter(Object) then
			return
		end
		if Toggles.ArchivesDebugToggle.Value and not Seen[Object] then
			Seen[Object] = true
			print("[Abysall Fork]", "THREAT", Object.ClassName, Object.Name, "|", Object:GetFullName())
		end
		Track(Object, { Label = Object.Name, Unlisted = true })
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

	for _, Tagged in ipairs(CollectionService:GetTagged("ScannerThreat")) do
		ConsiderTagged(Tagged)
	end
	table.insert(Connections, CollectionService:GetInstanceAddedSignal("ScannerThreat"):Connect(ConsiderTagged))

	Toggles.EntityESPToggle:OnChanged(RefreshAll)
	Toggles.ArchivesUnlistedToggle:OnChanged(RefreshAll)
	Toggles.ArchivesHitboxToggle:OnChanged(RefreshAll)
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
			RestoreHitbox(Object)
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
