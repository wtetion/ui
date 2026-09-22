--[=[
    AxelUI Library
    A small, dependency-free Roblox/Luau UI library for executor scripts.

    Features
      * Clean font fallback (custom FontFace can be supplied)
      * Lucide-style image icons with a text fallback
      * Loading animation and animated window open
      * Press/hover animations for controls
      * Tabs, badges, live status text and status pills
      * Search box in the top bar
      * Descriptions on sections and controls
      * Toggle, button, slider, dropdown, input, keybind, label and status
      * Notification stack, secret toggle keybind and a touch-friendly floating button
      * Responsive desktop/mobile two-column layout
      * Unload() removes the window and every tracked connection

    Quick start is included in AxelUI_Library_Example.luau.
]=]

local AxelUI = {}
AxelUI.__index = AxelUI
AxelUI.TabMethods = {}
AxelUI.SectionMethods = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ACTIVE_FONT

local DEFAULT_THEME = {
    Background = Color3.fromRGB(12, 13, 17),
    Surface = Color3.fromRGB(17, 18, 23),
    Surface2 = Color3.fromRGB(23, 24, 30),
    Element = Color3.fromRGB(28, 29, 36),
    ElementHover = Color3.fromRGB(37, 38, 47),
    Border = Color3.fromRGB(49, 50, 61),
    Text = Color3.fromRGB(244, 245, 248),
    SubText = Color3.fromRGB(157, 160, 171),
    Muted = Color3.fromRGB(105, 108, 119),
    Accent = Color3.fromRGB(255, 174, 0),
    Accent2 = Color3.fromRGB(255, 205, 69),
    Success = Color3.fromRGB(91, 220, 139),
    Warning = Color3.fromRGB(255, 184, 74),
    Danger = Color3.fromRGB(255, 99, 111),
}

-- The icons are ordinary Roblox image assets, so the library does not need a
-- second remote dependency.  A caller can pass any rbxassetid/http URL too.
local ICONS = {
    dashboard = "7733970318",
    eggs = "8997385940",
    home = "7733960981",
    combat = "7734052758",
    player = "7743876054",
    settings = "7734053495",
    server = "7734053426",
    webhook = "7733992732",
    chart = "7733674319",
    shield = "7734056608",
    eye = "7733774602",
    move = "7734020989",
    target = "7743872758",
    wrench = "7734058803",
    search = "7734052925",
    info = "7733964719",
    check = "7733715400",
    x = "7743878496",
    copy = "7733764083",
    power = "7734042423",
    download = "7733770755",
    upload = "7743875428",
    refresh = "7734051052",
    chevron = "7733717755",
}

local function copyTheme(theme)
    local result = {}
    for key, value in pairs(DEFAULT_THEME) do result[key] = value end
    for key, value in pairs(theme or {}) do result[key] = value end
    return result
end

local function asset(value)
    if value == nil or value == "" then return nil end
    local text = tostring(value)
    local mapped = ICONS[string.lower(text)]
    if mapped then return "rbxassetid://" .. mapped end
    if text:match("^%d+$") then return "rbxassetid://" .. text end
    return text
end

local function imageSource(value)
    local source = asset(value)
    if not source then return nil end
    if source:find("://", 1, true) then return source end
    local ok, custom = pcall(function()
        if type(getcustomasset) == "function" then return getcustomasset(source) end
    end)
    return ok and custom or source
end

local function fontFace(value, bold)
    local enumValue = value or ACTIVE_FONT or (bold and Enum.Font.GothamBold or Enum.Font.Gotham)
    local ok, result = pcall(function()
        if typeof(enumValue) == "EnumItem" then
            return Font.fromEnum(enumValue)
        end
        if type(enumValue) == "string" and Font and type(Font.new) == "function" then
            return Font.new(enumValue)
        end
        return enumValue
    end)
    return ok and result or (bold and Enum.Font.GothamBold or Enum.Font.Gotham)
end

local function new(className, properties, parent)
    local instance = Instance.new(className)
    for key, value in pairs(properties or {}) do
        pcall(function() instance[key] = value end)
    end
    if parent then instance.Parent = parent end
    return instance
end

local function corner(parent, radius)
    return new("UICorner", { CornerRadius = UDim.new(0, radius or 6) }, parent)
end

local function stroke(parent, color, transparency, thickness)
    return new("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function pad(parent, left, right, top, bottom)
    return new("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or left or 0),
        PaddingTop = UDim.new(0, top or left or 0),
        PaddingBottom = UDim.new(0, bottom or top or left or 0),
    }, parent)
end

local function tween(instance, goal, duration, style, direction)
    if not instance or not instance.Parent then return end
    local ok, result = pcall(function()
        local info = TweenInfo.new(
            duration or 0.18,
            style or Enum.EasingStyle.Quart,
            direction or Enum.EasingDirection.Out
        )
        local animation = TweenService:Create(instance, info, goal)
        animation:Play()
        return animation
    end)
    return ok and result or nil
end

local function textLabel(parent, text, size, color, bold)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = tostring(text or ""),
        TextColor3 = color,
        TextSize = size or 13,
        FontFace = fontFace(nil, bold),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        RichText = true,
    }, parent)
end

local function icon(parent, value, size, tint)
    local image = imageSource(value)
    if image then
        return new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = image,
            ImageColor3 = tint or Color3.new(1, 1, 1),
            Size = UDim2.fromOffset(size or 18, size or 18),
            ScaleType = Enum.ScaleType.Fit,
        }, parent)
    end
    return textLabel(parent, tostring(value or "•"), size or 18, tint or Color3.new(1, 1, 1), true)
end

