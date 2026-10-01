return function(Env)
	local Services = Env.Services
	local Library = Env.Library
	local Container = Env.Container

	local NotificationLibrary = {
		LiveNotifications = 0,
		Notifications = 1
	}

	local Kinds = {
		info = { Glyph = "i" },
		success = { Glyph = "+", Color = Color3.fromRGB(80, 220, 140) },
		warning = { Glyph = "!", Color = Color3.fromRGB(255, 190, 70) },
		error = { Glyph = "x", Color = Color3.fromRGB(255, 90, 100) }
	}

	local function InferKind(TitleText, Desc)
		local Text = string.lower(tostring(TitleText) .. " " .. tostring(Desc))
		if Text:find("fail") or Text:find("error") or Text:find("cannot") or Text:find("can't") then
			return "error"
		end
		if Text:find("warning") or Text:find("spawned") or Text:find("danger") then
			return "warning"
		end
		if Text:find("success") or Text:find("copied") or Text:find("complete") or Text:find("loaded") then
			return "success"
		end
		return "info"
	end

	function NotificationLibrary:Notify(TitleText, Desc, Delay, Kind)
		task.spawn(function()
			local Width = Library.IsMobile and 300 or 380
			local Gap = 62
			local Margin = 16
			local Style = Kinds[Kind] or Kinds[InferKind(TitleText, Desc)]
			local Tint = Style.Color or Library.Scheme.AccentColor

			local Notification = Instance.new("Frame")
			local Stroke = Instance.new("UIStroke")
			local Line = Instance.new("Frame")
			local Badge = Instance.new("TextLabel")
			local BadgeCorner = Instance.new("UICorner")
			local NotificationCorner = Instance.new("UICorner")
			local Title = Instance.new("TextLabel")
			local Description = Instance.new("TextLabel")

			Notification.Name = "Notification"
			Notification.Parent = Container
			Notification.BackgroundColor3 = Library.Scheme.BackgroundColor
			Notification.BackgroundTransparency = 0.12
			Notification.ClipsDescendants = true
			Notification.BorderSizePixel = 0
			Notification.Position = UDim2.new(1, 5, 0, 60 + (Gap * NotificationLibrary.LiveNotifications))
			Notification.Size = UDim2.new(0, Width, 0, 54)
			Notification:SetAttribute("ID", NotificationLibrary.Notifications)
			Notification:SetAttribute("CurrentPosition", Notification.Position)

			Stroke.Color = Tint
			Stroke.Transparency = 0.65
			Stroke.Thickness = 1
			Stroke.Parent = Notification

			NotificationCorner.CornerRadius = UDim.new(0, 10)
			NotificationCorner.Parent = Notification

			Line.Name = "Line"
			Line.Parent = Notification
			Line.BackgroundColor3 = Tint
			Line.BorderSizePixel = 0
			Line.Position = UDim2.new(0, 0, 1, -2)
			Line.Size = UDim2.new(0, 0, 0, 2)

			Badge.Name = "Badge"
			Badge.Parent = Notification
			Badge.BackgroundColor3 = Tint
			Badge.BackgroundTransparency = 0.8
			Badge.Position = UDim2.new(0, 14, 0.5, -14)
			Badge.Size = UDim2.new(0, 28, 0, 28)
			Badge.Font = Enum.Font.GothamBold
			Badge.Text = Style.Glyph
			Badge.TextColor3 = Tint
			Badge.TextSize = 16

			BadgeCorner.CornerRadius = UDim.new(0, 14)
			BadgeCorner.Parent = Badge

			Title.Name = "Title"
			Title.Parent = Notification
			Title.BackgroundTransparency = 1
			Title.Position = UDim2.new(0, 54, 0, 8)
			Title.Size = UDim2.new(1, -66, 0, 18)
			Title.Font = Enum.Font.GothamBold
			Title.TextTruncate = Enum.TextTruncate.AtEnd
			Title.Text = TitleText or "..."
			Title.TextColor3 = Library.Scheme.FontColor
			Title.TextSize = 13
			Title.TextStrokeTransparency = 1
			Title.TextXAlignment = Enum.TextXAlignment.Left

			Description.Name = "Description"
			Description.Parent = Notification
			Description.BackgroundTransparency = 1
			Description.Position = UDim2.new(0, 54, 0, 27)
			Description.Size = UDim2.new(1, -66, 0, 18)
			Description.Font = Enum.Font.Gotham
			Description.TextTruncate = Enum.TextTruncate.AtEnd
			Description.Text = Desc or "..."
			Description.TextColor3 = Library.Scheme.FontColor
			Description.TextTransparency = 0.25
			Description.TextSize = 12
			Description.TextStrokeTransparency = 1
			Description.TextXAlignment = Enum.TextXAlignment.Left

			NotificationLibrary.LiveNotifications += 1
			NotificationLibrary.Notifications += 1

			Services.TweenService:Create(
				Notification,
				TweenInfo.new(1, Enum.EasingStyle.Exponential),
				{ Position = UDim2.new(1, -(Width + Margin), 0, Notification.Position.Y.Offset) }
			):Play()

			task.wait(0.25)
			if typeof(Delay) == "Instance" then
				Delay.Destroying:Wait()
			else
				Services.TweenService:Create(
					Line,
					TweenInfo.new(Delay - 0.25, Enum.EasingStyle.Linear),
					{ Size = UDim2.new(1, 0, 0, 2) }
				):Play()
				task.wait(Delay - 0.25)
			end

			Notification:SetAttribute("Destroying", true)

			Services.TweenService:Create(
				Notification,
				TweenInfo.new(0.75, Enum.EasingStyle.Exponential, Enum.EasingDirection.In),
				{ Position = UDim2.new(1, 5, 0, Notification.Position.Y.Offset) }
			):Play()

			NotificationLibrary.LiveNotifications -= 1

			local NotifId = Notification:GetAttribute("ID")

			for _, Object in Container:GetChildren() do
				if Object.Name == "Notification"
					and Object:GetAttribute("ID")
					and Object:GetAttribute("ID") > NotifId
					and Object:GetAttribute("Destroying") ~= true
					and Object.Position.Y.Offset ~= 60
				then
					local NewY = Object:GetAttribute("CurrentPosition").Y.Offset - Gap
					Object:SetAttribute("CurrentPosition", UDim2.new(1, -(Width + Margin), 0, NewY))
					Services.TweenService:Create(
						Object,
						TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut),
						{ Position = UDim2.new(1, -(Width + Margin), 0, NewY) }
					):Play()
				end
			end

			task.wait(0.75)
			Notification:Destroy()
		end)
	end

	return NotificationLibrary
end
