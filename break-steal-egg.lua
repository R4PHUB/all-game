-- RapHub | break-steal-egg.lua | build 2026-11-25 12:22 WIB

local RAPHUB_BUILD = "2026-11-25 12:22 WIB"
local Library = (function()
--[[
	RapHub UI v2 — template panel untuk semua game RapHub

	Pemakaian singkat:
		local Window = Library:CreateWindow({
			Title = "RapHub",                       -- nama hub (warna aksen)
			SubTitle = "Nama Game",                 -- nama game di header
			Logo = "rbxassetid://123",              -- (opsional) logo
			LogoUrl = "https://.../logo.png",       -- (opsional) logo dari URL (getcustomasset)
			Discord = "discord.gg/raphub",          -- (opsional) teks di kanan header
			Size = UDim2.fromOffset(640, 430),
			ConfigFolder = "RapHub/Configs/NamaGame",
		})
		local Tab = Window:Tab({ Name = "Main", Icon = "home" })   -- Icon: nama di Library.Icons / rbxassetid
		local Section = Tab:Section({ Title = "Auto Farm", Open = true })
		Section:Toggle({ Title = "Auto Farm", Default = false, Flag = "AutoFarm", Callback = function(v) end })
		Section:Dropdown({ Title = "Zones", Options = {...}, Multi = true, Default = {}, Flag = "Zones", Callback = function(v) end })
		Section:Input({ Title = "Min $/s", Default = "0", Placeholder = "0", Flag = "MinCash", Callback = function(v) end })
		Section:Slider({ Title = "Delay", Min = 0, Max = 10, Default = 1, Increment = 0.1, Suffix = "s", Callback = function(v) end })
		Section:Button({ Title = "Teleport", Callback = function() end })
		Section:Paragraph({ Title = "Info", Content = "..." })   -- :Set({ Title, Content })
		Library:Notify({ Title = "RapHub", Content = "Halo", Duration = 3 })
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer

local Library = {
	Unloaded = false,
	LogoStatus = "belum",
	Flags = {},
	Setters = {},
	ConfigFolder = "RapHub/Configs",
	Theme = {
		Accent = Color3.fromRGB(155, 89, 255),
		Background = Color3.fromRGB(16, 12, 24),
		Sidebar = Color3.fromRGB(20, 15, 30),
		Section = Color3.fromRGB(30, 23, 44),
		Element = Color3.fromRGB(38, 30, 55),
		Stroke = Color3.fromRGB(70, 50, 110),
		Text = Color3.fromRGB(240, 236, 248),
		SubText = Color3.fromRGB(165, 155, 185),
		Muted = Color3.fromRGB(110, 100, 130),
	},
	-- Ikon Lucide (asset Roblox, sudah dicek valid)
	Icons = {
		home = "rbxassetid://10723407389",
		bot = "rbxassetid://10709782230",
		cart = "rbxassetid://10734952479",
		star = "rbxassetid://10734966248",
		send = "rbxassetid://10734943902",
		settings = "rbxassetid://10734950309",
		save = "rbxassetid://10734941499",
		search = "rbxassetid://10734943674",
		["map-pin"] = "rbxassetid://10734886004",
		egg = "rbxassetid://10723345518",
		sword = "rbxassetid://10734975486",
		target = "rbxassetid://10734977012",
		trophy = "rbxassetid://10747363809",
		user = "rbxassetid://10747373176",
		wrench = "rbxassetid://10747383470",
		layers = "rbxassetid://10723424505",
		list = "rbxassetid://10723433811",
		gift = "rbxassetid://10723396402",
		bell = "rbxassetid://10709775704",
		info = "rbxassetid://10723415903",
		play = "rbxassetid://10734923549",
		refresh = "rbxassetid://10734933222",
		repeatIcon = "rbxassetid://10734933966",
		shield = "rbxassetid://10734951847",
		sliders = "rbxassetid://10734963400",
		folder = "rbxassetid://10723387563",
		navigation = "rbxassetid://10734906744",
		check = "rbxassetid://10709790644",
		["chevron-down"] = "rbxassetid://10709790948",
		["chevron-right"] = "rbxassetid://10709791437",
		minus = "rbxassetid://10734896206",
		x = "rbxassetid://10747384394",
		message = "rbxassetid://10734888000",
	},
}

local Theme = Library.Theme

---------------------------------------------------------------------
-- Util
---------------------------------------------------------------------
local Env = (getgenv and getgenv()) or _G
if type(Env.RapHubCleanup) == "function" then
	pcall(Env.RapHubCleanup)
end

local CreatedGuis = {}
local Connections = {}

local function Create(Class, Props, Parent)
	local Inst = Instance.new(Class)
	for Key, Value in pairs(Props or {}) do
		Inst[Key] = Value
	end
	if Parent then
		Inst.Parent = Parent
	end
	return Inst
end

local function Corner(Parent, Radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, Radius or 6) }, Parent)
end

local function Stroke(Parent, Color, Transparency, Thickness)
	return Create("UIStroke", {
		Color = Color or Theme.Stroke,
		Transparency = Transparency or 0,
		Thickness = Thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, Parent)
end

local function Padding(Parent, Top, Right, Bottom, Left)
	return Create("UIPadding", {
		PaddingTop = UDim.new(0, Top or 0),
		PaddingRight = UDim.new(0, Right or 0),
		PaddingBottom = UDim.new(0, Bottom or 0),
		PaddingLeft = UDim.new(0, Left or 0),
	}, Parent)
end

local function Tween(Inst, Time, Props)
	local T = TweenService:Create(Inst, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
	T:Play()
	return T
end

local function Connect(Signal, Fn)
	local C = Signal:Connect(Fn)
	table.insert(Connections, C)
	return C
end

local function Icon(Name)
	if not Name or Name == "" then
		return ""
	end
	return Library.Icons[Name] or Name
end

local function GuiParent()
	if RunService:IsStudio() then
		return Player:WaitForChild("PlayerGui")
	end
	local ok, Hui = pcall(function()
		return gethui and gethui()
	end)
	if ok and Hui then
		return Hui
	end
	local ok2, Core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 and Core then
		return Core
	end
	return Player:WaitForChild("PlayerGui")
end

local function NewGui(Name, Order)
	local Gui = Create("ScreenGui", {
		Name = Name,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		DisplayOrder = Order or 100,
	})
	local ok = pcall(function()
		Gui.Parent = GuiParent()
	end)
	if not ok then
		Gui.Parent = Player:WaitForChild("PlayerGui")
	end
	table.insert(CreatedGuis, Gui)
	return Gui
end

local function MakeDraggable(Handle, Target)
	local Dragging, StartInput, StartPos = false, nil, nil
	Connect(Handle.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging, StartInput, StartPos = true, Input.Position, Target.Position
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)
	Connect(UserInputService.InputChanged, function(Input)
		if
			Dragging
			and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
		then
			local Delta = Input.Position - StartInput
			Target.Position =
				UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
		end
	end)
end

function Library:Destroy()
	self.Unloaded = true
	for _, C in ipairs(Connections) do
		pcall(function()
			C:Disconnect()
		end)
	end
	for _, Gui in ipairs(CreatedGuis) do
		pcall(function()
			Gui:Destroy()
		end)
	end
end

Env.RapHubCleanup = function()
	Library:Destroy()
end

---------------------------------------------------------------------
-- Notifikasi (kanan bawah, hilang otomatis)
---------------------------------------------------------------------
local NotifyHolder

function Library:Notify(Config)
	Config = Config or {}
	local Title = Config.Title or "RapHub"
	local Content = Config.Content or ""
	local Duration = tonumber(Config.Duration or Config.Delay) or 3

	if not NotifyHolder or not NotifyHolder.Parent then
		local Gui = NewGui("RapHubNotify", 1000)
		NotifyHolder = Create("Frame", {
			AnchorPoint = Vector2.new(1, 1),
			BackgroundTransparency = 1,
			Position = UDim2.new(1, -16, 1, -16),
			Size = UDim2.new(0, 290, 1, -32),
		}, Gui)
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 6),
		}, NotifyHolder)
	end

	local Slot = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = math.floor(os.clock() * 100),
	}, NotifyHolder)

	local Card = Create("Frame", {
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 40, 0, 0),
	}, Slot)
	Corner(Card, 8)
	Stroke(Card, Theme.Stroke)
	Padding(Card, 10, 12, 12, 14)
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, Card)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = Title,
		TextColor3 = Theme.Accent,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
	}, Card)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Font = Enum.Font.GothamMedium,
		Text = Content,
		TextColor3 = Theme.SubText,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 2,
	}, Card)

	local Bar = Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
	}, Card)

	local Closed = false
	local function Close()
		if Closed then
			return
		end
		Closed = true
		Tween(Card, 0.25, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 }).Completed:Wait()
		Slot:Destroy()
	end

	Tween(Card, 0.3, { Position = UDim2.new(0, 0, 0, 0) })
	Tween(Bar, Duration, { Size = UDim2.new(0, 0, 0, 2) })
	task.delay(Duration, Close)
	return { Close = Close }
end

-- Nama lama (kompatibel dengan script sebelumnya)
function Library:SetNotification(Config)
	return self:Notify({
		Title = (Config.Title or "RapHub") .. (Config.Description and (" • " .. Config.Description) or ""),
		Content = Config.Content,
		Duration = Config.Delay or Config.Time,
	})
end

---------------------------------------------------------------------
-- Config (simpan / muat nilai semua kontrol yang punya Flag)
---------------------------------------------------------------------
local function EnsureFolder(Path)
	if not makefolder then
		return
	end
	local Built = ""
	for Part in Path:gmatch("[^/]+") do
		Built = Built == "" and Part or (Built .. "/" .. Part)
		pcall(function()
			if not (isfolder and isfolder(Built)) then
				makefolder(Built)
			end
		end)
	end
end

function Library:SaveConfig(Name)
	if not writefile or not Name or Name == "" then
		return false
	end
	EnsureFolder(self.ConfigFolder)
	local ok = pcall(function()
		writefile(self.ConfigFolder .. "/" .. Name .. ".json", HttpService:JSONEncode(self.Flags))
	end)
	return ok
end

function Library:LoadConfig(Name)
	if not readfile or not Name or Name == "" then
		return false
	end
	local Path = self.ConfigFolder .. "/" .. Name .. ".json"
	if isfile and not isfile(Path) then
		return false
	end
	local ok, Data = pcall(function()
		return HttpService:JSONDecode(readfile(Path))
	end)
	if not ok or type(Data) ~= "table" then
		return false
	end
	for Flag, Value in pairs(Data) do
		local Setter = self.Setters[Flag]
		if Setter then
			pcall(Setter, Value)
		end
	end
	return true
end

function Library:DeleteConfig(Name)
	local Path = self.ConfigFolder .. "/" .. tostring(Name) .. ".json"
	return delfile ~= nil and pcall(delfile, Path)
end

function Library:ListConfigs()
	local List = {}
	if not listfiles then
		return List
	end
	EnsureFolder(self.ConfigFolder)
	local ok, Files = pcall(listfiles, self.ConfigFolder)
	if ok and type(Files) == "table" then
		for _, File in ipairs(Files) do
			local Name = tostring(File):gsub("\\", "/"):match("([^/]+)%.json$")
			if Name then
				table.insert(List, Name)
			end
		end
	end
	table.sort(List)
	return List
