-- RapHub | break-steal-egg.lua

local Library = (function()
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local Custom = {}
do
	-- Tema RapHub (ungu)
	Custom.ColorRGB = Color3.fromRGB(155, 89, 255) -- aksen utama
	Custom.Background = Color3.fromRGB(17, 12, 26) -- latar window
	Custom.Stroke = Color3.fromRGB(78, 48, 130) -- garis tepi window
	Custom.Dark = Color3.fromRGB(24, 16, 38) -- panel gelap (dropdown, notif)

	function Custom:Create(Name, Properties, Parent)
		local _instance = Instance.new(Name)

		for i, v in pairs(Properties) do
			_instance[i] = v
		end

		if Parent then
			_instance.Parent = Parent
		end

		return _instance
	end

	function Custom:EnabledAFK()
		Player.Idled:Connect(function()
			VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
			task.wait(1)
			VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
		end)
	end
end

Custom:EnabledAFK()

-- Cari parent GUI yang aman (Studio -> PlayerGui, executor -> gethui/CoreGui)
local function GetGuiParent()
	if RunService:IsStudio() then
		return Player:WaitForChild("PlayerGui")
	end
	local ok, hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and hui then
		return hui
	end
	local ok2, core = pcall(function()
		return cloneref and cloneref(game:GetService("CoreGui")) or game:GetService("CoreGui")
	end)
	if ok2 and core then
		return core
	end
	return Player:WaitForChild("PlayerGui")
end

-- Logo tombol buka panel (muncul saat panel di-minimize).
-- Ganti dengan asset ID gambar logo bulat kamu, contoh: "rbxassetid://1234567890"
Custom.LogoImage = "rbxassetid://139538771251251"

-- Hapus panel lama kalau script dieksekusi ulang
local Env = (getgenv and getgenv()) or _G
if type(Env.RapHubCleanup) == "function" then
	pcall(Env.RapHubCleanup)
end
local CreatedGuis = {}

local function OpenClose()
	local ScreenGui = Custom:Create("ScreenGui", {
		Name = "RapHubToggle",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 999,
	}, GetGuiParent())
	table.insert(CreatedGuis, ScreenGui)

	local Button = Custom:Create("ImageButton", {
		Name = "OpenButton",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Custom.Dark,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 80, 0, 100),
		Size = UDim2.new(0, 56, 0, 56),
		Image = Custom.LogoImage,
		ScaleType = Enum.ScaleType.Crop,
		AutoButtonColor = false,
		Visible = false,
	}, ScreenGui)

	Custom:Create("UICorner", { CornerRadius = UDim.new(1, 0) }, Button)
	Custom:Create("UIStroke", { Color = Custom.ColorRGB, Thickness = 2.5 }, Button)

	-- Huruf cadangan kalau gambar logo gagal dimuat
	local Fallback = Custom:Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = "R",
		TextColor3 = Custom.ColorRGB,
		TextSize = 28,
		Visible = false,
	}, Button)

	-- "R" hanya tampil selama logo belum termuat; hilang otomatis begitu logo siap
	local function UpdateFallback()
		Fallback.Visible = not Button.IsLoaded
	end
	Button:GetPropertyChangedSignal("IsLoaded"):Connect(UpdateFallback)
	Button:GetPropertyChangedSignal("Visible"):Connect(UpdateFallback)

	task.spawn(function()
		pcall(function()
			game:GetService("ContentProvider"):PreloadAsync({ Custom.LogoImage })
		end)
		UpdateFallback()
	end)

	-- Bisa digeser; geser tidak dianggap klik
	local Dragging, DragStart, StartPos, Moved = false, nil, nil, false

	Button.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Dragging, Moved = true, false
			DragStart, StartPos = input.Position, Button.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			Dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local Delta = input.Position - DragStart
			if Delta.Magnitude > 6 then
				Moved = true
			end
			Button.Position =
				UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		end
	end)

	return Button, function()
		return Moved
	end
end

local Open_Close, OpenCloseWasDragged = OpenClose()

local function MakeDraggable(topbarobject, object)
	local dragging, dragStart, startPos = false, nil, nil

	local function UpdatePos(input)
		local delta = input.Position - dragStart
		local newPos =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		object.Position = newPos
	end

	topbarobject.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	topbarobject.InputChanged:Connect(function(input)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			UpdatePos(input)
		end
	end)
end

function CircleClick(Button, X, Y)
	task.spawn(function()
		Button.ClipsDescendants = true

		local Circle = Instance.new("ImageLabel")
		Circle.Image = "rbxassetid://106471194043211"
		Circle.ImageColor3 = Custom.ColorRGB
		Circle.ImageTransparency = 0.8999999761581421
		Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Circle.BackgroundTransparency = 1
		Circle.ZIndex = 10
		Circle.Name = "Circle"
		Circle.Parent = Button

		local NewX = X - Button.AbsolutePosition.X
		local NewY = Y - Button.AbsolutePosition.Y
		Circle.Position = UDim2.new(0, NewX, 0, NewY)

		local Size = math.max(Button.AbsoluteSize.X, Button.AbsoluteSize.Y) * 1.5

		local Time = 0.5
		local TweenInfo = TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		local Tween = TweenService:Create(Circle, TweenInfo, {
			Size = UDim2.new(0, Size, 0, Size),
			Position = UDim2.new(0.5, -Size / 2, 0.5, -Size / 2),
		})

		Tween:Play()

		Tween.Completed:Connect(function()
			for i = 1, 10 do
				Circle.ImageTransparency = Circle.ImageTransparency + 0.01
				wait(Time / 10)
			end
			Circle:Destroy()
		end)
	end)
end

local Speed_Library = {}

Speed_Library.Unloaded = false

Env.RapHubCleanup = function()
	Speed_Library.Unloaded = true
	for _, Gui in ipairs(CreatedGuis) do
		pcall(function()
			Gui:Destroy()
		end)
	end
end

-- /// Notifikasi (tumpuk di kanan bawah, hilang otomatis setelah Delay detik)

local NotifyHolder
local NotifyCount = 0

local function GetNotifyHolder()
	if NotifyHolder and NotifyHolder.Parent then
		return NotifyHolder
	end

	local Gui = Custom:Create("ScreenGui", {
		Name = "RapHubNotify",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		DisplayOrder = 1000,
	}, GetGuiParent())
	table.insert(CreatedGuis, Gui)

	NotifyHolder = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.new(0, 300, 1, -40),
		Name = "NotificationLayout",
	}, Gui)

	Custom:Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 8),
	}, NotifyHolder)

	return NotifyHolder
end

function Speed_Library:SetNotification(Config)
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	local Content = Config[3] or Config.Content or ""
	local Time = tonumber(Config[5] or Config.Time) or 0.35
	local Delay = tonumber(Config[6] or Config.Delay) or 3

	NotifyCount += 1

	local Slot = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = NotifyCount,
		Size = UDim2.new(1, 0, 0, 60),
		Name = "NotificationFrame",
	}, GetNotifyHolder())

	local Card = Custom:Create("Frame", {
		BackgroundColor3 = Custom.Dark,
		BorderSizePixel = 0,
		Position = UDim2.new(1, 30, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		ClipsDescendants = true,
		Name = "NotificationFrameReal",
	}, Slot)

	Custom:Create("UICorner", { CornerRadius = UDim.new(0, 8) }, Card)
	Custom:Create("UIStroke", { Color = Custom.Stroke, Thickness = 1.5 }, Card)

	Custom:Create("Frame", {
		BackgroundColor3 = Custom.ColorRGB,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 8, 0, 10),
		Size = UDim2.new(0, 3, 1, -20),
		Name = "Accent",
	}, Card)

	Custom:Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		RichText = true,
		Text = Title .. '  <font color="#' .. Custom.ColorRGB:ToHex() .. '">' .. Description .. "</font>",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 20, 0, 9),
		Size = UDim2.new(1, -50, 0, 16),
		Name = "Title",
	}, Card)

	local ContentLabel = Custom:Create("TextLabel", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamMedium,
		Text = Content,
		TextColor3 = Color3.fromRGB(180, 170, 200),
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(0, 20, 0, 29),
		Size = UDim2.new(1, -32, 0, 0),
		Name = "Content",
	}, Card)

	local CloseButton = Custom:Create("TextButton", {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		Text = "X",
		TextColor3 = Color3.fromRGB(200, 200, 200),
		TextSize = 14,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -6, 0, 6),
		Size = UDim2.new(0, 22, 0, 22),
		Name = "Close",
	}, Card)

	local Progress = Custom:Create("Frame", {
		BackgroundColor3 = Custom.ColorRGB,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		Name = "Progress",
	}, Card)

	local Closed = false
	local function Close()
		if Closed then
			return
		end
		Closed = true

		local Tween = TweenService:Create(
			Card,
			TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 30, 0, 0) }
		)
		Tween:Play()
		Tween.Completed:Wait()
		Slot:Destroy()
	end

	CloseButton.Activated:Connect(function()
		task.spawn(Close)
	end)

	task.spawn(function()
		task.wait()
		Slot.Size = UDim2.new(1, 0, 0, math.max(52, ContentLabel.AbsoluteSize.Y + 40))

		TweenService:Create(
			Card,
			TweenInfo.new(Time, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(0, 0, 0, 0) }
		):Play()
		TweenService:Create(Progress, TweenInfo.new(Delay, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) })
			:Play()

		task.wait(Delay)
		Close()
	end)

	local Handle = {}
	function Handle:Close()
		task.spawn(Close)
	end
	return Handle
end

