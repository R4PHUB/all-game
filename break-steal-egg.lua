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
	  - Teleport ke telur (daftar telur yang muncul, terdekat, auto + filter)
	  - Teleport ke zona (nama asli zona) & lokasi penting (base, mesin)
	`Library` (UI) ditanam otomatis di atas file ini oleh build.js
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

---------------------------------------------------------------------
-- Setting
---------------------------------------------------------------------
local Settings = {
	TeleportMode = "Jalan (Aman)", -- "Jalan (Aman)" | "Instant" | "Tween"
	WalkMultiplier = 1, -- pengali WalkSpeed untuk mode Jalan (Aman)
	TweenSpeed = 300, -- stud per detik
	ZoneTarget = "Pintu Masuk", -- "Pintu Masuk" | "Tengah Zona" | "Area Telur"
	AutoPriority = "Terdekat", -- "Terdekat" | "Luck Tertinggi" | "Terberat"
	AutoNames = {}, -- kosong = semua telur
	AutoRarities = {}, -- kosong = semua rarity
	AutoStayTime = 10, -- detik maksimal di satu telur
}

---------------------------------------------------------------------
-- Data game (dibaca dari ReplicatedStorage.Shared, ada cadangan)
---------------------------------------------------------------------
local ZONE_NAMES = {
	Zone1 = "Forest Zone",
	Zone2 = "Desert Zone",
	Zone3 = "Snowy Zone",
	Zone4 = "Candy Zone",
	Zone5 = "Swamp Zone",
	Zone6 = "Ocean Zone",
	Zone7 = "Volcano Zone",
	Zone8 = "Blossom Zone",
	Zone9 = "Galaxy Zone",
	Zone10 = "Planet X Zone",
	Zone11 = "Haunted Graveyard",
	Zone12 = "Fairy Castle",
	Zone13 = "Fantasy Expansion",
	Zone14 = "Mount Olympus",
	Zone15 = "Pirate Cove",
}

local RARITY_ORDER = {
	"Common",
	"Uncommon",
	"Rare",
	"Epic",
	"Legendary",
	"Mythic",
	"Divine",
	"Cosmic",
	"Secret",
	"Celestial",
	"Inferno",
	"Void",
	"Omega",
	"Spectral",
	"Ethereal",
}

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

-- Ambil nama zona dari game kalau bisa
if ZoneDisplayInfo then
	for ZoneId, Info in pairs(ZoneDisplayInfo) do
		if type(Info) == "table" and type(Info.Name) == "string" then
			ZONE_NAMES[ZoneId] = Info.Name
		end
	end
end

-- Urutan rarity dari ZonesConfig (kalau ada)
if ZonesConfig and type(ZonesConfig.Zones) == "table" then
	local List = {}
	for _, Zone in ipairs(ZonesConfig.Zones) do
		if type(Zone) == "table" and Zone.Rarity then
			table.insert(List, Zone.Rarity)
		end
	end
	if #List > 0 then
		RARITY_ORDER = List
	end
end

local function ZoneIndex(ZoneId)
	return tonumber(tostring(ZoneId):match("%d+")) or 999
end

local function ZoneName(ZoneId)
	return ZONE_NAMES[ZoneId] or ZoneId
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

	local Origin = Vector3.new(X, FromY or 40, Z)
	local Result = workspace:Raycast(Origin, Vector3.new(0, -200, 0), Params)
	return Result and Result.Position or Vector3.new(X, 3, Z)
end

local function GetHumanoid()
	local Character = Player.Character
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local ActiveTween
local MoveToken = 0
local PullBackWarning -- diisi setelah fungsi Notify ada

-- Hentikan gerakan yang sedang berjalan (jalan aman / tween)
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

local function TeleportTo(TargetCFrame)
	local Root = GetRoot()
	if not Root or not TargetCFrame then
		return false
	end

	StopMoving()
	local Token = MoveToken

	if Settings.TeleportMode == "Jalan (Aman)" then
		return WalkTo(TargetCFrame, Token)
	end

	if Settings.TeleportMode == "Tween" then
		local Distance = (Root.Position - TargetCFrame.Position).Magnitude
		local Duration = math.max(Distance / math.max(Settings.TweenSpeed, 1), 0.05)

		-- Tahan karakter supaya tidak jatuh saat tween
		local Hold = RunService.Heartbeat:Connect(function()
			if Root.Parent then
				Root.AssemblyLinearVelocity = Vector3.zero
			end
		end)

		ActiveTween = TweenService:Create(Root, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
			CFrame = TargetCFrame,
		})
		ActiveTween:Play()
		ActiveTween.Completed:Wait()
		ActiveTween = nil
		Hold:Disconnect()
	else
		Root.CFrame = TargetCFrame

		-- Cek apakah server menarik balik karakter (anti-cheat)
		task.delay(1.5, function()
			if Token == MoveToken and Root.Parent and (Root.Position - TargetCFrame.Position).Magnitude > 25 then
				if PullBackWarning then
					PullBackWarning()
				end
			end
		end)
	end

	Root.AssemblyLinearVelocity = Vector3.zero
	return Token == MoveToken