end

local function RegisterFlag(Flag, Value, Setter)
	if Flag then
		Library.Flags[Flag] = Value
		Library.Setters[Flag] = Setter
	end
end

---------------------------------------------------------------------
-- Window
---------------------------------------------------------------------
function Library:CreateWindow(Config)
	Config = Config or {}
	self.ConfigFolder = Config.ConfigFolder or self.ConfigFolder
	if Config.Accent then
		Theme.Accent = Config.Accent
	end

	local Size = Config.Size or UDim2.fromOffset(640, 430)
	local MinSize = Vector2.new(520, 320)
	local Gui = NewGui("RapHub", 100)

	local Main = Create("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = Size,
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.06,
		ClipsDescendants = true,
	}, Gui)
	Corner(Main, 10)
	Stroke(Main, Theme.Stroke, 0.2)

	-- ===== Header =====
	local Header = Create("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 42),
	}, Main)
	Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
	}, Header)

	local Left = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 14, 0, 0),
		Size = UDim2.new(0.6, 0, 1, 0),
	}, Header)
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 9),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Left)

	-- Logo (bulat) + cadangan huruf kalau gambar belum bisa dimuat
	local Logo = Create("ImageLabel", {
		BackgroundColor3 = Theme.Element,
		Size = UDim2.fromOffset(24, 24),
		Image = Config.Logo or "",
		ScaleType = Enum.ScaleType.Crop,
		LayoutOrder = 1,
	}, Left)
	Corner(Logo, 12)
	local LogoLetter = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = string.sub(Config.Title or "R", 1, 1),
		TextColor3 = Theme.Accent,
		TextSize = 14,
	}, Logo)

	Create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBlack,
		Text = Config.Title or "RapHub",
		TextColor3 = Theme.Accent,
		TextSize = 16,
		LayoutOrder = 2,
	}, Left)
	Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.85,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(1, 18),
		LayoutOrder = 3,
	}, Left)
	Create("TextLabel", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = Config.SubTitle or "",
		TextColor3 = Theme.Text,
		TextSize = 12,
		LayoutOrder = 4,
	}, Left)

	local Right = Create("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		Size = UDim2.new(0.4, 0, 1, 0),
	}, Header)
	Create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, Right)

	if Config.Discord then
		Create("ImageLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(14, 14),
			Image = Icon("message"),
			ImageColor3 = Theme.Accent,
			LayoutOrder = 1,
		}, Right)
		Create("TextLabel", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.new(0, 0, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = Config.Discord,
			TextColor3 = Theme.Accent,
			TextSize = 12,
			LayoutOrder = 2,
		}, Right)
		Create("Frame", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.85,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(1, 16),
			LayoutOrder = 3,
		}, Right)
	end

	local function HeaderButton(IconName, Order)
		local Button = Create("ImageButton", {
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(22, 22),
			Image = Icon(IconName),
			ImageColor3 = Theme.SubText,
			LayoutOrder = Order,
		}, Right)
		Connect(Button.MouseEnter, function()
			Tween(Button, 0.15, { ImageColor3 = Theme.Accent })
		end)
		Connect(Button.MouseLeave, function()
			Tween(Button, 0.15, { ImageColor3 = Theme.SubText })
		end)
		return Button
	end
	local MinButton = HeaderButton("minus", 4)
	local CloseButton = HeaderButton("x", 5)

	MakeDraggable(Header, Main)

	-- ===== Sidebar =====
	local SidebarWidth = Config.SidebarWidth or 150
	local Sidebar = Create("Frame", {
		Name = "Sidebar",
		BackgroundColor3 = Theme.Sidebar,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 42),
		Size = UDim2.new(0, SidebarWidth, 1, -42),
	}, Main)
	Create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 0.93,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
	}, Sidebar)

	-- Kotak pencarian fitur
	local SearchBox = Create("Frame", {
		BackgroundColor3 = Theme.Element,
		BackgroundTransparency = 0.3,
		Position = UDim2.new(0, 8, 0, 8),
		Size = UDim2.new(1, -16, 0, 28),
	}, Sidebar)
	Corner(SearchBox, 6)
	Stroke(SearchBox, Theme.Stroke, 0.4)
	Create("ImageLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 8, 0.5, -7),
		Size = UDim2.fromOffset(14, 14),
		Image = Icon("search"),
		ImageColor3 = Theme.SubText,
	}, SearchBox)
	local SearchInput = Create("TextBox", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 28, 0, 0),
		Size = UDim2.new(1, -32, 1, 0),
		Font = Enum.Font.GothamMedium,
		PlaceholderText = "Search feature...",
		PlaceholderColor3 = Theme.Muted,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
	}, SearchBox)

	local TabList = Create("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 44),
		Size = UDim2.new(1, 0, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 0,
	}, Sidebar)
	Padding(TabList, 2, 8, 8, 8)
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, TabList)

	-- ===== Konten =====
	local Content = Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, SidebarWidth, 0, 42),
		Size = UDim2.new(1, -SidebarWidth, 1, -42),
	}, Main)

	local PageHeader = Create("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 38),
	}, Content)
	Create("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 14, 0.5, -9),
		Size = UDim2.fromOffset(3, 18),
	}, PageHeader)
	local PageTitle = Create("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.GothamBlack,
		Text = "",
		TextColor3 = Theme.Text,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, PageHeader)

	local Pages = Create("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 0, 0, 38),
		Size = UDim2.new(1, 0, 1, -38),
	}, Content)

	-- ===== Resize (pojok kanan bawah) =====
	local Grip = Create("TextButton", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -2, 1, -2),
		Size = UDim2.fromOffset(16, 16),
		Text = "",
		ZIndex = 20,
	}, Main)
	for _, Dot in ipairs({ { 12, 4 }, { 8, 8 }, { 12, 8 }, { 4, 12 }, { 8, 12 }, { 12, 12 } }) do
		Create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(Dot[1] - 1, Dot[2] - 1),
			Size = UDim2.fromOffset(2, 2),
			ZIndex = 20,
		}, Grip)
	end
	do
		local Resizing, StartInput, StartSize, StartPos = false, nil, nil, nil
		Connect(Grip.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Resizing, StartInput = true, Input.Position
				StartSize = Main.AbsoluteSize
				StartPos = Main.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Resizing = false
					end
				end)
			end
		end)
		Connect(UserInputService.InputChanged, function(Input)
			if
				Resizing
				and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			then
				local Delta = Input.Position - StartInput
				local W = math.max(MinSize.X, StartSize.X + Delta.X)
				local H = math.max(MinSize.Y, StartSize.Y + Delta.Y)
				Main.Size = UDim2.fromOffset(W, H)
				-- Main berjangkar di tengah: geser setengah perubahan supaya pojok kiri atas diam
				Main.Position = UDim2.new(
					StartPos.X.Scale,
					StartPos.X.Offset + (W - StartSize.X) / 2,
					StartPos.Y.Scale,
					StartPos.Y.Offset + (H - StartSize.Y) / 2
				)
			end
		end)
	end

	-- ===== Tombol buka (muncul saat minimize) =====
	local ToggleGui = NewGui("RapHubToggle", 999)
	local OpenButton = Create("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0, 60, 0, 80),
		Size = UDim2.fromOffset(Config.ToggleSize or 40, Config.ToggleSize or 40),
		Image = Config.Logo or "",
		ScaleType = Enum.ScaleType.Crop,
		AutoButtonColor = false,
		Visible = false,
	}, ToggleGui)
	Corner(OpenButton, 100)
	local OpenStroke = Stroke(OpenButton, Theme.Accent, 0.2, 1.5)
	local OpenLetter = Create("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = Enum.Font.GothamBlack,
		Text = string.sub(Config.Title or "R", 1, 1),
		TextColor3 = Theme.Accent,
		TextSize = 18,
	}, OpenButton)

	local OpenMoved = false
	do
		local Dragging, StartInput, StartPos = false, nil, nil
		Connect(OpenButton.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging, OpenMoved, StartInput, StartPos = true, false, Input.Position, OpenButton.Position
				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		Connect(UserInputService.InputChanged, function(Input)
			if
				Dragging
				and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
			then
				local Delta = Input.Position - StartInput
				if Delta.Magnitude > 6 then
					OpenMoved = true
				end
				OpenButton.Position =
					UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
			end
		end)
	end

	-- Logo: rbxassetid atau URL (getcustomasset). Huruf cadangan disembunyikan saat gambar termuat.
	local function ApplyLogo(Image)
		if not Image or Image == "" then
			return
		end
		Logo.Image = Image
		OpenButton.Image = Image
		local function Update()
			LogoLetter.Visible = not Logo.IsLoaded
			OpenLetter.Visible = not OpenButton.IsLoaded
			-- Logo sudah berbentuk bulat sendiri: latar & garis tebal tidak diperlukan
			Logo.BackgroundTransparency = Logo.IsLoaded and 1 or 0
			OpenButton.BackgroundTransparency = OpenButton.IsLoaded and 1 or 0
			OpenStroke.Transparency = OpenButton.IsLoaded and 0.6 or 0.2
		end
		Connect(Logo:GetPropertyChangedSignal("IsLoaded"), Update)
		Connect(OpenButton:GetPropertyChangedSignal("IsLoaded"), Update)
		task.spawn(function()
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ Logo, OpenButton })
			end)
			Update()
		end)
		task.delay(2, Update)
		Update()
	end
	ApplyLogo(Config.Logo)

	--[[
		Cadangan logo yang andal: gambar logo diunduh lalu ditampilkan lewat getcustomasset.
		Tidak bergantung izin aset Roblox di game orang lain. Sumber gambar:
		Config.LogoUrl, atau otomatis dari API thumbnail Roblox untuk asset ID di Config.Logo.
		File disimpan di RapHub/logo_<id>.png (cache, cukup diunduh sekali).
	]]
	local function HttpGet(Url)
		local ok, Body = pcall(function()
			return game:HttpGet(Url)
		end)
		if ok and type(Body) == "string" then
			return Body
		end
		if request then
			local ok2, Response = pcall(request, { Url = Url, Method = "GET" })
			if ok2 and type(Response) == "table" and type(Response.Body) == "string" then
				return Response.Body
			end
		end
		return nil
	end

	local function LoadCustomLogo()
		if not (getcustomasset and writefile) then
			Library.LogoStatus = "executor tidak punya getcustomasset/writefile"
			return false
		end
		local AssetId = tostring(Config.Logo or ""):match("%d+")
		local Path = "RapHub/logo_" .. (AssetId or "custom") .. ".png"

		local Cached = false
		pcall(function()
			Cached = isfile and isfile(Path) or false
		end)

		if not Cached then
			local Url = Config.LogoUrl
			if not Url and AssetId then
				local Json = HttpGet(
					"https://thumbnails.roblox.com/v1/assets?assetIds="
						.. AssetId
						.. "&size=420x420&format=Png&isCircular=false"
				)
				local ok, Data = pcall(function()
					return HttpService:JSONDecode(Json)
				end)
				local Entry = ok and type(Data) == "table" and Data.data and Data.data[1]
				-- Gambar private/ditolak hanya memberi placeholder: jangan dipakai
				if Entry and Entry.state == "Completed" and tostring(Entry.imageUrl):find("/Image/") then
					Url = Entry.imageUrl
				end
			end
			if not Url then
				Library.LogoStatus = "thumbnail logo tidak tersedia (masih private/ditolak?)"
				return false
			end
			local Png = HttpGet(Url)
			if not Png or #Png < 200 or Png:sub(2, 4) ~= "PNG" then
				Library.LogoStatus = "gagal unduh gambar logo"
				return false
			end
			EnsureFolder("RapHub")
			if not pcall(writefile, Path, Png) then
				Library.LogoStatus = "gagal menyimpan file logo"
				return false
			end
		end

		local ok, Asset = pcall(getcustomasset, Path)
		if ok and Asset then
			ApplyLogo(Asset)
			Library.LogoStatus = "OK (file " .. Path .. ")"
			return true
		end
		Library.LogoStatus = "getcustomasset gagal: " .. tostring(Asset)
		return false
	end

	task.spawn(function()
		-- Beri kesempatan rbxassetid termuat dulu; kalau gagal pakai logo unduhan
		task.wait(Config.LogoUrl and 0 or 1.5)
		if Logo.IsLoaded then
			Library.LogoStatus = "OK (rbxassetid)"
		else
			LoadCustomLogo()
		end
	end)

	local function SetMinimized(State)
		Main.Visible = not State
		OpenButton.Visible = State
	end
	Connect(MinButton.MouseButton1Click, function()
		SetMinimized(true)
	end)
	Connect(OpenButton.MouseButton1Click, function()
		if not OpenMoved then
			SetMinimized(false)
		end
	end)
	Connect(CloseButton.MouseButton1Click, function()
		Library:Destroy()
	end)
	Connect(UserInputService.InputBegan, function(Input, Processed)
		if not Processed and Input.KeyCode == (Config.Keybind or Enum.KeyCode.RightControl) then
			SetMinimized(Main.Visible)
		end
	end)

	---------------------------------------------------------------------
	-- Tab
	---------------------------------------------------------------------
	local Window = { Tabs = {}, Current = nil }
	local TabCount = 0

	local function ApplySearch()
		local Query = SearchInput.Text:lower()
		local Tab = Window.Current
		if not Tab then
			return
		end
		for _, Section in ipairs(Tab.Sections) do
			local Any = false
			for _, Row in ipairs(Section.Rows) do
				local Match = Query == "" or Row.Title:lower():find(Query, 1, true) ~= nil
				Row.Frame.Visible = Match
				Any = Any or Match
			end
			Section.Frame.Visible = Query == "" or Any or Section.Title:lower():find(Query, 1, true) ~= nil
			Section.Body.Visible = (Query ~= "" and Any) or (Query == "" and Section.Open)
			Section.Arrow.Rotation = Section.Body.Visible and 180 or 0
		end
	end
	Connect(SearchInput:GetPropertyChangedSignal("Text"), ApplySearch)

	function Window:SelectTab(Tab)
		for _, Other in ipairs(self.Tabs) do
			local Active = Other == Tab
			Other.Page.Visible = Active
			Tween(Other.Button, 0.15, { BackgroundTransparency = Active and 0.9 or 1 })
			Tween(Other.Label, 0.15, { TextColor3 = Active and Theme.Text or Theme.SubText })
			Tween(Other.IconImage, 0.15, { ImageColor3 = Active and Theme.Accent or Theme.SubText })
			Other.Bar.Visible = Active
		end
		self.Current = Tab
		PageTitle.Text = Tab.Name
		ApplySearch()
	end

	function Window:Tab(TabConfig)
		TabConfig = TabConfig or {}
		TabCount += 1
		local Tab = { Name = TabConfig.Name or ("Tab " .. TabCount), Sections = {} }

		local Button = Create("TextButton", {
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 32),
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = TabCount,
		}, TabList)
		Corner(Button, 6)
		local Bar = Create("Frame", {
			BackgroundColor3 = Theme.Accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0.5, -8),
			Size = UDim2.fromOffset(3, 16),
			Visible = false,
		}, Button)
		Corner(Bar, 2)
		local IconImage = Create("ImageLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0.5, -8),
			Size = UDim2.fromOffset(16, 16),
			Image = Icon(TabConfig.Icon),
			ImageColor3 = Theme.SubText,
		}, Button)
		local Label = Create("TextLabel", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 36, 0, 0),
			Size = UDim2.new(1, -40, 1, 0),
			Font = Enum.Font.GothamBold,
			Text = Tab.Name,
			TextColor3 = Theme.SubText,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, Button)

		local Page = Create("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Accent,
			Visible = false,
		}, Pages)
		Padding(Page, 2, 14, 14, 14)
		Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, Page)

		Tab.Button, Tab.Bar, Tab.IconImage, Tab.Label, Tab.Page = Button, Bar, IconImage, Label, Page

		Connect(Button.MouseEnter, function()
			if Window.Current ~= Tab then
				Tween(Button, 0.15, { BackgroundTransparency = 0.95 })
			end
		end)
		Connect(Button.MouseLeave, function()
			if Window.Current ~= Tab then
				Tween(Button, 0.15, { BackgroundTransparency = 1 })
			end
		end)
		Connect(Button.MouseButton1Click, function()
			Window:SelectTab(Tab)
		end)

		table.insert(Window.Tabs, Tab)
		if not Window.Current then
			Window:SelectTab(Tab)
		end

		---------------------------------------------------------------------
		-- Section
		---------------------------------------------------------------------
		local SectionCount = 0
		function Tab:Section(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionCount += 1
			local Section = {
				Title = SectionConfig.Title or "Section",
				Open = SectionConfig.Open == true,
				Rows = {},
			}

			local Frame = Create("Frame", {
				BackgroundColor3 = Theme.Section,
				BackgroundTransparency = 0.25,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				LayoutOrder = SectionCount,
			}, Page)
			Corner(Frame, 7)
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, Frame)

			local HeaderButton2 = Create("TextButton", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 34),
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = 0,
			}, Frame)
			Create("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 12, 0, 0),
				Size = UDim2.new(1, -44, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = Section.Title,
				TextColor3 = Theme.Text,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, HeaderButton2)
			local Arrow = Create("ImageLabel", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -12, 0.5, 0),
				Size = UDim2.fromOffset(14, 14),
				Image = Icon("chevron-down"),
				ImageColor3 = Theme.Accent,
				Rotation = Section.Open and 180 or 0,
			}, HeaderButton2)

			local Body = Create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = Section.Open,
				LayoutOrder = 1,
			}, Frame)
			Padding(Body, 0, 10, 10, 10)
			Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, Body)

			Section.Frame, Section.Body, Section.Arrow = Frame, Body, Arrow
			table.insert(Tab.Sections, Section)

			Connect(HeaderButton2.MouseButton1Click, function()
				Section.Open = not Body.Visible
				Body.Visible = Section.Open
				Tween(Arrow, 0.2, { Rotation = Section.Open and 180 or 0 })
			end)

			local Order = 0
			local function NextOrder()
				Order += 2
				return Order
			end

			-- Baris standar: label kiri, kontrol kanan
			local function Row(Title, Height)
				local RowFrame = Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, Height or 32),
					LayoutOrder = NextOrder(),
				}, Body)
				Corner(RowFrame, 5)
				local TitleLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 4, 0, 0),
					Size = UDim2.new(0.55, -4, 1, 0),
					Font = Enum.Font.GothamBold,
					Text = Title,
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, RowFrame)
				table.insert(Section.Rows, { Frame = RowFrame, Title = Title })
				return RowFrame, TitleLabel
			end

			-- Kotak kontrol di kanan (dropdown / input)
			local function ControlBox(Parent, WidthScale)
				local Box = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					BackgroundTransparency = 0.2,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Size = UDim2.new(WidthScale or 0.45, 0, 0, 26),
				}, Parent)
				Corner(Box, 5)
				Stroke(Box, Theme.Stroke, 0.5)
				return Box
			end

			---------------- Toggle ----------------
			function Section:Toggle(Opt)
				Opt = Opt or {}
				local Obj = { Value = Opt.Default == true }
				local RowFrame = Row(Opt.Title or "Toggle")
				local Switch = Create("TextButton", {
					BackgroundColor3 = Theme.Element,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Size = UDim2.fromOffset(38, 20),
					Text = "",
					AutoButtonColor = false,
				}, RowFrame)
				Corner(Switch, 10)
				local Knob = Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 3, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
				}, Switch)
				Corner(Knob, 7)

				local function Render()
					Tween(Switch, 0.18, { BackgroundColor3 = Obj.Value and Theme.Accent or Theme.Element })
					Tween(Knob, 0.18, { Position = Obj.Value and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) })
				end

				function Obj:Set(Value)
					Obj.Value = Value == true
					if Opt.Flag then
						Library.Flags[Opt.Flag] = Obj.Value
					end
					Render()
					if Opt.Callback then
						task.spawn(Opt.Callback, Obj.Value)
					end
				end

				local function Flip()
					Obj:Set(not Obj.Value)
				end
				Connect(Switch.MouseButton1Click, Flip)
				local Click = Create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -46, 1, 0),
					Text = "",
				}, RowFrame)
				Connect(Click.MouseButton1Click, Flip)

				RegisterFlag(Opt.Flag, Obj.Value, function(V)
					Obj:Set(V)
				end)
				Obj:Set(Obj.Value)
				return Obj
			end

			---------------- Dropdown ----------------
			function Section:Dropdown(Opt)
				Opt = Opt or {}
				local Multi = Opt.Multi == true
				local Obj = { Options = Opt.Options or {}, Value = nil }
				if Multi then
					Obj.Value = type(Opt.Default) == "table" and table.clone(Opt.Default) or {}
				else
					Obj.Value = type(Opt.Default) == "table" and Opt.Default[1] or Opt.Default
				end

				local RowFrame = Row(Opt.Title or "Dropdown")
				local Box = ControlBox(RowFrame, 0.45)
				local Button = Create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "",
				}, Box)
				local ValueLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 9, 0, 0),
					Size = UDim2.new(1, -30, 1, 0),
					Font = Enum.Font.GothamMedium,
					Text = "",
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextTruncate = Enum.TextTruncate.AtEnd,
					TextXAlignment = Enum.TextXAlignment.Left,
				}, Box)
				local Caret = Create("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -8, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
					Image = Icon("chevron-down"),
					ImageColor3 = Theme.Accent,
				}, Box)

				-- Daftar pilihan (terbuka di bawah baris)
				local List = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					BackgroundTransparency = 0.15,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Visible = false,
					LayoutOrder = RowFrame.LayoutOrder + 1,
				}, Body)
				Corner(List, 6)
				Stroke(List, Theme.Stroke, 0.5)
				Padding(List, 6, 6, 6, 6)
				Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, List)

				local Filter = Create("TextBox", {
					BackgroundColor3 = Theme.Background,
					BackgroundTransparency = 0.3,
					Size = UDim2.new(1, 0, 0, 24),
					Font = Enum.Font.GothamMedium,
					PlaceholderText = "Search...",
					PlaceholderColor3 = Theme.Muted,
					Text = "",
					TextColor3 = Theme.Text,
					TextSize = 12,
					ClearTextOnFocus = false,
					LayoutOrder = 1,
				}, List)
				Corner(Filter, 4)
				Padding(Filter, 0, 6, 0, 8)
				Filter.TextXAlignment = Enum.TextXAlignment.Left

				local Scroll = Create("ScrollingFrame", {
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 150),
					CanvasSize = UDim2.new(),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					ScrollBarThickness = 3,
					ScrollBarImageColor3 = Theme.Accent,
					LayoutOrder = 2,
				}, List)
				Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Scroll)

				local OptionButtons = {}

				local function IsSelected(Option)
					if Multi then
						return table.find(Obj.Value, Option) ~= nil
					end
					return Obj.Value == Option
				end

				local function UpdateLabel()
					if Multi then
						local Count = #Obj.Value
						if Count == 0 then
							ValueLabel.Text = Opt.Placeholder or "Select Options"
							ValueLabel.TextColor3 = Theme.SubText
						elseif Count <= 2 then
							ValueLabel.Text = table.concat(Obj.Value, ", ")
							ValueLabel.TextColor3 = Theme.Text
						else
							ValueLabel.Text = Obj.Value[1] .. ", " .. Obj.Value[2] .. " (+" .. (Count - 2) .. ")"
							ValueLabel.TextColor3 = Theme.Text
						end
					else
						ValueLabel.Text = Obj.Value and tostring(Obj.Value) or (Opt.Placeholder or "Select Option")
						ValueLabel.TextColor3 = Obj.Value and Theme.Text or Theme.SubText
					end
					for Option, Item in pairs(OptionButtons) do
						local Selected = IsSelected(Option)
						Item.Label.TextColor3 = Selected and Theme.Accent or Theme.Text
						Item.Check.Visible = Selected
					end
				end

				local function Fire()
					if Opt.Flag then
						Library.Flags[Opt.Flag] = Multi and table.clone(Obj.Value) or Obj.Value
					end
					if Opt.Callback then
						task.spawn(Opt.Callback, Multi and table.clone(Obj.Value) or Obj.Value)
					end
				end

				local function Open(State)
					List.Visible = State
					Tween(Caret, 0.15, { Rotation = State and 180 or 0 })
				end

				local function Build()
					for _, Item in pairs(OptionButtons) do
						Item.Button:Destroy()
					end
					table.clear(OptionButtons)
					for Index, Option in ipairs(Obj.Options) do
						local OptionButton = Create("TextButton", {
							BackgroundColor3 = Color3.new(1, 1, 1),
							BackgroundTransparency = 1,
							Size = UDim2.new(1, -4, 0, 24),
							Text = "",
							AutoButtonColor = false,
							LayoutOrder = Index,
						}, Scroll)
						Corner(OptionButton, 4)
						local OptionLabel = Create("TextLabel", {
							BackgroundTransparency = 1,
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, -30, 1, 0),
							Font = Enum.Font.GothamMedium,
							Text = tostring(Option),
							TextColor3 = Theme.Text,
							TextSize = 12,
							TextTruncate = Enum.TextTruncate.AtEnd,
							TextXAlignment = Enum.TextXAlignment.Left,
						}, OptionButton)
						local Check = Create("ImageLabel", {
							BackgroundTransparency = 1,
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.new(1, -6, 0.5, 0),
							Size = UDim2.fromOffset(12, 12),
							Image = Icon("check"),
							ImageColor3 = Theme.Accent,
							Visible = false,
						}, OptionButton)
						OptionButtons[Option] = { Button = OptionButton, Label = OptionLabel, Check = Check }

						Connect(OptionButton.MouseEnter, function()
							Tween(OptionButton, 0.1, { BackgroundTransparency = 0.93 })
						end)
						Connect(OptionButton.MouseLeave, function()
							Tween(OptionButton, 0.1, { BackgroundTransparency = 1 })
						end)
						Connect(OptionButton.MouseButton1Click, function()
							if Multi then
								local Found = table.find(Obj.Value, Option)
								if Found then
									table.remove(Obj.Value, Found)
								else
									table.insert(Obj.Value, Option)
								end
							else
								Obj.Value = Option
								Open(false)
							end
							UpdateLabel()
							Fire()
						end)
					end
					Filter.Text = ""
					UpdateLabel()
				end

				Connect(Filter:GetPropertyChangedSignal("Text"), function()
					local Query = Filter.Text:lower()
					for Option, Item in pairs(OptionButtons) do
						Item.Button.Visible = Query == "" or tostring(Option):lower():find(Query, 1, true) ~= nil
					end
				end)
				Connect(Button.MouseButton1Click, function()
					Open(not List.Visible)
				end)

				function Obj:Set(Value)
					if Multi then
						Obj.Value = type(Value) == "table" and table.clone(Value) or {}
					else
						Obj.Value = type(Value) == "table" and Value[1] or Value
					end
					UpdateLabel()
					Fire()
				end

				-- Ganti daftar pilihan; pilihan yang masih ada dipertahankan
				function Obj:Refresh(Options, Keep)
					Obj.Options = Options or {}
					local Wanted = Keep
					if Wanted == nil then
						Wanted = Obj.Value
					end
					if Multi then
						local Kept = {}
						for _, Option in ipairs(type(Wanted) == "table" and Wanted or {}) do
							if table.find(Obj.Options, Option) then
								table.insert(Kept, Option)
							end
						end
						Obj.Value = Kept
					else
						local Single = type(Wanted) == "table" and Wanted[1] or Wanted
						Obj.Value = (Single and table.find(Obj.Options, Single)) and Single or nil
					end
					Build()
					Fire()
				end

				RegisterFlag(Opt.Flag, Obj.Value, function(V)
					Obj:Set(V)
				end)
				Build()
				Fire()
				return Obj
			end

			---------------- Input ----------------
			function Section:Input(Opt)
				Opt = Opt or {}
				local Obj = { Value = tostring(Opt.Default or "") }
				local RowFrame = Row(Opt.Title or "Input")
				local Box = ControlBox(RowFrame, 0.45)
				local TextBox = Create("TextBox", {
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 9, 0, 0),
					Size = UDim2.new(1, -18, 1, 0),
					Font = Enum.Font.GothamMedium,
					PlaceholderText = Opt.Placeholder or "",
					PlaceholderColor3 = Theme.Muted,
					Text = Obj.Value,
					TextColor3 = Theme.Text,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					ClearTextOnFocus = false,
				}, Box)

				function Obj:Set(Value)
					Obj.Value = tostring(Value or "")
					TextBox.Text = Obj.Value
					if Opt.Flag then
						Library.Flags[Opt.Flag] = Obj.Value
					end
					if Opt.Callback then
						task.spawn(Opt.Callback, Obj.Value)
					end
				end
				Connect(TextBox.FocusLost, function()
					Obj:Set(TextBox.Text)
				end)

				RegisterFlag(Opt.Flag, Obj.Value, function(V)
					Obj:Set(V)
				end)
				Obj:Set(Obj.Value)
				return Obj
			end

			---------------- Slider ----------------
			function Section:Slider(Opt)
				Opt = Opt or {}
				local Min, Max = Opt.Min or 0, Opt.Max or 100
				local Increment = Opt.Increment or 1
				local Obj = { Value = Opt.Default or Min }
				local RowFrame = Row(Opt.Title or "Slider")

				local Track = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Size = UDim2.new(0.3, 0, 0, 6),
				}, RowFrame)
				Corner(Track, 3)
				local Fill = Create("Frame", {
					BackgroundColor3 = Theme.Accent,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 0, 1, 0),
				}, Track)
				Corner(Fill, 3)
				local Knob = Create("Frame", {
					BackgroundColor3 = Color3.new(1, 1, 1),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.fromOffset(12, 12),
				}, Track)
				Corner(Knob, 6)
				local ValueLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(0.7, -12, 0.5, 0),
					Size = UDim2.fromOffset(70, 20),
					Font = Enum.Font.GothamBold,
					Text = "",
					TextColor3 = Theme.Accent,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Right,
				}, RowFrame)

				local function Round(Value)
					Value = math.clamp(Value, Min, Max)
					Value = math.floor(Value / Increment + 0.5) * Increment
					return tonumber(string.format("%.4g", Value))
				end

				function Obj:Set(Value)
					Obj.Value = Round(tonumber(Value) or Min)
					local Alpha = (Max > Min) and (Obj.Value - Min) / (Max - Min) or 0
					Fill.Size = UDim2.new(Alpha, 0, 1, 0)
					Knob.Position = UDim2.new(Alpha, 0, 0.5, 0)
					ValueLabel.Text = tostring(Obj.Value) .. (Opt.Suffix or "")
					if Opt.Flag then
						Library.Flags[Opt.Flag] = Obj.Value
					end
					if Opt.Callback then
						task.spawn(Opt.Callback, Obj.Value)
					end
				end

				local Dragging = false
				local function FromInput(Input)
					local Alpha = math.clamp((Input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
					Obj:Set(Min + (Max - Min) * Alpha)
				end
				Connect(Track.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = true
						FromInput(Input)
					end
				end)
				Connect(UserInputService.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
						Dragging = false
					end
				end)
				Connect(UserInputService.InputChanged, function(Input)
					if
						Dragging
						and (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch)
					then
						FromInput(Input)
					end
				end)

				RegisterFlag(Opt.Flag, Obj.Value, function(V)
					Obj:Set(V)
				end)
				Obj:Set(Obj.Value)
				return Obj
			end

			---------------- Button ----------------
			function Section:Button(Opt)
				Opt = Opt or {}
				local RowFrame = Row(Opt.Title or "Button")
				local Click = Create("TextButton", {
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					Text = "",
				}, RowFrame)
				Create("ImageLabel", {
					BackgroundTransparency = 1,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -6, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					Image = Icon(Opt.Icon or "play"),
					ImageColor3 = Theme.Accent,
				}, RowFrame)
				Connect(Click.MouseEnter, function()
					Tween(RowFrame, 0.1, { BackgroundTransparency = 0.94 })
				end)
				Connect(Click.MouseLeave, function()
					Tween(RowFrame, 0.1, { BackgroundTransparency = 1 })
				end)
				Connect(Click.MouseButton1Click, function()
					Tween(RowFrame, 0.05, { BackgroundTransparency = 0.85 })
					task.delay(0.1, function()
						Tween(RowFrame, 0.15, { BackgroundTransparency = 1 })
					end)
					if Opt.Callback then
						task.spawn(Opt.Callback)
					end
				end)
				return {}
			end

			---------------- Paragraph ----------------
			function Section:Paragraph(Opt)
				Opt = Opt or {}
				local Holder = Create("Frame", {
					BackgroundColor3 = Theme.Element,
					BackgroundTransparency = 0.5,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					LayoutOrder = NextOrder(),
				}, Body)
				Corner(Holder, 5)
				Padding(Holder, 7, 9, 8, 9)
				Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, Holder)
				local TitleLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 15),
					Font = Enum.Font.GothamBold,
					Text = Opt.Title or "",
					TextColor3 = Theme.Accent,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}, Holder)
				local ContentLabel = Create("TextLabel", {
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					Font = Enum.Font.GothamMedium,
					Text = Opt.Content or "",
					TextColor3 = Theme.SubText,
					TextSize = 12,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}, Holder)
				table.insert(Section.Rows, { Frame = Holder, Title = Opt.Title or "" })

				local Obj = {}
				function Obj:Set(Data)
					if type(Data) == "table" then
						if Data.Title then
							TitleLabel.Text = Data.Title
						end
						if Data.Content then
							ContentLabel.Text = Data.Content
						end
					else
						ContentLabel.Text = tostring(Data)
					end
				end
				return Obj
			end

			return Section
		end

		return Tab
	end

	return Window