local function resolveParent()
    local parent
    pcall(function()
        if type(gethui) == "function" then parent = gethui() end
    end)
    if parent then return parent end
    local ok, coreGui = pcall(game.GetService, game, "CoreGui")
    if ok and coreGui then return coreGui end
    local player = Players.LocalPlayer
    return player and player:FindFirstChildOfClass("PlayerGui") or nil
end

local function connect(self, signal, callback)
    if not signal or type(callback) ~= "function" then return nil end
    local ok, connection = pcall(function() return signal:Connect(callback) end)
    if ok and connection then
        table.insert(self._connections, connection)
        return connection
    end
end

local function keyMatches(input, key)
    if not input or not key then return false end
    if typeof(key) == "EnumItem" then return input.KeyCode == key end
    local wanted = string.lower(tostring(key))
    return string.lower(tostring(input.KeyCode.Name)) == wanted
        or string.lower(tostring(input.UserInputType.Name)) == wanted
end

local function pressAnimation(self, button, scaleObject)
    if not button then return end
    local scale = scaleObject or new("UIScale", { Scale = 1 }, button)
    connect(self, button.MouseEnter, function()
        tween(scale, { Scale = 1.025 }, 0.13)
    end)
    connect(self, button.MouseLeave, function()
        tween(scale, { Scale = 1 }, 0.16)
    end)
    connect(self, button.MouseButton1Down, function()
        tween(scale, { Scale = 0.96 }, 0.07)
    end)
    connect(self, button.MouseButton1Up, function()
        tween(scale, { Scale = 1.025 }, 0.1)
    end)
end

local function setTextColor(instance, color)
    if instance then pcall(function() instance.TextColor3 = color end) end
end

function AxelUI:_registerSearch(row, query)
    row._axelSearchText = string.lower(tostring(query or ""))
    table.insert(self._searchRows, row)
    local text = string.lower(self.Search and self.Search.Text or "")
    row.Visible = text == "" or row._axelSearchText:find(text, 1, true) ~= nil
end

function AxelUI:_refreshSearch(text)
    text = string.lower(tostring(text or ""))
    for _, row in ipairs(self._searchRows) do
        if row and row.Parent then
            row.Visible = text == "" or tostring(row._axelSearchText or ""):find(text, 1, true) ~= nil
        end
    end
end

function AxelUI:_makeRow(parent, data, height)
    data = data or {}
    local row = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Surface2,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, height or 38),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(row, 5)
    local rowStroke = stroke(row, self.Theme.Border, 0.4, 1)
    local inner = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
    }, row)
    pad(inner, 10, 10, 6, 6)
    local textOffset = 0
    if data.Icon then
        local iconHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(22, 22), Position = UDim2.fromOffset(0, 3) }, inner)
        local elementIcon = icon(iconHolder, data.Icon, 16, data.IconColor or self.Theme.Accent2)
        elementIcon.Position = UDim2.fromOffset(3, 3)
        textOffset = 27
    end
    local title = textLabel(inner, data.Name or "Element", 13, self.Theme.Text, true)
    title.Size = UDim2.new(1, -145 - textOffset, 0, data.Description and 17 or 26)
    title.Position = UDim2.fromOffset(textOffset, data.Description and 0 or 0)
    if data.Description then
        local description = textLabel(inner, data.Description, 10, self.Theme.SubText, false)
        description.TextWrapped = true
        description.Size = UDim2.new(1, -145 - textOffset, 0, 16)
        description.Position = UDim2.fromOffset(textOffset, 17)
    end
    pressAnimation(self, row)
    connect(self, row.MouseEnter, function()
        tween(row, { BackgroundColor3 = self.Theme.ElementHover }, 0.12)
        tween(rowStroke, { Transparency = 0.05 }, 0.12)
    end)
    connect(self, row.MouseLeave, function()
        tween(row, { BackgroundColor3 = self.Theme.Surface2 }, 0.18)
        tween(rowStroke, { Transparency = 0.4 }, 0.18)
    end)
    self:_registerSearch(row, (data.Name or "") .. " " .. (data.Description or ""))
    return row, inner, title
end

function AxelUI:_setActiveTab(tab, active)
    if not tab or not tab.Button then return end
    local color = active and self.Theme.Accent or self.Theme.SubText
    local background = active and self.Theme.Element or self.Theme.Surface
    tween(tab.Button, { BackgroundColor3 = background }, 0.18)
    setTextColor(tab.Title, color)
    if tab.Icon then tween(tab.Icon, { ImageColor3 = color }, 0.18) end
    if tab.Indicator then
        tween(tab.Indicator, {
            BackgroundTransparency = active and 0 or 1,
            Size = UDim2.new(0, active and 3 or 0, 0.64, 0),
        }, 0.2, Enum.EasingStyle.Quint)
    end
end

function AxelUI:SelectTab(tab)
    if self._destroyed or not tab then return end
    for _, other in ipairs(self.Tabs) do
        local active = other == tab
        other.Page.Visible = active
        self:_setActiveTab(other, active)
    end
    self.ActiveTab = tab
    self.TabTitle.Text = tab.Name
    self.TabSubtitle.Text = tab.Description or ""
    if tab.Status then
        self:SetStatus(tab.Status.Text, tab.Status.Color)
    end
    if self.GlowStroke then
        tween(self.GlowStroke, { Transparency = 0.34 }, 0.14)
        task.delay(0.18, function()
            if not self._destroyed then tween(self.GlowStroke, { Transparency = 0.58 }, 0.3) end
        end)
    end
end

function AxelUI:SetStatus(text, color)
    if not self.StatusText then return end
    self.StatusText.Text = tostring(text or "Ready")
    local tint = color or self.Theme.Success
    self.StatusDot.BackgroundColor3 = tint
    self.StatusText.TextColor3 = tint
