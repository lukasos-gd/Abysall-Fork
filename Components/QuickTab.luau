return function(Window)
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options
	local Environment = Abysall.Environment
	local HttpService = game:GetService("HttpService")

	local QuickTab = Window:AddTab("Quick", "zap")
	local PresetBox = QuickTab:AddLeftGroupbox("Presets", "sliders-horizontal")
	local FavoriteBox = QuickTab:AddRightGroupbox("Favorites", "star")

	local PresetOrder = { "Legit", "Visuals only", "Notifiers only", "Quality of life" }
	local Presets = {
		["Legit"] = {
			"NotifyEntities", "NotifyItemsToggle", "NotifyLibraryCode", "NotifyOxygen",
			"ObjectiveESPToggle", "DoorESPToggle", "ItemESPToggle", "CurrencyESPToggle", "EntityESPToggle"
		},
		["Visuals only"] = {
			"ObjectiveESPToggle", "DoorESPToggle", "HidingSpotESPToggle", "PlayerESPToggle",
			"ChestESPToggle", "ItemESPToggle", "CurrencyESPToggle", "LadderESPToggle",
			"EntityESPToggle", "ESPShowDistance", "AmbientToggle"
		},
		["Notifiers only"] = {
			"NotifyEntities", "NotifyItemsToggle", "NotifyLibraryCode", "NotifyOxygen",
			"NotifyHasteTime", "NotifyPlaySound"
		},
		["Quality of life"] = {
			"InstantPrompts", "EnableCharacterJump", "EnableCharacterSlide", "RemoveCameraShake",
			"RemoveCameraBobbing", "NotifyEntities", "NotifyItemsToggle"
		}
	}

	local Managed = {}
	for _, List in pairs(Presets) do
		for _, Name in ipairs(List) do
			Managed[Name] = true
		end
	end

	local function SetToggle(Name, Value)
		local Toggle = Toggles[Name]
		if Toggle and Toggle.Value ~= Value then
			pcall(function()
				Toggle:SetValue(Value)
			end)
		end
	end

	PresetBox:AddDropdown("PresetPicker", {
		Text = "Preset",
		Values = PresetOrder,
		Default = 1
	})

	PresetBox:AddButton({
		Text = "Apply Preset",
		Func = function()
			local Chosen = Options.PresetPicker.Value
			local List = Presets[Chosen]
			if not List then
				return
			end
			for Name in pairs(Managed) do
				SetToggle(Name, false)
			end
			for _, Name in ipairs(List) do
				SetToggle(Name, true)
			end
			Library:Notify("Applied preset: " .. Chosen)
		end
	})

	PresetBox:AddButton({
		Text = "Turn Preset Toggles Off",
		Func = function()
			for Name in pairs(Managed) do
				SetToggle(Name, false)
			end
			Library:Notify("Preset toggles turned off.")
		end
	})

	local SlotCount = 10
	local SavePath = "Abysall/Favorites.json"
	local Bound = {}
	local Hooked = {}
	local Slots = {}
	local DisplayToName = {}
	local DisplayValues = {}
	local NameToDisplay = {}

	local Names = {}
	for Name, Toggle in pairs(Toggles) do
		if type(Name) == "string" and not Name:find("^FavoriteSlot") then
			table.insert(Names, Name)
		end
	end
	table.sort(Names)

	for _, Name in ipairs(Names) do
		local Text = Toggles[Name].Text
		local Display = (type(Text) == "string" and Text ~= "") and Text or Name
		if DisplayToName[Display] then
			Display = Display .. " (" .. Name .. ")"
		end
		DisplayToName[Display] = Name
		NameToDisplay[Name] = Display
		table.insert(DisplayValues, Display)
	end

	local function ReadSaved()
		local Map = {}
		if Environment.isfile and Environment.readfile and Environment.isfile(SavePath) then
			local Success, Data = pcall(function()
				return HttpService:JSONDecode(Environment.readfile(SavePath))
			end)
			if Success and type(Data) == "table" then
				for _, Name in ipairs(Data) do
					if NameToDisplay[Name] then
						Map[NameToDisplay[Name]] = true
					end
				end
			end
		end
		return Map
	end

	local function WriteSaved(Selected)
		if not (Environment.writefile and Environment.isfolder) then
			return
		end
		local List = {}
		for Display in pairs(Selected) do
			if DisplayToName[Display] then
				table.insert(List, DisplayToName[Display])
			end
		end
		table.sort(List)
		pcall(function()
			Environment.writefile(SavePath, HttpService:JSONEncode(List))
		end)
	end

	for Slot = 1, SlotCount do
		local Index = "FavoriteSlot" .. Slot
		FavoriteBox:AddToggle(Index, {
			Text = "Slot " .. Slot,
			Default = false,
			Callback = function(Value)
				local Name = Bound[Slot]
				if Name and Toggles[Name] and Toggles[Name].Value ~= Value then
					pcall(function()
						Toggles[Name]:SetValue(Value)
					end)
				end
			end
		})
		Slots[Slot] = Toggles[Index]
		pcall(function()
			Slots[Slot]:SetVisible(false)
		end)
	end

	local function Hook(Name)
		if Hooked[Name] then
			return
		end
		Hooked[Name] = true
		Toggles[Name]:OnChanged(function()
			for Slot = 1, SlotCount do
				if Bound[Slot] == Name and Slots[Slot].Value ~= Toggles[Name].Value then
					pcall(function()
						Slots[Slot]:SetValue(Toggles[Name].Value)
					end)
				end
			end
		end)
	end

	local function Refresh(Selected)
		local Chosen = {}
		for Display in pairs(Selected) do
			if DisplayToName[Display] then
				table.insert(Chosen, Display)
			end
		end
		table.sort(Chosen)

		for Slot = 1, SlotCount do
			local Display = Chosen[Slot]
			local Name = Display and DisplayToName[Display]
			Bound[Slot] = Name
			if Name then
				Hook(Name)
				pcall(function()
					Slots[Slot]:SetText(Display)
					Slots[Slot]:SetValue(Toggles[Name].Value)
					Slots[Slot]:SetVisible(true)
				end)
			else
				pcall(function()
					Slots[Slot]:SetVisible(false)
				end)
			end
		end
	end

	FavoriteBox:AddDropdown("FavoritePicker", {
		Text = "Pinned toggles (max " .. SlotCount .. ")",
		Values = DisplayValues,
		Multi = true,
		Searchable = true,
		Callback = function(Value)
			if type(Value) == "table" then
				Refresh(Value)
				WriteSaved(Value)
			end
		end
	})

	FavoriteBox:AddDivider()

	local Saved = ReadSaved()
	if next(Saved) then
		pcall(function()
			Options.FavoritePicker:SetValue(Saved)
		end)
		Refresh(Saved)
	end
end