end

return Library
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
	ShortRange = 250, -- jarak satu kali lompat beruntun (Lynx lompat ~250 stud)
	LongTravel = "Hop", -- jarak jauh: "Hop" (lompat bertahap, tanpa mati) | "Respawn" (paling cepat)
	HopRest = 0.7, -- jeda antar lompatan bertahap (detik)
	NoFling = true, -- tidak terpental saat ditangkap guard
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
	PickAnimals = true, -- ambil hewan yang muncul (termasuk dari telur pecahan pemain lain)
	AnimalRarities = {}, -- kosong = semua
	AnimalMinWeight = 0, -- kg
	AnimalMinCash = 0, -- $/detik minimal hewan yang diambil
	StealPlayers = false, -- ikut ambil hewan dari base pemain lain
}

local Steal = {
	Enabled = false, -- ambil hewan yang bisa dicuri (StealPrompt) lalu setor
	Dropped = true, -- hewan jatuh / tergeletak di map
	OtherBases = false, -- hewan di base pemain lain
	Rarities = {}, -- kosong = semua
	MinWeight = 0, -- kg
	MutationOnly = false, -- hanya yang punya mutasi
	MinCash = 0, -- $/detik minimal
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

-- Uang dengan singkatan bebas huruf besar/kecil: "20t", "1.5B", "$13.7T/s", "2qa"
local MONEY_SUFFIX = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24, oc = 1e27, no = 1e30, dc = 1e33 }
local function ParseMoney(Text)
	Text = tostring(Text or ""):gsub(",", ""):gsub("%s", ""):lower()
	local Num, Suffix = Text:match("^%$?([%d%.]+)(%a*)")
	if not Num then
		return nil
	end
	return (tonumber(Num) or 0) * (MONEY_SUFFIX[Suffix] or 1)
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
local Fling = { Until = 0, Count = 0, Active = false, Hold = nil }
do
	local CatchFling = ReplicatedStorage:FindFirstChild("CatchFlingRemote")
	if CatchFling then
		CatchFling.OnClientEvent:Connect(function(Kind, _, Duration)
			if Kind == "fling" then
				Fling.Count += 1
				Fling.Active = true
				Fling.Hold = nil
				Fling.Until = os.clock() + math.max((tonumber(Duration) or 3) - 0.4, 0.5)
			elseif Kind == "release" then
				Fling.Until = 0
				Fling.Active = false
				Fling.Hold = nil
			end
		end)
	end