end

function AxelUI:Notify(message, content, notificationType)
    if self._destroyed then return end
    local data
    if type(message) == "table" then
        data = message
    else
        data = { Title = message, Content = content, Type = notificationType }
    end
    local kind = string.lower(tostring(data.Type or "info"))
    local colors = {
        success = self.Theme.Success,
        warning = self.Theme.Warning,
        error = self.Theme.Danger,
        danger = self.Theme.Danger,
        info = self.Theme.Accent2,
    }
    local icons = { success = "check", warning = "info", error = "x", danger = "x", info = "info" }
    local accent = colors[kind] or self.Theme.Accent2
    local holder = self.NotificationHolder
    if not holder then return end
    local card = new("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 301,
    }, holder)
    corner(card, 7)
    stroke(card, accent, 0.28, 1)
    local stripe = new("Frame", { BackgroundColor3 = accent, BorderSizePixel = 0, Size = UDim2.new(0, 3, 1, 0), ZIndex = 302 }, card)
    corner(stripe, 2)
    local iconHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(12, 12), ZIndex = 302 }, card)
    local typeIcon = icon(iconHolder, data.Icon or icons[kind] or "info", 16, accent); typeIcon.Position = UDim2.fromOffset(4, 4); typeIcon.ZIndex = 303
    local title = textLabel(card, data.Title or "Axel Hub", 12, self.Theme.Text, true); title.Position = UDim2.fromOffset(45, 8); title.Size = UDim2.new(1, -78, 0, 18); title.ZIndex = 302
    local body = textLabel(card, data.Content or "", 10, self.Theme.SubText, false); body.Position = UDim2.fromOffset(45, 27); body.Size = UDim2.new(1, -56, 0, 30); body.TextWrapped = true; body.TextYAlignment = Enum.TextYAlignment.Top; body.ZIndex = 302
    local close = new("TextButton", { AutoButtonColor = false, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", Size = UDim2.fromOffset(20, 20), Position = UDim2.new(1, -27, 0, 8), ZIndex = 302 }, card)
    local closeIcon = icon(close, "x", 11, self.Theme.Muted); closeIcon.Position = UDim2.fromOffset(4, 4); closeIcon.ZIndex = 303
    local scale = new("UIScale", { Scale = 0.88 }, card)
    local closed = false
    local function closeCard()
        if closed then return end
        closed = true
        tween(scale, { Scale = 0.88 }, 0.14)
        tween(card, { BackgroundTransparency = 1 }, 0.14)
        task.delay(0.16, function() if card.Parent then card:Destroy() end end)
    end
    connect(self, close.MouseButton1Click, closeCard)
    table.insert(self._notifications, card)
    tween(scale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    local duration = tonumber(data.Duration)
    if duration == nil then duration = 3.5 end
    if duration > 0 then task.delay(duration, closeCard) end
    return { Instance = card, Close = closeCard }
end

function AxelUI:SetOpen(visible)
    if self._destroyed or not self.Window then return end
    visible = visible == true
    if visible then
        self.Window.Visible = true
        tween(self.Scale, { Scale = 1 }, 0.22, Enum.EasingStyle.Back)
    else
        tween(self.Scale, { Scale = 0.92 }, 0.16)
        task.delay(0.17, function()
            if not self._destroyed and not self._open then self.Window.Visible = false end
        end)
    end
    self._open = visible
end

function AxelUI:SetToggleKeybind(key)
    self.ToggleKeybind = key or Enum.KeyCode.RightControl
end

function AxelUI:_applyResponsive()
    if self._destroyed or not self.Window then return end
    local viewport = Vector2.new(1280, 720)
    pcall(function()
        if workspace.CurrentCamera then viewport = workspace.CurrentCamera.ViewportSize end
    end)
    local mobile = viewport.X <= 760 or (UserInputService.TouchEnabled and viewport.X <= 900)
    self.IsMobile = mobile

    if mobile then
        local width = math.max(300, math.min(480, viewport.X - 18))
        local height = math.max(360, math.min(720, viewport.Y - 26))
        self.Window.Size = UDim2.fromOffset(width, height)
        self.Sidebar.Size = UDim2.new(0, 64, 1, -50)
        self.PageHolder.Position = UDim2.fromOffset(64, 50)
        self.PageHolder.Size = UDim2.new(1, -64, 1, -50)
        self.NavTitle.Visible = false
        self.Footer.Visible = false
        self.HeaderSubtitle.Visible = false
        self.FpsText.Visible = false
        self.StatusDot.Visible = false
        self.StatusText.Visible = false
        self.Search.Position = UDim2.fromOffset(120, 10)
        self.Search.Size = UDim2.new(1, -206, 0, 30)
        self.SearchIcon.Position = UDim2.new(1, -96, 0, 17)
        self.TabTitle.TextSize = 13
        self.TabSubtitle.Visible = false
        self.TabHeader.Size = UDim2.new(1, 0, 0, 38)
        self.TabTitle.Position = UDim2.fromOffset(12, 8)
        self.TouchButton.Visible = true
        self.NotificationHolder.Size = UDim2.fromOffset(220, 0)
        self.NotificationHolder.Position = UDim2.new(1, -10, 0, 58)
    else
        self.Window.Size = self.DesktopSize or UDim2.fromOffset(820, 560)
        self.Sidebar.Size = UDim2.new(0, 170, 1, -50)
        self.PageHolder.Position = UDim2.fromOffset(170, 50)
        self.PageHolder.Size = UDim2.new(1, -170, 1, -50)
        self.NavTitle.Visible = true
        self.Footer.Visible = true
        self.HeaderSubtitle.Visible = true
        self.FpsText.Visible = true
        self.StatusDot.Visible = true
        self.StatusText.Visible = true
        self.Search.Position = UDim2.fromOffset(245, 10)
        self.Search.Size = UDim2.fromOffset(280, 30)
        self.SearchIcon.Position = UDim2.fromOffset(500, 17)
        self.TabTitle.TextSize = 15
        self.TabSubtitle.Visible = true
        self.TabHeader.Size = UDim2.new(1, 0, 0, 42)
        self.TabTitle.Position = UDim2.fromOffset(16, 3)
        self.TouchButton.Visible = false
        self.NotificationHolder.Size = UDim2.fromOffset(300, 0)
        self.NotificationHolder.Position = UDim2.new(1, -18, 0, 62)
    end

    for _, tab in ipairs(self.Tabs) do
        if tab.Title then tab.Title.Visible = not mobile end
        if tab.Subtitle then tab.Subtitle.Visible = not mobile end
        if tab.IconHolder then
            tab.IconHolder.Position = UDim2.fromOffset(mobile and 20 or 12, 7)
        end
        if tab.ColumnLayout then
            tab.ColumnLayout.FillDirection = mobile and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            tab.ColumnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            tab.ColumnLayout.Padding = UDim.new(0, mobile and 8 or 10)
        end
        if tab.LeftBody then tab.LeftBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
        if tab.RightBody then tab.RightBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
    end
end

function AxelUI:SetFont(font)
    self._font = font
    ACTIVE_FONT = font
    -- Existing elements inherit a normal Gotham fallback. New controls use the
    -- requested font. This keeps the method safe even on old executors.
end

function AxelUI:AddTab(data)
    data = data or {}
    local tab = {
        Window = self,
        Name = tostring(data.Name or data.name or "Tab"),
        Description = tostring(data.Description or data.Subtitle or data.subtitle or ""),
        IconValue = data.Icon or data.icon,
        Status = nil,
        Sections = {},
    }
    setmetatable(tab, { __index = self.TabMethods })

    local button = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, 39),
    }, self.TabList)
    corner(button, 6)
    local indicator = new("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.18, 0),
        Size = UDim2.new(0, 3, 0.64, 0),
    }, button)
    corner(indicator, 2)
    local iconHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(24, 24), Position = UDim2.fromOffset(12, 7) }, button)
    local tabIcon = icon(iconHolder, tab.IconValue or "dashboard", 18, self.Theme.SubText)
    tabIcon.Position = UDim2.fromOffset(3, 3)
    local title = textLabel(button, tab.Name, 12, self.Theme.SubText, true)
    title.Position = UDim2.fromOffset(43, 2)
    title.Size = UDim2.new(1, -75, 0, 21)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    local subtitle = textLabel(button, tab.Description, 9, self.Theme.Muted, false)
    subtitle.Position = UDim2.fromOffset(43, 21)
    subtitle.Size = UDim2.new(1, -75, 0, 14)
    subtitle.TextTruncate = Enum.TextTruncate.AtEnd
    local badge
    if data.Badge ~= nil then
        badge = new("TextLabel", {
            BackgroundColor3 = self.Theme.Accent,
            TextColor3 = self.Theme.Background,
            Text = tostring(data.Badge),
            TextSize = 9,
            FontFace = fontFace(nil, true),
            Size = UDim2.fromOffset(28, 16),
            Position = UDim2.new(1, -38, 0, 11),
        }, button)
        corner(badge, 8)
    end
    tab.Button, tab.Title, tab.Subtitle, tab.IconHolder, tab.Icon, tab.Indicator, tab.Badge = button, title, subtitle, iconHolder, tabIcon, indicator, badge

    local page = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, self.PageHolder)
    local pageBody = new("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarImageColor3 = self.Theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, -26, 1, -60),
        Position = UDim2.fromOffset(13, 50),
    }, page)
    pad(pageBody, 0, 5, 0, 10)
    local columns = new("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, 0),
    }, pageBody)
    local leftColumn = new("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0.5, -5, 0, 0),
    }, columns)
    local rightColumn = new("Frame", {
        BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(0.5, -5, 0, 0),
    }, columns)
    local columnLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, columns)
    leftColumn.LayoutOrder = 1
    rightColumn.LayoutOrder = 2
    local leftLayout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, leftColumn)
    local rightLayout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, rightColumn)
    tab.Page, tab.Body, tab.Layout = page, leftColumn, leftLayout
    tab.Columns, tab.LeftBody, tab.RightBody = columns, leftColumn, rightColumn
    tab.ColumnLayout = columnLayout
    tab._nextSide = "Left"
    table.insert(self.Tabs, tab)

    connect(self, button.MouseButton1Click, function() self:SelectTab(tab) end)
    pressAnimation(self, button)
    if #self.Tabs == 1 then self:SelectTab(tab) end
    if self._applyResponsive then self:_applyResponsive() end
    return tab