function Speed_Library:CreateWindow(Config)
	local Title = Config[1] or Config.Title or ""
	local Description = Config[2] or Config.Description or ""
	local TabWidth = Config[3] or Config["Tab Width"] or 120
	local SizeUi = Config[4] or Config.SizeUi or UDim2.fromOffset(550, 315)

	local Funcs = {}

	local SpeedHubXGui = Custom:Create("ScreenGui", {
		Name = "RapHub",
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	}, GetGuiParent())
	table.insert(CreatedGuis, SpeedHubXGui)

	local DropShadowHolder = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 455, 0, 350),
		ZIndex = 0,
		Name = "DropShadowHolder",
		Position = UDim2.new(
			0,
			(SpeedHubXGui.AbsoluteSize.X // 2 - 455 // 2),
			0,
			(SpeedHubXGui.AbsoluteSize.Y // 2 - 350 // 2)
		),
	}, SpeedHubXGui)

	local DropShadow = Custom:Create("ImageLabel", {
		Image = "",
		ImageColor3 = Custom.Background,
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		ZIndex = 0,
		Name = "DropShadow",
	}, DropShadowHolder)

	local Main = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Custom.Background,
		BackgroundTransparency = 0.05,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = SizeUi,
		Name = "Main",
	}, DropShadow)

	Custom:Create("UICorner", {}, Main)

	Custom:Create("UIStroke", {
		Color = Custom.Stroke,
		Thickness = 1.6,
	}, Main)

	local Top = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 38),
		Name = "Top",
	}, Main)

	local TextLabel = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
	}, Top)

	Custom:Create("UICorner", {}, Top)

	local TextLabel1 = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = Description,
		TextColor3 = Custom.ColorRGB,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, -(TextLabel.TextBounds.X + 104), 1, 0),
		Position = UDim2.new(0, TextLabel.TextBounds.X + 15, 0, 0),
	}, Top)

	Custom:Create("UIStroke", {
		Color = Custom.ColorRGB,
		Thickness = 0.4,
	}, TextLabel1)

	local Close = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "X",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Close",
	}, Top)

	local Min = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "-",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 18,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(1, -42, 0.5, 0),
		Size = UDim2.new(0, 25, 0, 25),
		Name = "Min",
	}, Top)

	local LayersTab = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 9, 0, 50),
		Size = UDim2.new(0, TabWidth, 1, -59),
		Name = "LayersTab",
	}, Main)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 2),
	}, LayersTab)

	Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.85,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 38),
		Size = UDim2.new(1, 0, 0, 1),
		Name = "DecideFrame",
	}, Main)

	local Layers = Custom:Create("Frame", {
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, TabWidth + 18, 0, 50),
		Size = UDim2.new(1, -(TabWidth + 9 + 18), 1, -59),
		Name = "Layers",
	}, Main)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 2),
	}, Layers)

	local NameTab = Custom:Create("TextLabel", {
		Font = Enum.Font.GothamBold,
		Text = "",
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 24,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 30),
		Name = "NameTab",
	}, Layers)

	local LayersReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 1, -33),
		Name = "LayersReal",
	}, Layers)

	local LayersFolder = Custom:Create("Folder", {
		Name = "LayersFolder",
	}, LayersReal)

	local LayersPageLayout = Custom:Create("UIPageLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Name = "LayersPageLayout",
		TweenTime = 0.5,
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
	}, LayersFolder)

	local ScrollTab = Custom:Create("ScrollingFrame", {
		CanvasSize = UDim2.new(0, 0, 2.10000002, 0),
		ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
		ScrollBarThickness = 0,
		Active = true,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.9990000128746033,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -10),
		Name = "ScrollTab",
	}, LayersTab)

	local UIListLayout = Custom:Create("UIListLayout", {
		Padding = UDim.new(0, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, ScrollTab)

	local function UpdateSize()
		local _Total = 0

		for _, v in pairs(ScrollTab:GetChildren()) do
			if v.Name ~= "UIListLayout" then
				_Total = _Total + 3 + v.Size.Y.Offset
			end
		end

		ScrollTab.CanvasSize = UDim2.new(0, 0, 0, _Total)
	end

	ScrollTab.ChildAdded:Connect(UpdateSize)
	ScrollTab.ChildRemoved:Connect(UpdateSize)

	local function SetMinimized(State)
		DropShadowHolder.Visible = not State
		Open_Close.Visible = State
	end

	Min.Activated:Connect(function()
		CircleClick(Min, Player:GetMouse().X, Player:GetMouse().Y)
		SetMinimized(true)
	end)

	Open_Close.Activated:Connect(function()
		if OpenCloseWasDragged() then
			return
		end
		SetMinimized(false)
	end)

	-- Tombol keyboard RightControl untuk buka/tutup panel
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl and SpeedHubXGui.Parent then
			SetMinimized(DropShadowHolder.Visible)
		end
	end)

	Close.Activated:Connect(function()
		CircleClick(Close, Player:GetMouse().X, Player:GetMouse().Y)
		Env.RapHubCleanup()
	end)

	DropShadowHolder.Size = UDim2.new(0, 115 + TextLabel.TextBounds.X + 1 + TextLabel1.TextBounds.X, 0, 350)
	MakeDraggable(Top, DropShadowHolder)

	-- /// Resize (tarik pojok kanan bawah)

	local MinSize = Vector2.new(420, 260)

	local ResizeHandle = Custom:Create("TextButton", {
		Name = "ResizeHandle",
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -3, 1, -3),
		Size = UDim2.fromOffset(18, 18),
		Text = "",
		AutoButtonColor = false,
		ZIndex = 20,
	}, Main)

	for _, Dot in ipairs({ { 14, 4 }, { 10, 8 }, { 14, 8 }, { 6, 12 }, { 10, 12 }, { 14, 12 } }) do
		Custom:Create("Frame", {
			BackgroundColor3 = Custom.ColorRGB,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(Dot[1] - 1, Dot[2] - 1),
			Size = UDim2.fromOffset(2, 2),
			ZIndex = 20,
		}, ResizeHandle)
	end

	local Resizing, ResizeStart, StartSize, StartHolderPos = false, nil, nil, nil

	ResizeHandle.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			Resizing = true
			ResizeStart = input.Position
			StartSize = Vector2.new(Main.Size.X.Offset, Main.Size.Y.Offset)
			StartHolderPos = DropShadowHolder.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					Resizing = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if
			Resizing
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			local Delta = input.Position - ResizeStart
			local Viewport = SpeedHubXGui.AbsoluteSize

			local W = math.clamp(StartSize.X + Delta.X, MinSize.X, math.max(MinSize.X, Viewport.X - 20))
			local H = math.clamp(StartSize.Y + Delta.Y, MinSize.Y, math.max(MinSize.Y, Viewport.Y - 20))

			Main.Size = UDim2.fromOffset(W, H)
			DropShadow.Size = UDim2.fromOffset(W, H)

			-- Panel berpusat di holder, jadi geser holder setengah perubahan agar pojok kiri atas diam
			DropShadowHolder.Position = UDim2.new(
				StartHolderPos.X.Scale,
				StartHolderPos.X.Offset + (W - StartSize.X) / 2,
				StartHolderPos.Y.Scale,
				StartHolderPos.Y.Offset + (H - StartSize.Y) / 2
			)
		end
	end)

	-- /// Blur

	local MoreBlur = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Position = UDim2.new(1, 8, 1, 8),
		Size = UDim2.new(1, 154, 1, 54),
		Visible = false,
		Name = "MoreBlur",
	}, Layers)

	local DropShadowHolder1 = Custom:Create("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		ZIndex = 0,
		Name = "DropShadowHolder",
	}, MoreBlur)

	local DropShadow1 = Custom:Create("ImageLabel", {
		Image = "",
		ImageColor3 = Color3.fromRGB(0, 0, 0),
		ImageTransparency = 0.5,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, 35, 1, 35),
		ZIndex = 0,
		Name = "DropShadow",
	}, DropShadowHolder1)

	Custom:Create("UICorner", {}, MoreBlur)

	local ConnectButton = Custom:Create("TextButton", {
		Font = Enum.Font.SourceSans,
		Text = "",
		TextColor3 = Color3.fromRGB(0, 0, 0),
		TextSize = 14,
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0),
		Name = "ConnectButton",
	}, MoreBlur)

	local DropdownSelect = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Custom.Dark,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = UDim2.new(1, 172, 0.5, 0),
		Size = UDim2.new(0, 160, 1, -16),
		Name = "DropdownSelect",
		ClipsDescendants = true,
	}, MoreBlur)

	ConnectButton.Activated:Connect(function()
		if MoreBlur.Visible then
			local tweenInfo = TweenInfo.new(0.2)

			local _Hide = TweenService:Create(MoreBlur, tweenInfo, { BackgroundTransparency = 0.999 })
			local _Move = TweenService:Create(DropdownSelect, tweenInfo, { Position = UDim2.new(1, 172, 0.5, 0) })

			_Hide:Play()
			_Move:Play()

			task.wait(0.2)
			MoreBlur.Visible = false
		end
	end)

	Custom:Create("UICorner", {
		CornerRadius = UDim.new(0, 3),
		Parent = DropdownSelect,
	})

	Custom:Create("UIStroke", {
		Color = Color3.fromRGB(255, 255, 255),
		Thickness = 2.5,
		Transparency = 0.8,
		Parent = DropdownSelect,
	})

	local DropdownSelectReal = Custom:Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = 0.999,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(1, -10, 1, -10),
		Name = "DropdownSelectReal",
		Parent = DropdownSelect,
	})

	local DropdownFolder = Custom:Create("Folder", {
		Name = "DropdownFolder",
		Parent = DropdownSelectReal,
	})

	local DropPageLayout = Custom:Create("UIPageLayout", {
		EasingDirection = Enum.EasingDirection.InOut,
		EasingStyle = Enum.EasingStyle.Quad,
		TweenTime = 0.01,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Archivable = false,
		Name = "DropPageLayout",
		Parent = DropdownFolder,
	})

	-- /// Create Tab

	local Tabs = {}
	local CountTab = 0
	local CountDropdown = 0
	function Tabs:CreateTab(Config)
		local _Name = Config[1] or Config.Name or ""
		local Icon = Config[2] or Config.Icon or ""

		local ScrolLayers = Custom:Create("ScrollingFrame", {
			ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80),
			ScrollBarThickness = 0,
			Active = true,
			LayoutOrder = CountTab,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "ScrolLayers",
			Parent = LayersFolder,
		})

		Custom:Create("UIListLayout", {
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = ScrolLayers,
		})

		local Tab = Custom:Create("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = CountTab == 0 and 0.92 or 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			LayoutOrder = CountTab,
			Size = UDim2.new(1, 0, 0, 30),
			Name = "Tab",
			Parent = ScrollTab,
		})

		Custom:Create("UICorner", {
			CornerRadius = UDim.new(0, 4),
			Parent = Tab,
		})

		local TabButton = Custom:Create("TextButton", {
			Font = Enum.Font.GothamBold,
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Name = "TabButton",
		}, Tab)

		Custom:Create("TextLabel", {
			Font = Enum.Font.GothamBold,
			Text = _Name,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 30, 0, 0),
			Name = "TabName",
		}, Tab)

		Custom:Create("ImageLabel", {
			Image = Icon,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 0.999,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 9, 0, 7),
			Size = UDim2.new(0, 16, 0, 16),
			Name = "FeatureImg",
		}, Tab)

		if CountTab == 0 then
			LayersPageLayout:JumpToIndex(0)
			NameTab.Text = _Name

			local ChooseFrame = Custom:Create("Frame", {
				BackgroundColor3 = Custom.ColorRGB,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 2, 0, 9),
				Size = UDim2.new(0, 1, 0, 12),
				Name = "ChooseFrame",
			}, Tab)

			Custom:Create("UIStroke", {
				Color = Custom.ColorRGB,
				Thickness = 1.6,
			}, ChooseFrame)

			Custom:Create("UICorner", {}, ChooseFrame)
		end

		TabButton.Activated:Connect(function()
			CircleClick(TabButton, Player:GetMouse().X, Player:GetMouse().Y)
			local FrameChoose = nil

			for _, s in pairs(ScrollTab:GetChildren()) do
				for _, v in pairs(s:GetChildren()) do
					if v.Name == "ChooseFrame" then
						FrameChoose = v
						break
					end
				end

				if FrameChoose then
					break
				end
			end

			if FrameChoose and Tab.LayoutOrder ~= LayersPageLayout.CurrentPage.LayoutOrder then
				for _, TabFrame in pairs(ScrollTab:GetChildren()) do
					if TabFrame.Name == "Tab" then
						TweenService:Create(
							TabFrame,
							TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
							{ BackgroundTransparency = 0.999 }
						):Play()
					end
				end

				local _TabT = TweenService:Create(
					Tab,
					TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.InOut),
					{ BackgroundTransparency = 0.92 }
				)
				local _FTween = TweenService:Create(
					FrameChoose,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Position = UDim2.new(0, 2, 0, 9 + (33 * Tab.LayoutOrder)) }
				)

				_TabT:Play()
				_FTween:Play()

				LayersPageLayout:JumpToIndex(Tab.LayoutOrder)

				task.wait(0.05)
				NameTab.Text = _Name

				TweenService:Create(
					FrameChoose,
					TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = UDim2.new(0, 1, 0, 20) }
				):Play()

				task.wait(0.2)
				TweenService:Create(
					FrameChoose,
					TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut),
					{ Size = UDim2.new(0, 1, 0, 12) }
				):Play()
			end
		end)

		--- /// Section

		local Sections, CountSection = {}, 0

		function Sections:AddSection(Title, OpenSection)
			local Title = Title or ""
			local OpenSection = OpenSection or false

			local Section = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.999,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = CountSection,
				Size = UDim2.new(1, 0, 0, 30),
				Name = "Section",
			}, ScrolLayers)

			local SectionReal = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.935,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(1, 1, 0, 30),
				Name = "SectionReal",
			}, Section)

			Custom:Create("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}, SectionReal)

			local SectionButton = Custom:Create("TextButton", {
				Font = Enum.Font.SourceSans,
				Text = "",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 14,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Name = "SectionButton",
			}, SectionReal)

			local FeatureFrame = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(1, -5, 0.5, 0),
				Size = UDim2.new(0, 20, 0, 20),
				Name = "FeatureFrame",
			}, SectionReal)

			local FeatureImg = Custom:Create("ImageLabel", {
				Image = "rbxassetid://125609963478878",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Rotation = -90,
				Size = UDim2.new(1, 6, 1, 6),
				Name = "FeatureImg",
			}, FeatureFrame)

			local SectionTitle = Custom:Create("TextLabel", {
				Font = Enum.Font.GothamBold,
				Text = Title,
				TextColor3 = Color3.fromRGB(230, 230, 230),
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.new(1, -50, 0, 13),
				Name = "SectionTitle",
			}, SectionReal)

			local SectionDecideFrame = Custom:Create("Frame", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 33),
				Size = UDim2.new(0, 0, 0, 2),
				Name = "SectionDecideFrame",
			}, Section)
			Custom:Create("UICorner", {}, SectionDecideFrame)
			Custom:Create("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Custom.Background),
					ColorSequenceKeypoint.new(0.5, Custom.ColorRGB),
					ColorSequenceKeypoint.new(1, Custom.Background),
				}),
			}, SectionDecideFrame)

			local SectionAdd = Custom:Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.9990000128746033,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 38),
				Size = UDim2.new(1, 0, 0, 100),
				Name = "SectionAdd",
			}, Section)

			Custom:Create("UICorner", {
				CornerRadius = UDim.new(0, 2),
			}, SectionAdd)

			Custom:Create("UIListLayout", {
				Padding = UDim.new(0, 3),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}, SectionAdd)

			local function UpdateSizeScroll()
				local OffsetY = 0

				for _, child in pairs(ScrolLayers:GetChildren()) do
					if child.Name ~= "UIListLayout" then
						OffsetY = OffsetY + 3 + child.Size.Y.Offset
					end
				end

				ScrolLayers.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
			end

			local function UpdateSizeSection()
				if OpenSection then
					local SectionSizeYWitdh = 38

					for _, v in pairs(SectionAdd:GetChildren()) do
						if v.Name ~= "UIListLayout" and v.Name ~= "UICorner" then
							SectionSizeYWitdh = SectionSizeYWitdh + v.Size.Y.Offset + 3
						end
					end

					TweenService:Create(FeatureFrame, TweenInfo.new(0.1), { Rotation = 90 }):Play()
					TweenService:Create(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 1, 0, SectionSizeYWitdh) })
						:Play()
					TweenService
						:Create(SectionAdd, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, SectionSizeYWitdh - 38) })
						:Play()
					TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(1, 0, 0, 2) }):Play()

					task.wait(0.5)
					UpdateSizeScroll()
				end
			end

			local function ToggleSection()
				CircleClick(SectionButton, Player:GetMouse().X, Player:GetMouse().Y)

				if OpenSection then
					TweenService:Create(FeatureFrame, TweenInfo.new(0.1), { Rotation = 0 }):Play()
					TweenService:Create(Section, TweenInfo.new(0.1), { Size = UDim2.new(1, 1, 0, 30) }):Play()
					TweenService:Create(SectionDecideFrame, TweenInfo.new(0.1), { Size = UDim2.new(0, 0, 0, 2) }):Play()

					OpenSection = false
					task.wait(0.1)
					UpdateSizeScroll()
				else
					OpenSection = true
					UpdateSizeSection()
				end
			end

			SectionButton.Activated:Connect(ToggleSection)
			SectionAdd.ChildAdded:Connect(UpdateSizeSection)
			SectionAdd.ChildRemoved:Connect(UpdateSizeSection)

			UpdateSizeScroll()

			local Item, ItemCount = {}, 0
			function Item:AddParagraph(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local SettingFuncs = {}

				local Paragraph = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Paragraph",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Paragraph)

				local ParagraphTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -16, 0, 13),
					Name = "ParagraphTitle",
				}, Paragraph)

				local ParagraphContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Name = "ParagraphContent",
				}, Paragraph)

				local function UpdateParagraphSize()
					ParagraphContent.TextWrapped = false
					local lineCount = math.ceil(ParagraphContent.TextBounds.X / ParagraphContent.AbsoluteSize.X)

					ParagraphContent.Size = UDim2.new(1, -16, 0, 12 + (12 * lineCount))
					Paragraph.Size = UDim2.new(1, 0, 0, ParagraphContent.AbsoluteSize.Y + 33)
					ParagraphContent.TextWrapped = true

					UpdateSizeSection()
				end

				UpdateParagraphSize()

				ParagraphContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateParagraphSize)

				function SettingFuncs:Set(Config)
					local Title = Config[1] or Config.Title or ""
					local Content = Config[2] or Config.Content or ""

					ParagraphTitle.Text = Title
					ParagraphContent.Text = Content

					UpdateParagraphSize()
				end

				return SettingFuncs
			end

			function Item:AddSeperator(Config)
				local Title = Config[1] or Config.Title or ""
				local Sep_Funcs = {}

				local Seperator = Custom:Create("Frame", {
					BackgroundColor3 = Custom.Dark,
					BackgroundTransparency = 0.1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 1,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 30),
					Name = "Seperator",
				}, SectionAdd)

				local SeperatorTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
					TextStrokeTransparency = 0.8,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Center,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 12, 0, 0),
					Size = UDim2.new(1, -16, 1, 0),
					Name = "SeperatorTitle",
				}, Seperator)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 6),
				}, Seperator)

				local Gradient = Custom:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 110, 220)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 70, 190)),
					}),
					Rotation = 90,
				}, Seperator)

				function Sep_Funcs:Set(Config)
					local Title = Config[1] or Config.Title or ""

					SeperatorTitle.Text = Title
				end

				ItemCount += 1
				return Sep_Funcs
			end

			function Item:AddLine()
				local LineFuncs = {}

				local Line = Custom:Create("Frame", {
					BackgroundColor3 = Custom.ColorRGB,
					BackgroundTransparency = 0.2,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 7),
					Name = "Line",
				}, SectionAdd)

				Custom:Create("UICorner", { CornerRadius = UDim.new(0, 3) }, Line)

				Custom:Create("UIGradient", {
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 80, 200)),
						ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 140)),
					}),
					Rotation = 0,
				}, Line)

				ItemCount += 1
				return LineFuncs
			end

			function Item:AddButton(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Icon = Config[3] or Config.Icon or "rbxassetid://7734010488"
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Button = {}

				local Button = Custom:Create("Frame", {
					Name = "Button",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Button)

				Custom:Create("TextLabel", {
					Name = "ButtonTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13),
				}, Button)

				local ButtonContent = Custom:Create("TextLabel", {
					Name = "ButtonContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12),
				}, Button)

				local function UpdateButtonSize()
					local _Height = 12 + (12 * (ButtonContent.TextBounds.X // ButtonContent.AbsoluteSize.X))
					ButtonContent.Size = UDim2.new(1, -100, 0, _Height)

					Button.Size = UDim2.new(1, 0, 0, ButtonContent.AbsoluteSize.Y + 33)
				end

				ButtonContent.TextWrapped = true
				UpdateButtonSize()

				ButtonContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					ButtonContent.TextWrapped = false
					UpdateButtonSize()
					ButtonContent.TextWrapped = true
					UpdateSizeSection()
				end)

				local ButtonButton = Custom:Create("TextButton", {
					Name = "ButtonButton",
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
				}, Button)

				local FeatureFrame1 = Custom:Create("Frame", {
					Name = "FeatureFrame",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 25, 0, 25),
				}, Button)

				Custom:Create("ImageLabel", {
					Name = "FeatureImg",
					Image = Icon,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 1, 0),
				}, FeatureFrame1)

				ButtonButton.Activated:Connect(function()
					CircleClick(ButtonButton, Player:GetMouse().X, Player:GetMouse().Y)

					Callback()
				end)

				ItemCount += 1
				return Funcs_Button
			end

			function Item:AddToggle(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or false
				local Callback = Config[4] or Config.Callback or function() end

				local Funcs_Toggle = { Value = Default }

				local Toggle = Custom:Create("Frame", {
					Name = "Toggle",
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Toggle)

				local ToggleTitle = Custom:Create("TextLabel", {
					Name = "ToggleTitle",
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextSize = 13,
					TextColor3 = Color3.fromRGB(231, 231, 231),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -100, 0, 13),
				}, Toggle)

				local ToggleContent = Custom:Create("TextLabel", {
					Name = "ToggleContent",
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextSize = 12,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextTransparency = 0.6,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -100, 0, 12),
				}, Toggle)

				local function UpdateToggleSize()
					ToggleContent.TextWrapped = false
					local Ratio = ToggleContent.TextBounds.X / ToggleContent.AbsoluteSize.X

					ToggleContent.Size = UDim2.new(1, -100, 0, 12 + (12 * math.ceil(Ratio)))
					Toggle.Size = UDim2.new(1, 0, 0, ToggleContent.AbsoluteSize.Y + 33)
					ToggleContent.TextWrapped = true
				end

				UpdateToggleSize()

				ToggleContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					UpdateToggleSize()
					UpdateSizeSection()
				end)

				local ToggleButton = Custom:Create("TextButton", {
					Name = "ToggleButton",
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
				}, Toggle)

				local FeatureFrame2 = Custom:Create("Frame", {
					Name = "FeatureFrame2",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.92,
					BorderSizePixel = 0,
					Position = UDim2.new(1, -15, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 15),
				}, Toggle)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, FeatureFrame2)

				local UIStroke8 = Custom:Create("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Thickness = 2,
					Transparency = 0.9,
				}, FeatureFrame2)

				local ToggleCircle = Custom:Create("Frame", {
					Name = "ToggleCircle",
					BackgroundColor3 = Color3.fromRGB(230, 230, 230),
					BorderSizePixel = 0,
					Size = UDim2.new(0, 14, 0, 14),
					Position = UDim2.new(0, 0, 0, 0),
				}, FeatureFrame2)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 15),
				}, ToggleCircle)

				local function ToggleAnimation(isOn)
					local TitleColor = isOn and Custom.ColorRGB or Color3.fromRGB(230, 230, 230)
					local CirclePosition = isOn and UDim2.new(0, 15, 0, 0) or UDim2.new(0, 0, 0, 0)
					local StrokeColor = isOn and Custom.ColorRGB or Color3.fromRGB(255, 255, 255)
					local StrokeTransparency = isOn and 0 or 0.9
					local FrameColor = isOn and Custom.ColorRGB or Color3.fromRGB(255, 255, 255)
					local FrameTransparency = isOn and 0 or 0.92

					local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

					TweenService:Create(ToggleTitle, tweenInfo, { TextColor3 = TitleColor }):Play()
					TweenService:Create(ToggleCircle, tweenInfo, { Position = CirclePosition }):Play()
					TweenService
						:Create(UIStroke8, tweenInfo, { Color = StrokeColor, Transparency = StrokeTransparency })
						:Play()
					TweenService:Create(
						FeatureFrame2,
						tweenInfo,
						{ BackgroundColor3 = FrameColor, BackgroundTransparency = FrameTransparency }
					):Play()
				end

				ToggleButton.Activated:Connect(function()
					CircleClick(ToggleButton, Player:GetMouse().X, Player:GetMouse().Y)
					Funcs_Toggle.Value = not Funcs_Toggle.Value
					Funcs_Toggle:Set(Funcs_Toggle.Value)
				end)

				function Funcs_Toggle:Set(Value)
					Callback(Value)
					ToggleAnimation(Value)
				end
				Funcs_Toggle:Set(Funcs_Toggle.Value)

				ItemCount += 1
				return Funcs_Toggle
			end

			function Item:AddSlider(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Increment = Config[3] or Config.Increment or 1
				local Min = Config[4] or Config.Min or 0
				local Max = Config[5] or Config.Max or 100
				local Default = Config[6] or Config.Default or 50
				local Callback = Config[7] or Config.Callback or function() end

				local Funcs_Slider = { Value = Default }

				local Slider = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9350000023841858,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Slider",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Slider)

				Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "SliderTitle",
				}, Slider)

				local SliderContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6000000238418579,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "SliderContent",
				}, Slider)

				local function UpdateSliderSize()
					SliderContent.TextWrapped = false
					SliderContent.Size = UDim2.new(
						1,
						-180,
						0,
						12 + (12 * math.floor(SliderContent.TextBounds.X / SliderContent.AbsoluteSize.X))
					)
					Slider.Size = UDim2.new(1, 0, 0, SliderContent.AbsoluteSize.Y + 33)
					SliderContent.TextWrapped = true
				end

				SliderContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					UpdateSliderSize()
					UpdateSizeSection()
				end)
				UpdateSliderSize()

				local SliderInput = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -155, 0.5, 0),
					Size = UDim2.new(0, 28, 0, 20),
					Name = "SliderInput",
				}, Slider)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 2),
				}, SliderInput)

				local TextBox = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					Text = "90",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 13,
					TextWrapped = true,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.9990000128746033,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, -1, 0, 0),
					Size = UDim2.new(1, 0, 1, 0),
				}, SliderInput)

				local SliderFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.800000011920929,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -20, 0.5, 0),
					Size = UDim2.new(0, 100, 0, 3),
					Name = "SliderFrame",
				}, Slider)

				Custom:Create("UICorner", {}, SliderFrame)

				local SliderDraggable = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0.899999976, 0, 0, 1),
					Name = "SliderDraggable",
				}, SliderFrame)

				Custom:Create("UICorner", {}, SliderDraggable)

				local SliderCircle = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Custom.ColorRGB,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 4, 0.5, 0),
					Size = UDim2.new(0, 8, 0, 8),
					Name = "SliderCircle",
				}, SliderDraggable)

				Custom:Create("UICorner", {}, SliderCircle)

				Custom:Create("UIStroke", {
					Color = Custom.ColorRGB,
				}, SliderCircle)

				local Dragging = false

				local function Round(Number, Factor)
					local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
					if Result < 0 then
						Result = Result + Factor
					end
					return Result
				end

				function Funcs_Slider:Set(Value)
					Value = math.clamp(Round(Value, Increment), Min, Max)
					Funcs_Slider.Value = Value
					TextBox.Text = tostring(Value)

					TweenService:Create(
						SliderDraggable,
						TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Size = UDim2.fromScale((Value - Min) / (Max - Min), 1) }
					):Play()
				end

				SliderFrame.InputBegan:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						Dragging = true
					end
				end)

				SliderFrame.InputEnded:Connect(function(Input)
					if
						Input.UserInputType == Enum.UserInputType.MouseButton1
						or Input.UserInputType == Enum.UserInputType.Touch
					then
						Dragging = false
						Callback(Funcs_Slider.Value)
					end
				end)

				local _LastX = nil
				UserInputService.InputChanged:Connect(function(Input)
					if Dragging then
						local CurrPosX = Input.Position.X
						if CurrPosX ~= _LastX then
							_LastX = CurrPosX

							local SizeScale = math.clamp(
								(CurrPosX - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X,
								0,
								1
							)
							Funcs_Slider:Set(Min + ((Max - Min) * SizeScale))
						end
					end
				end)

				TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					local Valid = TextBox.Text:gsub("[^%d]", "")
					if Valid ~= "" then
						local ValidNumber = math.min(tonumber(Valid), Max)
						TextBox.Text = tostring(ValidNumber)
					else
						TextBox.Text = "0"
					end
				end)

				TextBox.FocusLost:Connect(function()
					if TextBox.Text ~= "" then
						Funcs_Slider:Set(tonumber(TextBox.Text))
						Callback(Funcs_Slider.Value)
					else
						Funcs_Slider:Set(0)
						Callback(Funcs_Slider.Value)
					end
				end)

				Funcs_Slider:Set(tonumber(Default))
				Callback(Funcs_Slider.Value)

				ItemCount += 1
				return Funcs_Slider
			end

			function Item:AddInput(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Default = Config[3] or Config.Default or ""
				local Callback = Config[4] or Config.Callback or function() end
				local Funcs_Input = { Value = Default }

				local Input = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Input",
				}, SectionAdd)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Input)

				local InputTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "InputTitle",
				}, Input)

				local InputContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "InputContent",
					Parent = Input,
				})

				local function UpdateInputSize()
					local Ratio = InputContent.TextBounds.X / InputContent.AbsoluteSize.X
					local Calculated = 12 + (12 * math.floor(Ratio))

					InputContent.Size = UDim2.new(1, -180, 0, Calculated)
					Input.Size = UDim2.new(1, 0, 0, InputContent.AbsoluteSize.Y + 33)
				end

				UpdateInputSize()

				InputContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					InputContent.TextWrapped = false
					UpdateInputSize()
					InputContent.TextWrapped = true
					UpdateSizeSection()
				end)

				local InputFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					ClipsDescendants = true,
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.new(0, 148, 0, 30),
					Name = "InputFrame",
				}, Input)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, InputFrame)

				local InputTextBox = Custom:Create("TextBox", {
					CursorPosition = -1,
					Font = Enum.Font.GothamBold,
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					PlaceholderText = "Write your input there",
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.new(1, -10, 1, -8),
					Name = "InputTextBox",
				}, InputFrame)

				function Funcs_Input:Set(Value)
					InputTextBox.Text = Value
					Funcs_Input.Value = Value
					Callback(Value)
				end

				InputTextBox.FocusLost:Connect(function()
					Funcs_Input:Set(InputTextBox.Text)
				end)

				Funcs_Input:Set(Default)

				ItemCount += 1
				return Funcs_Input
			end

			function Item:AddDropdown(Config)
				local Title = Config[1] or Config.Title or ""
				local Content = Config[2] or Config.Content or ""
				local Multi = Config[3] or Config.Multi or false
				local Options = Config[4] or Config.Options or {}
				local Default = Config[5] or Config.Default or {}
				local Callback = Config[6] or Config.Callback or function() end

				local Funcs_Dropdown = { Value = Default, Options = Options }

				local Dropdown = Custom:Create("Frame", {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.935,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = ItemCount,
					Size = UDim2.new(1, 0, 0, 35),
					Name = "Dropdown",
				}, SectionAdd)

				local DropdownButton = Custom:Create("TextButton", {
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ToggleButton",
				}, Dropdown)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, Dropdown)

				local DropdownTitle = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Color3.fromRGB(230, 230, 230),
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 10),
					Size = UDim2.new(1, -180, 0, 13),
					Name = "DropdownTitle",
					Parent = Dropdown,
				})

				local DropdownContent = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = Content,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Bottom,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 10, 0, 23),
					Size = UDim2.new(1, -180, 0, 12),
					Name = "DropdownContent",
					Parent = Dropdown,
				})

				DropdownContent.Size =
					UDim2.new(1, -180, 0, 12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X)))
				DropdownContent.TextWrapped = true
				Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)

				DropdownContent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
					DropdownContent.TextWrapped = false

					DropdownContent.Size = UDim2.new(
						1,
						-180,
						0,
						12 + (12 * (DropdownContent.TextBounds.X // DropdownContent.AbsoluteSize.X))
					)
					Dropdown.Size = UDim2.new(1, 0, 0, DropdownContent.AbsoluteSize.Y + 33)

					DropdownContent.TextWrapped = true

					UpdateSizeSection()
				end)

				local SelectOptionsFrame = Custom:Create("Frame", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.95,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.new(0, 148, 0, 30),
					Name = "SelectOptionsFrame",
					LayoutOrder = CountDropdown,
				}, Dropdown)

				Custom:Create("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}, SelectOptionsFrame)

				DropdownButton.Activated:Connect(function()
					if not MoreBlur.Visible then
						MoreBlur.Visible = true

						local tweenInfo = TweenInfo.new(0.1)

						DropPageLayout:JumpToIndex(SelectOptionsFrame.LayoutOrder)

						local BlurTween = TweenService:Create(MoreBlur, tweenInfo, { BackgroundTransparency = 0.7 })
						local DropdownTween =
							TweenService:Create(DropdownSelect, tweenInfo, { Position = UDim2.new(1, -11, 0.5, 0) })

						BlurTween:Play()
						DropdownTween:Play()
					end
				end)

				local OptionSelecting = Custom:Create("TextLabel", {
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					TextTransparency = 0.6,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 5, 0.5, 0),
					Size = UDim2.new(1, -30, 1, -8),
					Name = "OptionSelecting",
				}, SelectOptionsFrame)

				local OptionImg = Custom:Create("ImageLabel", {
					Image = "rbxassetid://90200523188815",
					ImageColor3 = Color3.fromRGB(231, 231, 231),
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 25, 0, 25),
					Name = "OptionImg",
				}, SelectOptionsFrame)

				local ScrollSelect = Custom:Create("ScrollingFrame", {
					CanvasSize = UDim2.new(0, 0, 0, 0),
					ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
					ScrollBarThickness = 0,
					Active = true,
					LayoutOrder = CountDropdown,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.999,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 1, 0),
					Name = "ScrollSelect",
				}, DropdownFolder)

				Custom:Create("UIListLayout", {
					Padding = UDim.new(0, 3),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}, ScrollSelect)

				local SearchBar = Custom:Create("TextBox", {
					Font = Enum.Font.GothamBold,
					PlaceholderText = "Search",
					PlaceholderColor3 = Color3.fromRGB(120, 120, 120),
					Text = "",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 12,
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.9,
					BorderColor3 = Custom.ColorRGB,
					BorderSizePixel = 1,
					Size = UDim2.new(1, 0, 0, 20),
					Name = "SearchBar",
				}, ScrollSelect)

				SearchBar:GetPropertyChangedSignal("Text"):Connect(function()
					local SearchText = string.lower(SearchBar.Text)

					for _, v in pairs(ScrollSelect:GetChildren()) do
						if v:IsA("Frame") and v.Name == "Option" and v.Name ~= "SearchBar" then
							local OptionText = v:FindFirstChild("OptionText")
							if OptionText then
								v.Visible = string.find(string.lower(OptionText.Text), SearchText) ~= nil
							end
						end
					end
				end)

				local DropCount = 0

				function Funcs_Dropdown:Clear()
					for _, DropFrame in pairs(ScrollSelect:GetChildren()) do
						if DropFrame.Name == "Option" then
							Funcs_Dropdown.Value = {}
							Funcs_Dropdown.Options = {}
							OptionSelecting.Text = "Select Options"
							DropFrame:Destroy()
						end
					end
				end

				function Funcs_Dropdown:Set(Value)
					Funcs_Dropdown.Value = Value or Funcs_Dropdown.Value

					for _, Drop in pairs(ScrollSelect:GetChildren()) do
						if Drop.Name ~= "UIListLayout" and Drop.Name ~= "SearchBar" then
							local isTextFound = table.find(Funcs_Dropdown.Value, Drop.OptionText.Text)
							local tweenInfoInOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)

							local Size = isTextFound and UDim2.new(0, 1, 0, 12) or UDim2.new(0, 0, 0, 0)
							local BackgroundTransparency = isTextFound and 0.935 or 0.999
							local Transparency = isTextFound and 0 or 0.999

							TweenService:Create(Drop.ChooseFrame, tweenInfoInOut, { Size = Size }):Play()
							TweenService
								:Create(Drop.ChooseFrame.UIStroke, tweenInfoInOut, { Transparency = Transparency })
								:Play()
							TweenService
								:Create(Drop, tweenInfoInOut, { BackgroundTransparency = BackgroundTransparency })
								:Play()
						end
					end

					local DropdownValueTable = table.concat(Funcs_Dropdown.Value, ", ")
					OptionSelecting.Text = DropdownValueTable ~= "" and DropdownValueTable or "Select Options"
					Callback(Funcs_Dropdown.Value)
				end

				function Funcs_Dropdown:AddOption(OptionName)
					OptionName = OptionName or "Option"

					local Option = Custom:Create("Frame", {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						LayoutOrder = DropCount,
						Size = UDim2.new(1, 0, 0, 30),
						Name = "Option",
					}, ScrollSelect)

					Custom:Create("UICorner", {
						CornerRadius = UDim.new(0, 3),
					}, Option)

					local OptionButton = Custom:Create("TextButton", {
						Font = Enum.Font.GothamBold,
						Text = "",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 1, 0),
						Name = "OptionButton",
					}, Option)

					Custom:Create("TextLabel", {
						Font = Enum.Font.GothamBold,
						Text = OptionName,
						TextSize = 13,
						TextColor3 = Color3.fromRGB(230, 230, 230),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Top,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.999,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 8, 0, 8),
						Size = UDim2.new(1, -100, 0, 13),
						Name = "OptionText",
					}, Option)

					local ChooseFrame = Custom:Create("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Custom.ColorRGB,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 2, 0.5, 0),
						Size = UDim2.new(0, 0, 0, 0),
						Name = "ChooseFrame",
					}, Option)

					Custom:Create("UIStroke", {
						Color = Custom.ColorRGB,
						Thickness = 1.6,
						Transparency = 0.999,
					}, ChooseFrame)

					Custom:Create("UICorner", {}, ChooseFrame)

					OptionButton.Activated:Connect(function()
						CircleClick(OptionButton, Player:GetMouse().X, Player:GetMouse().Y)

						local isOptionSelected = Option.BackgroundTransparency > 0.95

						if Multi then
							if isOptionSelected then
								if not table.find(Funcs_Dropdown.Value, OptionName) then
									table.insert(Funcs_Dropdown.Value, OptionName)
								end
							else
								for i, value in ipairs(Funcs_Dropdown.Value) do
									if value == OptionName then
										table.remove(Funcs_Dropdown.Value, i)
										break
									end
								end
							end
						else
							Funcs_Dropdown.Value = { OptionName }
						end

						Funcs_Dropdown:Set(Funcs_Dropdown.Value)
					end)

					local function UpdateCanvasSize()
						local OffsetY = 0

						for _, child in ipairs(ScrollSelect:GetChildren()) do
							if child.Name ~= "UIListLayout" and child.Name ~= "SearchBar" then
								OffsetY = OffsetY + 5 + child.Size.Y.Offset
							end
						end

						ScrollSelect.CanvasSize = UDim2.new(0, 0, 0, OffsetY)
					end

					UpdateCanvasSize()

					DropCount += 1
				end

				function Funcs_Dropdown:Refresh(RefreshList, Selecting)
					RefreshList = RefreshList or {}
					Selecting = Selecting or {}

					Funcs_Dropdown:Clear()

					for _, Drop in ipairs(RefreshList) do
						Funcs_Dropdown:AddOption(Drop)
					end

					Funcs_Dropdown.Options = RefreshList
					Funcs_Dropdown:Set(Selecting)
				end

				Funcs_Dropdown:Refresh(Funcs_Dropdown.Options, Funcs_Dropdown.Value)

				ItemCount += 1
				CountDropdown += 1
				return Funcs_Dropdown
			end

			ItemCount += 1
			return Item
		end

		CountTab += 1
		return Sections
	end

	return Tabs