end

--[[
	Anti terpental: saat ditangkap guard, game memasang VectorForce ke seluruh badan
	(itu yang melempar karakter). Selama farm aktif, gaya itu dihapus dan posisi
	ditahan di titik teleport terakhir -> karakter cukup "pindah", tidak terlempar.
]]
local function WatchFlingForces(Character)
	Character.DescendantAdded:Connect(function(D)
		if Fling.Active and Settings.NoFling and Working() and (D:IsA("VectorForce") or D:IsA("BodyVelocity") or D:IsA("BodyForce")) then
			task.defer(function()
				pcall(function()
					D:Destroy()
				end)
			end)
		end
	end)
end
if Player.Character then
	WatchFlingForces(Player.Character)
end
Player.CharacterAdded:Connect(WatchFlingForces)

RunService.Heartbeat:Connect(function()
	if not Fling.Active or not Settings.NoFling or not Working() then
		return
	end
	local Root = GetRoot()
	if Root then
		Root.AssemblyLinearVelocity = Vector3.zero
		Root.AssemblyAngularVelocity = Vector3.zero
		if Fling.Hold then
			Root.CFrame = Fling.Hold
		end
	end
end)

-- Teleport selama fling window (tanpa batas jarak) + tahan posisi di sana
local function FlingTeleport(TargetCFrame)
	local Root = GetRoot()
	if Root and TargetCFrame then
		Fling.Hold = TargetCFrame
		Root.CFrame = TargetCFrame
		Root.AssemblyLinearVelocity = Vector3.zero
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
local function StepTo(TargetCFrame, Token, Quiet)
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
			if PullBackWarning and not Quiet then
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