end

function AxelUI.TabMethods:SetBadge(value, color)
    if not self.Badge then
        self.Badge = new("TextLabel", {
            BackgroundColor3 = self.Window.Theme.Accent,
            TextColor3 = self.Window.Theme.Background,
            TextSize = 9,
            FontFace = fontFace(nil, true),
            Size = UDim2.fromOffset(28, 16),
            Position = UDim2.new(1, -38, 0, 11),
        }, self.Button)
        corner(self.Badge, 8)
    end
    self.Badge.Text = tostring(value or "")
    self.Badge.Visible = value ~= nil and tostring(value) ~= ""
    if color then self.Badge.BackgroundColor3 = color end
end

function AxelUI.TabMethods:SetStatus(text, color)
    self.Status = { Text = tostring(text or "Ready"), Color = color or self.Window.Theme.Success }
    if self.Window.ActiveTab == self then self.Window:SetStatus(self.Status.Text, self.Status.Color) end
end

function AxelUI.TabMethods:AddSection(data)
    data = data or {}
    local section = {
        Tab = self,
        Window = self.Window,
        Name = tostring(data.Name or data.Title or "Section"),
        Description = tostring(data.Description or ""),
        Controls = {},
    }
    setmetatable(section, { __index = AxelUI.SectionMethods })
    local requestedSide = string.lower(tostring(data.Side or data.Column or ""))
    local parent = self.LeftBody or self.Body
    if requestedSide == "right" then
        parent = self.RightBody or parent
    elseif requestedSide == "auto" then
        if self._nextSide == "Right" then
            parent = self.RightBody or parent
            self._nextSide = "Left"
        else
            self._nextSide = "Right"
        end
    end
    local card = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Surface,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, -5, 0, 0),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(card, 7)
    stroke(card, self.Window.Theme.Border, 0.28, 1)
    local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, data.Description ~= "" and 53 or 35) }, card)
    pad(header, 12, 12, 8, 4)
    local title = textLabel(header, section.Name, 14, self.Window.Theme.Text, true)
    title.Size = UDim2.new(1, -20, 0, 18)
    if section.Description ~= "" then
        local description = textLabel(header, section.Description, 10, self.Window.Theme.SubText, false)
        description.Size = UDim2.new(1, -20, 0, 17)
        description.Position = UDim2.fromOffset(0, 20)
        description.TextWrapped = true
    end
    local body = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) }, card)
    pad(body, 10, 10, 2, 10)
    local layout = new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, body)
    section.Card, section.Body, section.Layout = card, body, layout
    table.insert(self.Sections, section)
    return section
