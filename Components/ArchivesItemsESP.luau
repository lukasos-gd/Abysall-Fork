return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local ItemNames = Env.ItemNames
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options
	local CollectionService = game:GetService("CollectionService")
	local PlayersService = game:GetService("Players")
	local LocalPlayer = PlayersService.LocalPlayer

	Groupbox:AddToggle("ArchivesItemsToggle", {
		Text = "Archives Items",
		Default = true,
		Tooltip = "Items ESP and Notify Items also cover items the main list doesn't know, like the new Archives items."
	})

	local Alive = {}
	local Shown = {}
	local LastNotify = {}
	local Connections = {}

	local function Humanize(Text)
		return (tostring(Text):gsub("_", " "):gsub("(%l)(%u)", "%1 %2"))
	end

	local function InsideCharacter(Object)
		local Ancestor = Object.Parent
		while Ancestor and Ancestor ~= workspace do
			if PlayersService:GetPlayerFromCharacter(Ancestor) then
				return true
			end
			Ancestor = Ancestor.Parent
		end
		return false
	end

	local function DistanceTo(Object)
		local Character = LocalPlayer.Character
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		local Origin = Root and Root.Position or workspace.CurrentCamera.CFrame.Position
		return (Object:GetPivot().Position - Origin).Magnitude
	end

	local function Register(Label)
		for _, Name in ipairs({ "NotifyItemList", "ItemESPList" }) do
			local Dropdown = Options[Name]
			if Dropdown and type(Dropdown.Values) == "table" and not table.find(Dropdown.Values, Label) then
				local Values = table.clone(Dropdown.Values)
				table.insert(Values, Label)
				table.sort(Values)
				pcall(function()
					Dropdown:SetValues(Values)
				end)
				local Selected = table.clone(type(Dropdown.Value) == "table" and Dropdown.Value or {})
				Selected[Label] = true
				pcall(function()
					Dropdown:SetValue(Selected)
				end)
			end
		end
	end

	local function Wanted(Label)
		local Selected = Options.NotifyItemList.Value
		return type(Selected) == "table" and Selected[Label] == true
	end

	local function Refresh(Object)
		local Label = Alive[Object]
		if not Label then
			return
		end
		local ESPSelected = Options.ItemESPList.Value
		if Toggles.ItemESPToggle.Value and Toggles.ArchivesItemsToggle.Value and type(ESPSelected) == "table" and ESPSelected[Label] then
			if not Shown[Object] then
				Shown[Object] = true
				pcall(Functions.AddESP, {
					Object = Object,
					Text = Label,
					Color = Options.ItemESPColor.Value
				})
			end
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
		if Alive[Object] or not Object.Parent or not Object:IsA("Model") then
			return
		end
		local Pickup = Object:GetAttribute("Pickup")
		if not Pickup and not CollectionService:HasTag(Object, "ItemDrop") then
			return
		end
		if Object.Name == "ArchivesStorageBox" or Pickup == "ArchivesStorageBox" then
			return
		end
		if ItemNames[Object.Name] or (Pickup and ItemNames[Pickup]) then
			return
		end
		if InsideCharacter(Object) then
			return
		end

		local Label = Object:GetAttribute("Tool_NameSingular") or (Pickup and Humanize(Pickup)) or Humanize(Object.Name)
		Alive[Object] = Label
		Register(Label)
		Refresh(Object)

		if Toggles.NotifyItemsToggle.Value and Toggles.ArchivesItemsToggle.Value and Wanted(Label) then
			local Now = os.clock()
			if not LastNotify[Label] or Now - LastNotify[Label] >= 5 then
				LastNotify[Label] = Now
				local Body = "Check the area around you."
				if Toggles.NotifyItemsShowDistance.Value then
					Body = math.floor(DistanceTo(Object)) .. " studs away"
				end
				Functions.Notify({
					Title = "Item '" .. Label .. "' found!",
					Body = Body,
					Kind = "success",
					Time = 5
				})
			end
		end

		Object.Destroying:Once(function()
			Alive[Object] = nil
			if Shown[Object] then
				Shown[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
		end)
	end

	local function Later(Object)
		task.delay(0.3, Consider, Object)
	end

	for _, Tagged in ipairs(CollectionService:GetTagged("ItemDrop")) do
		Consider(Tagged)
	end
	table.insert(Connections, CollectionService:GetInstanceAddedSignal("ItemDrop"):Connect(Later))

	for _, Child in ipairs(workspace:GetChildren()) do
		Consider(Child)
	end
	table.insert(Connections, workspace.ChildAdded:Connect(Later))

	local function WatchRooms(Rooms)
		table.insert(Connections, Rooms.DescendantAdded:Connect(function(Descendant)
			if Descendant:IsA("Model") then
				Later(Descendant)
			end
		end))
	end

	local Rooms = workspace:FindFirstChild("CurrentRooms")
	if Rooms then
		for _, Descendant in ipairs(Rooms:GetDescendants()) do
			if Descendant:IsA("Model") then
				Consider(Descendant)
			end
		end
		WatchRooms(Rooms)
	else
		table.insert(Connections, workspace.ChildAdded:Connect(function(Child)
			if Child.Name == "CurrentRooms" then
				WatchRooms(Child)
			end
		end))
	end

	Toggles.ItemESPToggle:OnChanged(RefreshAll)
	Toggles.ArchivesItemsToggle:OnChanged(RefreshAll)
	Options.ItemESPList:OnChanged(RefreshAll)
	Options.ItemESPColor:OnChanged(function()
		for Object in pairs(Shown) do
			Shown[Object] = nil
			pcall(Functions.RemoveESP, Object)
		end
		RefreshAll()
	end)

	Abysall.Cleanup:Add(function()
		for Object in pairs(Shown) do
			pcall(Functions.RemoveESP, Object)
		end
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
	end)
end