--[[
	Lompat bertahap (jarak jauh TANPA respawn): lompat ~ShortRange stud (ledakan
	pendek seperti Lynx), berhenti sebentar, ulangi sampai tiba. Ditarik balik ->
	jeda diperpanjang; 3x ditarik balik -> menyerah (pemanggil pakai cadangan).
]]
local function HopTo(TargetCFrame, Token)
	local Rest, PullBacks = Settings.HopRest, 0
	while Token == MoveToken do
		local Root = GetRoot()
		if not Root then
			return false
		end
		local Target = TargetCFrame.Position
		local Flat = Vector3.new(Target.X - Root.Position.X, 0, Target.Z - Root.Position.Z)
		if Flat.Magnitude <= Settings.ShortRange then
			return StepTo(TargetCFrame, Token, true)
		end

		local Humanoid = GetHumanoid()
		local HipOffset = (Humanoid and Humanoid.HipHeight or 2) + Root.Size.Y / 2
		local Mid = Root.Position + Flat.Unit * Settings.ShortRange
		local Ground = GroundAt(Mid.X, Mid.Z, Root.Position.Y + 25)
		Mid = Vector3.new(Mid.X, Ground.Y + HipOffset, Mid.Z)
		local Segment = CFrame.lookAt(Mid, Mid + Flat.Unit)
		if StepTo(Segment, Token, true) then
			task.wait(Rest)
		else
			if Token ~= MoveToken then
				return false
			end
			PullBacks += 1
			if PullBacks >= 3 then
				LastMoveProblem = "Lompat bertahap ditarik balik 3x"
				return false
			end
			Rest *= 1.6
			task.wait(Rest)
		end
	end
	return false
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
		FlingTeleport(TargetCFrame)
		return true
	end

	if Settings.TeleportMode == "Jalan (Aman)" then
		return WalkTo(TargetCFrame, Token)
	end

	-- "Instant": dekat = lompat kecil, jauh = lompat bertahap (tanpa mati) atau respawn teleport
	local Distance = (Root.Position - TargetCFrame.Position).Magnitude
	if Distance <= Settings.ShortRange then
		return StepTo(TargetCFrame, Token)
	end
	if IsCarrying() then
		-- Jangan mati saat membawa hewan; jalan biasa (tidak dideteksi)
		return WalkTo(TargetCFrame, Token)
	end
	if Settings.LongTravel == "Hop" then
		if HopTo(TargetCFrame, Token) then
			return true
		end
		if Token ~= MoveToken then
			return false
		end
		-- Lompat bertahap gagal terus: cadangan respawn teleport
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

-- Kunci nama yang dinormalkan: "PhoenixEgg" = "Phoenix Egg" = "phoenix egg"
local function NormName(Text)
	return (tostring(Text):lower():gsub("[^%w]", ""))
end

-- Jenis telur DIPELAJARI dari telur yang benar-benar muncul di tiap zona
-- (semua zona dipindai saat load, hasil disimpan ke RapHub/EggTypes.txt)
local EggTypes = {} -- NormName -> { Name, ZoneId }
local EGG_TYPES_FILE = "RapHub/EggTypes.txt"

local function LearnEggType(Name, ZoneId)
	if type(Name) ~= "string" or type(ZoneId) ~= "string" or not ZoneId:match("^Zone%d+$") then
		return false
	end
	local Key = NormName(Name)
	if Key == "" or EggTypes[Key] then
		return false
	end
	EggTypes[Key] = { Name = Name, ZoneId = ZoneId }
	return true
end

pcall(function()
	if isfile and readfile and isfile(EGG_TYPES_FILE) then
		for Line in readfile(EGG_TYPES_FILE):gmatch("[^\n]+") do
			local ZoneId, Name = Line:match("^(Zone%d+)|(.+)$")
			if ZoneId then
				LearnEggType(Name, ZoneId)
			end
		end
	end
end)

local function SaveEggTypes()
	if not writefile then
		return
	end
	local Lines = {}
	for _, Info in pairs(EggTypes) do
		table.insert(Lines, Info.ZoneId .. "|" .. Info.Name)
	end
	table.sort(Lines)
	pcall(function()
		if makefolder and not (isfolder and isfolder("RapHub")) then
			makefolder("RapHub")
		end
		writefile(EGG_TYPES_FILE, table.concat(Lines, "\n"))
	end)
end

-- Label dropdown "Treasure Egg - Pirate Cove" -> nama telur
local function EggLabelName(Label)
	return tostring(Label):match("^(.-) %- ") or tostring(Label)
end

-- Daftar Egg Types: urut zona lalu nama, label "Nama - Zona"
local function AllEggNames()
	for _, Egg in ipairs(CollectEggs()) do
		LearnEggType(Egg.Name, Egg.ZoneId)
	end
	local Items = {}
	for _, Info in pairs(EggTypes) do
		table.insert(Items, Info)
	end
	table.sort(Items, function(x, y)
		if ZoneIndex(x.ZoneId) ~= ZoneIndex(y.ZoneId) then
			return ZoneIndex(x.ZoneId) < ZoneIndex(y.ZoneId)
		end
		return x.Name < y.Name
	end)
	local List = {}
	for _, Info in ipairs(Items) do
		table.insert(List, Info.Name .. " - " .. ZoneName(Info.ZoneId))
	end
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
local FarmNameKeys = {} -- kunci NormName dari Farm.Names (diisi saat dropdown berubah)
local MyDps = nil -- damage per detik terukur dari pukulan sendiri
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
	-- Sudah tahu damage sendiri: lewati telur yang HP-nya tidak bisa habis dalam batas waktu
	if MyDps and MyDps > 0 and Egg.Health ~= math.huge and Egg.Health / MyDps > Farm.MaxTimePerEgg then
		return false
	end
	if #Farm.Names > 0 and not FarmNameKeys[NormName(Egg.Name)] then
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
	SubTitle = "Break and Steal an Egg",
	Logo = "rbxassetid://139538771251251",
	Size = UDim2.fromOffset(660, 440),
	ConfigFolder = "RapHub/Configs/BreakStealEgg",
})

local MainTab = Window:Tab({ Name = "Main", Icon = "home" })
local AutomationTab = Window:Tab({ Name = "Automation", Icon = "bot" })
local TeleportTab = Window:Tab({ Name = "Teleport", Icon = "map-pin" })
local SettingTab = Window:Tab({ Name = "Settings", Icon = "settings" })
local ConfigTab = Window:Tab({ Name = "Config", Icon = "save" })

-- Log farm (disimpan otomatis ke RapHub/FarmLog.txt saat farm/steal aktif)
local FarmLogLines = {}
local function FarmLog(Text)
	local Line = string.format("[%s] %s", os.date("%H:%M:%S"), Text)
	table.insert(FarmLogLines, Line)
	if #FarmLogLines > 500 then
		table.remove(FarmLogLines, 1)
	end
end