end

-- Berdiri di atas tanah pada posisi `Pos`, menghadap `LookAt`
local function StandAt(Pos, LookAt)
	local Ground = GroundAt(Pos.X, Pos.Z, Pos.Y + 25)
	local Stand = Ground + Vector3.new(0, 3.5, 0)
	if LookAt then
		return CFrame.lookAt(Stand, Vector3.new(LookAt.X, Stand.Y, LookAt.Z))
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
	Notify("Anti-cheat", 'Teleport ditarik balik server. Pakai mode "Jalan (Aman)" di Settings.')
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

	-- Cadangan (tidak di-cache, label mungkin belum terisi)
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

local function Distance(Egg)
	local Root = GetRoot()
	return Root and (Egg.Position - Root.Position).Magnitude or 0
end

-- Teleport ke samping telur, menghadap telur
local function TeleportToEgg(Egg)
	if not Egg or not Egg.Part.Parent then
		return false
	end
	local EggPos = Egg.Part.Position
	local Radius = math.max(Egg.Size.X, Egg.Size.Z) / 2 + 3

	-- Dekati dari arah pemain sekarang (lebih natural), cadangan dari sisi +X
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

-- Label dropdown: "Luna Egg [Void] - Fairy Castle"
local function EggKey(Egg)
	return string.format("%s [%s] - %s", Egg.Name, Egg.Rarity, ZoneName(Egg.ZoneId))
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

local function ZoneLabel(ZoneId)
	return string.format("%d. %s", ZoneIndex(ZoneId), ZoneName(ZoneId))
end

local function ZoneTargetCFrame(ZoneId)
	local Build = GetBuild()
	if not Build then
		return nil
	end

	local Index = ZoneIndex(ZoneId)
	local Hitboxes = Build:FindFirstChild("ZoneHitboxes")
	local Hitbox = Hitboxes and Hitboxes:FindFirstChild(tostring(Index))

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
		-- tidak ada telur -> lanjut ke pintu masuk
	end

	if Hitbox and Hitbox:IsA("BasePart") then
		local Center = Hitbox.Position
		if Settings.ZoneTarget == "Tengah Zona" then
			return StandAt(Vector3.new(Center.X, 15, Center.Z))
		end
		-- Pintu masuk = sisi zona yang menghadap base (arah +X), menghadap ke dalam zona
		local Entrance = Vector3.new(Center.X + Hitbox.Size.X / 2 - 12, 15, Center.Z)
		return StandAt(Entrance, Vector3.new(Center.X, 0, Center.Z))
	end

	-- Cadangan: pivot model zona
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

---------------------------------------------------------------------
-- UI
---------------------------------------------------------------------
local Window = Library:CreateWindow({
	Title = "RapHub",
	Description = "Break and Steal an Egg",
	["Tab Width"] = 120,
	SizeUi = UDim2.fromOffset(560, 340),
})

local EggTab = Window:CreateTab({ Name = "Telur", Icon = "" })
local AreaTab = Window:CreateTab({ Name = "Area", Icon = "" })
local SettingTab = Window:CreateTab({ Name = "Settings", Icon = "" })

-- ===================== Tab Telur =====================
local EggSection = EggTab:AddSection("Teleport Telur", true)

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

-- Susun daftar telur (urut zona lalu nama) + perbarui info
local function RefreshEggList(Force)
	local Eggs = CollectEggs()
	local Count, Order = {}, {}

	for _, Egg in ipairs(Eggs) do
		local Key = EggKey(Egg)
		if not Count[Key] then
			Count[Key] = 0
			table.insert(Order, { Key = Key, Zone = ZoneIndex(Egg.ZoneId), Name = Egg.Name })
		end
		Count[Key] += 1
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

	return Eggs
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

EggSection:AddButton({
	Title = "Refresh Daftar Telur",
	Content = "Daftar juga diperbarui otomatis",
	Callback = function()
		RefreshEggList(true)
	end,
})

-- ===================== Auto Telur =====================
local AutoSection = EggTab:AddSection("Auto Teleport Telur", false)

local AutoEgg = false
AutoSection:AddToggle({
	Title = "Auto Teleport Telur",
	Content = "Pindah ke telur berikutnya saat telur pecah / hilang",
	Default = false,
	Callback = function(Value)
		AutoEgg = Value
		if not Value then
			StopMoving()
		end
	end,
})

AutoSection:AddDropdown({
	Title = "Prioritas",
	Content = "Telur mana yang didatangi dulu",
	Multi = false,
	Options = { "Terdekat", "Luck Tertinggi", "Terberat" },
	Default = { "Terdekat" },
	Callback = function(Value)
		Settings.AutoPriority = Value and Value[1] or "Terdekat"
	end,
})

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

local NameFilter = AutoSection:AddDropdown({
	Title = "Filter Nama Telur",
	Content = "Kosong = semua telur",
	Multi = true,
	Options = AllEggNames(),
	Default = {},
	Callback = function(Value)
		Settings.AutoNames = Value or {}
	end,
})