end

function AxelUI.SectionMethods:AddDescription(text)
    local label = textLabel(self.Body, text, 11, self.Window.Theme.SubText, false)
    label.Size = UDim2.new(1, 0, 0, 26)
    label.TextWrapped = true
    self.Window:_registerSearch(label, text)
    return label
end

function AxelUI.SectionMethods:AddLabel(data)
    data = type(data) == "table" and data or { Name = data }
    local label = textLabel(self.Body, data.Name or data.Text or "", data.TextSize or 12, data.Color or self.Window.Theme.SubText, data.Bold)
    label.Size = UDim2.new(1, 0, 0, data.Height or 20)
    if data.Description then label.Text = tostring(data.Name or "") .. "  <font color=\"#9699A5\">" .. tostring(data.Description) .. "</font>" end
    self.Window:_registerSearch(label, (data.Name or "") .. " " .. (data.Description or ""))
    return label
end

function AxelUI.SectionMethods:AddParagraph(data)
    data = data or {}
    local wrapper = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 0) }, self.Body)
    local title = textLabel(wrapper, data.Title or data.Name or "Info", 12, self.Window.Theme.Accent2, true)
    title.Size = UDim2.new(1, 0, 0, 18)
    local content = textLabel(wrapper, data.Content or "", 11, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(0, 19)
    content.Size = UDim2.new(1, 0, 0, data.Height or 36)
    content.TextWrapped = true
    content.TextYAlignment = Enum.TextYAlignment.Top
    self.Window:_registerSearch(wrapper, tostring(data.Title or "") .. " " .. tostring(data.Content or ""))
    local handle = { Instance = wrapper, Title = title, Content = content }
    function handle:Set(value) self.Content.Text = tostring(value or "") end
    function handle:Get() return self.Content.Text end
    function handle:SetVisibility(value) self.Instance.Visible = value == true end
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddImage(data)
    data = type(data) == "table" and data or { Image = data }
    local height = tonumber(data.Height) or 120
    local holder = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
    }, self.Body)
    corner(holder, 6)
    stroke(holder, self.Window.Theme.Border, 0.22, 1)
    local picture = new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = imageSource(data.Image or data.Source or data.Asset),
        ImageColor3 = data.Tint or Color3.new(1, 1, 1),
        ScaleType = data.ScaleType or Enum.ScaleType.Fit,
        Size = UDim2.new(1, -12, 1, data.Caption and -30 or -12),
        Position = UDim2.fromOffset(6, 6),
    }, holder)
    corner(picture, 5)
    if data.Caption then
        local caption = textLabel(holder, data.Caption, 10, self.Window.Theme.SubText, false)
        caption.Position = UDim2.new(0, 8, 1, -24)
        caption.Size = UDim2.new(1, -16, 0, 18)
        caption.TextXAlignment = Enum.TextXAlignment.Center
    end
    self.Window:_registerSearch(holder, tostring(data.Caption or data.Name or "Image"))
    return { Instance = holder, Image = picture }
end

function AxelUI.SectionMethods:AddButton(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 38)
    local buttonIcon = icon(inner, data.Icon or "check", 16, data.IconColor or self.Window.Theme.Accent2)
    buttonIcon.Position = UDim2.new(1, -30, 0.5, -8)
    connect(self.Window, row.MouseButton1Click, function()
        if type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback) end)
        end
    end)
    table.insert(self.Controls, row)
    return row
end