-- Nilai label dropdown (Inggris, seperti Lynx) -> nilai internal script
local PRIORITY = { Nearest = "Terdekat", ["Highest Luck"] = "Luck Tertinggi", ["Biggest Size"] = "Terberat", ["Lowest HP"] = "HP Terendah" }
local MOVE_MODE = { ["Instant (Faster)"] = "Instant (Lynx)", ["Walk (Safe)"] = "Jalan (Aman)" }
local BANK_MODE = { ["Guard Catch (Fast)"] = "Lewat Guard (Cepat)", ["Walk to Base"] = "Jalan ke Base" }
local HIT_MODE = { ["Game Swing"] = "Swing Game (Aman)", ["Virtual Click"] = "Klik Virtual" }

local ZoneNameOptions = {}
for _, ZoneId in ipairs(GetZoneList()) do
	table.insert(ZoneNameOptions, ZoneName(ZoneId))
end

-- Filter hewan dipakai bersama oleh Auto Farm & Steal Only
local function SyncStealFilters()
	Steal.Rarities = Farm.AnimalRarities
	Steal.MinCash = Farm.AnimalMinCash
	Steal.Zones = Farm.Zones
	Steal.OtherBases = Farm.StealPlayers
	Steal.Dropped = true
end

-- ===================== Main: Auto Farm Eggs =====================
local FarmSection = MainTab:Section({ Title = "Auto Farm Eggs", Open = true })

local FarmStatus = FarmSection:Paragraph({ Title = "Status", Content = "Off" })

local LastStatus = ""
local function SetStatus(Text)
	if Text ~= LastStatus then
		LastStatus = Text
		FarmLog(Text)
		pcall(function()
			FarmStatus:Set({ Title = "Status", Content = Text })
		end)
	end
end

FarmSection:Dropdown({
	Title = "Zones (empty = all)",
	Options = ZoneNameOptions,
	Multi = true,
	Default = {},
	Flag = "FarmZones",
	Callback = function(Value)
		Farm.Zones = Value or {}
		SyncStealFilters()
	end,
})

local FarmNameDropdown = FarmSection:Dropdown({
	Title = "Egg Types (empty = all)",
	Options = AllEggNames(),
	Multi = true,
	Default = {},
	Flag = "FarmEggTypes",
	Callback = function(Value)
		Farm.Names = Value or {}
		table.clear(FarmNameKeys)
		for _, Name in ipairs(Farm.Names) do
			FarmNameKeys[NormName(EggLabelName(Name))] = true
		end
	end,
})

FarmSection:Dropdown({
	Title = "Animal Rarities (empty = all)",
	Options = table.clone(RARITY_ORDER),
	Multi = true,
	Default = {},
	Flag = "FarmAnimalRarities",
	Callback = function(Value)
		Farm.AnimalRarities = Value or {}
		SyncStealFilters()
	end,
})

FarmSection:Input({
	Title = "Min Cash Per Second ($/s)",
	Default = "0",
	Placeholder = "0, 500m, 20t, 1qa",
	Flag = "FarmMinCash",
	Callback = function(Value)
		Farm.AnimalMinCash = ParseMoney(Value) or 0
		SyncStealFilters()
	end,
})

FarmSection:Dropdown({
	Title = "Egg Priority",
	Options = { "Nearest", "Highest Luck", "Biggest Size", "Lowest HP" },
	Default = "Nearest",
	Flag = "FarmPriority",
	Callback = function(Value)
		Farm.Priority = PRIORITY[Value] or "Terdekat"
	end,
})

FarmSection:Toggle({
	Title = "Titanic Eggs First",
	Default = true,
	Flag = "FarmTitanicFirst",
	Callback = function(Value)
		Farm.TitanicFirst = Value
	end,
})

FarmSection:Dropdown({
	Title = "Farm Mode",
	Options = { "Instant (Faster)", "Walk (Safe)" },
	Default = "Instant (Faster)",
	Flag = "FarmMode",
	Callback = function(Value)
		Settings.TeleportMode = MOVE_MODE[Value] or "Instant (Lynx)"
	end,
})

FarmSection:Toggle({
	Title = "Auto Farm Eggs",
	Default = false,
	Flag = "AutoFarm",
	Callback = function(Value)
		Farm.Enabled = Value
		Farm.PickAnimals = true -- mengambil hewan yang muncul adalah bagian dari farm
		if not Value and not Steal.Enabled then
			StopMoving()
			SetStatus("Off")
		end
	end,
})

FarmSection:Toggle({
	Title = "Steal From Players",
	Default = false,
	Flag = "FarmStealPlayers",
	Callback = function(Value)
		Farm.StealPlayers = Value
		SyncStealFilters()
	end,
})

-- ===================== Main: Steal Only =====================
local StealSection = MainTab:Section({ Title = "Steal Only", Open = false })

local StealInfo = StealSection:Paragraph({ Title = "Stealable Animals", Content = "Scanning..." })

StealSection:Toggle({
	Title = "Steal Only (no egg breaking)",
	Default = false,
	Flag = "StealOnly",
	Callback = function(Value)
		SyncStealFilters()
		Steal.Enabled = Value
		if not Value and not Farm.Enabled then
			StopMoving()
			SetStatus("Off")
		end
	end,
})

StealSection:Toggle({
	Title = "Mutation Only",
	Default = false,
	Flag = "StealMutationOnly",
	Callback = function(Value)
		Steal.MutationOnly = Value
	end,
})

StealSection:Toggle({
	Title = "Patrol Zones When Empty",
	Default = false,
	Flag = "StealPatrol",
	Callback = function(Value)
		Steal.Patrol = Value
	end,
})

-- ===================== Automation: Place Animals =====================
local AnimalSection = AutomationTab:Section({ Title = "Place Animals", Open = true })

local BaseInfo = AnimalSection:Paragraph({ Title = "Base", Content = "Scanning..." })

AnimalSection:Toggle({
	Title = "Auto Place Animals",
	Default = false,
	Flag = "AutoPlace",
	Callback = function(Value)
		Place.Auto = Value
	end,
})

AnimalSection:Dropdown({
	Title = "Place Rarities (empty = all)",
	Options = table.clone(RARITY_ORDER),
	Multi = true,
	Default = {},
	Flag = "PlaceRarities",
	Callback = function(Value)
		Place.Rarities = Value or {}
	end,
})

AnimalSection:Slider({
	Title = "Place Every N Animals",
	Min = 1,
	Max = 20,
	Default = Place.Every,
	Increment = 1,
	Flag = "PlaceEvery",
	Callback = function(Value)
		Place.Every = Value
	end,
})

