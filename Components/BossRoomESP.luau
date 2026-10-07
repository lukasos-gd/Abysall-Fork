return function(Env)
	local Functions = Env.Functions
	local Groupbox = Env.Groupbox
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options
	local CollectionService = game:GetService("CollectionService")

	local WrongColor = Color3.fromRGB(150, 150, 150)

	Groupbox:AddToggle("BossRoomWrongBoxesToggle", {
		Text = "Boss Room: Show Wrong Boxes",
		Default = false,
		Tooltip = "Also labels the boxes that don't match any deposit machine. Needs Objectives on."
	})

	local Shown = {}
	local Watched = {}
	local Connections = {}

	local function SetESP(Object, Text, Color)
		local Current = Shown[Object]
		if Text == nil then
			if Current then
				Shown[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
			return
		end
		if Current and Current.Text == Text and Current.Color == Color then
			return
		end
		if Current then
			pcall(Functions.RemoveESP, Object)
		end
		Shown[Object] = { Text = Text, Color = Color }
		pcall(Functions.AddESP, {
			Object = Object,
			Text = Text,
			Color = Color
		})
	end

	local MaxDistance = 670
	local LocalPlayer = game:GetService("Players").LocalPlayer

	local function IsFar(Object)
		local Character = LocalPlayer.Character
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		local Origin = Root and Root.Position or workspace.CurrentCamera.CFrame.Position
		local Position
		if Object:IsA("Model") then
			Position = Object:GetPivot().Position
		else
			Position = Object.Position
		end
		local Limit = Shown[Object] and MaxDistance or (MaxDistance - 20)
		return (Position - Origin).Magnitude > Limit
	end

	local Refresh

	local function Hook(Object, Attribute)
		if Watched[Object] then
			return
		end
		Watched[Object] = true
		if Attribute then
			table.insert(Connections, Object:GetAttributeChangedSignal(Attribute):Connect(function()
				Refresh()
			end))
		end
		Object.Destroying:Once(function()
			Watched[Object] = nil
			if Shown[Object] then
				Shown[Object] = nil
				pcall(Functions.RemoveESP, Object)
			end
		end)
	end

	Refresh = function()
		local Enabled = Toggles.ObjectiveESPToggle.Value
		local Base = Options.ObjectiveESPColor.Value
		local Machines = CollectionService:GetTagged("PackageDepositMachine")
		local Needed = {}

		for _, Machine in ipairs(Machines) do
			local Id = Machine:GetAttribute("BoxID")
			if Id then
				Needed[Id] = true
			end
		end

		for _, Machine in ipairs(Machines) do
			Hook(Machine, "BoxID")
			local Id = Machine:GetAttribute("BoxID")
			if Enabled and Id and not IsFar(Machine) then
				SetESP(Machine, "Deposit [" .. Id .. "]", Base)
			else
				SetESP(Machine, nil)
			end
		end

		for _, Box in ipairs(CollectionService:GetTagged("ArchivesStorageBoxDrop")) do
			Hook(Box, nil)
			local Id = Box:GetAttribute("Tool_BoxID")
			local Text
			local Color
			if Enabled and Id and not IsFar(Box) then
				if Needed[Id] then
					Text = "Box [" .. Id .. "]"
					Color = Base
				elseif Toggles.BossRoomWrongBoxesToggle.Value then
					Text = "Box [" .. Id .. "] (wrong)"
					Color = WrongColor
				end
			end
			SetESP(Box, Text, Color)
		end
	end

	for _, Tag in ipairs({ "PackageDepositMachine", "ArchivesStorageBoxDrop" }) do
		table.insert(Connections, CollectionService:GetInstanceAddedSignal(Tag):Connect(function()
			task.defer(Refresh)
		end))
		table.insert(Connections, CollectionService:GetInstanceRemovedSignal(Tag):Connect(function()
			task.defer(Refresh)
		end))
	end

	Toggles.ObjectiveESPToggle:OnChanged(Refresh)
	Toggles.BossRoomWrongBoxesToggle:OnChanged(Refresh)
	Options.ObjectiveESPColor:OnChanged(function()
		for Object in pairs(Shown) do
			Shown[Object] = nil
			pcall(Functions.RemoveESP, Object)
		end
		Refresh()
	end)

	local Running = true
	task.spawn(function()
		while Running do
			task.wait(0.5)
			pcall(Refresh)
		end
	end)

	Abysall.Cleanup:Add(function()
		Running = false
		for Object in pairs(Shown) do
			pcall(Functions.RemoveESP, Object)
		end
		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end
	end)

	Refresh()
end