AutoSection:AddDropdown({
	Title = "Filter Rarity",
	Content = "Kosong = semua rarity",
	Multi = true,
	Options = table.clone(RARITY_ORDER),
	Default = {},
	Callback = function(Value)
		Settings.AutoRarities = Value or {}
	end,
})

AutoSection:AddButton({
	Title = "Refresh Filter Nama",
	Content = "Ambil ulang nama telur di map",
	Callback = function()
		NameFilter:Refresh(AllEggNames(), Settings.AutoNames)
	end,
})

AutoSection:AddSlider({
	Title = "Maks Waktu per Telur",
	Content = "Detik sebelum pindah telur",
	Increment = 1,
	Min = 2,
	Max = 60,
	Default = Settings.AutoStayTime,
	Callback = function(Value)
		Settings.AutoStayTime = Value
	end,
})

local function PassAutoFilter(Egg)
	if #Settings.AutoNames > 0 and not table.find(Settings.AutoNames, Egg.Name) then
		return false
	end
	if #Settings.AutoRarities > 0 and not table.find(Settings.AutoRarities, Egg.Rarity) then
		return false
	end
	return true
end

local function PickAutoEgg(Skip)
	local Best, BestScore = nil, nil
	for _, Egg in ipairs(CollectEggs()) do
		if PassAutoFilter(Egg) and not Skip[Egg.Model] then
			local Score
			if Settings.AutoPriority == "Luck Tertinggi" then
				Score = -Egg.Luck
			elseif Settings.AutoPriority == "Terberat" then
				Score = -Egg.Weight
			else
				Score = Distance(Egg)
			end
			if not BestScore or Score < BestScore then
				Best, BestScore = Egg, Score
			end
		end
	end
	return Best
end

-- ===================== Tab Area =====================
local ZoneSection = AreaTab:AddSection("Teleport Zona", true)

local ZoneByLabel = {}
local function ZoneOptions()
	ZoneByLabel = {}
	local List = {}
	for _, ZoneId in ipairs(GetZoneList()) do
		local Label = ZoneLabel(ZoneId)
		ZoneByLabel[Label] = ZoneId
		table.insert(List, Label)
	end
	return List
end

local SelectedZone = nil
ZoneSection:AddDropdown({
	Title = "Pilih Zona",
	Content = "Semua zona di map",
	Multi = false,
	Options = ZoneOptions(),
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

local PlaceSection = AreaTab:AddSection("Lokasi Lain", true)

PlaceSection:AddButton({
	Title = "Base Saya",
	Content = "Kembali ke plot milikmu",
	Callback = function()
		local Plot = MyPlot()
		local Spawn = Plot and (Plot:FindFirstChild("SpawnPoint") or Plot:FindFirstChild("Hitbox"))
		if Spawn and Spawn:IsA("BasePart") then
			TeleportTo(StandAt(Spawn.Position))
		else
			Notify("Area", "Base kamu tidak ditemukan.")
		end
	end,
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

TpSection:AddDropdown({
	Title = "Mode Teleport",
	Content = "Jalan (Aman) = lolos anti-cheat. Instant/Tween bisa ditarik balik",
	Multi = false,
	Options = { "Jalan (Aman)", "Instant", "Tween" },
	Default = { "Jalan (Aman)" },
	Callback = function(Value)
		Settings.TeleportMode = Value and Value[1] or "Jalan (Aman)"
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
	Callback = function()
		StopMoving()
	end,
})

TpSection:AddSlider({
	Title = "Kecepatan Tween",
	Content = "Stud per detik",
	Increment = 10,
	Min = 50,
	Max = 1000,
	Default = Settings.TweenSpeed,
	Callback = function(Value)
		Settings.TweenSpeed = Value
	end,
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

-- Perbarui daftar telur berkala (pilihan tetap dipertahankan)
task.spawn(function()
	while not Library.Unloaded do
		task.wait(4)
		pcall(RefreshEggList, false)
	end
end)

-- Auto: datangi telur, tunggu sampai pecah/hilang atau waktu habis, lalu lanjut
task.spawn(function()
	local Skip = setmetatable({}, { __mode = "k" })

	while not Library.Unloaded do
		if AutoEgg then
			local Egg = PickAutoEgg(Skip)
			if Egg then
				TeleportToEgg(Egg)

				local Started = os.clock()
				while
					AutoEgg
					and not Library.Unloaded
					and Egg.Model.Parent
					and Egg.Part.Parent
					and Egg.Part:GetAttribute("Broken") ~= true
					and os.clock() - Started < Settings.AutoStayTime
				do
					task.wait(0.25)
				end

				-- Waktu habis tapi telur masih ada: lewati sementara
				if Egg.Model.Parent and Egg.Part:GetAttribute("Broken") ~= true then
					Skip[Egg.Model] = true
				end
			else
				table.clear(Skip)
				task.wait(1)
			end
		else
			task.wait(0.5)
		end
	end
end)

Notify("Loaded", "Break and Steal an Egg siap dipakai!")