AnimalSection:Button({
	Title = "Place All Now",
	Icon = "layers",
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

-- ===================== Teleport =====================
local EggSection = TeleportTab:Section({ Title = "Eggs", Open = true })

local EggInfo = EggSection:Paragraph({ Title = "Eggs on Map", Content = "Scanning..." })

local SelectedEggKey = nil
local LastEggOptions = ""

local EggDropdown = EggSection:Dropdown({
	Title = "Select Egg",
	Options = {},
	Placeholder = "Select Egg",
	Callback = function(Value)
		SelectedEggKey = Value
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
		EggDropdown:Refresh(Options, SelectedEggKey)
	end
	EggInfo:Set({ Title = "Eggs on Map", Content = string.format("%d eggs, %d types loaded", #Eggs, #Options) })
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

EggSection:Button({
	Title = "Teleport to Selected Egg",
	Icon = "navigation",
	Callback = function()
		if not SelectedEggKey then
			Notify("Teleport", "Pilih telur dulu.")
			return
		end
		local Egg = NearestEgg(function(Egg)
			return EggKey(Egg) == SelectedEggKey
		end)
		if Egg then
			TeleportToEgg(Egg)
		else
			Notify("Teleport", "Telur itu sudah tidak ada.")
			RefreshEggList(true)
		end
	end,
})

EggSection:Button({
	Title = "Teleport to Nearest Egg",
	Icon = "navigation",
	Callback = function()
		local Egg = NearestEgg()
		if Egg then
			TeleportToEgg(Egg)
		else
			Notify("Teleport", "Tidak ada telur di map.")
		end
	end,
})

local ZoneSection = TeleportTab:Section({ Title = "Zones", Open = true })

local ZoneByLabel, ZoneLabels = {}, {}
for _, ZoneId in ipairs(GetZoneList()) do
	local Label = string.format("%d. %s", ZoneIndex(ZoneId), ZoneName(ZoneId))
	ZoneByLabel[Label] = ZoneId
	table.insert(ZoneLabels, Label)
end

local SelectedZone = nil
ZoneSection:Dropdown({
	Title = "Select Zone",
	Options = ZoneLabels,
	Placeholder = "Select Zone",
	Callback = function(Value)
		SelectedZone = Value and ZoneByLabel[Value] or nil
	end,
})

ZoneSection:Dropdown({
	Title = "Destination",
	Options = { "Entrance", "Center", "Egg Area" },
	Default = "Entrance",
	Callback = function(Value)
		Settings.ZoneTarget = ({ Entrance = "Pintu Masuk", Center = "Tengah Zona", ["Egg Area"] = "Area Telur" })[Value]
			or "Pintu Masuk"
	end,
})

ZoneSection:Button({
	Title = "Teleport to Zone",
	Icon = "navigation",
	Callback = function()
		if not SelectedZone then
			Notify("Teleport", "Pilih zona dulu.")
			return
		end
		local Target = ZoneTargetCFrame(SelectedZone)
		if Target then
			TeleportTo(Target)
		else
			Notify("Teleport", "Posisi " .. ZoneName(SelectedZone) .. " tidak ditemukan.")
		end
	end,
})

local PlaceSection = TeleportTab:Section({ Title = "Locations", Open = false })

PlaceSection:Button({ Title = "My Base", Icon = "home", Callback = GoToBase })

local function AddModelButton(Title, ModelName)
	PlaceSection:Button({
		Title = Title,
		Icon = "navigation",
		Callback = function()
			local Model = workspace:FindFirstChild(ModelName)
			if Model and Model:IsA("Model") then
				local Pos = Model:GetPivot().Position
				TeleportTo(StandAt(Pos + Vector3.new(10, 0, 0), Pos))
			else
				Notify("Teleport", Title .. " tidak ditemukan.")
			end
		end,
	})
end
AddModelButton("Animal Merging", "EggMachine")
AddModelButton("Fuse Machine", "FuseMachine")

-- ===================== Settings =====================
local FarmTune = SettingTab:Section({ Title = "Farm", Open = true })

FarmTune:Dropdown({
	Title = "Bank Method",
	Options = { "Guard Catch (Fast)", "Walk to Base" },
	Default = "Guard Catch (Fast)",
	Flag = "BankMethod",
	Callback = function(Value)
		Farm.BankMode = BANK_MODE[Value] or "Lewat Guard (Cepat)"
	end,
})

FarmTune:Dropdown({
	Title = "Hit Method",
	Options = { "Game Swing", "Virtual Click" },
	Default = "Game Swing",
	Flag = "HitMethod",
	Callback = function(Value)
		Farm.HitMode = HIT_MODE[Value] or "Swing Game (Aman)"
	end,
})

FarmTune:Toggle({
	Title = "Auto Best Zone (by Speed)",
	Default = true,
	Flag = "AutoBestZone",
	Callback = function(Value)
		Farm.AutoBestZone = Value
	end,
})

FarmTune:Toggle({
	Title = "Bank When Satchel Full",
	Default = true,
	Flag = "BankWhenFull",
	Callback = function(Value)
		Farm.ReturnWhenFull = Value
	end,
})

FarmTune:Slider({
	Title = "Max Time per Egg",
	Min = 5,
	Max = 120,
	Default = Farm.MaxTimePerEgg,
	Increment = 1,
	Suffix = "s",
	Flag = "MaxTimePerEgg",
	Callback = function(Value)
		Farm.MaxTimePerEgg = Value
	end,
})

local MoveSection = SettingTab:Section({ Title = "Movement", Open = false })

MoveSection:Toggle({
	Title = "Anti Fling (when caught)",
	Default = true,
	Flag = "NoFling",
	Callback = function(Value)
		Settings.NoFling = Value
	end,
})

MoveSection:Slider({
	Title = "Hop Distance per Frame",
	Min = 8,
	Max = 45,
	Default = Settings.StepSize,
	Increment = 1,
	Suffix = " st",
	Flag = "StepSize",
	Callback = function(Value)
		Settings.StepSize = Value
	end,
})

MoveSection:Dropdown({
	Title = "Long Distance Travel",
	Options = { "Hop (No Respawn)", "Respawn (Fastest)" },
	Default = "Hop (No Respawn)",
	Flag = "LongTravel",
	Callback = function(Value)
		Settings.LongTravel = Value == "Respawn (Fastest)" and "Respawn" or "Hop"
	end,
})

MoveSection:Slider({
	Title = "Hop Burst Distance",
	Min = 50,
	Max = 400,
	Default = Settings.ShortRange,
	Increment = 10,
	Suffix = " st",
	Flag = "ShortRange",
	Callback = function(Value)
		Settings.ShortRange = Value
	end,
})

MoveSection:Slider({
	Title = "Hop Rest",
	Min = 0.2,
	Max = 3,
	Default = Settings.HopRest,
	Increment = 0.1,
	Suffix = "s",
	Flag = "HopRest",
	Callback = function(Value)
		Settings.HopRest = Value
	end,
})

MoveSection:Slider({
	Title = "Walk Speed Multiplier",
	Min = 0.5,
	Max = 3,
	Default = 1,
	Increment = 0.1,
	Suffix = "x",
	Flag = "WalkMultiplier",
	Callback = function(Value)
		Settings.WalkMultiplier = Value
	end,
})

MoveSection:Button({ Title = "Stop Moving", Icon = "x", Callback = StopMoving })

-- ===================== Config =====================
local ConfigSection = ConfigTab:Section({ Title = "Config", Open = true })

local AUTOLOAD_FILE = "RapHub/Configs/BreakStealEgg/.autoload"
local function HasAutoload()
	local ok, Result = pcall(function()
		return isfile and isfile(AUTOLOAD_FILE)
	end)
	return ok and Result == true
end

local ConfigName = "default"
ConfigSection:Input({
	Title = "Config Name",
	Default = "default",
	Placeholder = "default",
	Callback = function(Value)
		ConfigName = Value ~= "" and Value or "default"
	end,
})

local ConfigList = ConfigSection:Dropdown({
	Title = "Saved Configs",
	Options = Library:ListConfigs(),
	Placeholder = "Select Config",
	Callback = function(Value)
		if Value then
			ConfigName = Value
		end
	end,
})

ConfigSection:Button({
	Title = "Save Config",
	Icon = "save",
	Callback = function()
		local ok = Library:SaveConfig(ConfigName)
		Notify("Config", ok and ("Tersimpan: " .. ConfigName) or "Gagal menyimpan (executor tidak mendukung writefile)")
		ConfigList:Refresh(Library:ListConfigs(), ConfigName)
	end,
})

ConfigSection:Button({
	Title = "Load Config",
	Icon = "folder",
	Callback = function()
		local ok = Library:LoadConfig(ConfigName)
		Notify("Config", ok and ("Dimuat: " .. ConfigName) or ("Config tidak ditemukan: " .. ConfigName))
	end,
})

ConfigSection:Button({
	Title = "Delete Config",
	Icon = "x",
	Callback = function()
		Library:DeleteConfig(ConfigName)
		ConfigList:Refresh(Library:ListConfigs())
		Notify("Config", "Dihapus: " .. ConfigName)
	end,
})

ConfigSection:Toggle({
	Title = "Auto Load \"default\" on Start",
	Default = HasAutoload(),
	Callback = function(Value)
		pcall(function()
			if Value and writefile then
				Library:SaveConfig("default")
				writefile(AUTOLOAD_FILE, "default")
			elseif not Value and delfile and HasAutoload() then
				delfile(AUTOLOAD_FILE)
			end
		end)
	end,
})

local InfoSection = ConfigTab:Section({ Title = "Info", Open = true })
InfoSection:Paragraph({
	Title = "RapHub",
	Content = "Version " .. tostring(RAPHUB_BUILD or "dev") .. "\nRightControl = show/hide panel. Drag the bottom-right corner to resize.",
})

-- Auto load config "default" kalau diaktifkan
task.defer(function()
	if HasAutoload() then
		Library:LoadConfig("default")
	end
end)

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

local ChainInFling -- ambil berantai selama fling window (diisi di bagian auto steal)

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
		-- Berhenti ~8 stud dari guard (tidak masuk ke badannya), guard yang datang menangkap
		if Flat.Magnitude > 8 then
			local Next = R.Position + Flat.Unit * math.min(Flat.Magnitude - 8, Settings.StepSize)
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
		FlingTeleport(Spot)
		local BankStart = os.clock()
		while CarryCount() > 0 and os.clock() - BankStart < 2 do
			task.wait(0.05)
		end
		FarmLog(CarryCount() == 0 and "Setor berhasil di SafeZone" or "Setor gagal: hewan masih dibawa setelah di SafeZone")
	elseif CarryCount() == 0 then
		FarmLog("Ditangkap guard tapi hewan tidak bisa diambil lagi (hilang)")
	else
		FarmLog("Fling window habis sebelum sempat ke SafeZone")
	end

	-- 4. Kembali ke tempat farm (masih fling window = teleport langsung)
	EquipPickaxe()
	TeleportTo(ReturnTo)

	-- 5. Sisa fling window: ambil hewan berikutnya & setor lagi (cara Lynx)
	if ChainInFling and InFlingWindow() then
		ChainInFling(Spot, ReturnTo)
	end
	return true
end

local function Bank()
	if Farm.BankMode == "Lewat Guard (Cepat)" then
		-- Guard bisa punya jeda sebelum menangkap lagi: coba sampai 3x
		for Try = 1, 3 do
			if CarryCount() == 0 then
				return
			end
			if BankViaGuard() then
				-- Sesekali pulang ke base untuk menaruh hewan
				if Place.Auto and #AnimalTools() >= Place.Every then
					BankAndPlace()
				end
				return
			end
			FarmLog(string.format("Guard tidak menangkap (percobaan %d/3)", Try))
			if Try < 3 then
				task.wait(2)
			end
		end
		if CarryCount() == 0 then
			FarmLog("Hewan sudah tidak dibawa, tidak perlu pulang")
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

-- Penghasilan hewan ("$13.7T/s") dibaca dari label di atas hewan dekat prompt
local CashCache = setmetatable({}, { __mode = "k" })
local function CashNear(Prompt, Pos)
	local Cached = CashCache[Prompt]
	if Cached and os.clock() - Cached.At < 3 then
		return Cached.Value
	end
	local Params = OverlapParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	local Ignore = { Player.Character }
	local Build, Plots = GetBuild(), workspace:FindFirstChild("Plots")
	if Build then
		table.insert(Ignore, Build)
	end
	if Plots then
		table.insert(Ignore, Plots)
	end
	Params.FilterDescendantsInstances = Ignore

	local Value = nil
	local ok, Parts = pcall(function()
		return workspace:GetPartBoundsInRadius(Pos, 12, Params)
	end)
	if ok then
		local Seen = {}
		for _, Part in ipairs(Parts) do
			local Model = Part:FindFirstAncestorWhichIsA("Model") or Part
			if not Seen[Model] and #Model:GetChildren() < 80 then
				Seen[Model] = true
				for _, Label in ipairs(Model:GetDescendants()) do
					if Label:IsA("TextLabel") then
						local Plain = Label.Text:gsub("<[^>]->", "")
						local Amount = Plain:match("%$%s*([%d%.,]+%s*%a*)%s*/%s*[sS]")
						if Amount then
							Value = ParseMoney(Amount)
							break
						end
					end
				end
			end
			if Value then
				break
			end
		end
	end
	CashCache[Prompt] = { At = os.clock(), Value = Value }
	return Value
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
	local Pos = PromptPosition(Prompt)
	Info.Cash = Pos and CashNear(Prompt, Pos) or nil
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

local function StealFilter(Info, Cfg)
	Cfg = Cfg or Steal
	if #Cfg.Rarities > 0 and not table.find(Cfg.Rarities, Info.Rarity) then
		return false
	end
	local Weight = tonumber(Info.WeightKg)
	if Cfg.MinWeight > 0 and Weight and Weight < Cfg.MinWeight then
		return false
	end
	if Cfg.MutationOnly and (Info.Mutation == nil or Info.Mutation == "") then
		return false
	end
	if (Cfg.MinCash or 0) > 0 and (Info.Cash == nil or Info.Cash < Cfg.MinCash) then
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

local function StealTargets(Cfg)
	Cfg = Cfg or Steal
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
			if (InBase and Cfg.OtherBases) or (not InBase and Cfg.Dropped) then
				local ZoneOk = true
				if Pos and #Cfg.Zones > 0 then
					local ZoneId = ZoneIdAt(Pos)
					ZoneOk = ZoneId ~= nil and table.find(Cfg.Zones, ZoneName(ZoneId)) ~= nil
				end
				if Pos and ZoneOk then
					local Info = PromptInfo(Prompt)
					if StealFilter(Info, Cfg) then
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

-- Setelan pencarian hewan untuk Auto Farm (hewan tergeletak di zona farm, bukan base orang)
local function FarmAnimalConfig()
	return {
		Dropped = true,
		OtherBases = Farm.StealPlayers,
		Rarities = Farm.AnimalRarities,
		MinWeight = Farm.AnimalMinWeight,
		MinCash = Farm.AnimalMinCash,
		MutationOnly = false,
		Zones = Farm.Zones,
	}
end

local LastStealResult = "-"

-- Selama fling window masih ada: ambil hewan terdekat -> SafeZone -> balik, berulang
ChainInFling = function(Spot, ReturnTo)
	local Cfg = (Farm.Enabled and Farm.PickAnimals) and FarmAnimalConfig() or (Steal.Enabled and Steal) or nil
	if not Cfg then
		return
	end
	local Count = 0
	while InFlingWindow() and Working() and CarryCount() < SatchelCapacity() do
		local Target = StealTargets(Cfg)[1]
		if not Target or Target.Distance > 200 then
			break
		end
		local Root = GetRoot()
		local Anchor = Target.Prompt.Parent
		if not Root or not Anchor or not Anchor:IsA("BasePart") then
			break
		end

		FlingTeleport(StandAt(Anchor.Position))
		local Before, Started, Attempt = CarryCount(), os.clock(), 0
		while CarryCount() <= Before and os.clock() - Started < 0.8 and InFlingWindow() and Target.Prompt.Parent do
			Attempt += 1
			FirePrompt(Target.Prompt, Attempt)
			task.wait(0.05)
		end
		if CarryCount() <= Before then
			StealSkip[Target.Prompt] = true
			break
		end
		Count += 1
		FarmLog("Ambil berantai (fling window): " .. Target.Name)
		if not InFlingWindow() then
			break -- dibawa, nanti disetor di langkah berikutnya
		end

		FlingTeleport(Spot)
		local BankStart = os.clock()
		while CarryCount() > 0 and os.clock() - BankStart < 1 do
			task.wait(0.05)
		end
		FlingTeleport(ReturnTo)
	end
	if Count > 0 then
		FarmLog(string.format("Rantai fling window: %d hewan", Count))
	end
end

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
		-- Hewan bisa berjalan: ikuti posisi prompt (jangkauan prompt ~10 stud)
		local Root = GetRoot()
		if Root and Anchor and Anchor:IsA("BasePart") and (Anchor.Position - Root.Position).Magnitude > 7 then
			TeleportTo(StandAt(Anchor.Position))
		end
		Method = FirePrompt(Info.Prompt, Attempt)
		task.wait(0.2)
	end

	if CarryCount() > Before then
		LastStealResult = "Berhasil: " .. Label .. " (" .. Method .. ")"
		FarmLog(LastStealResult)
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
	FarmLog(LastStealResult)
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
local function CountEggsInZone(Index, IgnoreFilter)
	local Count = 0
	for _, Egg in ipairs(CollectEggs()) do
		if ZoneIndex(Egg.ZoneId) == Index and (IgnoreFilter or FarmFilter(Egg)) then
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

-- Zona tujuan farm: zona pilihan (filter Zones, yang tertinggi dulu) atau zona terbaik otomatis
local function TargetZoneIndex()
	if #Farm.Zones > 0 then
		local Best = nil
		for _, ZoneId in ipairs(GetZoneList()) do
			local Index = ZoneIndex(ZoneId)
			local Empty = ZoneEmptyUntil[Index] and os.clock() < ZoneEmptyUntil[Index]
			if table.find(Farm.Zones, ZoneName(ZoneId)) and not Empty and (not Best or Index > Best) then
				Best = Index
			end
		end
		return Best
	end
	if Farm.AutoBestZone then
		return BestZoneIndex()
	end
	return nil
end

-- Telur zona tujuan belum terlihat (streaming): muat dulu, kalau perlu datangi.
-- Tetap kosong -> tandai kosong 90 detik (pindah ke zona pilihan/zona bawah lainnya).
EnsureBestZoneLoaded = function()
	CurrentBestIndex = BestZoneIndex()
	local Index = TargetZoneIndex()
	if not Index or CountEggsInZone(Index) > 0 then
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

	-- Telur zona ini terlihat tapi tidak ada yang lolos (terlalu kuat / filter): tidak perlu didatangi
	if CountEggsInZone(Index, true) > 0 then
		ZoneEmptyUntil[Index] = os.clock() + 90
		FarmLog(string.format(
			"%s: telur ada tapi terlalu kuat/tidak lolos filter (damage kamu %s/dtk), dilewati 90 dtk",
			Label,
			MyDps and string.format("%.3g", MyDps) or "belum diukur"
		))
		CurrentBestIndex = BestZoneIndex()
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
	else
		FarmLog("Gagal menuju " .. Label .. " (" .. tostring(LastMoveProblem or "?") .. ")")
	end

	ZoneEmptyUntil[Index] = os.clock() + 90
	FarmLog(Label .. " tidak ada telur yang cocok (" .. LastPickStats .. "), dilewati 90 dtk")
	CurrentBestIndex = BestZoneIndex()
end

-- Saat load: pindai semua zona (streaming) untuk mempelajari jenis telur tiap zona
task.spawn(function()
	task.wait(3)
	local Learned = 0
	for _, ZoneId in ipairs(GetZoneList()) do
		if Library.Unloaded then
			return
		end
		StreamZone(ZoneIndex(ZoneId))
		task.wait(0.3)
		for _, Egg in ipairs(CollectEggs()) do
			if LearnEggType(Egg.Name, Egg.ZoneId) then
				Learned += 1
			end
		end
	end
	SaveEggTypes()
	FarmLog(string.format("Jenis telur dipelajari: %d baru dari pemindaian zona", Learned))
	pcall(function()
		FarmNameDropdown:Refresh(AllEggNames(), Farm.Names)
	end)
end)

local function FarmStep()
	-- Masih dipegang guard: tunggu "release" dulu (kalau mencuri sekarang, hewan langsung direbut)
	if Fling.Active then
		SetStatus("Menunggu guard melepas...")
		local Started = os.clock()
		while Fling.Active and os.clock() - Started < 5 do
			task.wait(0.1)
		end
		Fling.Active = false
		Fling.Hold = nil
		return
	end

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

	-- Auto farm: hewan yang muncul & lolos filter diambil dulu (lebih cepat dari memecah telur)
	if Farm.Enabled and Farm.PickAnimals and CarryCount() < SatchelCapacity() then
		local Animal = StealTargets(FarmAnimalConfig())[1]
		if Animal then
			StealOne(Animal)
			return
		end
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

	if Farm.AutoBestZone or #Farm.Zones > 0 then
		EnsureBestZoneLoaded()
	end

	local Egg = PickFarmEgg(FarmSkip)
	if not Egg then
		if Farm.ReturnWhenFull and CarryCount() > 0 then
			Bank()
			return
		end
		SetStatus("Menunggu telur/hewan yang cocok (" .. LastPickStats .. ")")
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
		-- (ambang pakai ukuran telur: telur besar titik tengahnya memang jauh)
		if Distance(Egg) > math.max(Egg.Size.X, Egg.Size.Z) / 2 + 8 then
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
			MyDps = math.max(MyDps or 0, Rate)
			local Eta = NowHP / Rate
			FarmLog(string.format("%s: HP turun %.3g/dtk, pecah sekitar %.0f dtk lagi | cara: %s", Label, Rate, Eta, MethodText))
			if Eta > Farm.MaxTimePerEgg then
				TooStrong[Egg.Name] = os.clock() + 600
				FarmLog(Label .. " terlalu kuat untuk batas waktu, jenis ini dilewati 10 menit")
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

-- Catat kejadian penting dari server ke FarmLog (anti-cheat, setor, bawa/lepas hewan)
do
	local NotifyRemote = ReplicatedStorage:FindFirstChild("Notify")
	if NotifyRemote and NotifyRemote:IsA("RemoteEvent") then
		NotifyRemote.OnClientEvent:Connect(function(Text, Kind)
			if Working() and type(Text) == "string" then
				FarmLog("Server [" .. tostring(Kind) .. "]: " .. Text:gsub("<[^>]->", ""))
			end
		end)
	end
	local Banked = ReplicatedStorage:FindFirstChild("AnimalBankedRemote")
	if Banked and Banked:IsA("RemoteEvent") then
		Banked.OnClientEvent:Connect(function(List)
			if Working() and type(List) == "table" then
				local Names = {}
				for _, Item in ipairs(List) do
					if type(Item) == "table" then
						table.insert(Names, tostring(Item.Name) .. (Item.Variant and (" (" .. tostring(Item.Variant) .. ")") or ""))
					end
				end
				FarmLog("TERSIMPAN: " .. table.concat(Names, ", "))
			end
		end)
	end
	Player:GetAttributeChangedSignal("Carrying"):Connect(function()
		if Working() then
			local Name = Player:GetAttribute("Carrying")
			FarmLog(Name and ("Membawa: " .. tostring(Name) .. " [" .. tostring(Player:GetAttribute("CarryingRarity")) .. "]") or "Tidak membawa hewan lagi")
		end
	end)
	local CatchFling = ReplicatedStorage:FindFirstChild("CatchFlingRemote")
	if CatchFling and CatchFling:IsA("RemoteEvent") then
		CatchFling.OnClientEvent:Connect(function(Kind)
			if Working() then
				FarmLog("Guard: " .. tostring(Kind))
			end
		end)
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
local DiagSection = SettingTab:Section({ Title = "Diagnostics", Open = false })

local DiagInfo = DiagSection:Paragraph({
	Title = "System Status",
	Content = "Press Check Now",
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
	table.insert(Parts, "Damage terukur: " .. (MyDps and string.format("%.3g/dtk", MyDps) or "belum"))
	Check("Modul ZonesConfig", ZonesConfig ~= nil)
	Check("Modul EggRewards", EggRewardsModule ~= nil)
	table.insert(Parts, "Logo: " .. tostring(Library.LogoStatus))
	return table.concat(Parts, " | ")
end

LogDiagnostics = function()
	FarmLog("=== MULAI === versi " .. tostring(RAPHUB_BUILD or "dev") .. " | " .. DiagnoseText())
	FarmLog(string.format(
		"Setelan: mode gerak %s (jauh: " .. tostring(Settings.LongTravel) .. ") | cara pukul %s | setor %s | zona %s | auto zona terbaik %s (%s) | speed %s",
		Settings.TeleportMode,
		Farm.HitMode,
		Farm.BankMode,
		#Farm.Zones > 0 and table.concat(Farm.Zones, ",") or "semua",
		tostring(Farm.AutoBestZone),
		ZoneName(BestZoneId()),
		tostring(Player:GetAttribute("SpeedPower"))
	))
end

DiagSection:Button({
	Title = "Check Now",
	Icon = "info",
	Callback = function()
		local ok, Text = pcall(DiagnoseText)
		DiagInfo:Set({ Title = "System Status", Content = ok and Text or ("Error cek: " .. tostring(Text)) })
	end,
})

DiagSection:Button({
	Title = "Test Hit Nearest Egg",
	Icon = "sword",
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

DiagSection:Button({
	Title = "Test Steal Nearest Animal",
	Icon = "target",
	Callback = function()
		local Saved = { Rarities = Steal.Rarities, MinWeight = Steal.MinWeight, MinCash = Steal.MinCash, MutationOnly = Steal.MutationOnly, Zones = Steal.Zones }
		Steal.Rarities, Steal.MinWeight, Steal.MinCash, Steal.MutationOnly, Steal.Zones = {}, 0, 0, false, {}
		table.clear(StealSkip)
		local Target = StealTargets()[1]
		Steal.Rarities, Steal.MinWeight, Steal.MinCash, Steal.MutationOnly, Steal.Zones = Saved.Rarities, Saved.MinWeight, Saved.MinCash, Saved.MutationOnly, Saved.Zones

		if not Target then
			LastStealResult = "Tidak ada StealPrompt terlihat (total: " .. #AllStealPrompts() .. ")"
		else
			StealOne(Target)
		end
		Notify("Tes Curi", LastStealResult)
		pcall(function()
			DiagInfo:Set({ Title = "System Status", Content = DiagnoseText() })
		end)
	end,
})

-- Tulis detail semua ProximityPrompt di map ke file (untuk menyempurnakan auto steal)
DiagSection:Button({
	Title = "Scan Steal Prompts (file)",
	Icon = "search",
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