end

return Speed_Library
end)()

--[[
	RapHub - Break and Steal an Egg
	  - Auto Farm Eggs: datangi telur, pukul sampai pecah, pulang ke base saat satchel penuh
	  - Teleport ke telur / zona / lokasi penting
	`Library` (UI) ditanam otomatis di atas file ini oleh build.js
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

---------------------------------------------------------------------
-- Setting
---------------------------------------------------------------------
local Settings = {
	TeleportMode = "Instant (Lynx)", -- "Instant (Lynx)" | "Jalan (Aman)"
	StepSize = 28, -- stud per frame untuk lompat jarak dekat (Lynx ~28)
	ShortRange = 150, -- di atas jarak ini pakai respawn teleport
	WalkMultiplier = 1, -- pengali WalkSpeed untuk mode Jalan (Aman)
	TweenSpeed = 300, -- stud per detik
	ZoneTarget = "Pintu Masuk", -- "Pintu Masuk" | "Tengah Zona" | "Area Telur"
}

local Farm = {
	Enabled = false,
	Zones = {}, -- nama zona, kosong = semua
	Names = {}, -- nama telur, kosong = semua
	Rarities = {}, -- rarity telur, kosong = semua
	MinWeight = 0, -- kg
	Priority = "Terdekat", -- "Terdekat" | "Luck Tertinggi" | "Terberat" | "HP Terendah"
	TitanicFirst = true,
	HitMode = "Swing Game (Aman)", -- "Swing Game (Aman)" | "Klik Virtual"
	HitDelay = 0.15, -- detik antar pukulan
	MaxTimePerEgg = 30, -- detik sebelum menyerah pada satu telur
	ReturnWhenFull = true, -- setor hewan saat satchel penuh
	BankMode = "Lewat Guard (Cepat)", -- "Lewat Guard (Cepat)" | "Jalan ke Base"
	AutoBestZone = true, -- tanpa filter Zones: farm di zona tertinggi sesuai Speed
}

local Steal = {
	Enabled = false, -- ambil hewan yang bisa dicuri (StealPrompt) lalu setor
	Dropped = true, -- hewan jatuh / tergeletak di map
	OtherBases = false, -- hewan di base pemain lain
	Rarities = {}, -- kosong = semua
	MinWeight = 0, -- kg
	MutationOnly = false, -- hanya yang punya mutasi
	Zones = {}, -- zona tempat mencuri, kosong = semua
	StreamScan = true, -- minta isi zona jauh dikirim server (tanpa ke sana)
	Patrol = false, -- kalau kosong, keliling zona pakai respawn teleport
}

-- Farm atau steal sedang aktif
local function Working()
	return Farm.Enabled or Steal.Enabled
end

---------------------------------------------------------------------
-- Data game: SEMUA nama diambil langsung dari game (tidak ada daftar manual)
---------------------------------------------------------------------
local function SafeRequire(Parent, Name)
	local Module = Parent and Parent:FindFirstChild(Name)
	if not Module then
		return nil
	end
	local ok, Result = pcall(require, Module)
	return ok and type(Result) == "table" and Result or nil
end

local Shared = ReplicatedStorage:FindFirstChild("Shared")
local ZoneDisplayInfo = SafeRequire(Shared, "ZoneDisplayInfo")
local ZonesConfig = SafeRequire(Shared, "ZonesConfig")
local EggRewardsModule = SafeRequire(Shared, "EggRewards")

-- Sumber data yang berhasil dipakai (ditampilkan di Settings > Diagnosa)
local DataSource = { Zones = "tidak ada", Rarities = {} }

-- Nama zona: modul ZoneDisplayInfo milik game
local ZONE_NAMES = {}
if ZoneDisplayInfo then
	for ZoneId, Info in pairs(ZoneDisplayInfo) do
		if type(Info) == "table" and type(Info.Name) == "string" then
			ZONE_NAMES[ZoneId] = Info.Name
		end
	end
	if next(ZONE_NAMES) then
		DataSource.Zones = "ZoneDisplayInfo"
	end
end

-- Rarity: urutan tingkat dari ZonesConfig, lalu semua rarity lain yang ada di game
local RARITY_ORDER = {}
do
	local Seen = {}
	local function Add(Rarity, Source)
		if type(Rarity) == "string" and Rarity ~= "" and not Seen[Rarity] then
			Seen[Rarity] = true
			table.insert(RARITY_ORDER, Rarity)
			if not table.find(DataSource.Rarities, Source) then
				table.insert(DataSource.Rarities, Source)
			end
		end
	end

	if ZonesConfig and type(ZonesConfig.Zones) == "table" then
		for _, Zone in ipairs(ZonesConfig.Zones) do
			if type(Zone) == "table" then
				Add(Zone.Rarity, "ZonesConfig")
			end
		end
	end

	-- Folder ReplicatedStorage.Rarities (berisi semua rarity, termasuk Primordial/Abyssal/Godly)
	local RaritiesFolder = ReplicatedStorage:FindFirstChild("Rarities")
	if RaritiesFolder then
		for _, Child in ipairs(RaritiesFolder:GetChildren()) do
			Add(Child.Name, "RS.Rarities")
		end
	end

	if EggRewardsModule and type(EggRewardsModule.RarityColors) == "table" then
		local Extra = {}
		for Rarity in pairs(EggRewardsModule.RarityColors) do
			table.insert(Extra, Rarity)
		end
		table.sort(Extra)
		for _, Rarity in ipairs(Extra) do
			Add(Rarity, "EggRewards")
		end
	end
end

local function ZoneIndex(ZoneId)
	return tonumber(tostring(ZoneId):match("%d+")) or 999
end

local function ZoneName(ZoneId)
	return ZONE_NAMES[ZoneId] or ("Zona " .. ZoneIndex(ZoneId))
end

local SUFFIX = { K = 1e3, M = 1e6, B = 1e9, T = 1e12, Qa = 1e15, Qi = 1e18, Sx = 1e21, Sp = 1e24 }
local function ParseShort(Text)
	if type(Text) == "number" then
		return Text
	end
	if type(Text) ~= "string" then
		return 0
	end
	local Num, Suffix = Text:match("([%d%.]+)%s*(%a*)")
	return (tonumber(Num) or 0) * (SUFFIX[Suffix] or 1)
end


---------------------------------------------------------------------
-- Karakter & teleport
---------------------------------------------------------------------
local function GetRoot()
	local Character = Player.Character
	return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local Character = Player.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function GetBuild()
	return workspace:FindFirstChild("Build")
end

-- Cari tanah di titik X/Z (abaikan hitbox zona & karakter)
local function GroundAt(X, Z, FromY)
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.RespectCanCollide = true

	local Ignore = { Player.Character }
	local Build = GetBuild()
	local Hitboxes = Build and Build:FindFirstChild("ZoneHitboxes")
	if Hitboxes then
		table.insert(Ignore, Hitboxes)
	end
	Params.FilterDescendantsInstances = Ignore

	local Result = workspace:Raycast(Vector3.new(X, FromY or 40, Z), Vector3.new(0, -200, 0), Params)
	return Result and Result.Position or Vector3.new(X, 3, Z)
end

local ActiveTween
local MoveToken = 0
local PullBackWarning -- diisi setelah fungsi Notify ada

local function StopMoving()
	MoveToken += 1
	if ActiveTween then
		ActiveTween:Cancel()
		ActiveTween = nil
	end
end

--[[
	Mode "Jalan (Aman)": geser karakter tiap frame sambil tetap menempel di tanah,
	dengan kecepatan = WalkSpeed x pengali. Server melihatnya seperti berlari biasa,
	jadi tidak kena anti-cheat (fly / teleport ditarik balik).
]]
local function WalkTo(TargetCFrame, Token)
	local Root, Humanoid = GetRoot(), GetHumanoid()
	if not Root or not Humanoid then
		return false
	end

	local Target = TargetCFrame.Position
	local HipOffset = Humanoid.HipHeight + Root.Size.Y / 2

	while Token == MoveToken and Root.Parent and Humanoid.Health > 0 do
		local Dt = RunService.Heartbeat:Wait()
		local Pos = Root.Position
		local Flat = Vector3.new(Target.X - Pos.X, 0, Target.Z - Pos.Z)
		local Dist = Flat.Magnitude
		if Dist < 1.5 then
			break
		end

		local Dir = Flat.Unit
		local Speed = math.max(Humanoid.WalkSpeed, 16) * Settings.WalkMultiplier
		local Next = Pos + Dir * math.min(Dist, Speed * Dt)
		local Ground = GroundAt(Next.X, Next.Z, Pos.Y + 6)
		local NewPos = Vector3.new(Next.X, Ground.Y + HipOffset, Next.Z)

		Root.CFrame = CFrame.lookAt(NewPos, NewPos + Dir)
		Root.AssemblyLinearVelocity = Dir * Speed
	end

	if Token ~= MoveToken or not Root.Parent then
		return false
	end

	Root.CFrame = TargetCFrame
	Root.AssemblyLinearVelocity = Vector3.zero
	return true
end

--[[
	Fling window: saat ditangkap guard, server mengirim CatchFlingRemote "fling"
	sampai "release" (~3 detik). Selama itu anti-cheat tidak memeriksa posisi,
	jadi teleport jarak berapa pun aman (cara yang dipakai Lynx).
]]
local Fling = { Until = 0, Count = 0 }
do
	local CatchFling = ReplicatedStorage:FindFirstChild("CatchFlingRemote")
	if CatchFling then
		CatchFling.OnClientEvent:Connect(function(Kind, _, Duration)
			if Kind == "fling" then
				Fling.Count += 1
				Fling.Until = os.clock() + math.max((tonumber(Duration) or 3) - 0.4, 0.5)
			elseif Kind == "release" then
				Fling.Until = 0
			end
		end)
	end
end

local function InFlingWindow()
	return os.clock() < Fling.Until
end

local LastMoveProblem = nil -- ditampilkan di panel Diagnosa
local MoveNotify -- diisi setelah fungsi Notify ada

--[[
	Lompat kecil per frame (jarak DEKAT saja). Lynx hanya memakai ini untuk
	ledakan pendek (~250 stud). Kalau server menarik balik sekali saja,
	langsung berhenti (mengulang terus = diledakkan anti-cheat).
]]
local function StepTo(TargetCFrame, Token)
	local Root, Humanoid = GetRoot(), GetHumanoid()
	if not Root or not Humanoid then
		return false
	end

	local Target = TargetCFrame.Position
	local HipOffset = Humanoid.HipHeight + Root.Size.Y / 2
	local Expected = nil

	while Token == MoveToken and Root.Parent and Humanoid.Health > 0 do
		if InFlingWindow() then
			break
		end

		local Pos = Root.Position
		if Expected and (Pos - Expected).Magnitude > 40 then
			LastMoveProblem = "Lompat ditarik balik server"
			if PullBackWarning then
				PullBackWarning()
			end
			return false
		end

		local Flat = Vector3.new(Target.X - Pos.X, 0, Target.Z - Pos.Z)
		local Dist = Flat.Magnitude
		if Dist < 1.5 then
			break
		end

		local Dir = Flat.Unit
		local Next = Pos + Dir * math.min(Dist, Settings.StepSize)
		local Ground = GroundAt(Next.X, Next.Z, Pos.Y + 6)
		local NewPos = Vector3.new(Next.X, Ground.Y + HipOffset, Next.Z)

		Root.CFrame = CFrame.lookAt(NewPos, NewPos + Dir)
		Root.AssemblyLinearVelocity = Vector3.zero
		Expected = NewPos
		RunService.Heartbeat:Wait()
	end

	if Token ~= MoveToken or not Root.Parent then
		return false
	end

	Root.CFrame = TargetCFrame
	Root.AssemblyLinearVelocity = Vector3.zero
	return true
end

--[[
	Respawn Teleport (jarak JAUH, cara Lynx dari rekaman):
	HRP di-anchor -> karakter dimatikan -> begitu karakter baru muncul,
	langsung dipindah ke tujuan pada frame-frame pertama, sebelum anti-cheat
	server mulai mengawasi karakter baru. Tidak dipakai saat membawa hewan
	(hewan bisa jatuh saat mati).
]]
local Respawning = false
local function RespawnTo(TargetCFrame, Token)
	local Root, Humanoid = GetRoot(), GetHumanoid()
	if Respawning or not Root or not Humanoid then
		return false
	end
	Respawning = true

	local Arrived = false
	local Conn = Player.CharacterAdded:Connect(function(Character)
		local NewRoot = Character:WaitForChild("HumanoidRootPart", 5)
		if not NewRoot then
			return
		end
		-- Tahan di tujuan selama frame-frame awal karakter baru
		local Until = os.clock() + 0.6
		while os.clock() < Until and NewRoot.Parent do
			NewRoot.CFrame = TargetCFrame
			NewRoot.AssemblyLinearVelocity = Vector3.zero
			RunService.Heartbeat:Wait()
		end
		Arrived = true
	end)

	pcall(function()
		Root.Anchored = true
		Humanoid.Health = 0
	end)

	local Started = os.clock()
	while not Arrived and Token == MoveToken and os.clock() - Started < 12 do
		task.wait(0.05)
	end
	Conn:Disconnect()
	Respawning = false

	if not Arrived then
		LastMoveProblem = "Respawn teleport gagal / timeout"
		return false
	end

	-- Cek apakah posisi bertahan
	task.wait(1)
	local NewRoot = GetRoot()
	if NewRoot and (NewRoot.Position - TargetCFrame.Position).Magnitude > 40 then
		LastMoveProblem = "Respawn teleport ditarik balik"
		if MoveNotify then
			MoveNotify("Respawn teleport ditarik balik server.")
		end
		return false
	end
	return true
end

local function IsCarrying()
	return Player:GetAttribute("Carrying") ~= nil
end

local function TeleportTo(TargetCFrame)
	local Root = GetRoot()
	if not Root or not TargetCFrame then
		return false
	end

	StopMoving()
	local Token = MoveToken

	-- Sedang terpental guard: teleport langsung tanpa batas jarak
	if InFlingWindow() then
		Root.CFrame = TargetCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
		return true
	end

	if Settings.TeleportMode == "Jalan (Aman)" then
		return WalkTo(TargetCFrame, Token)
	end

	-- "Instant (Lynx)": dekat = lompat kecil, jauh = respawn teleport
	local Distance = (Root.Position - TargetCFrame.Position).Magnitude
	if Distance <= Settings.ShortRange then
		return StepTo(TargetCFrame, Token)
	end
	if IsCarrying() then
		-- Jangan mati saat membawa hewan; jalan biasa (tidak dideteksi)
		return WalkTo(TargetCFrame, Token)
	end
	return RespawnTo(TargetCFrame, Token)
end

-- Berdiri di atas tanah pada posisi `Pos`, menghadap `LookAt`
local function StandAt(Pos, LookAt)
	local Ground = GroundAt(Pos.X, Pos.Z, Pos.Y + 25)
	local Stand = Ground + Vector3.new(0, 3.5, 0)
	if LookAt then
		local Face = Vector3.new(LookAt.X, Stand.Y, LookAt.Z)
		-- Titik hadap sama dengan titik berdiri -> CFrame NaN (merusak karakter)
		if (Face - Stand).Magnitude > 0.1 then
			return CFrame.lookAt(Stand, Face)
		end
	end
	return CFrame.new(Stand)
end

local function Notify(Title, Content)
	pcall(function()
		Library:SetNotification({
			Title = "RapHub",
			Description = Title,
			Content = Content,
			Delay = 3,
		})
	end)
end

PullBackWarning = function()
	Notify("Anti-cheat", "Lompat ditarik balik server, gerakan dihentikan supaya tidak diledakkan.")
end

MoveNotify = function(Text)
	Notify("Anti-cheat", Text)
end

---------------------------------------------------------------------
-- Telur
---------------------------------------------------------------------
local NameCache = setmetatable({}, { __mode = "k" })

-- Nama telur seperti yang tampil di game ("Luna Egg"), dengan cadangan
local function EggDisplayName(Model, Part)
	if NameCache[Model] then
		return NameCache[Model]
	end

	-- Label nama bisa ada di part "Egg" atau "Outer", jadi cari di seluruh model
	local Ui = Model:FindFirstChild("EggInfoUi", true)
	local Label = Ui and Ui:FindFirstChild("Name")
	if Label and Label:IsA("TextLabel") and Label.Text ~= "" then
		NameCache[Model] = Label.Text
		return Label.Text
	end

	return Part:GetAttribute("EggInfoName") or Part:GetAttribute("EggType") or (Model.Name:gsub("^%d+:%s*", ""))
end

local function ReadEgg(Model, ZoneId)
	if not Model:IsA("Model") then
		return nil
	end
	local Part = Model:FindFirstChild("Egg")
	if not Part or not Part:IsA("BasePart") then
		return nil
	end
	if Part:GetAttribute("Broken") == true then
		return nil
	end

	local ZoneIdx = Part:GetAttribute("ZoneIndex")
	ZoneId = ZoneId or (ZoneIdx and ("Zone" .. ZoneIdx)) or "Lainnya"

	return {
		Model = Model,
		Part = Part,
		Name = EggDisplayName(Model, Part),
		Rarity = Part:GetAttribute("EggInfoRarity") or "?",
		ZoneId = ZoneId,
		Luck = ParseShort(Part:GetAttribute("EggInfoLuck")),
		Weight = tonumber(Part:GetAttribute("WeightKg")) or 0,
		Health = tonumber(Part:GetAttribute("Health")) or math.huge,
		Position = Part.Position,
		Size = Part.Size,
	}
end

-- Semua telur yang sedang ada di map
local function CollectEggs()
	local Eggs = {}
	local Build = GetBuild()
	local ZoneBuilds = Build and Build:FindFirstChild("ZoneBuilds")

	if ZoneBuilds then
		for _, Zone in ipairs(ZoneBuilds:GetChildren()) do
			local Folder = Zone:FindFirstChild("Eggs")
			if Folder then
				for _, Model in ipairs(Folder:GetChildren()) do
					local Egg = ReadEgg(Model, Zone.Name)
					if Egg then
						table.insert(Eggs, Egg)
					end
				end
			end
		end
	end

	-- Telur event / spesial
	local Extra = workspace:FindFirstChild("Eggs")
	if Extra then
		for _, Model in ipairs(Extra:GetChildren()) do
			local Egg = ReadEgg(Model, nil)
			if Egg then
				table.insert(Eggs, Egg)
			end
		end
	end

	return Eggs
end

local function EggAlive(Egg)
	return Egg.Model.Parent ~= nil and Egg.Part.Parent ~= nil and Egg.Part:GetAttribute("Broken") ~= true
end

local function Distance(Egg)
	local Root = GetRoot()
	return Root and (Egg.Part.Position - Root.Position).Magnitude or 0
end

-- Teleport ke samping telur, menghadap telur
local function TeleportToEgg(Egg)
	if not Egg or not Egg.Part.Parent then
		return false
	end
	local EggPos = Egg.Part.Position
	local Radius = math.max(Egg.Size.X, Egg.Size.Z) / 2 + 2.5

	local Root = GetRoot()
	local Dir = Vector3.new(1, 0, 0)
	if Root then
		local Flat = Vector3.new(Root.Position.X - EggPos.X, 0, Root.Position.Z - EggPos.Z)
		if Flat.Magnitude > 1 then
			Dir = Flat.Unit
		end
	end

	return TeleportTo(StandAt(EggPos + Dir * Radius, EggPos))
end

local function EggKey(Egg)
	return string.format("%s [%s] - %s", Egg.Name, Egg.Rarity, ZoneName(Egg.ZoneId))
end

local function AllEggNames()
	local Seen, List = {}, {}
	for _, Egg in ipairs(CollectEggs()) do
		if not Seen[Egg.Name] then
			Seen[Egg.Name] = true
			table.insert(List, Egg.Name)
		end
	end
	table.sort(List)
	return List
end

---------------------------------------------------------------------
-- Zona & lokasi
---------------------------------------------------------------------
local function GetZoneList()
	local Zones = {}
	local Build = GetBuild()
	local ZoneBuilds = Build and Build:FindFirstChild("ZoneBuilds")
	if ZoneBuilds then
		for _, Zone in ipairs(ZoneBuilds:GetChildren()) do
			table.insert(Zones, Zone.Name)
		end
	end
	table.sort(Zones, function(a, b)
		return ZoneIndex(a) < ZoneIndex(b)
	end)
	return Zones
end

local function ZoneTargetCFrame(ZoneId)
	local Build = GetBuild()
	if not Build then
		return nil
	end

	local Hitboxes = Build:FindFirstChild("ZoneHitboxes")
	local Hitbox = Hitboxes and Hitboxes:FindFirstChild(tostring(ZoneIndex(ZoneId)))

	if Settings.ZoneTarget == "Area Telur" then
		local Sum, Count = Vector3.zero, 0
		for _, Egg in ipairs(CollectEggs()) do
			if Egg.ZoneId == ZoneId then
				Sum += Egg.Position
				Count += 1
			end
		end
		if Count > 0 then
			return StandAt(Sum / Count)
		end
	end

	if Hitbox and Hitbox:IsA("BasePart") then
		local Center = Hitbox.Position
		if Settings.ZoneTarget == "Tengah Zona" then
			return StandAt(Vector3.new(Center.X, 15, Center.Z))
		end
		-- Pintu masuk = sisi zona yang menghadap base (arah +X)
		local Entrance = Vector3.new(Center.X + Hitbox.Size.X / 2 - 12, 15, Center.Z)
		return StandAt(Entrance, Vector3.new(Center.X, 0, Center.Z))
	end

	local ZoneBuilds = Build:FindFirstChild("ZoneBuilds")
	local Zone = ZoneBuilds and ZoneBuilds:FindFirstChild(ZoneId)
	if Zone and Zone:IsA("Model") then
		return StandAt(Zone:GetPivot().Position)
	end
	return nil
end

local function MyPlot()
	local Plots = workspace:FindFirstChild("Plots")
	if not Plots then
		return nil
	end
	for _, Plot in ipairs(Plots:GetChildren()) do
		if Plot:GetAttribute("OwnerUserId") == Player.UserId then
			return Plot
		end
	end
	return nil
end

local function GoToBase()
	local Plot = MyPlot()
	local Spawn = Plot and (Plot:FindFirstChild("SpawnPoint") or Plot:FindFirstChild("Hitbox"))
	if Spawn and Spawn:IsA("BasePart") then
		return TeleportTo(StandAt(Spawn.Position))
	end
	Notify("Area", "Base kamu tidak ditemukan.")
	return false
end

---------------------------------------------------------------------
-- Modul client game (aksi lewat jalur resmi game = aman & akurat)
---------------------------------------------------------------------
local ModuleCache = {}

local function GameModule(Name)
	if ModuleCache[Name] then
		return ModuleCache[Name]
	end
	local Scripts = Player:FindFirstChild("PlayerScripts")
	local Client = Scripts and Scripts:FindFirstChild("Client")
	local Controllers = Client and Client:FindFirstChild("Controllers")
	local Module = Controllers and Controllers:FindFirstChild(Name)
	if not Module or not Module:IsA("ModuleScript") then
		return nil
	end
	local ok, Result = pcall(require, Module)
	if ok and type(Result) == "table" then
		ModuleCache[Name] = Result
		return Result
	end
	return nil
end

---------------------------------------------------------------------
-- Pukul telur
---------------------------------------------------------------------
local function GetPickaxe()
	for _, Container in ipairs({ Player.Character, Player:FindFirstChild("Backpack") }) do
		if Container then
			for _, Tool in ipairs(Container:GetChildren()) do
				if Tool:IsA("Tool") and Tool.Name:find("Pickaxe") then
					return Tool
				end
			end
		end
	end
	return nil
end

local function EquipPickaxe()
	local Tool, Humanoid = GetPickaxe(), GetHumanoid()
	if Tool and Humanoid and Tool.Parent ~= Player.Character then
		Humanoid:EquipTool(Tool)
	end
	return Tool
end

local function FaceEgg(Egg)
	local Root = GetRoot()
	if Root then
		local Pos = Egg.Part.Position
		Root.CFrame = CFrame.lookAt(Root.Position, Vector3.new(Pos.X, Root.Position.Y, Pos.Z))
	end
end

-- Cadangan: klik kiri virtual di tengah layar (game memukul lewat klik mouse)
local function ClickScreen()
	pcall(function()
		local VirtualInputManager = game:GetService("VirtualInputManager")
		local Size = workspace.CurrentCamera.ViewportSize
		VirtualInputManager:SendMouseButtonEvent(Size.X / 2, Size.Y * 0.6, 0, true, game, 0)
		VirtualInputManager:SendMouseButtonEvent(Size.X / 2, Size.Y * 0.6, 0, false, game, 0)
	end)
end

-- Kembalikan nama cara pukul yang dipakai (untuk log)
local function HitEgg(Egg)
	local Tool = EquipPickaxe()
	FaceEgg(Egg)
	if not Tool then
		return "tanpa-pickaxe"
	end

	-- Utama: fungsi Swing milik game (cooldown, ID pukulan, remote diurus game)
	if Farm.HitMode == "Swing Game (Aman)" then
		local Controller = GameModule("PickaxeController")
		if not Controller or type(Controller.Swing) ~= "function" then
			ClickScreen()
			return "klik (modul gagal)"
		end
		local ok, Swung = pcall(Controller.Swing, Egg.Part)
		if not ok then
			ClickScreen()
			return "klik (swing error)"
		end
		return Swung and "swing" or "swing-cooldown"
	end

	ClickScreen()
	return "klik"
end

---------------------------------------------------------------------
-- Hewan yang dibawa (atribut asli game)
---------------------------------------------------------------------
local function CarryCount()
	local Count = tonumber(Player:GetAttribute("CarryCount"))
	if Count then
		return Count
	end
	return Player:GetAttribute("Carrying") ~= nil and 1 or 0
end

local function SatchelCapacity()
	return tonumber(Player:GetAttribute("SatchelCapacity")) or 1
end

local function IsJailed()
	return Player:GetAttribute("Jailed") == true or Player:GetAttribute("CarryingJail") == true
end

---------------------------------------------------------------------
-- Taruh hewan di base sendiri (posisi dihitung dari Hitbox base masing-masing)
---------------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")

local Place = {
	Auto = false,
	Rarities = {}, -- kosong = semua
	Every = 5, -- mode setor lewat guard: pulang taruh hewan tiap N hewan di Backpack
}

local function AnimalTools()
	local List = {}
	for _, Container in ipairs({ Player.Character, Player:FindFirstChild("Backpack") }) do
		if Container then
			for _, Tool in ipairs(Container:GetChildren()) do
				if
					Tool:IsA("Tool")
					and (CollectionService:HasTag(Tool, "AnimalTool") or Tool:GetAttribute("AnimalName") ~= nil)
				then
					table.insert(List, Tool)
				end
			end
		end
	end
	return List
end

local function PlotUsage(Plot)
	return tonumber(Plot:GetAttribute("AnimalsPlaced")) or 0, tonumber(Plot:GetAttribute("MaxAnimals")) or 0
end

-- Titik kosong di lantai base (grid di dalam Hitbox, jauh dari hewan yang sudah ada)
local function FreeSpots(Plot)
	local Hitbox = Plot:FindFirstChild("Hitbox")
	if not Hitbox or not Hitbox:IsA("BasePart") then
		return {}
	end

	local PlacedFolder = Plot:FindFirstChild("PlacedAnimals")
	local Taken = {}
	if PlacedFolder then
		for _, Animal in ipairs(PlacedFolder:GetChildren()) do
			local ok, Pos = pcall(function()
				return Animal:GetPivot().Position
			end)
			if ok then
				table.insert(Taken, { Pos = Pos, Span = tonumber(Animal:GetAttribute("PlacedHalfSpan")) or 4 })
			end
		end
	end

	local Ignore = { Hitbox }
	if PlacedFolder then
		table.insert(Ignore, PlacedFolder)
	end
	for _, Other in ipairs(Players:GetPlayers()) do
		if Other.Character then
			table.insert(Ignore, Other.Character)
		end
	end

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Ignore

	local Size = Hitbox.Size
	local Spots = {}
	for X = -Size.X / 2 + 4, Size.X / 2 - 4, 5 do
		for Z = -Size.Z / 2 + 4, Size.Z / 2 - 4, 5 do
			local From = Hitbox.CFrame:PointToWorldSpace(Vector3.new(X, -Size.Y / 2 + 6, Z))
			local Hit = workspace:Raycast(From, Vector3.new(0, -12, 0), Params)
			if Hit then
				local Free = true
				for _, Item in ipairs(Taken) do
					local Gap = Vector3.new(Hit.Position.X - Item.Pos.X, 0, Hit.Position.Z - Item.Pos.Z).Magnitude
					if Gap < Item.Span + 3 then
						Free = false
						break
					end
				end
				if Free then
					table.insert(Spots, Hit.Position)
				end
			end
		end
	end

	local Center = Hitbox.Position
	table.sort(Spots, function(a, b)
		return (a - Center).Magnitude < (b - Center).Magnitude
	end)
	return Spots
end

local PlaceSeq = 0
local function PlaceToolAt(Tool, Spot)
	local Controller = GameModule("AnimalToolController")
	if Controller and type(Controller.PlaceAt) == "function" then
		if pcall(Controller.PlaceAt, Tool, Spot) then
			return
		end
	end
	local Remote = ReplicatedStorage:FindFirstChild("PlaceAnimalRemote")
	if Remote then
		PlaceSeq += 1
		Remote:FireServer(Tool, Spot, PlaceSeq)
	end
end

local PlaceBusy = false

-- Taruh semua hewan di Backpack (sesuai filter). Harus sudah berada di base.
local function PlaceAllAnimals()
	if PlaceBusy then
		return 0
	end
	PlaceBusy = true

	local Placed = 0
	local Plot = MyPlot()
	local Humanoid = GetHumanoid()
	local Controller = GameModule("AnimalToolController")

	if Plot and Humanoid then
		for _, Tool in ipairs(AnimalTools()) do
			local Rarity = Tool:GetAttribute("Rarity")
			if #Place.Rarities > 0 and not table.find(Place.Rarities, Rarity) then
				continue
			end

			local Used, Max = PlotUsage(Plot)
			if Max > 0 and Used >= Max then
				Notify("Base", string.format("Base penuh (%d/%d)", Used, Max))
				break
			end

			Humanoid:EquipTool(Tool)
			task.wait(0.3)

			local Tries = 0
			for _, Spot in ipairs(FreeSpots(Plot)) do
				if not Tool.Parent then
					break
				end
				local Allowed = true
				if Controller and type(Controller.CanPlaceAt) == "function" then
					local ok, Result = pcall(Controller.CanPlaceAt, Spot)
					Allowed = not ok or Result == true
				end
				if Allowed then
					Tries += 1
					PlaceToolAt(Tool, Spot)

					-- Berhasil = tool hilang dari karakter/backpack
					local Started = os.clock()
					while Tool.Parent and os.clock() - Started < 2.5 do
						task.wait(0.1)
					end
					if not Tool.Parent then
						Placed += 1
						break
					end
					if Tries >= 4 then
						break
					end
				end
			end
			task.wait(0.2)
		end
	end

	PlaceBusy = false
	return Placed
end

-- Zona tertinggi yang Speed-mu sudah cukup (RequiredPower = "Recommended Speed" di game)
local function BestZoneId()
	local Power = tonumber(Player:GetAttribute("SpeedPower")) or 0
	local Best = nil
	if ZonesConfig and type(ZonesConfig.Zones) == "table" then
		for _, Zone in ipairs(ZonesConfig.Zones) do
			if type(Zone) == "table" and Zone.Id and (tonumber(Zone.RequiredPower) or 0) <= Power then
				Best = Zone.Id
			end
		end
	end
	return Best or "Zone1"
end

local ZoneEmptyUntil = {} -- nomor zona -> os.clock() sampai kapan dianggap kosong

-- Nomor zona tertinggi yang boleh dipakai: Speed cukup & tidak sedang ditandai kosong
local function BestZoneIndex()
	local Index = ZoneIndex(BestZoneId())
	while Index > 1 and ZoneEmptyUntil[Index] and os.clock() < ZoneEmptyUntil[Index] do
		Index -= 1
	end
	return Index
end

local TooStrong = {} -- nama telur -> os.clock() sampai kapan dilewati
local CurrentBestIndex = nil
local LastPickStats = "" -- alasan kalau tidak ada telur cocok (untuk status & log)

local function FarmFilter(Egg)
	if #Farm.Zones > 0 then
		if not table.find(Farm.Zones, ZoneName(Egg.ZoneId)) then
			return false
		end
	elseif Farm.AutoBestZone and CurrentBestIndex and ZoneIndex(Egg.ZoneId) > CurrentBestIndex then
		-- Zona di atas kemampuan Speed: dilewati
		return false
	end
	if TooStrong[Egg.Name] and os.clock() < TooStrong[Egg.Name] then
		return false
	end
	if #Farm.Names > 0 and not table.find(Farm.Names, Egg.Name) then
		return false
	end
	if #Farm.Rarities > 0 and not table.find(Farm.Rarities, Egg.Rarity) then
		return false
	end
	if Egg.Weight < Farm.MinWeight then
		return false
	end
	return true
end

local function FarmScore(Egg)
	if Farm.Priority == "Luck Tertinggi" then
		return -Egg.Luck
	elseif Farm.Priority == "Terberat" then
		return -Egg.Weight
	elseif Farm.Priority == "HP Terendah" then
		return Egg.Health
	end
	return Distance(Egg)
end

--[[
	Urutan pilihan telur:
	  1. Titanic dulu (kalau aktif)
	  2. Auto Zona Terbaik: zona TERTINGGI yang Speed cukup DAN sedang ada telurnya
	     (zona teratas kosong -> otomatis turun ke zona di bawahnya)
	  3. Prioritas (terdekat / luck / berat / HP)
]]
local function PickFarmEgg(Skip)
	CurrentBestIndex = BestZoneIndex()
	local UseZoneRank = Farm.AutoBestZone and #Farm.Zones == 0
	local Best, BestRank, BestZone, BestScore = nil, nil, nil, nil
	local Total, Passed, Skipped = 0, 0, 0

	for _, Egg in ipairs(CollectEggs()) do
		Total += 1
		if FarmFilter(Egg) then
			Passed += 1
			if Skip[Egg.Model] then
				Skipped += 1
			else
				local Rank = (Farm.TitanicFirst and Egg.Name:lower():find("titanic")) and 0 or 1
				local Zone = UseZoneRank and -ZoneIndex(Egg.ZoneId) or 0
				local Score = FarmScore(Egg)
				local Better = not Best
					or Rank < BestRank
					or (Rank == BestRank and Zone < BestZone)
					or (Rank == BestRank and Zone == BestZone and Score < BestScore)
				if Better then
					Best, BestRank, BestZone, BestScore = Egg, Rank, Zone, Score
				end
			end
		end
	end

	LastPickStats = string.format(
		"%d telur di map, %d lolos filter, %d dilewati sementara%s",
		Total,
		Passed,
		Skipped,
		UseZoneRank and (" | zona maks: " .. ZoneName("Zone" .. CurrentBestIndex)) or ""
	)
	return Best
end

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------
local Window = Library:CreateWindow({
	Title = "RapHub",
	Description = "Break and Steal an Egg",
	["Tab Width"] = 120,
	SizeUi = UDim2.fromOffset(580, 360),
})

local MainTab = Window:CreateTab({ Name = "Main", Icon = "" })
local TeleportTab = Window:CreateTab({ Name = "Teleport", Icon = "" })
local SettingTab = Window:CreateTab({ Name = "Settings", Icon = "" })

-- ===================== Main: Auto Farm Eggs =====================
local FarmSection = MainTab:AddSection("Auto Farm Eggs", true)

local FarmStatus = FarmSection:AddParagraph({
	Title = "Status",
	Content = "Mati",
})

-- Log farm (disimpan otomatis ke RapHub/FarmLog.txt saat farm/steal aktif)
local FarmLogLines = {}
local function FarmLog(Text)
	local Line = string.format("[%s] %s", os.date("%H:%M:%S"), Text)
	table.insert(FarmLogLines, Line)
	if #FarmLogLines > 500 then
		table.remove(FarmLogLines, 1)
	end
end

local LastStatus = ""
local function SetStatus(Text)
	if Text ~= LastStatus then
		LastStatus = Text
		FarmLog(Text)
		task.spawn(function()
			pcall(function()
				FarmStatus:Set({ Title = "Status", Content = Text })
			end)
		end)
	end
end

local ZoneNameOptions = {}
for _, ZoneId in ipairs(GetZoneList()) do
	table.insert(ZoneNameOptions, ZoneName(ZoneId))
end

FarmSection:AddDropdown({
	Title = "Zones (kosong = semua)",
	Content = "Zona tempat farm",
	Multi = true,
	Options = ZoneNameOptions,
	Default = {},
	Callback = function(Value)
		Farm.Zones = Value or {}
	end,
})

local FarmNameDropdown = FarmSection:AddDropdown({
	Title = "Egg Types (kosong = semua)",
	Content = "Jenis telur",
	Multi = true,
	Options = AllEggNames(),
	Default = {},
	Callback = function(Value)
		Farm.Names = Value or {}
	end,
})

FarmSection:AddDropdown({
	Title = "Egg Rarities (kosong = semua)",
	Content = "Rarity telur",
	Multi = true,
	Options = table.clone(RARITY_ORDER),
	Default = {},
	Callback = function(Value)
		Farm.Rarities = Value or {}
	end,
})

FarmSection:AddInput({
	Title = "Min Berat (kg)",
	Content = "Lewati telur yang lebih ringan",
	Default = "0",
	Callback = function(Value)
		Farm.MinWeight = tonumber(Value) or 0
	end,
})

FarmSection:AddDropdown({
	Title = "Egg Priority",
	Content = "Telur mana yang dipukul dulu",
	Multi = false,
	Options = { "Terdekat", "Luck Tertinggi", "Terberat", "HP Terendah" },
	Default = { "Terdekat" },
	Callback = function(Value)
		Farm.Priority = Value and Value[1] or "Terdekat"
	end,
})

FarmSection:AddToggle({
	Title = "Titanic Eggs First",
	Content = "Dahulukan telur Titanic kalau muncul",
	Default = true,
	Callback = function(Value)
		Farm.TitanicFirst = Value
	end,
})

FarmSection:AddToggle({
	Title = "Auto Zona Terbaik",
	Content = "Kalau Zones kosong: farm di zona tertinggi yang Speed-mu sudah cukup (Recommended Speed)",
	Default = true,
	Callback = function(Value)
		Farm.AutoBestZone = Value
	end,
})

FarmSection:AddDropdown({
	Title = "Farm Mode",
	Content = "Instant (Lynx) = dekat lompat, jauh respawn teleport. Jalan = pelan",
	Multi = false,
	Options = { "Instant (Lynx)", "Jalan (Aman)" },
	Default = { "Instant (Lynx)" },
	Callback = function(Value)
		Settings.TeleportMode = Value and Value[1] or "Instant (Lynx)"
	end,
})

FarmSection:AddDropdown({
	Title = "Cara Setor Hewan",
	Content = "Lewat Guard = ditangkap guard lalu teleport ke SafeZone (seperti Lynx)",
	Multi = false,
	Options = { "Lewat Guard (Cepat)", "Jalan ke Base" },
	Default = { "Lewat Guard (Cepat)" },
	Callback = function(Value)
		Farm.BankMode = Value and Value[1] or "Lewat Guard (Cepat)"
	end,
})

FarmSection:AddDropdown({
	Title = "Cara Pukul",
	Content = "Swing Game = pakai fungsi pickaxe game. Klik Virtual = cadangan",
	Multi = false,
	Options = { "Swing Game (Aman)", "Klik Virtual" },
	Default = { "Swing Game (Aman)" },
	Callback = function(Value)
		Farm.HitMode = Value and Value[1] or "Swing Game (Aman)"
	end,
})

FarmSection:AddToggle({
	Title = "Setor Saat Satchel Penuh",
	Content = "Simpan hewan yang dibawa supaya tidak hilang",
	Default = true,
	Callback = function(Value)
		Farm.ReturnWhenFull = Value
	end,
})

FarmSection:AddToggle({
	Title = "Auto Farm Eggs",
	Content = "Mulai farm",
	Default = false,
	Callback = function(Value)
		Farm.Enabled = Value
		if not Value and not Steal.Enabled then
			StopMoving()
			SetStatus("Mati")
		end
	end,
})

FarmSection:AddButton({
	Title = "Refresh Egg Types",
	Content = "Ambil ulang nama telur di map",
	Callback = function()
		FarmNameDropdown:Refresh(AllEggNames(), Farm.Names)
	end,
})

-- ===================== Main: Auto Steal =====================
local StealSection = MainTab:AddSection("Auto Steal", true)

local StealInfo = StealSection:AddParagraph({
	Title = "Hewan bisa dicuri",
	Content = "Menghitung...",
})

StealSection:AddToggle({
	Title = "Auto Steal",
	Content = "Ambil hewan yang lolos filter (bukan harus pecahan sendiri) lalu setor ke SafeZone",
	Default = false,
	Callback = function(Value)
		Steal.Enabled = Value
		if not Value and not Farm.Enabled then
			StopMoving()
			SetStatus("Mati")
		end
	end,
})

StealSection:AddToggle({
	Title = "Curi Hewan Jatuh",
	Content = "Hewan tergeletak di map (mis. pemain lain ditangkap guard)",
	Default = true,
	Callback = function(Value)
		Steal.Dropped = Value
	end,
})

StealSection:AddToggle({
	Title = "Curi dari Base Pemain Lain",
	Content = "Hewan yang ditaruh di base orang lain",
	Default = false,
	Callback = function(Value)
		Steal.OtherBases = Value
	end,
})

StealSection:AddDropdown({
	Title = "Animal Rarities (kosong = semua)",
	Content = "Hanya curi rarity ini",
	Multi = true,
	Options = table.clone(RARITY_ORDER),
	Default = {},
	Callback = function(Value)
		Steal.Rarities = Value or {}
	end,
})

StealSection:AddInput({
	Title = "Min Berat Hewan (kg)",
	Content = "Lewati hewan yang lebih ringan",
	Default = "0",
	Callback = function(Value)
		Steal.MinWeight = tonumber(Value) or 0
	end,
})

StealSection:AddToggle({
	Title = "Hanya yang Bermutasi",
	Content = "Gold, Hacker, dll",
	Default = false,
	Callback = function(Value)
		Steal.MutationOnly = Value
	end,
})

StealSection:AddDropdown({
	Title = "Zones (kosong = semua)",
	Content = "Zona tempat mencuri",
	Multi = true,
	Options = table.clone(ZoneNameOptions),
	Default = {},
	Callback = function(Value)
		Steal.Zones = Value or {}
	end,
})

StealSection:AddToggle({
	Title = "Pindai Zona Jauh",
	Content = "Minta server mengirim isi zona jauh supaya hewannya terlihat (tanpa ke sana)",
	Default = true,
	Callback = function(Value)
		Steal.StreamScan = Value
	end,
})

StealSection:AddToggle({
	Title = "Patroli Zona",
	Content = "Kalau tidak ada target, keliling zona (respawn teleport) untuk mencari hewan",
	Default = false,
	Callback = function(Value)
		Steal.Patrol = Value
	end,
})

-- ===================== Main: Taruh Hewan =====================
local AnimalSection = MainTab:AddSection("Taruh Hewan di Base", false)

local BaseInfo = AnimalSection:AddParagraph({
	Title = "Base",
	Content = "Menghitung...",
})

local function AnimalRarityOptions()
	local Seen, List = {}, {}
	for _, Rarity in ipairs(RARITY_ORDER) do
		Seen[Rarity] = true
		table.insert(List, Rarity)
	end
	for _, Tool in ipairs(AnimalTools()) do
		local Rarity = Tool:GetAttribute("Rarity")
		if type(Rarity) == "string" and not Seen[Rarity] then
			Seen[Rarity] = true
			table.insert(List, Rarity)
		end
	end
	return List
end

AnimalSection:AddDropdown({
	Title = "Animal Rarities (kosong = semua)",
	Content = "Hanya taruh hewan rarity ini",
	Multi = true,
	Options = AnimalRarityOptions(),
	Default = {},
	Callback = function(Value)
		Place.Rarities = Value or {}
	end,
})

AnimalSection:AddToggle({
	Title = "Auto Taruh Hewan",
	Content = "Taruh hewan otomatis di base saat farm",
	Default = false,
	Callback = function(Value)
		Place.Auto = Value
	end,
})

AnimalSection:AddSlider({
	Title = "Taruh Tiap N Hewan",
	Content = "Mode setor Lewat Guard: pulang ke base setelah Backpack berisi N hewan",
	Increment = 1,
	Min = 1,
	Max = 20,
	Default = Place.Every,
	Callback = function(Value)
		Place.Every = Value
	end,
})

AnimalSection:AddButton({
	Title = "Taruh Semua Sekarang",
	Content = "Pulang ke base lalu taruh semua hewan di Backpack",
	Callback = function()
		if #AnimalTools() == 0 then
			Notify("Base", "Tidak ada hewan di Backpack.")
			return
		end
		if GoToBase() then
			local Count = PlaceAllAnimals()
			Notify("Base", Count .. " hewan ditaruh.")
		end
	end,
})

local FarmTune = MainTab:AddSection("Pengaturan Farm", false)

FarmTune:AddSlider({
	Title = "Jeda Pukulan (x0.01 detik)",
	Content = "Makin kecil makin cepat",
	Increment = 1,
	Min = 5,
	Max = 100,
	Default = 15,
	Callback = function(Value)
		Farm.HitDelay = Value / 100
	end,
})

FarmTune:AddSlider({
	Title = "Maks Waktu per Telur",
	Content = "Detik sebelum pindah telur lain",
	Increment = 1,
	Min = 5,
	Max = 120,
	Default = Farm.MaxTimePerEgg,
	Callback = function(Value)
		Farm.MaxTimePerEgg = Value
	end,
})

-- ===================== Teleport =====================
local EggSection = TeleportTab:AddSection("Teleport Telur", true)

local EggInfo = EggSection:AddParagraph({
	Title = "Telur di map",
	Content = "Menghitung...",
})

local SelectedEggKey = nil
local LastEggOptions = ""

local EggDropdown = EggSection:AddDropdown({
	Title = "Pilih Telur",
	Content = "Telur yang sedang muncul",
	Multi = false,
	Options = {},
	Default = {},
	Callback = function(Value)
		SelectedEggKey = Value and Value[1] or nil
	end,
})

local function RefreshEggList(Force)
	local Eggs = CollectEggs()
	local Seen, Order = {}, {}

	for _, Egg in ipairs(Eggs) do
		local Key = EggKey(Egg)
		if not Seen[Key] then
			Seen[Key] = true
			table.insert(Order, { Key = Key, Zone = ZoneIndex(Egg.ZoneId), Name = Egg.Name })
		end
	end

	table.sort(Order, function(a, b)
		if a.Zone ~= b.Zone then
			return a.Zone < b.Zone
		end
		return a.Name < b.Name
	end)

	local Options = {}
	for _, Item in ipairs(Order) do
		table.insert(Options, Item.Key)
	end

	local Joined = table.concat(Options, "|")
	if Force or Joined ~= LastEggOptions then
		LastEggOptions = Joined
		local Keep = (SelectedEggKey and table.find(Options, SelectedEggKey)) and { SelectedEggKey } or {}
		EggDropdown:Refresh(Options, Keep)
		SelectedEggKey = Keep[1]
	end

	EggInfo:Set({
		Title = "Telur di map",
		Content = string.format("%d telur, %d jenis", #Eggs, #Options),
	})
end

local function NearestEgg(Filter)
	local Best, BestDist = nil, math.huge
	for _, Egg in ipairs(CollectEggs()) do
		if not Filter or Filter(Egg) then
			local Dist = Distance(Egg)
			if Dist < BestDist then
				Best, BestDist = Egg, Dist
			end
		end
	end
	return Best
end

EggSection:AddButton({
	Title = "Teleport ke Telur Terpilih",
	Content = "Ke telur pilihan yang paling dekat",
	Callback = function()
		if not SelectedEggKey then
			Notify("Telur", "Pilih telur dulu di dropdown.")
			return
		end
		local Egg = NearestEgg(function(Egg)
			return EggKey(Egg) == SelectedEggKey
		end)
		if Egg then
			TeleportToEgg(Egg)
		else
			Notify("Telur", "Telur itu sudah tidak ada. Daftar diperbarui.")
			RefreshEggList(true)
		end
	end,
})

EggSection:AddButton({
	Title = "Teleport ke Telur Terdekat",
	Content = "Langsung ke telur paling dekat",
	Callback = function()
		local Egg = NearestEgg()
		if Egg then
			TeleportToEgg(Egg)
		else
			Notify("Telur", "Tidak ada telur di map.")
		end
	end,
})

local ZoneSection = TeleportTab:AddSection("Teleport Zona", true)

local ZoneByLabel = {}
local ZoneLabels = {}
for _, ZoneId in ipairs(GetZoneList()) do
	local Label = string.format("%d. %s", ZoneIndex(ZoneId), ZoneName(ZoneId))
	ZoneByLabel[Label] = ZoneId
	table.insert(ZoneLabels, Label)
end

local SelectedZone = nil
ZoneSection:AddDropdown({
	Title = "Pilih Zona",
	Content = "Semua zona di map",
	Multi = false,
	Options = ZoneLabels,
	Default = {},
	Callback = function(Value)
		SelectedZone = Value and Value[1] and ZoneByLabel[Value[1]] or nil
	end,
})

ZoneSection:AddDropdown({
	Title = "Titik Tujuan",
	Content = "Posisi di dalam zona",
	Multi = false,
	Options = { "Pintu Masuk", "Tengah Zona", "Area Telur" },
	Default = { "Pintu Masuk" },
	Callback = function(Value)
		Settings.ZoneTarget = Value and Value[1] or "Pintu Masuk"
	end,
})

ZoneSection:AddButton({
	Title = "Teleport ke Zona",
	Content = "Pindah ke zona yang dipilih",
	Callback = function()
		if not SelectedZone then
			Notify("Area", "Pilih zona dulu.")
			return
		end
		local Target = ZoneTargetCFrame(SelectedZone)
		if Target then
			TeleportTo(Target)
		else
			Notify("Area", "Posisi " .. ZoneName(SelectedZone) .. " tidak ditemukan.")
		end
	end,
})

local PlaceSection = TeleportTab:AddSection("Lokasi Lain", false)

PlaceSection:AddButton({
	Title = "Base Saya",
	Content = "Kembali ke plot milikmu",
	Callback = GoToBase,
})

local function AddModelButton(Title, Content, ModelName)
	PlaceSection:AddButton({
		Title = Title,
		Content = Content,
		Callback = function()
			local Model = workspace:FindFirstChild(ModelName)
			if Model and Model:IsA("Model") then
				local Pos = Model:GetPivot().Position
				TeleportTo(StandAt(Pos + Vector3.new(10, 0, 0), Pos))
			else
				Notify("Area", Title .. " tidak ditemukan.")
			end
		end,
	})
end

AddModelButton("Animal Merging", "Mesin merge hewan", "EggMachine")
AddModelButton("Fuse Machine", "Mesin fuse", "FuseMachine")

-- ===================== Settings =====================
local TpSection = SettingTab:AddSection("Teleport", true)

TpSection:AddSlider({
	Title = "Jarak Lompat per Frame",
	Content = "Untuk jarak dekat. Lynx ~28 stud",
	Increment = 1,
	Min = 8,
	Max = 45,
	Default = Settings.StepSize,
	Callback = function(Value)
		Settings.StepSize = Value
	end,
})

TpSection:AddSlider({
	Title = "Batas Jarak Dekat (stud)",
	Content = "Lebih jauh dari ini = respawn teleport",
	Increment = 10,
	Min = 50,
	Max = 400,
	Default = Settings.ShortRange,
	Callback = function(Value)
		Settings.ShortRange = Value
	end,
})

TpSection:AddSlider({
	Title = "Pengali Kecepatan Jalan",
	Content = "x WalkSpeed (dibagi 10). 10 = normal, makin besar makin berisiko",
	Increment = 1,
	Min = 5,
	Max = 30,
	Default = 10,
	Callback = function(Value)
		Settings.WalkMultiplier = Value / 10
	end,
})

TpSection:AddButton({
	Title = "Stop Gerak",
	Content = "Hentikan perjalanan yang sedang berlangsung",
	Callback = StopMoving,
})

local UiSection = SettingTab:AddSection("Panel", true)
UiSection:AddParagraph({
	Title = "Tips",
	Content = "RightControl = buka/tutup panel. Tarik pojok kanan bawah untuk ubah ukuran.",
})

---------------------------------------------------------------------
-- Loop
---------------------------------------------------------------------
RefreshEggList(true)

task.spawn(function()
	while not Library.Unloaded do
		task.wait(4)
		pcall(RefreshEggList, false)
	end
end)

-- Info base (jumlah hewan ditaruh / kapasitas / di Backpack)
task.spawn(function()
	local Last = ""
	while not Library.Unloaded do
		local Plot = MyPlot()
		local Text = "Base tidak ditemukan"
		if Plot then
			local Used, Max = PlotUsage(Plot)
			Text = string.format("Ditaruh: %d/%d | Di Backpack: %d hewan", Used, Max, #AnimalTools())
		end
		if Text ~= Last then
			Last = Text
			pcall(function()
				BaseInfo:Set({ Title = "Base", Content = Text })
			end)
		end
		task.wait(2)
	end
end)

-- Pulang ke base, tunggu hewan tersimpan, lalu (opsional) taruh hewan
local function BankAndPlace()
	SetStatus(string.format("Pulang ke base (bawa %d/%d)", CarryCount(), SatchelCapacity()))
	if not GoToBase() then
		return
	end

	local Started = os.clock()
	while Working() and CarryCount() > 0 and os.clock() - Started < 6 do
		task.wait(0.2)
	end

	if Place.Auto and Working() and #AnimalTools() > 0 then
		SetStatus("Menaruh hewan di base...")
		PlaceAllAnimals()
	end
end

---------------------------------------------------------------------
-- Setor lewat guard (cara Lynx): ditangkap guard -> fling window ->
-- ambil lagi hewan -> teleport ke SafeZone -> tersimpan -> teleport balik
---------------------------------------------------------------------
local function SafeSpot()
	local Build = GetBuild()
	local Hitboxes = Build and Build:FindFirstChild("ZoneHitboxes")
	local Safe = Hitboxes and Hitboxes:FindFirstChild("SafeZone")
	if not Safe or not Safe:IsA("BasePart") then
		return nil
	end
	-- Tepi SafeZone dari arah zona + 7 stud (titik yang sama dipakai Lynx: x = -73)
	local Edge = Safe.CFrame:PointToWorldSpace(Vector3.new(-Safe.Size.X / 2 + 7, 0, 0))
	local Ground = GroundAt(Edge.X, 1, 20)
	return CFrame.new(Ground + Vector3.new(0, 3.5, 0))
end

local function GuardPosition(Guard)
	local Root = Guard:FindFirstChild("HumanoidRootPart") or Guard.PrimaryPart
	if Root and Root:IsA("BasePart") then
		return Root.Position
	end
	local ok, Pivot = pcall(function()
		return Guard:GetPivot().Position
	end)
	return ok and Pivot or nil
end

-- Guard = model di ZoneBuilds.ZoneN yang punya atribut ChaseState
local function FindGuard(ZoneId)
	local Build = GetBuild()
	local ZoneBuilds = Build and Build:FindFirstChild("ZoneBuilds")
	local Root = GetRoot()
	if not ZoneBuilds or not Root then
		return nil
	end
	local Best, BestDist = nil, math.huge
	for _, Zone in ipairs(ZoneBuilds:GetChildren()) do
		if not ZoneId or Zone.Name == ZoneId then
			for _, Model in ipairs(Zone:GetChildren()) do
				if Model:IsA("Model") and Model:GetAttribute("ChaseState") ~= nil then
					local Pos = GuardPosition(Model)
					local Dist = Pos and (Pos - Root.Position).Magnitude or math.huge
					if Dist < BestDist then
						Best, BestDist = Model, Dist
					end
				end
			end
		end
	end
	return Best
end

-- Tekan prompt. Attempt ganjil = fireproximityprompt, genap = tahan manual
-- (beberapa executor punya fireproximityprompt yang tidak bekerja di game ini)
local function FirePrompt(Prompt, Attempt)
	Attempt = Attempt or 1
	if Attempt % 2 == 1 and fireproximityprompt then
		if pcall(fireproximityprompt, Prompt) then
			return "fireproximityprompt"
		end
	end
	local ok = pcall(function()
		Prompt:InputHoldBegin()
		task.wait(Prompt.HoldDuration + 0.05)
		Prompt:InputHoldEnd()
	end)
	return ok and "InputHold" or "gagal"
end

-- Prompt hewan yang terjatuh (PromptAnchor muncul di dekat karakter saat ditangkap)
local function NearestDropPrompt(MaxDist)
	local Root = GetRoot()
	if not Root then
		return nil
	end
	local Best, BestDist = nil, MaxDist
	for _, Anchor in ipairs(workspace:GetChildren()) do
		if Anchor.Name == "PromptAnchor" and Anchor:IsA("BasePart") then
			local Dist = (Anchor.Position - Root.Position).Magnitude
			if Dist < BestDist then
				local Prompt = Anchor:FindFirstChildWhichIsA("ProximityPrompt", true)
				if Prompt then
					Best, BestDist = Prompt, Dist
				end
			end
		end
	end
	return Best
end

local function BankViaGuard()
	local Root = GetRoot()
	local Spot = SafeSpot()
	if not Root or not Spot then
		return false
	end

	local ReturnTo = Root.CFrame
	local Guard = FindGuard(Player:GetAttribute("CarryingZone")) or FindGuard(nil)
	if not Guard then
		return false
	end

	SetStatus("Mendekati guard " .. Guard.Name .. " supaya ditangkap...")
	StopMoving()
	local Token = MoveToken
	local StartFlings = Fling.Count
	local Started = os.clock()

	-- 1. Lompat ke arah guard sampai ditangkap
	local Expected = nil
	while Working() and Token == MoveToken and Fling.Count == StartFlings and os.clock() - Started < 8 do
		local GuardPos = GuardPosition(Guard)
		local R, Hum = GetRoot(), GetHumanoid()
		if not GuardPos or not R or not Hum then
			break
		end
		if Expected and (R.Position - Expected).Magnitude > 40 and Fling.Count == StartFlings then
			LastMoveProblem = "Lompat ke guard ditarik balik"
			return false
		end
		Expected = nil
		local Flat = Vector3.new(GuardPos.X - R.Position.X, 0, GuardPos.Z - R.Position.Z)
		if Flat.Magnitude > 2 then
			local Next = R.Position + Flat.Unit * math.min(Flat.Magnitude - 1, Settings.StepSize)
			local Ground = GroundAt(Next.X, Next.Z, R.Position.Y + 6)
			local NewPos = Vector3.new(Next.X, Ground.Y + Hum.HipHeight + R.Size.Y / 2, Next.Z)
			R.CFrame = CFrame.lookAt(NewPos, NewPos + Flat.Unit)
			R.AssemblyLinearVelocity = Vector3.zero
			Expected = NewPos
		end
		RunService.Heartbeat:Wait()
	end

	if Fling.Count == StartFlings then
		return false -- tidak tertangkap
	end

	-- 2. Hewan jatuh saat ditangkap -> ambil lagi secepatnya
	local PickStart = os.clock()
	while CarryCount() == 0 and os.clock() - PickStart < 0.6 do
		local Prompt = NearestDropPrompt(25)
		if Prompt then
			FirePrompt(Prompt)
		end
		task.wait(0.03)
	end

	-- 3. Teleport ke SafeZone selama fling window -> hewan tersimpan
	if CarryCount() > 0 and InFlingWindow() then
		SetStatus("Teleport ke SafeZone...")
		local R = GetRoot()
		if R then
			R.CFrame = Spot
			R.AssemblyLinearVelocity = Vector3.zero
		end
		local BankStart = os.clock()
		while CarryCount() > 0 and os.clock() - BankStart < 1.2 do
			task.wait(0.05)
		end
	end

	-- 4. Kembali ke tempat farm (masih fling window = teleport langsung)
	EquipPickaxe()
	TeleportTo(ReturnTo)
	return true
end

local function Bank()
	if Farm.BankMode == "Lewat Guard (Cepat)" then
		if BankViaGuard() then
			-- Sesekali pulang ke base untuk menaruh hewan
			if Place.Auto and #AnimalTools() >= Place.Every then
				BankAndPlace()
			end
			return
		end
		SetStatus("Guard tidak menangkap, setor jalan ke base...")
	end
	BankAndPlace()
end

---------------------------------------------------------------------
-- Auto steal: StealPrompt (tag "SmartPrompt") milik hewan yang bisa diambil
---------------------------------------------------------------------
local STEAL_ATTRS = { "AnimalName", "Rarity", "WeightKg", "Mutation", "OwnerUserId", "Variant", "SizeMult" }

local function PromptPosition(Prompt)
	local Parent = Prompt.Parent
	if Parent and Parent:IsA("Attachment") then
		return Parent.WorldPosition
	elseif Parent and Parent:IsA("BasePart") then
		return Parent.Position
	end
	local Model = Prompt:FindFirstAncestorWhichIsA("Model")
	if Model then
		local ok, Pivot = pcall(function()
			return Model:GetPivot().Position
		end)
		if ok then
			return Pivot
		end
	end
	return nil
end

-- Nama hewan -> rarity. Sumber: modul EggRewards (semua hewan di game) +
-- atribut asli hewan di Backpack & base semua pemain (AnimalName / Rarity).
-- Kunci dinormalkan (huruf kecil, tanpa spasi) supaya "Fangtooth Fish" = "FangtoothFish".
local function NameKey(Text)
	return (tostring(Text):lower():gsub("[^%w]", ""))
end

local AnimalRarity = {}
local AnimalRarityLoaded = false
local AnimalRarityCount = 0

local function LearnAnimal(Name, Rarity)
	if type(Name) == "string" and type(Rarity) == "string" and Rarity ~= "" then
		local Key = NameKey(Name)
		if Key ~= "" and not AnimalRarity[Key] then
			AnimalRarity[Key] = Rarity
			AnimalRarityCount += 1
		end
	end
end

-- Pelajari dari hewan nyata di game (Tool di Backpack, hewan di base semua pemain)
local LastLearn = 0
local function LearnFromWorld()
	if os.clock() - LastLearn < 5 then
		return
	end
	LastLearn = os.clock()
	for _, Container in ipairs({ Player:FindFirstChild("Backpack"), Player.Character }) do
		if Container then
			for _, Tool in ipairs(Container:GetChildren()) do
				LearnAnimal(Tool:GetAttribute("AnimalName"), Tool:GetAttribute("Rarity"))
			end
		end
	end
	local Plots = workspace:FindFirstChild("Plots")
	if Plots then
		for _, Plot in ipairs(Plots:GetChildren()) do
			local Placed = Plot:FindFirstChild("PlacedAnimals")
			if Placed then
				for _, Animal in ipairs(Placed:GetChildren()) do
					LearnAnimal(Animal:GetAttribute("AnimalName") or Animal.Name, Animal:GetAttribute("Rarity"))
				end
			end
		end
	end
end

local function GetAnimalRarity()
	if not AnimalRarityLoaded then
		AnimalRarityLoaded = true
		local EggRewards = EggRewardsModule
		if EggRewards and type(EggRewards.Pool) == "table" then
			for _, Entry in ipairs(EggRewards.Pool) do
				if type(Entry) == "table" and Entry.Name and Entry.Rarity then
					LearnAnimal(Entry.Name, Entry.Rarity)
					if type(EggRewards.DisplayName) == "function" then
						local ok, Display = pcall(EggRewards.DisplayName, Entry.Name)
						if ok then
							LearnAnimal(Display, Entry.Rarity)
						end
					end
				end
			end
		end
	end
	LearnFromWorld()
	return AnimalRarity
end

local function RarityOfAnimal(Name)
	return GetAnimalRarity()[NameKey(Name)]
end

-- ObjectText: '<font color="#4FE8D2"><b>[360Kg]</b></font> Gold Fangtooth Fish'
-- -> berat 360, nama "Fangtooth Fish", mutasi "Gold", rarity dari EggRewards
local function ParseObjectText(Text)
	local Plain = Text:gsub("<[^>]->", "")
	local WeightText = Plain:match("%[([^%]]+)%]")
	local Weight = WeightText and ParseShort((WeightText:gsub("[Kk][Gg]", ""):gsub(",", ""))) or nil
	local Name = Plain:gsub("%b[]", ""):gsub("^%s+", ""):gsub("%s+$", "")

	local Rarity, Mutation = RarityOfAnimal(Name), nil
	if not Rarity then
		-- Coba buang kata depan (mutasi), mis. "Gold Fangtooth Fish"
		local Words = Name:split(" ")
		for Cut = 1, math.min(2, #Words - 1) do
			local Rest = table.concat(Words, " ", Cut + 1)
			if RarityOfAnimal(Rest) then
				Rarity = RarityOfAnimal(Rest)
				Mutation = table.concat(Words, " ", 1, Cut)
				Name = Rest
				break
			end
		end
	end
	return Name, Weight, Rarity, Mutation
end

-- Info hewan: atribut (kalau ada) + isi teks prompt
local function PromptInfo(Prompt)
	local Info = {}
	local Node = Prompt
	for _ = 1, 6 do
		if not Node or Node == workspace then
			break
		end
		for _, Key in ipairs(STEAL_ATTRS) do
			if Info[Key] == nil then
				Info[Key] = Node:GetAttribute(Key)
			end
		end
		Node = Node.Parent
	end

	local Name, Weight, Rarity, Mutation = ParseObjectText(Prompt.ObjectText or "")
	Info.Name = Info.AnimalName or (Name ~= "" and Name) or "Hewan"
	Info.WeightKg = Info.WeightKg or Weight
	Info.Rarity = Info.Rarity or Rarity or RarityOfAnimal(Info.Name)
	Info.Mutation = Info.Mutation or Mutation
	return Info
end

local function AllStealPrompts()
	local List, Seen = {}, {}
	local function Add(Prompt)
		if not Seen[Prompt] and Prompt:IsA("ProximityPrompt") and Prompt.Name == "StealPrompt" then
			Seen[Prompt] = true
			table.insert(List, Prompt)
		end
	end
	for _, Prompt in ipairs(CollectionService:GetTagged("SmartPrompt")) do
		Add(Prompt)
	end
	-- Cadangan: prompt di PromptAnchor / AnimalPickups
	for _, Child in ipairs(workspace:GetChildren()) do
		if Child.Name == "PromptAnchor" or Child.Name == "AnimalPickups" then
			for _, D in ipairs(Child:GetDescendants()) do
				Add(D)
			end
		end
	end
	return List
end

local function StealFilter(Info)
	if #Steal.Rarities > 0 and not table.find(Steal.Rarities, Info.Rarity) then
		return false
	end
	local Weight = tonumber(Info.WeightKg)
	if Steal.MinWeight > 0 and Weight and Weight < Steal.MinWeight then
		return false
	end
	if Steal.MutationOnly and (Info.Mutation == nil or Info.Mutation == "") then
		return false
	end
	return true
end

local StealSkip = setmetatable({}, { __mode = "k" })

-- ZoneId dari posisi (pakai ZoneHitboxes)
local function ZoneIdAt(Pos)
	local Build = GetBuild()
	local Hitboxes = Build and Build:FindFirstChild("ZoneHitboxes")
	if not Hitboxes then
		return nil
	end
	for _, Box in ipairs(Hitboxes:GetChildren()) do
		if Box:IsA("BasePart") and tonumber(Box.Name) then
			local Rel = Box.CFrame:PointToObjectSpace(Pos)
			local Half = Box.Size / 2
			if math.abs(Rel.X) <= Half.X and math.abs(Rel.Z) <= Half.Z then
				return "Zone" .. Box.Name
			end
		end
	end
	return nil
end

-- Base (plot) tempat sebuah posisi berada, dicek dari Hitbox tiap plot
-- (prompt hewan di base ada di Workspace.PromptAnchor, bukan di folder Plots)
local function PlotAt(Pos)
	local Plots = workspace:FindFirstChild("Plots")
	if not Plots then
		return nil
	end
	for _, Plot in ipairs(Plots:GetChildren()) do
		local Hitbox = Plot:FindFirstChild("Hitbox")
		if Hitbox and Hitbox:IsA("BasePart") then
			local Rel = Hitbox.CFrame:PointToObjectSpace(Pos)
			local Half = Hitbox.Size / 2 + Vector3.new(4, 10, 4)
			if math.abs(Rel.X) <= Half.X and math.abs(Rel.Y) <= Half.Y and math.abs(Rel.Z) <= Half.Z then
				return Plot
			end
		end
	end
	return nil
end

local function StealTargets()
	local List = {}
	local Root = GetRoot()
	local Plot = MyPlot()
	local Plots = workspace:FindFirstChild("Plots")

	for _, Prompt in ipairs(AllStealPrompts()) do
		local Pos = Prompt.Enabled and PromptPosition(Prompt) or nil
		local PlotHere = Pos and PlotAt(Pos) or nil
		local Mine = Plot ~= nil and (PlotHere == Plot or Prompt:IsDescendantOf(Plot))
		if Pos and Prompt:IsDescendantOf(workspace) and not StealSkip[Prompt] and not Mine then
			local InBase = PlotHere ~= nil or (Plots ~= nil and Prompt:IsDescendantOf(Plots))
			if (InBase and Steal.OtherBases) or (not InBase and Steal.Dropped) then
				local ZoneOk = true
				if Pos and #Steal.Zones > 0 then
					local ZoneId = ZoneIdAt(Pos)
					ZoneOk = ZoneId ~= nil and table.find(Steal.Zones, ZoneName(ZoneId)) ~= nil
				end
				if Pos and ZoneOk then
					local Info = PromptInfo(Prompt)
					if StealFilter(Info) then
						Info.Prompt = Prompt
						Info.Position = Pos
						Info.InBase = InBase
						Info.Distance = Root and (Pos - Root.Position).Magnitude or 0
						table.insert(List, Info)
					end
				end
			end
		end
	end

	table.sort(List, function(a, b)
		return a.Distance < b.Distance
	end)
	return List
end

local LastStealResult = "-"

-- Datangi prompt, tekan sampai hewan terbawa (CarryCount naik)
local function StealOne(Info)
	local Label = Info.Name .. (Info.Rarity and (" [" .. tostring(Info.Rarity) .. "]") or "")
	SetStatus("Mencuri " .. Label)
	local Before = CarryCount()

	-- Berdiri tepat di titik prompt (jangkauan prompt hanya ~10 stud)
	local Anchor = Info.Prompt.Parent
	local Target = (Anchor and Anchor:IsA("BasePart")) and Anchor.Position or Info.Position
	if Info.Distance > 5 then
		if not TeleportTo(StandAt(Target)) then
			StealSkip[Info.Prompt] = true
			LastStealResult = "Gagal sampai ke " .. Label .. " (" .. tostring(LastMoveProblem or "?") .. ")"
			return false
		end
	end

	local Started, Attempt, Method = os.clock(), 0, "-"
	while os.clock() - Started < 3 and CarryCount() <= Before and Info.Prompt.Parent and Info.Prompt.Enabled do
		Attempt += 1
		Method = FirePrompt(Info.Prompt, Attempt)
		task.wait(0.2)
	end

	if CarryCount() > Before then
		LastStealResult = "Berhasil: " .. Label .. " (" .. Method .. ")"
		return true
	end

	local Root = GetRoot()
	LastStealResult = string.format(
		"Gagal ambil %s | percobaan %d | metode %s | jarak %.1f | prompt %s",
		Label,
		Attempt,
		Method,
		Root and (Target - Root.Position).Magnitude or -1,
		Info.Prompt.Parent and (Info.Prompt.Enabled and "aktif" or "nonaktif") or "hilang"
	)
	StealSkip[Info.Prompt] = true
	return false
end

---------------------------------------------------------------------
-- Zona jauh: minta server mengirim isi zona (streaming) tanpa ke sana
---------------------------------------------------------------------
local function ZoneScanPoints()
	local Points = {}
	local Build = GetBuild()
	local Hitboxes = Build and Build:FindFirstChild("ZoneHitboxes")
	if not Hitboxes then
		return Points
	end
	for _, Box in ipairs(Hitboxes:GetChildren()) do
		local Index = tonumber(Box.Name)
		if Box:IsA("BasePart") and Index then
			local ZoneId = "Zone" .. Index
			if #Steal.Zones == 0 or table.find(Steal.Zones, ZoneName(ZoneId)) then
				-- Titik tiap ~200 stud sepanjang zona
				local Count = math.max(1, math.ceil(Box.Size.X / 200))
				for i = 1, Count do
					local X = Box.Position.X - Box.Size.X / 2 + (i - 0.5) * (Box.Size.X / Count)
					table.insert(Points, { ZoneId = ZoneId, Position = Vector3.new(X, 5, Box.Position.Z) })
				end
			end
		end
	end
	return Points
end

task.spawn(function()
	while not Library.Unloaded do
		if Steal.Enabled and Steal.StreamScan then
			for _, Point in ipairs(ZoneScanPoints()) do
				if not Steal.Enabled or Library.Unloaded then
					break
				end
				pcall(function()
					Player:RequestStreamAroundAsync(Point.Position, 2)
				end)
				task.wait(0.4)
			end
		end
		task.wait(2)
	end
end)

-- Patroli: kalau tidak ada target terlihat, datangi zona satu per satu
local PatrolIndex = 0
local function PatrolNextZone()
	local Zones = {}
	for _, ZoneId in ipairs(GetZoneList()) do
		if #Steal.Zones == 0 or table.find(Steal.Zones, ZoneName(ZoneId)) then
			table.insert(Zones, ZoneId)
		end
	end
	if #Zones == 0 then
		return
	end
	PatrolIndex = PatrolIndex % #Zones + 1
	local ZoneId = Zones[PatrolIndex]
	SetStatus("Patroli ke " .. ZoneName(ZoneId) .. " mencari hewan...")
	local Previous = Settings.ZoneTarget
	Settings.ZoneTarget = "Tengah Zona"
	local Target = ZoneTargetCFrame(ZoneId)
	Settings.ZoneTarget = Previous
	if Target then
		TeleportTo(Target)
		task.wait(1.5) -- beri waktu isi zona termuat
	end
end

-- Info jumlah target curi
task.spawn(function()
	local Last = ""
	while not Library.Unloaded do
		local ok, Targets = pcall(StealTargets)
		local Text = ok and string.format("%d hewan lolos filter (total StealPrompt: %d)", #Targets, #AllStealPrompts())
			or "Gagal membaca"
		if Text ~= Last then
			Last = Text
			pcall(function()
				StealInfo:Set({ Title = "Hewan bisa dicuri", Content = Text })
			end)
		end
		task.wait(3)
	end
end)

-- Auto farm: satu langkah per panggilan, dibungkus pcall supaya error terlihat
local LastFarmError = nil
local FarmSkip = setmetatable({}, { __mode = "k" })
local NoDamageStreak = 0
local EnsureBestZoneLoaded -- didefinisikan di bawah
local LogDiagnostics -- diisi setelah DiagnoseText ada

-- Jumlah telur lolos filter di satu zona (yang sudah termuat di client)
local function CountEggsInZone(Index)
	local Count = 0
	for _, Egg in ipairs(CollectEggs()) do
		if ZoneIndex(Egg.ZoneId) == Index and FarmFilter(Egg) then
			Count += 1
		end
	end
	return Count
end

-- Minta server mengirim isi zona (game memakai streaming: zona jauh tidak dimuat)
local function StreamZone(Index)
	local Build = GetBuild()
	local Hitboxes = Build and Build:FindFirstChild("ZoneHitboxes")
	local Box = Hitboxes and Hitboxes:FindFirstChild(tostring(Index))
	if not Box or not Box:IsA("BasePart") then
		return
	end
	local Points = math.max(1, math.ceil(Box.Size.X / 200))
	for i = 1, Points do
		local X = Box.Position.X - Box.Size.X / 2 + (i - 0.5) * (Box.Size.X / Points)
		pcall(function()
			Player:RequestStreamAroundAsync(Vector3.new(X, 5, Box.Position.Z), 2)
		end)
	end
end

-- Zona terbaik belum terlihat telurnya: muat dulu, kalau perlu datangi.
-- Tetap kosong -> tandai kosong 90 detik, farm turun ke zona di bawahnya.
EnsureBestZoneLoaded = function()
	CurrentBestIndex = BestZoneIndex()
	local Index = CurrentBestIndex
	if CountEggsInZone(Index) > 0 then
		return
	end

	local Label = ZoneName("Zone" .. Index)
	SetStatus("Memuat " .. Label .. "...")
	StreamZone(Index)
	task.wait(0.5)
	if CountEggsInZone(Index) > 0 then
		FarmLog(Label .. " termuat lewat streaming")
		return
	end

	SetStatus("Menuju " .. Label .. " (telur belum termuat)")
	local Target = ZoneTargetCFrame("Zone" .. Index)
	if Target and TeleportTo(Target) then
		task.wait(2)
		if CountEggsInZone(Index) > 0 then
			FarmLog(Label .. " termuat setelah didatangi")
			return
		end
	end

	ZoneEmptyUntil[Index] = os.clock() + 90
	FarmLog(Label .. " tidak ada telur yang cocok, turun ke zona bawahnya selama 90 dtk")
	CurrentBestIndex = BestZoneIndex()
end

local function FarmStep()
	if IsJailed() then
		SetStatus("Sedang ditahan, menunggu...")
		task.wait(1)
		return
	end

	-- Satchel penuh -> setor
	if Farm.ReturnWhenFull and CarryCount() >= SatchelCapacity() then
		Bank()
		return
	end

	-- Auto steal dulu (hewan siap ambil lebih cepat daripada memecah telur)
	if Steal.Enabled and CarryCount() < SatchelCapacity() then
		local Target = StealTargets()[1]
		if Target then
			StealOne(Target)
			return
		end
	end

	-- Hanya steal: setor yang dibawa, lalu tunggu target baru
	if not Farm.Enabled then
		if Farm.ReturnWhenFull and CarryCount() > 0 then
			Bank()
			return
		end
		if Steal.Patrol then
			PatrolNextZone()
			return
		end
		SetStatus("Menunggu hewan untuk dicuri... (" .. LastStealResult .. ")")
		task.wait(0.5)
		return
	end

	if Farm.AutoBestZone and #Farm.Zones == 0 then
		EnsureBestZoneLoaded()
	end

	local Egg = PickFarmEgg(FarmSkip)
	if not Egg then
		if Farm.ReturnWhenFull and CarryCount() > 0 then
			Bank()
			return
		end
		SetStatus("Menunggu telur yang cocok (" .. LastPickStats .. ")")
		table.clear(FarmSkip)
		task.wait(1)
		return
	end

	local Label = string.format("%s (%s)", Egg.Name, ZoneName(Egg.ZoneId))
	SetStatus("Menuju " .. Label)

	if Distance(Egg) > 10 and not TeleportToEgg(Egg) then
		-- Gagal sampai (ditarik balik / dibatalkan): jangan dipaksa, coba telur lain
		FarmSkip[Egg.Model] = true
		SetStatus("Gagal menuju " .. Label .. " (" .. tostring(LastMoveProblem or "?") .. ")")
		task.wait(2)
		return
	end

	local Started, Retries = os.clock(), 0
	local StartHP = tonumber(Egg.Part:GetAttribute("Health"))
	local CheckAt = os.clock() + 4
	local Methods = {}

	while Farm.Enabled and not Library.Unloaded and EggAlive(Egg) and not IsJailed() do
		if os.clock() - Started > Farm.MaxTimePerEgg then
			FarmLog("Waktu habis untuk " .. Label)
			FarmSkip[Egg.Model] = true
			break
		end

		-- Terpental (guard / dorongan) -> dekati lagi, maksimal 3x
		if Distance(Egg) > 12 then
			Retries += 1
			if Retries > 3 or not TeleportToEgg(Egg) then
				FarmLog("Terpental terus dari " .. Label .. ", pindah telur")
				FarmSkip[Egg.Model] = true
				break
			end
		end

		SetStatus(string.format("Memukul %s | bawa %d/%d", Label, CarryCount(), SatchelCapacity()))
		local Method = HitEgg(Egg)
		Methods[Method] = (Methods[Method] or 0) + 1

		-- Setelah 4 detik: cek apakah HP telur turun & bisa pecah tepat waktu
		if StartHP and os.clock() >= CheckAt then
			CheckAt = math.huge
			local NowHP = tonumber(Egg.Part:GetAttribute("Health")) or StartHP
			local Elapsed = math.max(os.clock() - Started, 0.1)
			local MethodParts = {}
			for Name, Count in pairs(Methods) do
				table.insert(MethodParts, Name .. " x" .. Count)
			end
			local MethodText = table.concat(MethodParts, ", ")

			if NowHP >= StartHP then
				NoDamageStreak += 1
				FarmLog(string.format(
					"HP %s TIDAK TURUN (%.0f) setelah %.0f dtk | cara: %s | jarak %.1f | streak %d",
					Label,
					NowHP,
					Elapsed,
					MethodText,
					Distance(Egg),
					NoDamageStreak
				))
				-- 2x berturut-turut tidak masuk -> ganti cara pukul otomatis
				if NoDamageStreak >= 2 then
					NoDamageStreak = 0
					Farm.HitMode = Farm.HitMode == "Swing Game (Aman)" and "Klik Virtual" or "Swing Game (Aman)"
					FarmLog("Ganti Cara Pukul ke: " .. Farm.HitMode)
					Notify("Auto Farm", "Pukulan tidak masuk, ganti cara pukul ke " .. Farm.HitMode)
				end
				FarmSkip[Egg.Model] = true
				break
			end

			NoDamageStreak = 0
			local Rate = (StartHP - NowHP) / Elapsed
			local Eta = NowHP / Rate
			FarmLog(string.format("%s: HP turun %.3g/dtk, pecah sekitar %.0f dtk lagi | cara: %s", Label, Rate, Eta, MethodText))
			if Eta > Farm.MaxTimePerEgg then
				TooStrong[Egg.Name] = os.clock() + 120
				FarmLog(Label .. " terlalu kuat untuk batas waktu, jenis ini dilewati 2 menit")
				FarmSkip[Egg.Model] = true
				break
			end
		end

		task.wait(Farm.HitDelay)
	end

	if not EggAlive(Egg) then
		FarmLog("Telur pecah: " .. Label .. " | bawa " .. CarryCount() .. "/" .. SatchelCapacity())
	end
end

-- Simpan log farm ke file tiap 10 detik saat aktif
task.spawn(function()
	pcall(function()
		if makefolder and not (isfolder and isfolder("RapHub")) then
			makefolder("RapHub")
		end
	end)
	while not Library.Unloaded do
		task.wait(10)
		if Working() and writefile and #FarmLogLines > 0 then
			pcall(writefile, "RapHub/FarmLog.txt", table.concat(FarmLogLines, "\n"))
		end
	end
end)

task.spawn(function()
	local WasWorking = false
	while not Library.Unloaded do
		local Active = Working()
		if Active and not WasWorking and LogDiagnostics then
			pcall(LogDiagnostics)
		end
		WasWorking = Active

		if not Active then
			task.wait(0.3)
		else
			local ok, Err = pcall(FarmStep)
			if not ok then
				LastFarmError = tostring(Err)
				SetStatus("Error: " .. LastFarmError)
				warn("[RapHub] Auto farm error: " .. LastFarmError)
				task.wait(2)
			end
		end
	end
end)

-- ===================== Diagnosa (tab Settings) =====================
local DiagSection = SettingTab:AddSection("Diagnosa", true)

local DiagInfo = DiagSection:AddParagraph({
	Title = "Status sistem",
	Content = "Tekan Cek Sekarang",
})

local function DiagnoseText()
	local Parts = {}
	local function Check(Label, Ok)
		table.insert(Parts, Label .. ": " .. (Ok and "OK" or "GAGAL"))
	end

	local Pick = GameModule("PickaxeController")
	Check("PickaxeController", Pick ~= nil and type(Pick.Swing) == "function")
	local AnimalCtl = GameModule("AnimalToolController")
	Check("AnimalToolController", AnimalCtl ~= nil and type(AnimalCtl.PlaceAt) == "function")
	Check("fireproximityprompt", type(fireproximityprompt) == "function")
	Check("Pickaxe", GetPickaxe() ~= nil)
	Check("Base", MyPlot() ~= nil)
	Check("SafeZone", SafeSpot() ~= nil)
	table.insert(Parts, "Telur: " .. #CollectEggs())
	table.insert(Parts, "Bawa: " .. CarryCount() .. "/" .. SatchelCapacity())
	table.insert(Parts, "Masalah gerak: " .. tostring(LastMoveProblem or "-"))
	table.insert(Parts, "Error farm: " .. tostring(LastFarmError or "-"))
	table.insert(Parts, "Curi terakhir: " .. LastStealResult)
	table.insert(Parts, "StreamingEnabled: " .. tostring(workspace.StreamingEnabled))
	-- Sumber data nama (semua dari game)
	local ZoneCount = 0
	for _ in pairs(ZONE_NAMES) do
		ZoneCount += 1
	end
	table.insert(Parts, string.format("Nama zona: %s (%d)", DataSource.Zones, ZoneCount))
	table.insert(Parts, string.format("Rarity: %d dari %s", #RARITY_ORDER, table.concat(DataSource.Rarities, "+")))
	GetAnimalRarity()
	table.insert(Parts, "Hewan dikenal: " .. AnimalRarityCount)
	Check("Modul ZonesConfig", ZonesConfig ~= nil)
	Check("Modul EggRewards", EggRewardsModule ~= nil)
	return table.concat(Parts, " | ")
end

LogDiagnostics = function()
	FarmLog("=== MULAI === " .. DiagnoseText())
	FarmLog(string.format(
		"Setelan: mode gerak %s | cara pukul %s | setor %s | zona %s | auto zona terbaik %s (%s) | speed %s",
		Settings.TeleportMode,
		Farm.HitMode,
		Farm.BankMode,
		#Farm.Zones > 0 and table.concat(Farm.Zones, ",") or "semua",
		tostring(Farm.AutoBestZone),
		ZoneName(BestZoneId()),
		tostring(Player:GetAttribute("SpeedPower"))
	))
end

DiagSection:AddButton({
	Title = "Cek Sekarang",
	Content = "Screenshot hasilnya kalau ada yang tidak jalan",
	Callback = function()
		local ok, Text = pcall(DiagnoseText)
		DiagInfo:Set({ Title = "Status sistem", Content = ok and Text or ("Error cek: " .. tostring(Text)) })
	end,
})

DiagSection:AddButton({
	Title = "Tes Pukul Telur Terdekat",
	Content = "Sekali pukul telur terdekat (harus berdiri di dekat telur)",
	Callback = function()
		local Best, BestDist = nil, math.huge
		for _, Egg in ipairs(CollectEggs()) do
			local Dist = Distance(Egg)
			if Dist < BestDist then
				Best, BestDist = Egg, Dist
			end
		end
		if not Best then
			Notify("Tes", "Tidak ada telur.")
			return
		end
		HitEgg(Best)
		Notify("Tes", string.format("Pukul %s (jarak %.1f stud). Lihat HP telurnya turun atau tidak.", Best.Name, BestDist))
	end,
})

DiagSection:AddButton({
	Title = "Tes Curi Terdekat",
	Content = "Curi 1 hewan terdekat tanpa filter, lalu tampilkan hasilnya",
	Callback = function()
		local Saved = { Rarities = Steal.Rarities, MinWeight = Steal.MinWeight, MutationOnly = Steal.MutationOnly, Zones = Steal.Zones }
		Steal.Rarities, Steal.MinWeight, Steal.MutationOnly, Steal.Zones = {}, 0, false, {}
		table.clear(StealSkip)
		local Target = StealTargets()[1]
		Steal.Rarities, Steal.MinWeight, Steal.MutationOnly, Steal.Zones = Saved.Rarities, Saved.MinWeight, Saved.MutationOnly, Saved.Zones

		if not Target then
			LastStealResult = "Tidak ada StealPrompt terlihat (total: " .. #AllStealPrompts() .. ")"
		else
			StealOne(Target)
		end
		Notify("Tes Curi", LastStealResult)
		pcall(function()
			DiagInfo:Set({ Title = "Status sistem", Content = DiagnoseText() })
		end)
	end,
})

-- Tulis detail semua ProximityPrompt di map ke file (untuk menyempurnakan auto steal)
DiagSection:AddButton({
	Title = "Scan Steal Prompt",
	Content = "Simpan detail prompt hewan ke RapHub/StealScan.txt",
	Callback = function()
		local Lines = { "== StealScan  PlaceId " .. game.PlaceId, "" }
		local Root = GetRoot()
		local Count, StealCount = 0, 0

		for _, Prompt in ipairs(workspace:GetDescendants()) do
			if Prompt:IsA("ProximityPrompt") then
				Count += 1
				if Prompt.Name == "StealPrompt" then
					StealCount += 1
				end
				if Count <= 150 then
					local Pos = PromptPosition(Prompt)
					local Tags = table.concat(CollectionService:GetTags(Prompt), ",")
					table.insert(Lines, string.format(
						"%s | name=%s action=%q object=%q enabled=%s hold=%.2f dist=%.0f tags=%s | jarak=%s",
						Prompt:GetFullName(),
						Prompt.Name,
						Prompt.ActionText,
						Prompt.ObjectText,
						tostring(Prompt.Enabled),
						Prompt.HoldDuration,
						Prompt.MaxActivationDistance,
						Tags,
						(Pos and Root) and string.format("%.0f", (Pos - Root.Position).Magnitude) or "?"
					))
					-- Atribut leluhur (3 tingkat)
					local Node = Prompt.Parent
					for Level = 1, 3 do
						if not Node or Node == workspace then
							break
						end
						local Attrs = {}
						for Key, Value in pairs(Node:GetAttributes()) do
							table.insert(Attrs, Key .. "=" .. tostring(Value))
						end
						table.sort(Attrs)
						table.insert(Lines, string.format(
							"    ^%d %s [%s] {%s}",
							Level,
							Node.Name,
							Node.ClassName,
							table.concat(Attrs, ", ")
						))
						Node = Node.Parent
					end
				end
			end
		end

		table.insert(Lines, "")
		table.insert(Lines, string.format("Total prompt: %d | StealPrompt: %d", Count, StealCount))
		local Text = table.concat(Lines, "\n")
		local Saved = writefile and pcall(writefile, "RapHub/StealScan.txt", Text)
		if not Saved and setclipboard then
			pcall(setclipboard, Text)
		end
		Notify("Scan", string.format("%d prompt (%d StealPrompt). %s", Count, StealCount, Saved and "Tersimpan RapHub/StealScan.txt" or "Di-copy ke clipboard"))
	end,
})

Notify("Loaded", "Break and Steal an Egg siap dipakai!")