function AxelUI.SectionMethods:AddToggle(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local track = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Element,
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
    }, inner)
    corner(track, 10)
    local knob = new("Frame", { BackgroundColor3 = self.Window.Theme.Muted, Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3) }, track)
    corner(knob, 7)
    local handle = { Value = data.Default == true, Row = row }
    function handle:Set(value, silent)
        self.Value = value == true
        local x = self.Value and 23 or 3
        tween(knob, { Position = UDim2.fromOffset(x, 3), BackgroundColor3 = self.Value and self.Window.Theme.Background or self.Window.Theme.Muted }, 0.16)
        tween(track, { BackgroundColor3 = self.Value and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, self.Value) end)
        end
    end
    function handle:Get() return self.Value end
    connect(self.Window, row.MouseButton1Click, function() handle:Set(not handle.Value) end)
    handle:Set(handle.Value, true)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddSlider(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 54)
    local minimum, maximum = tonumber(data.Min or data.Minimum) or 0, tonumber(data.Max or data.Maximum) or 100
    local value = math.clamp(tonumber(data.Default) or minimum, minimum, maximum)
    local valueText = textLabel(inner, "", 10, self.Window.Theme.Accent2, true)
    valueText.Size = UDim2.fromOffset(100, 18)
    valueText.Position = UDim2.new(1, -108, 0, 0)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    local bar = new("Frame", { BackgroundColor3 = self.Window.Theme.Element, Size = UDim2.new(1, -8, 0, 5), Position = UDim2.new(0, 0, 1, -11) }, inner)
    corner(bar, 4)
    local fill = new("Frame", { BackgroundColor3 = self.Window.Theme.Accent, Size = UDim2.new(0, 0, 1, 0) }, bar)
    corner(fill, 4)
    local handle = { Value = value, Row = row }
    local function setFromX(x, silent)
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local decimals = tonumber(data.Decimals) or 1
        local nextValue = minimum + (maximum - minimum) * ratio
        local power = 10 ^ decimals
        nextValue = math.floor(nextValue * power + 0.5) / power
        handle.Value = nextValue
        valueText.Text = tostring(nextValue) .. tostring(data.Suffix or "")
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, nextValue) end)
        end
    end
    function handle:Set(nextValue, silent)
        nextValue = math.clamp(tonumber(nextValue) or minimum, minimum, maximum)
        local ratio = (nextValue - minimum) / math.max(0.0001, maximum - minimum)
        handle.Value = nextValue
        valueText.Text = tostring(nextValue) .. tostring(data.Suffix or "")
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, nextValue) end)
        end
    end
    function handle:Get() return handle.Value end
    local sliding = false
    connect(self.Window, bar.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true
            setFromX(input.Position.X)
        end
    end)
    connect(self.Window, UserInputService.InputChanged, function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then setFromX(input.Position.X) end
    end)
    connect(self.Window, UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then sliding = false end
    end)
    handle:Set(value, true)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddDropdown(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local selected = data.Default
    local selector = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Text = tostring(selected or "Select"),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 11,
        FontFace = fontFace(nil, false),
        Size = UDim2.fromOffset(145, 25),
        Position = UDim2.new(1, -155, 0.5, -12),
    }, inner)
    corner(selector, 5)
    local popup
    local handle = { Value = selected, Row = row }
    local function close()
        if popup then popup:Destroy(); popup = nil end
    end
    local function open()
        close()
        popup = new("Frame", { BackgroundColor3 = self.Window.Theme.Surface, BorderSizePixel = 0, Size = UDim2.fromOffset(145, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 50 }, self.Window.Gui)
        corner(popup, 5); stroke(popup, self.Window.Theme.Border, 0.05, 1); pad(popup, 4, 4, 4, 4)
        popup.Position = UDim2.fromOffset(selector.AbsolutePosition.X, selector.AbsolutePosition.Y + selector.AbsoluteSize.Y + 4)
        local list = new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
        for _, option in ipairs(data.Options or data.Items or {}) do
            local optionButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Window.Theme.Surface2, BorderSizePixel = 0, Text = tostring(option), TextColor3 = self.Window.Theme.Text, TextSize = 11, FontFace = fontFace(nil, false), Size = UDim2.new(1, 0, 0, 25), ZIndex = 51 }, popup)
            corner(optionButton, 4)
            connect(self.Window, optionButton.MouseButton1Click, function()
                handle.Value = option; selector.Text = tostring(option); close()
                if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, option) end) end
            end)
        end
    end
    function handle:Set(value, silent)
        self.Value = value; selector.Text = tostring(value or "Select")
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, value) end) end
    end
    function handle:Get() return self.Value end
    connect(self.Window, selector.MouseButton1Click, open)
    pressAnimation(self.Window, selector)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddInput(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 42)
    local box = new("TextBox", { BackgroundColor3 = self.Window.Theme.Element, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = tostring(data.Placeholder or "Input"), PlaceholderColor3 = self.Window.Theme.Muted, Text = tostring(data.Default or ""), TextColor3 = self.Window.Theme.Text, TextSize = 11, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(160, 25), Position = UDim2.new(1, -170, 0.5, -12) }, inner)
    corner(box, 5); pad(box, 8, 8, 0, 0)
    local handle = { Instance = box, Value = box.Text }
    function handle:Set(value, silent)
        self.Value = tostring(value or ""); box.Text = self.Value
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, self.Value) end) end
    end
    function handle:Get() return box.Text end
    connect(self.Window, box.FocusLost, function() handle:Set(box.Text) end)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddKeybind(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local keyButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Window.Theme.Element, BorderSizePixel = 0, Text = tostring(data.Default or "None"), TextColor3 = self.Window.Theme.Text, TextSize = 11, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(100, 25), Position = UDim2.new(1, -110, 0.5, -12) }, inner)
    corner(keyButton, 5)
    local handle = { Value = tostring(data.Default or "None"), Listening = false }
    function handle:Set(value) self.Value = tostring(value or "None"); keyButton.Text = self.Value end
    function handle:Get() return self.Value end
    connect(self.Window, keyButton.MouseButton1Click, function()
        handle.Listening = true; keyButton.Text = "Press key..."
    end)
    connect(self.Window, UserInputService.InputBegan, function(input, processed)
        if handle.Listening and not processed then
            local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
            handle.Listening = false; handle:Set(key)
            if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, key) end) end
        end
    end)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddStatus(data)
    data = data or {}
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 34)
    local status = textLabel(inner, data.Text or data.Status or "Ready", 11, data.Color or self.Window.Theme.Success, true)
    status.Size = UDim2.new(0, 180, 0, 24)
    status.Position = UDim2.new(1, -180, 0, 0)
    status.TextXAlignment = Enum.TextXAlignment.Right
    local handle = { Instance = status, Text = tostring(data.Text or data.Status or "Ready"), Color = data.Color or self.Window.Theme.Success }
    function handle:Set(value, color)
        self.Text = tostring(value or "Ready"); self.Color = color or self.Color; status.Text = self.Text; status.TextColor3 = self.Color
    end
    function handle:Get() return self.Text end
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddDivider()
    return new("Frame", { BackgroundColor3 = self.Window.Theme.Border, BackgroundTransparency = 0.2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1) }, self.Body)
