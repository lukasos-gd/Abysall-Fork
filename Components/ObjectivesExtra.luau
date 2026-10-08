return function(Env)
	local Functions = Env.Functions
	local ItemNames = Env.ItemNames
	local Library = Abysall.Interface.Library
	local Toggles = Library.Toggles
	local Options = Library.Options

	local Finders = {
		{
			Label = "Fire Alarm",
			Match = function(Name)
				local Clean = string.lower(Name):gsub("[^%a]", "")
				return Clean:find("firealarm", 1, true) ~= nil
			end
		}
	}

	local Alive = {}
	local Shown = {}
	local Connections = {}

	local function Refresh(Object)
		local Label = Alive[Object]
		if not Label then
			return
		end
		if Toggles.ObjectiveESPToggle.Value then
			if not Shown[Object] then
				Shown[Object] = true
				pcall(Functions.AddESP, {
					Object = Object,
					Text = Label,
					Color = Options.ObjectiveESPColor.Value
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
		if ItemNames[Object.Name] then
			return
		end
		for _, Finder in ipairs(Finders) do
			if Finder.Match(Object.Name) then
				local Ancestor = Object.Parent
				while Ancestor and Ancestor ~= workspace do
					if Alive[Ancestor] then
						return
					end
					Ancestor = Ancestor.Parent
				end
				Alive[Object] = Finder.Label
				Refresh(Object)
				Object.Destroying:Once(function()
					Alive[Object] = nil
					if Shown[Object] then
						Shown[Object] = nil
						pcall(Functions.RemoveESP, Object)
					end
				end)
				return
			end
		end
	end

	task.spawn(function()
		local Count = 0
		for _, Descendant in ipairs(workspace:GetDescendants()) do
			if Descendant:IsA("Model") then
				Consider(Descendant)
			end
			Count += 1
			if Count % 2000 == 0 then
				task.wait()
			end
		end
	end)

	table.insert(Connections, workspace.DescendantAdded:Connect(function(Descendant)
		if Descendant:IsA("Model") then
			Consider(Descendant)
		end
	end))

	Toggles.ObjectiveESPToggle:OnChanged(RefreshAll)
	Options.ObjectiveESPColor:OnChanged(function()
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