end

function AxelUI:Unload()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    self._connections = {}
    if self._dropdownClose then pcall(self._dropdownClose) end
    if self.Gui then pcall(function() self.Gui:Destroy() end) end
    if self._globalKey and _G[self._globalKey] == self then _G[self._globalKey] = nil end
end

function AxelUI:Destroy()
    return self:Unload()
end

function AxelUI:Toggle()
    if not self.Window then return end
    self:SetOpen(not self._open)
end

function AxelUI.new(options)
    options = options or {}
    local globalKey = tostring(options.GuiName or options.Name or "AxelUI")
    if _G[globalKey] and type(_G[globalKey].Unload) == "function" then pcall(function() _G[globalKey]:Unload() end) end
    local self = setmetatable({
        _connections = {},
        _searchRows = {},
        _notifications = {},
        _destroyed = false,
        _open = true,
        _globalKey = globalKey,
        Theme = copyTheme(options.Theme),
        Tabs = {},
        ActiveTab = nil,
        _font = options.Font,
        ToggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightControl,
        DesktopSize = options.Size or UDim2.fromOffset(820, 560),
    }, AxelUI)
    ACTIVE_FONT = options.Font
    self.TabMethods = AxelUI.TabMethods
    self.Gui = new("ScreenGui", { Name = globalKey, IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global }, resolveParent())
    _G[globalKey] = self

    self.Window = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), Size = self.DesktopSize, ClipsDescendants = true }, self.Gui)
    corner(self.Window, 9)
    self.GlowStroke = stroke(self.Window, self.Theme.Accent, 0.58, 1.25)
    new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Background),
            ColorSequenceKeypoint.new(0.55, self.Theme.Surface),
            ColorSequenceKeypoint.new(1, self.Theme.Background),
        }),
        Rotation = 25,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(0.55, 0),
            NumberSequenceKeypoint.new(1, 0.14),
        }),
    }, self.Window)
    self.Scale = new("UIScale", { Scale = 0.9 }, self.Window)

    local header = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 50) }, self.Window)
    self.Header = header
    local logoHolder = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.fromOffset(32, 32), Position = UDim2.fromOffset(10, 9) }, header)
    corner(logoHolder, 8); icon(logoHolder, options.Logo or "dashboard", 20, self.Theme.Accent2).Position = UDim2.fromOffset(6, 6)
    local brand = textLabel(header, options.Name or "Axel UI", 14, self.Theme.Text, true); brand.Position = UDim2.fromOffset(52, 5); brand.Size = UDim2.fromOffset(150, 20)
    local subtitle = textLabel(header, options.Subtitle or "Clean, animated interface", 10, self.Theme.SubText, false); subtitle.Position = UDim2.fromOffset(52, 25); subtitle.Size = UDim2.fromOffset(180, 16)
    self.Brand, self.HeaderSubtitle = brand, subtitle
    local search = new("TextBox", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Search", PlaceholderColor3 = self.Theme.Muted, Text = "", TextColor3 = self.Theme.Text, TextSize = 12, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(280, 30), Position = UDim2.new(0, 245, 0, 10) }, header)
    corner(search, 5); stroke(search, self.Theme.Border, 0.25, 1); pad(search, 10, 30, 0, 0)
    self.SearchIcon = icon(header, "search", 15, self.Theme.Muted); self.SearchIcon.Position = UDim2.new(0, 500, 0, 17)
    self.Search = search
    self.StatusDot = new("Frame", { BackgroundColor3 = self.Theme.Success, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), Position = UDim2.new(1, -140, 0, 21) }, header); corner(self.StatusDot, 4)
    self.StatusText = textLabel(header, "Ready", 10, self.Theme.Success, true); self.StatusText.Position = UDim2.new(1, -126, 0, 14); self.StatusText.Size = UDim2.fromOffset(76, 20); self.StatusText.TextXAlignment = Enum.TextXAlignment.Left
    self.FpsText = textLabel(header, "FPS --", 10, self.Theme.SubText, true); self.FpsText.Position = UDim2.new(1, -232, 0, 14); self.FpsText.Size = UDim2.fromOffset(82, 20); self.FpsText.TextXAlignment = Enum.TextXAlignment.Right
    local unloadButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Text = "", Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -38, 0, 11) }, header)
    corner(unloadButton, 6)
    local unloadIcon = icon(unloadButton, "power", 15, self.Theme.SubText); unloadIcon.Position = UDim2.fromOffset(6, 6)
    self.UnloadButton = unloadButton
    pressAnimation(self, unloadButton)
    connect(self, unloadButton.MouseButton1Click, function() self:Unload() end)

    local sidebar = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 50), Size = UDim2.new(0, 170, 1, -50) }, self.Window)
    self.Sidebar = sidebar
    local navTitle = textLabel(sidebar, "NAVIGATION", 9, self.Theme.Muted, true); navTitle.Position = UDim2.fromOffset(14, 13); navTitle.Size = UDim2.new(1, -28, 0, 16)
    self.NavTitle = navTitle
    self.TabList = new("ScrollingFrame", { Active = true, AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), Position = UDim2.fromOffset(8, 36), ScrollBarImageColor3 = self.Theme.Accent, ScrollBarThickness = 2, Size = UDim2.new(1, -16, 1, -85) }, sidebar)
    new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, self.TabList)
    local footer = textLabel(sidebar, options.Footer or "AxelUI Library", 9, self.Theme.Muted, false); footer.Position = UDim2.new(0, 14, 1, -36); footer.Size = UDim2.new(1, -28, 0, 20)
    self.Footer = footer

    self.PageHolder = new("Frame", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(170, 50), Size = UDim2.new(1, -170, 1, -50) }, self.Window)
    local tabHeader = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 42) }, self.PageHolder)
    self.TabHeader = tabHeader
    self.TabTitle = textLabel(tabHeader, "Dashboard", 15, self.Theme.Text, true); self.TabTitle.Position = UDim2.fromOffset(16, 3); self.TabTitle.Size = UDim2.new(1, -28, 0, 19)
    self.TabSubtitle = textLabel(tabHeader, "", 10, self.Theme.SubText, false); self.TabSubtitle.Position = UDim2.fromOffset(16, 21); self.TabSubtitle.Size = UDim2.new(1, -28, 0, 15)
    local separator = new("Frame", { BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) }, tabHeader)

    self.NotificationHolder = new("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new(1, -18, 0, 62),
        Size = UDim2.fromOffset(300, 0),
        ZIndex = 300,
    }, self.Gui)
    new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right }, self.NotificationHolder)

    self.TouchButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(44, 44),
        Position = UDim2.new(1, -62, 1, -62),
        Visible = false,
        ZIndex = 250,
    }, self.Gui)
    corner(self.TouchButton, 11)
    stroke(self.TouchButton, self.Theme.Accent, 0.18, 1)
    local touchIcon = icon(self.TouchButton, "dashboard", 18, self.Theme.Accent2); touchIcon.Position = UDim2.fromOffset(13, 13); touchIcon.ZIndex = 251
    pressAnimation(self, self.TouchButton)
    connect(self, self.TouchButton.MouseButton1Click, function() self:Toggle() end)

    connect(self, search:GetPropertyChangedSignal("Text"), function() self:_refreshSearch(search.Text) end)
    connect(self, UserInputService.InputBegan, function(input, processed)
        if processed or self._destroyed then return end
        if keyMatches(input, self.ToggleKeybind) then self:Toggle() end
    end)
    self._fpsFrames = 0
    self._fpsLastSample = os.clock()
    connect(self, RunService.RenderStepped, function()
        if self._destroyed then return end
        self._fpsFrames += 1
        local now = os.clock()
        local elapsed = now - self._fpsLastSample
        if elapsed >= 0.5 then
            local fps = math.floor(self._fpsFrames / elapsed + 0.5)
            self._fpsFrames = 0
            self._fpsLastSample = now
            if self.FpsText then self.FpsText.Text = "FPS " .. tostring(fps) end
        end
    end)
    connect(self, self.Window.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true; self._dragStart = input.Position; self._windowStart = self.Window.Position
        end
    end)
    connect(self, self.Window.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then self._dragging = false end
    end)
    connect(self, UserInputService.InputChanged, function(input)
        if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - self._dragStart
            self.Window.Position = UDim2.new(self._windowStart.X.Scale, self._windowStart.X.Offset + delta.X, self._windowStart.Y.Scale, self._windowStart.Y.Offset + delta.Y)
        end
    end)
    pcall(function()
        if workspace.CurrentCamera then
            connect(self, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function() self:_applyResponsive() end)
        end
    end)
    self:_applyResponsive()

    local overlay = new("Frame", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 100 }, self.Window)
    local overlayIcon = icon(overlay, options.Logo or "dashboard", 46, self.Theme.Accent2); overlayIcon.AnchorPoint = Vector2.new(0.5, 0.5); overlayIcon.Position = UDim2.new(0.5, 0, 0.42, 0); overlayIcon.ZIndex = 101
    local loadingText = textLabel(overlay, options.LoadingText or "Loading interface...", 13, self.Theme.Text, true); loadingText.AnchorPoint = Vector2.new(0.5, 0); loadingText.Position = UDim2.new(0.5, 0, 0.58, 0); loadingText.Size = UDim2.fromOffset(260, 24); loadingText.TextXAlignment = Enum.TextXAlignment.Center; loadingText.ZIndex = 101
    local loadingBar = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.fromOffset(180, 4), Position = UDim2.new(0.5, -90, 0.66, 0), ZIndex = 101 }, overlay); corner(loadingBar, 4)
    local loadingFill = new("Frame", { BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), ZIndex = 102 }, loadingBar); corner(loadingFill, 4)
    tween(self.Scale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    tween(loadingFill, { Size = UDim2.fromScale(1, 1) }, 0.55)
    task.delay(0.62, function()
        if self._destroyed or not overlay.Parent then return end
        tween(overlay, { BackgroundTransparency = 1 }, 0.25)
        tween(overlayIcon, { ImageTransparency = 1 }, 0.2)
        tween(loadingText, { TextTransparency = 1 }, 0.2)
        tween(loadingBar, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.28, function() if overlay.Parent then overlay:Destroy() end end)
    end)

    function self:CreateTab(data) return self:AddTab(data) end
    function self:WindowToggle() return self:Toggle() end
    self._globalKey = globalKey
    return self
end

return AxelUI
