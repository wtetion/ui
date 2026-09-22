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
      * Theme switching, local/asset backgrounds and JSON config persistence
      * Oxide-style compatibility aliases: CreateWindow, AddSubTab and AddMultiDropdown
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
local HttpService = game:GetService("HttpService")
local ACTIVE_FONT
local ACTIVE_ASSET_FOLDER

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
    -- Compatibility names used by Oxide-style scripts.
    crown = "8997385940",
    bolt = "7734042423",
    gear = "7734053495",
    globe = "7734053426",
    discord = "7733992732",
    users = "7743876054",
    cart = "7733770755",
    file = "7733764083",
    monitor = "7733774602",
    palette = "7733674319",
    bell = "7733964719",
    activity = "7733674319",
    cpu = "7733674319",
    gamepad = "7734052758",
    list = "7733970318",
    plus = "7733715400",
    minus = "7743878496",
    -- Expanded Oxide-style semantic icon set.
    menu = "10734896206",
    grid = "10734950309",
    sliders = "10734897102",
    swords = "10747384394",
    sword = "10747384394",
    crosshair = "10723434538",
    aim = "10723434538",
    fire = "10723415285",
    flame = "10723415285",
    star = "10734924532",
    sparkle = "10723422246",
    user = "10747387118",
    person = "77052607579460",
    team = "10747387298",
    group = "10747387298",
    visible = "10709790644",
    render = "10709790644",
    esp = "10709790644",
    eyeoff = "10709790497",
    hidden = "10709790497",
    world = "10709778567",
    compass = "10709790373",
    map = "84513890895579",
    arrows = "10723422998",
    heart = "10723415389",
    alert = "10723345067",
    warning = "10747387522",
    lock = "10723417148",
    unlock = "10723422607",
    folder = "10709791437",
    save = "10709791258",
    clipboard = "10709751190",
    play = "10723422607",
    volume = "10723421745",
    camera = "10709778567",
    clock = "10723345037",
    time = "10723345037",
    code = "10709751190",
    terminal = "10709751190",
    bug = "10723415903",
    layers = "10723417148",
    inventory = "14118896735",
    backpack = "10723415285",
    gift = "10723415389",
    gem = "10723421745",
    coin = "13522871708",
    skull = "10747384394",
    teleport = "10090587519",
    running = "10723422998",
    favorite = "10734924532",
    -- Friendly aliases used by the reference example. Keeping these mapped
    -- avoids a blank ImageLabel when a script uses a semantic icon name.
    utilities = "7734058803",
    configs = "7733764083",
    marketplace = "7733770755",
    shop = "7733770755",
    speed = "7733674319",
    timer = "10723345037",
    contrast = "7733674319",
    sun = "10734924532",
}

-- Deterministic text glyphs keep semantic icons readable when an executor cannot
-- load a Roblox image asset. They are deliberately neutral symbols, not emoji.
local ICON_FALLBACKS = {
    dashboard = "▦", home = "⌂", player = "♙", person = "♙", user = "♙",
    world = "◇", globe = "◎", eye = "◉", eyeoff = "⊘", visible = "◉",
    utilities = "⌁", wrench = "⌁", configs = "▤", folder = "▱", shop = "◇",
    cart = "◇", marketplace = "◇", running = "↗", speed = "⌁", arrows = "↟",
    move = "↝", shield = "⬡", star = "✦", sparkle = "✦", clock = "◷",
    time = "◷", grid = "▦", save = "↓", download = "↓", upload = "↑",
    refresh = "↻", server = "□", settings = "⚙", gear = "⚙", power = "◌",
    check = "✓", x = "×", plus = "+", minus = "−", bolt = "ϟ", teleport = "↗",
    timer = "◷", discord = "◇", palette = "◈", layers = "▥", contrast = "◐",
    info = "i", alert = "!", warning = "!", search = "⌕", copy = "▣",
}

local function copyTheme(theme)
    local result = {}
    for key, value in pairs(DEFAULT_THEME) do result[key] = value end
    for key, value in pairs(theme or {}) do result[key] = value end
    return result
end

local function normalizeTheme(theme, base)
    local result = copyTheme(base or {})
    for key, value in pairs(theme or {}) do result[key] = value end
    -- Accept common names used by other Roblox UI libraries as aliases.
    if theme and theme.Panel and theme.Surface == nil then result.Surface = theme.Panel end
    if theme and theme.Row and theme.Surface2 == nil then result.Surface2 = theme.Row end
    if theme and theme.TextMain and theme.Text == nil then result.Text = theme.TextMain end
    if theme and theme.TextSub and theme.SubText == nil then result.SubText = theme.TextSub end
    if theme and theme.AccentLightYellow and theme.Accent == nil then result.Accent = theme.AccentLightYellow end
    if theme and theme.KnobAccent and theme.Accent2 == nil then result.Accent2 = theme.KnobAccent end
    if theme and theme.RedCancel and theme.Danger == nil then result.Danger = theme.RedCancel end
    if theme and theme.GreenActive and theme.Success == nil then result.Success = theme.GreenActive end
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

local function imageSource(value, assetFolder)
    if type(value) == "table" then
        value = value.Image or value.Asset or value.Id or value.Source
    end
    local source = asset(value)
    if not source then return nil end
    if source:find("://", 1, true) then return source end
    local candidates = { source }
    if assetFolder and tostring(assetFolder) ~= "" then
        local root = tostring(assetFolder):gsub("[\\/]+$", "")
        table.insert(candidates, 1, root .. "/" .. source)
        table.insert(candidates, 2, root .. "\\" .. source)
    end
    for _, candidate in ipairs(candidates) do
        if type(getcustomasset) == "function" then
            local ok, custom = pcall(getcustomasset, candidate)
            if ok and custom then return custom end
        end
        if type(getsynasset) == "function" then
            local ok, custom = pcall(getsynasset, candidate)
            if ok and custom then return custom end
        end
    end
    -- A bare local filename cannot be assigned to ImageLabel.Image. Return nil
    -- so controls can render their deterministic fallback instead of becoming
    -- a silent blank square.
    return nil
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
    local props = properties or {}
    for key, value in pairs(props) do
        pcall(function() instance[key] = value end)
    end
    -- ScreenGui uses Global ZIndex in this library. In that mode a parent's
    -- ZIndex is not inherited by its children; without this small inheritance
    -- rule a sidebar can render as a blank panel behind the next sibling.
    if parent and instance:IsA("GuiObject") then
        pcall(function()
            local parentZ = parent:IsA("GuiObject") and tonumber(parent.ZIndex) or 0
            if parentZ and parentZ > 0 then
                local ownZ = tonumber(instance.ZIndex) or 0
                if props.ZIndex == nil or ownZ <= parentZ then
                    instance.ZIndex = parentZ + 1 + math.max(0, ownZ)
                end
            end
        end)
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
    local config = type(value) == "table" and value or nil
    local source = config and (config.Image or config.Asset or config.Id or config.Source) or value
    local image = imageSource(source, ACTIVE_ASSET_FOLDER)
    if image then
        local imageLabel = new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = image,
            ImageColor3 = (config and config.Color) or tint or Color3.new(1, 1, 1),
            Size = UDim2.fromOffset((config and config.Size) or size or 18, (config and config.Size) or size or 18),
            ScaleType = (config and config.ScaleType) or Enum.ScaleType.Fit,
        }, parent)
        if config and config.ImageRectOffset then imageLabel.ImageRectOffset = config.ImageRectOffset end
        if config and config.ImageRectSize then imageLabel.ImageRectSize = config.ImageRectSize end
        -- Image assets can be blocked by the current game or executor. Keep
        -- the returned ImageLabel API-compatible, but reveal a readable glyph
        -- in the same slot when Roblox raises ImageFailed.
        local sourceText = string.lower(tostring(source or ""))
        local imageFallback = config and config.Fallback or ICON_FALLBACKS[sourceText] or (sourceText:find("logo", 1, true) and "✦") or "◇"
        local fallbackLabel = textLabel(parent, imageFallback, size or 18, tint or Color3.new(1, 1, 1), true)
        fallbackLabel.Visible = false
        fallbackLabel.TextXAlignment = Enum.TextXAlignment.Center
        fallbackLabel.TextYAlignment = Enum.TextYAlignment.Center
        fallbackLabel.Position = imageLabel.Position
        fallbackLabel.Size = imageLabel.Size
        fallbackLabel.ZIndex = (tonumber(imageLabel.ZIndex) or 0) + 1
        local function syncFallback()
            if not imageLabel.Parent or not fallbackLabel.Parent then return end
            fallbackLabel.Position = imageLabel.Position
            fallbackLabel.Size = imageLabel.Size
            fallbackLabel.ZIndex = (tonumber(imageLabel.ZIndex) or 0) + 1
        end
        pcall(function()
            imageLabel:GetPropertyChangedSignal("Position"):Connect(syncFallback)
            imageLabel:GetPropertyChangedSignal("Size"):Connect(syncFallback)
            imageLabel:GetPropertyChangedSignal("ZIndex"):Connect(syncFallback)
            imageLabel.ImageFailed:Connect(function()
                imageLabel.Visible = false
                fallbackLabel.Visible = true
            end)
        end)
        return imageLabel
    end
    local fallback = config and config.Fallback
    if not fallback then
        local sourceText = string.lower(tostring(source or ""))
        fallback = ICON_FALLBACKS[sourceText] or (sourceText:find("logo", 1, true) and "✦") or "◇"
    end
    return textLabel(parent, fallback, size or 18, tint or Color3.new(1, 1, 1), true)
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

local function keyName(value)
    if typeof(value) == "EnumItem" then return value.Name end
    local text = tostring(value or "None")
    return text:gsub("^Enum%.[^.]+%.", "")
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

function AxelUI:_registerFlag(flag, handle)
    if not flag or tostring(flag) == "" or not handle then return end
    self._flags[tostring(flag)] = handle
    handle.Flag = tostring(flag)
end

function AxelUI:_makeRow(parent, data, height)
    data = data or {}
    local rowHeight = height or 38
    if data.Description and rowHeight < 46 then rowHeight = 46 end
    local row = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = data.Primary and self.Theme.Accent or self.Theme.Surface2,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, rowHeight),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(row, 8)
    local rowStroke = stroke(row, data.Primary and self.Theme.Accent2 or self.Theme.Border, 0.4, 1)
    new("UIGradient", {
        Color = ColorSequence.new(data.Primary and self.Theme.Accent or self.Theme.Surface2, data.Primary and self.Theme.Accent2 or self.Theme.Element),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, data.Primary and 0.02 or 0.04), NumberSequenceKeypoint.new(1, 0.22) }),
        Rotation = 0,
    }, row)
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
    local title = textLabel(inner, data.Name or "Element", 13, data.Primary and self.Theme.Background or self.Theme.Text, true)
    title.Size = UDim2.new(1, -145 - textOffset, 0, data.Description and 17 or 26)
    title.Position = UDim2.fromOffset(textOffset, data.Description and 0 or 0)
    if data.Description then
        local description = textLabel(inner, data.Description, 10, data.Primary and self.Theme.Background or self.Theme.SubText, false)
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
        tween(row, { BackgroundColor3 = data.Primary and self.Theme.Accent or self.Theme.Surface2 }, 0.18)
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
    if tab.TabStroke then
        tween(tab.TabStroke, { Transparency = active and 0.05 or 0.9, Color = active and self.Theme.Accent or self.Theme.Border }, 0.18)
    end
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
    if self.TabHeader then self.TabHeader.Visible = tab.HideHeader ~= true end
    if tab.LayoutPills then tab:LayoutPills() end
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

function AxelUI:SetMaximized(value)
    if self._destroyed or not self.Window or self.IsMobile then return end
    value = value == true
    if value then
        self._restoreSize = self.Window.Size
        self.Window.Size = UDim2.new(1, -32, 1, -32)
    else
        self.Window.Size = self._restoreSize or self.DesktopSize or UDim2.fromOffset(926, 616)
    end
    self._maximized = value
    self:_applyResponsive()
end

function AxelUI:SetToggleKeybind(key)
    self.ToggleKeybind = key or Enum.KeyCode.RightControl
end

local function sameColor(a, b)
    return a and b and math.abs(a.R - b.R) < 0.001 and math.abs(a.G - b.G) < 0.001 and math.abs(a.B - b.B) < 0.001
end

function AxelUI:SetTheme(theme)
    if not self.Gui then
        self._pendingTheme = normalizeTheme(theme, self._pendingTheme)
        return self
    end
    local old = self.Theme or copyTheme()
    local nextTheme = normalizeTheme(theme, old)
    local palette = {
        { old.Background, nextTheme.Background }, { old.Surface, nextTheme.Surface },
        { old.Surface2, nextTheme.Surface2 }, { old.Element, nextTheme.Element },
        { old.ElementHover, nextTheme.ElementHover }, { old.Border, nextTheme.Border },
        { old.Text, nextTheme.Text }, { old.SubText, nextTheme.SubText },
        { old.Muted, nextTheme.Muted }, { old.Accent, nextTheme.Accent },
        { old.Accent2, nextTheme.Accent2 }, { old.Success, nextTheme.Success },
        { old.Warning, nextTheme.Warning }, { old.Danger, nextTheme.Danger },
    }
    self.Theme = nextTheme
    for _, object in ipairs(self.Gui:GetDescendants()) do
        for _, pair in ipairs(palette) do
            local before, after = pair[1], pair[2]
            pcall(function()
                if object:IsA("GuiObject") and sameColor(object.BackgroundColor3, before) then object.BackgroundColor3 = after end
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                    if sameColor(object.TextColor3, before) then object.TextColor3 = after end
                end
                if object:IsA("ImageLabel") or object:IsA("ImageButton") then
                    if sameColor(object.ImageColor3, before) then object.ImageColor3 = after end
                end
                if object:IsA("UIStroke") and sameColor(object.Color, before) then object.Color = after end
            end)
        end
    end
    pcall(function() self.Window.BackgroundColor3 = self.Theme.Background end)
    pcall(function() self.GlowStroke.Color = self.Theme.Accent end)
    return self
end

function AxelUI:GetTheme()
    return copyTheme(self.Theme or self._pendingTheme)
end

function AxelUI:SetBackground(source, transparency, scaleType)
    if not self.Gui or not self.Window then return nil end
    local image = imageSource(source, self.AssetFolder)
    if not image then return self:ClearBackground() end
    if not self.BackgroundImage then
        self.BackgroundImage = new("ImageLabel", {
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = 0,
        }, self.Window)
    end
    self.BackgroundImage.Image = image
    self.BackgroundImage.ImageTransparency = tonumber(transparency) or 0.72
    self.BackgroundImage.ScaleType = scaleType or Enum.ScaleType.Crop
    return self.BackgroundImage
end

function AxelUI:ClearBackground()
    if self.BackgroundImage then
        self.BackgroundImage:Destroy()
        self.BackgroundImage = nil
    end
end

local function cleanConfigName(name)
    local value = tostring(name or "default"):gsub("[^%w%-%_]", "_")
    return value == "" and "default" or value
end

local function configPath(window, name)
    local folder = tostring(window.ConfigFolder or "AxelUIConfigs")
    return folder .. "/" .. cleanConfigName(name) .. ".json"
end

function AxelUI:_saveConfig(name)
    if type(writefile) ~= "function" then return false, "writefile is unavailable" end
    local folder = tostring(self.ConfigFolder or "AxelUIConfigs")
    pcall(function()
        if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder(folder)) then makefolder(folder) end
    end)
    local values = {}
    for flag, handle in pairs(self._flags or {}) do
        if handle and type(handle.Get) == "function" then
            local ok, value = pcall(handle.Get, handle)
            if ok and (type(value) == "boolean" or type(value) == "number" or type(value) == "string" or type(value) == "table") then
                values[flag] = value
            end
        end
    end
    local okEncode, encoded = pcall(function() return HttpService:JSONEncode(values) end)
    if not okEncode then return false, tostring(encoded) end
    local okWrite, err = pcall(writefile, configPath(self, name), encoded)
    return okWrite, okWrite and nil or tostring(err)
end

function AxelUI:_loadConfig(name)
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return false, "readfile/isfile is unavailable" end
    local path = configPath(self, name)
    local exists = false
    pcall(function() exists = isfile(path) == true end)
    if not exists then return false, "config does not exist" end
    local okRead, content = pcall(readfile, path)
    if not okRead then return false, tostring(content) end
    local okDecode, values = pcall(function() return HttpService:JSONDecode(content) end)
    if not okDecode or type(values) ~= "table" then return false, "invalid config data" end
    for flag, value in pairs(values) do
        local handle = self._flags and self._flags[tostring(flag)]
        if handle and type(handle.Set) == "function" then pcall(handle.Set, handle, value, true) end
    end
    return true
end

function AxelUI:_listConfigs()
    if type(listfiles) ~= "function" then return {} end
    local result = {}
    local folder = tostring(self.ConfigFolder or "AxelUIConfigs")
    pcall(function()
        for _, path in ipairs(listfiles(folder)) do
            local name = tostring(path):match("([^/\\]+)%.json$")
            if name then table.insert(result, name) end
        end
    end)
    table.sort(result)
    return result
end

function AxelUI:SaveConfig(name)
    local target = self.Gui and self or self._activeWindow
    if target then return target:_saveConfig(name) end
    return false, "no active window"
end

function AxelUI:LoadConfig(name)
    local target = self.Gui and self or self._activeWindow
    if target then return target:_loadConfig(name) end
    return false, "no active window"
end

function AxelUI:ListConfigs()
    local target = self.Gui and self or self._activeWindow
    return target and target:_listConfigs() or {}
end

function AxelUI:DeleteConfig(name)
    local target = self.Gui and self or self._activeWindow
    if not target or type(delfile) ~= "function" then return false, "delfile is unavailable" end
    local ok, err = pcall(delfile, configPath(target, name))
    return ok, ok and nil or tostring(err)
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
        self.Header.Position = UDim2.fromOffset(64, 0)
        self.Header.Size = UDim2.new(1, -64, 0, 50)
        self.Sidebar.Position = UDim2.fromOffset(0, 0)
        self.Sidebar.Size = UDim2.new(0, 64, 1, 0)
        self.PageHolder.Position = UDim2.fromOffset(64, 50)
        self.PageHolder.Size = UDim2.new(1, -64, 1, -50)
        self.NavTitle.Visible = false
        self.Footer.Visible = false
        self.ProfileCard.Visible = false
        self.Brand.Visible = false
        self.HeaderSubtitle.Visible = false
        self.FpsText.Visible = false
        self.StatusDot.Visible = false
        self.StatusText.Visible = false
        self.Search.Position = UDim2.fromOffset(8, 9)
        self.Search.Size = UDim2.new(1, -48, 0, 32)
        self.SearchIcon.Position = UDim2.new(1, -30, 0, 18)
        self.TabTitle.TextSize = 13
        self.TabSubtitle.Visible = false
        self.TabHeader.Size = UDim2.new(1, 0, 0, 38)
        self.TabTitle.Position = UDim2.fromOffset(12, 8)
        self.TouchButton.Visible = true
        self.NotificationHolder.Size = UDim2.fromOffset(220, 0)
        self.NotificationHolder.Position = UDim2.new(1, -10, 0, 58)
    else
        if not self._maximized then self.Window.Size = self.DesktopSize or UDim2.fromOffset(926, 616) end
        self.Header.Position = UDim2.fromOffset(170, 0)
        self.Header.Size = UDim2.new(1, -170, 0, 58)
        self.Sidebar.Position = UDim2.fromOffset(0, 0)
        self.Sidebar.Size = UDim2.new(0, 170, 1, 0)
        self.PageHolder.Position = UDim2.fromOffset(170, 58)
        self.PageHolder.Size = UDim2.new(1, -170, 1, -58)
        self.NavTitle.Visible = true
        self.Footer.Visible = true
        self.ProfileCard.Visible = true
        self.Brand.Visible = true
        self.HeaderSubtitle.Visible = true
        self.FpsText.Visible = true
        self.StatusDot.Visible = true
        self.StatusText.Visible = true
        self.Search.Position = UDim2.fromOffset(20, 14)
        self.Search.Size = UDim2.fromOffset(374, 34)
        self.SearchIcon.Position = UDim2.fromOffset(368, 23)
        self.TabTitle.TextSize = 15
        self.TabSubtitle.Visible = true
        self.TabHeader.Size = UDim2.new(1, 0, 0, 46)
        self.TabTitle.Position = UDim2.fromOffset(18, 5)
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
        if tab.Hero and tab.PageBody and not tab.SubTabBar then
            local heroHeight = mobile and (tab.HeroMobileHeight or tab.HeroHeight or 104) or (tab.HeroHeight or 104)
            local heroTop = tab.HideHeader and (mobile and 12 or 14) or 50
            tab.Hero.Size = UDim2.new(1, mobile and -16 or -26, 0, heroHeight)
            tab.Hero.Position = UDim2.fromOffset(mobile and 8 or 13, heroTop)
            if tab.HeroWelcome and tab.HeroBanner then
                if mobile then
                    local welcomeHeight = math.min(82, math.max(68, heroHeight * 0.36))
                    tab.HeroWelcome.Position = UDim2.fromOffset(8, 0)
                    tab.HeroWelcome.Size = UDim2.new(1, -16, 0, welcomeHeight)
                    tab.HeroBanner.Position = UDim2.fromOffset(8, welcomeHeight + 4)
                    tab.HeroBanner.Size = UDim2.new(1, -16, 1, -(welcomeHeight + 4))
                else
                    tab.HeroWelcome.Position = UDim2.fromOffset(0, 0)
                    tab.HeroWelcome.Size = UDim2.new(0.35, 0, 1, 0)
                    tab.HeroBanner.Position = UDim2.new(0.35, 8, 0, 0)
                    tab.HeroBanner.Size = UDim2.new(0.65, -8, 1, 0)
                end
            end
            tab.PageBody.Position = UDim2.fromOffset(mobile and 8 or 13, heroTop + heroHeight + 10)
            tab.PageBody.Size = UDim2.new(1, mobile and -16 or -26, 1, -(heroTop + heroHeight + 20))
        end
        if tab.ColumnLayout then
            tab.ColumnLayout.FillDirection = mobile and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
            tab.ColumnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            tab.ColumnLayout.Padding = UDim.new(0, mobile and 8 or 10)
        end
        if tab.LeftBody then tab.LeftBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
        if tab.RightBody then tab.RightBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
        if tab.SubTabBar then
            local heroHeight = tab.Hero and (mobile and (tab.HeroMobileHeight or tab.HeroHeight or 104) or (tab.HeroHeight or 104)) or 0
            local heroTop = tab.HideHeader and (mobile and 12 or 14) or 50
            local pillY = heroHeight > 0 and (heroTop + heroHeight + 10) or 50
            tab.SubTabBar.Position = UDim2.fromOffset(mobile and 8 or 13, pillY)
            tab.SubTabBar.Size = UDim2.new(1, mobile and -16 or -26, 0, 30)
        end
        for _, subtab in ipairs(tab.SubTabs or {}) do
            if subtab.PageBody then
                local heroHeight = tab.Hero and (mobile and (tab.HeroMobileHeight or tab.HeroHeight or 104) or (tab.HeroHeight or 104)) or 0
                local heroTop = tab.HideHeader and (mobile and 12 or 14) or 50
                local contentY = heroHeight > 0 and (heroTop + heroHeight + 54) or 86
                local contentBottom = heroHeight > 0 and (heroTop + heroHeight + 64) or 96
                subtab.PageBody.Position = UDim2.fromOffset(mobile and 8 or 13, contentY)
                subtab.PageBody.Size = UDim2.new(1, mobile and -16 or -26, 1, -contentBottom)
            end
            if subtab.ColumnLayout then
                subtab.ColumnLayout.FillDirection = mobile and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
                subtab.ColumnLayout.Padding = UDim.new(0, mobile and 8 or 10)
            end
            if subtab.LeftBody then subtab.LeftBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
            if subtab.RightBody then subtab.RightBody.Size = mobile and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -5, 0, 0) end
        end
        if tab.LayoutPills then tab:LayoutPills() end
    end
end

function AxelUI:SetFont(font)
    self._font = font
    ACTIVE_FONT = font
    -- Existing elements inherit a normal Gotham fallback. New controls use the
    -- requested font. This keeps the method safe even on old executors.
end

local function preserveHeight(instance, height)
    if not instance then return end
    local size = instance.Size
    local nextHeight = math.max(0, height or 0)
    if size.Y.Scale ~= 0 or size.Y.Offset ~= nextHeight then
        instance.Size = UDim2.new(size.X.Scale, size.X.Offset, 0, nextHeight)
    end
end

local function bindVerticalLayout(window, parent, layout, extra, onSize)
    local function sync()
        local height = (layout.AbsoluteContentSize and layout.AbsoluteContentSize.Y or 0) + (extra or 0)
        preserveHeight(parent, height)
        if onSize then onSize(height) end
    end
    local function watch(child)
        if not child or not child:IsA("GuiObject") then return end
        connect(window, child:GetPropertyChangedSignal("Size"), function() task.defer(sync) end)
        connect(window, child:GetPropertyChangedSignal("Visible"), function() task.defer(sync) end)
    end
    connect(window, layout:GetPropertyChangedSignal("AbsoluteContentSize"), sync)
    connect(window, parent.ChildAdded, function(child) watch(child); task.defer(sync) end)
    connect(window, parent.ChildRemoved, function() task.defer(sync) end)
    for _, child in ipairs(parent:GetChildren()) do watch(child) end
    task.defer(sync)
    return sync
end

local function makePageColumns(window, page, topOffset)
    topOffset = topOffset or 50
    local pageBody = new("ScrollingFrame", {
        Active = true,
        AutomaticCanvasSize = Enum.AutomaticSize.None,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        ScrollBarImageColor3 = window.Theme.Accent,
        ScrollBarThickness = 3,
        Size = UDim2.new(1, -26, 1, -(topOffset + 10)),
        Position = UDim2.fromOffset(13, topOffset),
    }, page)
    pad(pageBody, 0, 5, 0, 10)
    local columns = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, 0),
    }, pageBody)
    local leftColumn = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        LayoutOrder = 1,
    }, columns)
    local rightColumn = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0.5, -5, 0, 0),
        LayoutOrder = 2,
    }, columns)
    local columnLayout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, columns)
    local leftLayout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, leftColumn)
    local rightLayout = new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, rightColumn)
    local function syncColumns()
        preserveHeight(leftColumn, leftLayout.AbsoluteContentSize.Y)
        preserveHeight(rightColumn, rightLayout.AbsoluteContentSize.Y)
        preserveHeight(columns, columnLayout.AbsoluteContentSize.Y)
        pageBody.CanvasSize = UDim2.new(0, 0, 0, columnLayout.AbsoluteContentSize.Y + 18)
    end
    connect(window, leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), syncColumns)
    connect(window, rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), syncColumns)
    connect(window, columnLayout:GetPropertyChangedSignal("AbsoluteContentSize"), syncColumns)
    connect(window, leftColumn.ChildAdded, function() task.defer(syncColumns) end)
    connect(window, leftColumn.ChildRemoved, function() task.defer(syncColumns) end)
    connect(window, rightColumn.ChildAdded, function() task.defer(syncColumns) end)
    connect(window, rightColumn.ChildRemoved, function() task.defer(syncColumns) end)
    task.defer(syncColumns)
    return pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout
end

local function makeSubTabCard(window, parent, title)
    local card = new("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, -5, 0, 0),
    }, parent)
    corner(card, 8)
    stroke(card, window.Theme.Border, 0.28, 1)
    new("UIGradient", {
        Color = ColorSequence.new(window.Theme.Surface, window.Theme.Background),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.02), NumberSequenceKeypoint.new(1, 0.16) }),
        Rotation = 90,
    }, card)
    local cardHeader = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32) }, card)
    pad(cardHeader, 12, 12, 6, 3)
    local cardTitle = textLabel(cardHeader, title, 13, window.Theme.Text, true)
    cardTitle.Size = UDim2.new(1, -10, 0, 20)
    local body = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 32),
        Size = UDim2.new(1, 0, 0, 0),
    }, card)
    pad(body, 10, 10, 2, 10)
    local layout = new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, body)
    bindVerticalLayout(window, body, layout, 12, function(height)
        preserveHeight(card, 32 + height)
    end)
    return card, body, layout
end

function AxelUI:AddTab(data)
    data = type(data) == "table" and data or { Name = data }
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
    corner(button, 9)
    local tabStroke = stroke(button, self.Theme.Border, 0.62, 1)
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
    tab.Button, tab.Title, tab.Subtitle, tab.IconHolder, tab.Icon, tab.Indicator, tab.Badge, tab.TabStroke = button, title, subtitle, iconHolder, tabIcon, indicator, badge, tabStroke

    local page = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 1, 0),
        Visible = false,
    }, self.PageHolder)
    local pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout = makePageColumns(self, page, 50)
    tab.Page, tab.Body, tab.Layout = page, leftColumn, leftLayout
    tab.Columns, tab.LeftBody, tab.RightBody = columns, leftColumn, rightColumn
    tab.PageBody = pageBody
    tab.ColumnLayout = columnLayout
    tab._nextSide = "Left"
    tab.SubTabs = {}
    table.insert(self.Tabs, tab)

    connect(self, button.MouseButton1Click, function() self:SelectTab(tab) end)
    connect(self, button.MouseEnter, function()
        if self.ActiveTab ~= tab and tab.TabStroke then tween(tab.TabStroke, { Transparency = 0.24, Color = self.Theme.Accent2 }, 0.14) end
    end)
    connect(self, button.MouseLeave, function()
        if self.ActiveTab ~= tab and tab.TabStroke then tween(tab.TabStroke, { Transparency = 0.9, Color = self.Theme.Border }, 0.16) end
    end)
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

-- Split dashboard hero: a welcome block on the left and an image banner on the
-- right, matching the reference dashboard composition without extra wrappers.
function AxelUI.TabMethods:AddHero(data)
    data = data or {}
    local height = tonumber(data.Height) or 104
    local mobileHeight = tonumber(data.MobileHeight) or math.max(226, height + 122)
    local heroTop = self.Window.IsMobile and 12 or 14
    self.HideHeader = data.HideTabHeader ~= false
    if self.Window.ActiveTab == self and self.Window.TabHeader then self.Window.TabHeader.Visible = not self.HideHeader end
    local hero = new("Frame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(13, heroTop),
        Size = UDim2.new(1, -26, 0, height),
        ClipsDescendants = true,
        ZIndex = 3,
    }, self.Page)
    local welcome = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.35, 0, 1, 0), ZIndex = 3 }, hero)
    local welcomeLabel = textLabel(welcome, data.WelcomeLabel or "Welcome to", 15, self.Window.Theme.SubText, false)
    welcomeLabel.Position = UDim2.fromOffset(8, 8); welcomeLabel.Size = UDim2.new(1, -16, 0, 22); welcomeLabel.ZIndex = 7
    local welcomeTitle = textLabel(welcome, data.WelcomeTitle or "Axel Hub", 38, self.Window.Theme.Text, true)
    welcomeTitle.Position = UDim2.fromOffset(8, 28); welcomeTitle.Size = UDim2.new(1, -12, 0, 46); welcomeTitle.TextTruncate = Enum.TextTruncate.AtEnd; welcomeTitle.ZIndex = 7
    local welcomeContent = textLabel(welcome, data.WelcomeContent or "Powerful tools. A smoother way to play.", 11, self.Window.Theme.SubText, false)
    welcomeContent.Position = UDim2.fromOffset(8, 76); welcomeContent.Size = UDim2.new(1, -12, 0, 20); welcomeContent.TextWrapped = true; welcomeContent.ZIndex = 7

    local banner = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Position = UDim2.new(0.35, 8, 0, 0),
        Size = UDim2.new(0.65, -8, 1, 0),
        ClipsDescendants = true,
        ZIndex = 3,
    }, hero)
    corner(banner, 11); stroke(banner, self.Window.Theme.Border, 0.14, 1)
    local source = imageSource(data.Image or data.Source or data.Asset, self.Window.AssetFolder)
    banner.BackgroundColor3 = source and self.Window.Theme.Element or Color3.fromRGB(61, 45, 24)
    new("UIGradient", { Color = source and ColorSequence.new(self.Window.Theme.Element, self.Window.Theme.Surface) or ColorSequence.new(Color3.fromRGB(107, 71, 26), self.Window.Theme.Background), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, source and 0.02 or 0.08), NumberSequenceKeypoint.new(1, source and 0.12 or 0.24) }), Rotation = 25 }, banner)
    local picture = new("ImageLabel", { BackgroundTransparency = 1, Image = source or "", ImageTransparency = tonumber(data.ImageTransparency) or 0.08, ScaleType = data.ScaleType or Enum.ScaleType.Crop, Size = UDim2.fromScale(1, 1), ZIndex = 4 }, banner)
    local shade = new("Frame", { BackgroundColor3 = self.Window.Theme.Background, BackgroundTransparency = source and 0.28 or 0.04, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, banner)
    new("UIGradient", { Color = ColorSequence.new(self.Window.Theme.Background, self.Window.Theme.Element), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.04), NumberSequenceKeypoint.new(0.58, 0.22), NumberSequenceKeypoint.new(1, 0.78) }), Rotation = 0 }, shade)
    local fallback = textLabel(banner, data.FallbackText or "AXEL HUB", 11, source and self.Window.Theme.Muted or self.Window.Theme.Accent2, true)
    fallback.AnchorPoint = Vector2.new(0.5, 0.5); fallback.Position = UDim2.fromScale(0.72, 0.5); fallback.Size = UDim2.fromOffset(150, 18); fallback.TextXAlignment = Enum.TextXAlignment.Center; fallback.Visible = source == nil; fallback.ZIndex = 6
    pcall(function()
        connect(self.Window, picture.ImageFailed, function() picture.Visible = false; shade.BackgroundTransparency = 0.04; fallback.Visible = true end)
    end)
    local title = textLabel(banner, data.BannerTitle or data.Title or "Customize your experience", 14, self.Window.Theme.Text, true)
    title.Position = UDim2.fromOffset(14, 13); title.Size = UDim2.new(0.62, 0, 0, 22); title.ZIndex = 7
    local content = textLabel(banner, data.Content or data.Description or "Simple. Powerful. Yours.", 10, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(14, 38); content.Size = UDim2.new(0.58, 0, 0, 26); content.TextWrapped = true; content.ZIndex = 7
    local action
    if data.Button or data.ActionText then
        action = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Window.Theme.Accent, BorderSizePixel = 0, Text = tostring(data.Button or data.ActionText), TextColor3 = self.Window.Theme.Background, TextSize = 10, FontFace = fontFace(nil, true), Size = UDim2.fromOffset(92, 27), Position = UDim2.fromOffset(14, math.max(62, height - 39)), ZIndex = 7 }, banner)
        corner(action, 8); pressAnimation(self.Window, action)
        connect(self.Window, action.MouseButton1Click, function() if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback) end) end end)
    end
    self.Hero, self.HeroWelcome, self.HeroBanner = hero, welcome, banner
    self.HeroWelcomeLabel, self.HeroWelcomeTitle, self.HeroWelcomeContent = welcomeLabel, welcomeTitle, welcomeContent
    self.HeroImage, self.HeroFallback, self.HeroHeight, self.HeroMobileHeight = picture, fallback, height, mobileHeight
    self.Window:_registerSearch(hero, tostring(data.Title or "") .. " " .. tostring(data.Content or ""))
    if self.Window.ActiveTab == self and self.Window.TabHeader then self.Window.TabHeader.Visible = not self.HideHeader end
    if self.Window._applyResponsive then self.Window:_applyResponsive() end
    return { Instance = hero, Banner = banner, Image = picture, Fallback = fallback, Title = title, Content = content, WelcomeTitle = welcomeTitle, Button = action }
end

-- Lightweight dashboard pills. Unlike AddSubTab, these are presentation tabs:
-- they keep one dashboard body intact, which is ideal for Home-style layouts
-- with a hero banner followed by two columns of cards.
function AxelUI.TabMethods:LayoutPills()
    if not self.PillBar or not self.PageBody then return end
    local mobile = self.Window.IsMobile
    local heroHeight = self.Hero and (mobile and (self.HeroMobileHeight or self.HeroHeight or 104) or (self.HeroHeight or 104)) or 0
    local heroTop = self.HideHeader and (mobile and 12 or 14) or 50
    local pillY = heroHeight > 0 and (heroTop + heroHeight + 10) or 50
    local bodyY = heroHeight > 0 and (heroTop + heroHeight + 54) or 86
    local bodyBottom = heroHeight > 0 and (heroTop + heroHeight + 64) or 96
    self.PillBar.Position = UDim2.fromOffset(mobile and 8 or 13, pillY)
    self.PillBar.Size = UDim2.new(1, mobile and -16 or -26, 0, 30)
    self.PageBody.Position = UDim2.fromOffset(mobile and 8 or 13, bodyY)
    self.PageBody.Size = UDim2.new(1, mobile and -16 or -26, 1, -bodyBottom)
end

function AxelUI.TabMethods:SelectPill(pill)
    if not pill then return end
    for _, other in ipairs(self.Pills or {}) do
        local active = other == pill
        other.Active = active
        tween(other.Button, { BackgroundColor3 = active and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
        setTextColor(other.Title, active and self.Window.Theme.Background or self.Window.Theme.SubText)
    end
    self.ActivePill = pill
    if type(pill.Callback) == "function" then
        task.spawn(function() pcall(pill.Callback, pill) end)
    end
end

function AxelUI.TabMethods:AddPill(data)
    data = type(data) == "table" and data or { Name = data }
    if not self.PillBar then
        self.PillBar = new("ScrollingFrame", {
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarThickness = 0,
            Size = UDim2.new(1, -26, 0, 30),
            Position = UDim2.fromOffset(13, 50),
            ZIndex = 3,
        }, self.Page)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }, self.PillBar)
        self.Pills = {}
    end
    local name = tostring(data.Name or data.Title or "Pill")
    local buttonWidth = math.max(70, math.min(132, #name * 7 + 28))
    local button = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        LayoutOrder = #self.Pills + 1,
        Text = name,
        TextColor3 = self.Window.Theme.SubText,
        TextSize = 10,
        FontFace = fontFace(nil, true),
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromOffset(buttonWidth, 28),
        ZIndex = 4,
    }, self.PillBar)
    corner(button, 14); stroke(button, self.Window.Theme.Border, 0.18, 1)
    local title = button
    local pill = { Tab = self, Button = button, Title = title, Name = name, Callback = data.Callback or data.callback, Active = false }
    table.insert(self.Pills, pill)
    connect(self.Window, button.MouseButton1Click, function() self:SelectPill(pill) end)
    pressAnimation(self.Window, button)
    if #self.Pills == 1 or data.Active then self:SelectPill(pill) end
    self:LayoutPills()
    return pill
end

function AxelUI.TabMethods:SelectSubTab(subtab)
    if not subtab then return end
    for _, other in ipairs(self.SubTabs or {}) do
        local active = other == subtab
        if other.PageBody then other.PageBody.Visible = active end
        if other.Button then
            tween(other.Button, { BackgroundColor3 = active and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
            setTextColor(other.Title, active and self.Window.Theme.Background or self.Window.Theme.SubText)
        end
    end
    self.ActiveSubTab = subtab
end

function AxelUI.TabMethods:AddSubTab(data)
    data = type(data) == "table" and data or { Name = data }
    local subtab = {
        Tab = self,
        Window = self.Window,
        Name = tostring(data.Name or data.Title or "Subtab"),
        Description = tostring(data.Description or data.Subtitle or ""),
        Controls = {},
        Sections = {},
    }
    setmetatable(subtab, { __index = AxelUI.SectionMethods })

    if not self.SubTabBar then
        self.SubTabBar = new("ScrollingFrame", {
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            Position = UDim2.fromOffset(13, 50),
            ScrollBarThickness = 0,
            Size = UDim2.new(1, -26, 0, 30),
            Visible = true,
        }, self.Page)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, self.SubTabBar)
    end

    local buttonWidth = math.max(92, math.min(190, #subtab.Name * 7 + 30))
    local button = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(buttonWidth, 28),
    }, self.SubTabBar)
    corner(button, 14)
    local title = textLabel(button, subtab.Name, 10, self.Window.Theme.SubText, true)
    title.Size = UDim2.new(1, -18, 1, 0)
    title.Position = UDim2.fromOffset(9, 0)
    title.TextXAlignment = Enum.TextXAlignment.Center
    subtab.Button, subtab.Title = button, title

    local pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout
    if #self.SubTabs == 0 then
        pageBody, columns, leftColumn, rightColumn, columnLayout = self.PageBody, self.Columns, self.LeftBody, self.RightBody, self.ColumnLayout
        leftLayout, rightLayout = self.Layout, self.RightBody and self.RightBody:FindFirstChildOfClass("UIListLayout")
        local heroHeight = self.Hero and (self.Window.IsMobile and (self.HeroMobileHeight or self.HeroHeight or 104) or (self.HeroHeight or 104)) or 0
        local heroTop = self.HideHeader and (self.Window.IsMobile and 12 or 14) or 50
        local contentY = heroHeight > 0 and (heroTop + heroHeight + 54) or 86
        local contentBottom = heroHeight > 0 and (heroTop + heroHeight + 64) or 96
        self.PageBody.Position = UDim2.fromOffset(13, contentY)
        self.PageBody.Size = UDim2.new(1, -26, 1, -contentBottom)
    else
        pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout = makePageColumns(self, self.Page, 86)
    end
    local card, body, layout = makeSubTabCard(self.Window, leftColumn, subtab.Name)
    subtab.PageBody, subtab.Columns = pageBody, columns
    subtab.LeftBody, subtab.RightBody = leftColumn, rightColumn
    subtab.ColumnLayout, subtab.Layout = columnLayout, layout
    subtab.Body, subtab.Card = body, card
    subtab._nextSide = "Left"
    table.insert(self.SubTabs, subtab)

    connect(self.Window, button.MouseButton1Click, function() self:SelectSubTab(subtab) end)
    pressAnimation(self.Window, button)
    if #self.SubTabs == 1 then
        self:SelectSubTab(subtab)
    else
        self:SelectSubTab(self.ActiveSubTab or self.SubTabs[1])
    end
    if self.Window._applyResponsive then self.Window:_applyResponsive() end
    return subtab
end

function AxelUI.TabMethods:AddSection(data)
    data = type(data) == "table" and data or { Name = data }
    local section = {
        Tab = self,
        Window = self.Window,
        Name = tostring(data.Name or data.Title or "Section"),
        Description = tostring(data.Description or ""),
        Controls = {},
        Collapsed = false,
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
        ClipsDescendants = true,
        Size = UDim2.new(1, -5, 0, 0),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(card, 9)
    stroke(card, self.Window.Theme.Border, 0.28, 1)
    new("UIGradient", {
        Color = ColorSequence.new(self.Window.Theme.Surface, self.Window.Theme.Background),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.02), NumberSequenceKeypoint.new(1, 0.16) }),
        Rotation = 90,
    }, card)
    local headerHeight = data.Description ~= "" and 48 or 35
    local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, headerHeight) }, card)
    pad(header, 12, 12, 8, 4)
    local title = textLabel(header, section.Name, 14, self.Window.Theme.Text, true)
    title.Size = UDim2.new(1, -52, 0, 18)
    local collapseButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Text = "-",
        TextColor3 = self.Window.Theme.Accent2,
        TextSize = 16,
        FontFace = fontFace(nil, true),
        Size = UDim2.fromOffset(24, 22),
        Position = UDim2.new(1, -34, 0, 5),
    }, header)
    corner(collapseButton, 8)
    if section.Description ~= "" then
        local description = textLabel(header, section.Description, 10, self.Window.Theme.SubText, false)
        description.Size = UDim2.new(1, -52, 0, 17)
        description.Position = UDim2.fromOffset(0, 20)
        description.TextWrapped = true
    end
    local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, headerHeight), Size = UDim2.new(1, 0, 0, 0) }, card)
    pad(body, 10, 10, 2, 6)
    local layout = new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, body)
    local syncBodyHeight
    syncBodyHeight = bindVerticalLayout(self.Window, body, layout, 12, function(height)
        if not section.Collapsed then
            preserveHeight(card, headerHeight + height)
        end
    end)
    section.Card, section.Body, section.Layout, section.Toggle = card, body, layout, collapseButton
    function section:SetCollapsed(value)
        self.Collapsed = value == true
        collapseButton.Text = self.Collapsed and "+" or "-"
        tween(collapseButton, { BackgroundColor3 = self.Collapsed and self.Window.Theme.Surface2 or self.Window.Theme.Element }, 0.16)
        if self.Collapsed then
            tween(body, { BackgroundTransparency = 1 }, 0.12)
            preserveHeight(card, headerHeight)
            task.delay(0.12, function() if body.Parent and self.Collapsed then body.Visible = false end end)
        else
            body.Visible = true
            tween(body, { BackgroundTransparency = 1 }, 0.14)
            if syncBodyHeight then syncBodyHeight() end
        end
    end
    connect(self.Window, collapseButton.MouseButton1Click, function() section:SetCollapsed(not section.Collapsed) end)
    pressAnimation(self.Window, collapseButton)
    table.insert(self.Sections, section)
    return section
end

function AxelUI.SectionMethods:AddDescription(text)
    local label = textLabel(self.Body, text, 11, self.Window.Theme.SubText, false)
    local description = tostring(text or "")
    local lines = select(2, description:gsub("\n", "\n")) + 1
    label.Size = UDim2.new(1, 0, 0, math.max(26, lines * 16))
    label.TextWrapped = true
    self.Window:_registerSearch(label, text)
    return label
end

-- Common aliases used by other Roblox UI libraries.
function AxelUI.SectionMethods:AddText(data, content)
    if content ~= nil then
        return self:AddParagraph({ Title = data, Content = content })
    end
    if type(data) == "table" and (data.Title or data.Content or data.Body) then
        data.Content = data.Content or data.Body
        return self:AddParagraph(data)
    end
    return self:AddLabel(data)
end

function AxelUI.SectionMethods:AddTextLabel(data)
    return self:AddLabel(data)
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
    local contentText = tostring(data.Content or "")
    local lineCount = select(2, contentText:gsub("\n", "\n")) + 1
    local contentHeight = tonumber(data.Height) or math.max(36, lineCount * 16, (#contentText > 90 and 52 or 0))
    local wrapper = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 19 + contentHeight) }, self.Body)
    local title = textLabel(wrapper, data.Title or data.Name or "Info", 12, self.Window.Theme.Accent2, true)
    title.Size = UDim2.new(1, 0, 0, 18)
    local content = textLabel(wrapper, data.Content or "", 11, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(0, 19)
    content.Size = UDim2.new(1, 0, 0, contentHeight)
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

function AxelUI.SectionMethods:AddBanner(data)
    data = data or {}
    local height = tonumber(data.Height) or 112
    local holder = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, height),
        ClipsDescendants = true,
    }, self.Body)
    corner(holder, 8); stroke(holder, self.Window.Theme.Border, 0.18, 1)
    local source = imageSource(data.Image or data.Source or data.Asset, self.Window.AssetFolder)
    local picture = new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = source or "",
        ImageColor3 = Color3.new(1, 1, 1),
        ImageTransparency = tonumber(data.ImageTransparency) or 0.18,
        ScaleType = data.ScaleType or Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1,
    }, holder)
    local shade = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Background,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 2,
    }, holder)
    new("UIGradient", {
        Color = ColorSequence.new(self.Window.Theme.Background, self.Window.Theme.Element),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 0.78),
        }),
        Rotation = 0,
    }, shade)
    local fallback = textLabel(holder, data.FallbackText or "Image unavailable", 10, self.Window.Theme.SubText, true)
    fallback.AnchorPoint = Vector2.new(0.5, 0.5)
    fallback.Position = UDim2.fromScale(0.5, 0.72)
    fallback.Size = UDim2.new(1, -28, 0, 18)
    fallback.TextXAlignment = Enum.TextXAlignment.Center
    fallback.ZIndex = 3
    fallback.Visible = source == nil
    pcall(function()
        connect(self.Window, picture.ImageFailed, function()
            picture.Visible = false
            shade.BackgroundTransparency = 0.08
            fallback.Visible = true
        end)
    end)
    local title = textLabel(holder, data.Title or data.Name or "Welcome", 14, self.Window.Theme.Text, true)
    title.Position = UDim2.fromOffset(14, 14); title.Size = UDim2.new(1, -28, 0, 22); title.ZIndex = 4
    local content = textLabel(holder, data.Content or data.Description or "", 10, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(14, 39); content.Size = UDim2.new(1, -170, 0, 34); content.TextWrapped = true; content.ZIndex = 4
    local action
    if data.Button or data.ActionText then
        action = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.Window.Theme.Accent,
            BorderSizePixel = 0,
            Text = tostring(data.Button or data.ActionText),
            TextColor3 = self.Window.Theme.Background,
            TextSize = 10,
            FontFace = fontFace(nil, true),
            Size = UDim2.fromOffset(112, 28),
            Position = UDim2.new(1, -126, 0.5, -14),
            ZIndex = 4,
        }, holder)
        corner(action, 7); pressAnimation(self.Window, action)
        connect(self.Window, action.MouseButton1Click, function()
            if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback) end) end
        end)
    end
    self.Window:_registerSearch(holder, tostring(data.Title or "") .. " " .. tostring(data.Content or ""))
    return { Instance = holder, Image = picture, Fallback = fallback, Title = title, Content = content, Button = action }
end

AxelUI.SectionMethods.AddHero = AxelUI.SectionMethods.AddBanner

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
    local source = imageSource(data.Image or data.Source or data.Asset, self.Window.AssetFolder)
    local picture = new("ImageLabel", {
        BackgroundTransparency = 1,
        Image = source or "",
        ImageColor3 = data.Tint or Color3.new(1, 1, 1),
        ScaleType = data.ScaleType or Enum.ScaleType.Fit,
        Size = UDim2.new(1, -12, 1, data.Caption and -30 or -12),
        Position = UDim2.fromOffset(6, 6),
        ZIndex = 1,
    }, holder)
    corner(picture, 5)
    local fallback = textLabel(holder, data.FallbackText or "Image unavailable", 10, self.Window.Theme.SubText, true)
    fallback.AnchorPoint = Vector2.new(0.5, 0.5)
    fallback.Position = UDim2.fromScale(0.5, data.Caption and 0.44 or 0.5)
    fallback.Size = UDim2.new(1, -24, 0, 18)
    fallback.TextXAlignment = Enum.TextXAlignment.Center
    fallback.ZIndex = 2
    fallback.Visible = source == nil
    pcall(function()
        connect(self.Window, picture.ImageFailed, function()
            picture.Visible = false
            fallback.Visible = true
        end)
    end)
    if data.Caption then
        local caption = textLabel(holder, data.Caption, 10, self.Window.Theme.SubText, false)
        caption.Position = UDim2.new(0, 8, 1, -24)
        caption.Size = UDim2.new(1, -16, 0, 18)
        caption.TextXAlignment = Enum.TextXAlignment.Center
    end
    self.Window:_registerSearch(holder, tostring(data.Caption or data.Name or "Image"))
    return { Instance = holder, Image = picture, Fallback = fallback }
end

function AxelUI.SectionMethods:AddButton(data)
    data = data or {}
    data.Icon = data.Icon or "check"
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

-- Compact horizontal actions used by dashboard footers and quick-action cards.
-- It keeps the reference layout dense while preserving normal Button callbacks.
function AxelUI.SectionMethods:AddActionBar(data)
    data = data or {}
    local actions = data.Actions or data.Items or {}
    local bar = new("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, 0, 0, tonumber(data.Height) or 32),
        LayoutOrder = data.LayoutOrder or 0,
    }, self.Body)
    local layout = new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        Padding = UDim.new(0, tonumber(data.Gap) or 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, bar)
    local handles = {}
    local count = math.max(1, #actions)
    for index, item in ipairs(actions) do
        item = type(item) == "table" and item or { Name = item }
        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = item.Primary and self.Window.Theme.Accent or self.Window.Theme.Element,
            BorderSizePixel = 0,
            LayoutOrder = index,
            Text = tostring(item.Name or item.Title or "Action"),
            TextColor3 = item.Primary and self.Window.Theme.Background or self.Window.Theme.Text,
            TextSize = tonumber(item.TextSize) or 10,
            FontFace = fontFace(nil, item.Bold ~= false),
            Size = UDim2.new(1 / count, -((tonumber(data.Gap) or 6) * (count - 1) / count), 0, tonumber(data.Height) or 32),
        }, bar)
        corner(button, 8); stroke(button, item.Primary and self.Window.Theme.Accent2 or self.Window.Theme.Border, 0.24, 1)
        pressAnimation(self.Window, button)
        connect(self.Window, button.MouseButton1Click, function()
            if type(item.Callback or item.callback) == "function" then task.spawn(function() pcall(item.Callback or item.callback) end) end
        end)
        handles[index] = { Instance = button, Button = button, Name = button.Text }
    end
    table.insert(self.Controls, handles)
    return { Instance = bar, Layout = layout, Buttons = handles }
end

function AxelUI.SectionMethods:AddToggle(data)
    data = data or {}
    data.Icon = data.Icon or "power"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local track = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Element,
        Size = UDim2.fromOffset(40, 20),
        Position = UDim2.new(1, -50, 0.5, -10),
        ZIndex = 8,
    }, inner)
    corner(track, 10)
    local knob = new("Frame", { BackgroundColor3 = self.Window.Theme.Muted, Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(3, 3), ZIndex = 9 }, track)
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
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddSlider(data)
    data = data or {}
    data.Icon = data.Icon or "chart"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 46)
    local minimum, maximum = tonumber(data.Min or data.Minimum) or 0, tonumber(data.Max or data.Maximum) or 100
    local value = math.clamp(tonumber(data.Default) or minimum, minimum, maximum)
    local valueText = textLabel(inner, "", 10, self.Window.Theme.Accent2, true)
    valueText.Size = UDim2.fromOffset(100, 18)
    valueText.Position = UDim2.new(1, -108, 0, 0)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.ZIndex = 8
    local bar = new("Frame", { BackgroundColor3 = self.Window.Theme.Element, Size = UDim2.new(1, -8, 0, 5), Position = UDim2.new(0, 0, 1, -11), ZIndex = 8 }, inner)
    corner(bar, 4)
    local fill = new("Frame", { BackgroundColor3 = self.Window.Theme.Accent, Size = UDim2.new(0, 0, 1, 0), ZIndex = 9 }, bar)
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
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddDropdown(data)
    data = data or {}
    data.Icon = data.Icon or "chevron"
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
        ZIndex = 8,
    }, inner)
    corner(selector, 5)
    local popup
    local handle = { Value = selected, Row = row }
    local function close()
        if popup then popup:Destroy(); popup = nil end
        if self.Window._dropdownClose == close then self.Window._dropdownClose = nil end
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
        self.Window._dropdownClose = close
    end
    function handle:Set(value, silent)
        self.Value = value; selector.Text = tostring(value or "Select")
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, value) end) end
    end
    function handle:Get() return self.Value end
    connect(self.Window, selector.MouseButton1Click, open)
    pressAnimation(self.Window, selector)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddMultiDropdown(data)
    data = data or {}
    data.Icon = data.Icon or "chevron"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local options = data.Options or data.Items or {}
    local selected = {}
    local selectedSet = {}
    local function setValues(values)
        selected = {}
        selectedSet = {}
        if type(values) == "table" then
            for _, value in ipairs(values) do
                local text = tostring(value)
                if not selectedSet[text] then
                    selectedSet[text] = true
                    table.insert(selected, value)
                end
            end
        elseif values ~= nil and tostring(values) ~= "" then
            selectedSet[tostring(values)] = true
            table.insert(selected, values)
        end
    end
    setValues(data.Default or {})
    local function displayValue()
        if #selected == 0 then return "None" end
        local parts = {}
        for _, value in ipairs(selected) do table.insert(parts, tostring(value)) end
        local text = table.concat(parts, ", ")
        return #text > 22 and text:sub(1, 19) .. "..." or text
    end
    local selector = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Text = displayValue(),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 11,
        FontFace = fontFace(nil, false),
        Size = UDim2.fromOffset(155, 25),
        Position = UDim2.new(1, -165, 0.5, -12),
        TextTruncate = Enum.TextTruncate.AtEnd,
        ZIndex = 8,
    }, inner)
    corner(selector, 5)
    local popup
    local optionButtons = {}
    local handle = { Value = selected, Row = row }
    local function close()
        if popup then popup:Destroy(); popup = nil end
        optionButtons = {}
        if self.Window._dropdownClose == close then self.Window._dropdownClose = nil end
    end
    local function refreshButtons()
        for value, button in pairs(optionButtons) do
            if button and button.Parent then
                button.Text = (selectedSet[tostring(value)] and "ON  " or "OFF  ") .. tostring(value)
                button.BackgroundColor3 = selectedSet[tostring(value)] and self.Window.Theme.ElementHover or self.Window.Theme.Surface2
            end
        end
    end
    local function open()
        close()
        popup = new("Frame", {
            BackgroundColor3 = self.Window.Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(175, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 60,
        }, self.Window.Gui)
        corner(popup, 7); stroke(popup, self.Window.Theme.Border, 0.05, 1); pad(popup, 4, 4, 4, 4)
        popup.Position = UDim2.fromOffset(selector.AbsolutePosition.X, selector.AbsolutePosition.Y + selector.AbsoluteSize.Y + 4)
        new("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
        for _, option in ipairs(options) do
            local value = tostring(option)
            local optionButton = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = selectedSet[value] and self.Window.Theme.ElementHover or self.Window.Theme.Surface2,
                BorderSizePixel = 0,
                Text = (selectedSet[value] and "ON  " or "OFF  ") .. value,
                TextColor3 = self.Window.Theme.Text,
                TextSize = 11,
                FontFace = fontFace(nil, false),
                Size = UDim2.new(1, 0, 0, 25),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
            }, popup)
            corner(optionButton, 4)
            optionButtons[value] = optionButton
            connect(self.Window, optionButton.MouseButton1Click, function()
                if selectedSet[value] then
                    selectedSet[value] = nil
                    for index, item in ipairs(selected) do
                        if tostring(item) == value then table.remove(selected, index); break end
                    end
                else
                    selectedSet[value] = true
                    table.insert(selected, option)
                end
                selector.Text = displayValue()
                refreshButtons()
                if type(data.Callback or data.callback) == "function" then
                    task.spawn(function() pcall(data.Callback or data.callback, selected) end)
                end
            end)
        end
        self.Window._dropdownClose = close
    end
    function handle:Set(values, silent)
        setValues(values)
        self.Value = selected
        selector.Text = displayValue()
        refreshButtons()
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, selected) end)
        end
    end
    function handle:Get()
        local result = {}
        for index, value in ipairs(selected) do result[index] = value end
        return result
    end
    connect(self.Window, selector.MouseButton1Click, open)
    pressAnimation(self.Window, selector)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddColorPicker(data)
    data = data or {}
    data.Icon = data.Icon or "chart"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local initial = typeof(data.Default) == "Color3" and data.Default or self.Window.Theme.Accent
    local swatch = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = initial,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(34, 22),
        Position = UDim2.new(1, -44, 0.5, -11),
        ZIndex = 8,
    }, inner)
    corner(swatch, 7); stroke(swatch, self.Window.Theme.Border, 0.15, 1)
    local popup
    local handle = { Value = initial, Row = row }
    local palette = {
        self.Window.Theme.Accent, self.Window.Theme.Accent2, self.Window.Theme.Success,
        self.Window.Theme.Warning, self.Window.Theme.Danger, self.Window.Theme.Text,
        Color3.fromRGB(116, 96, 255), Color3.fromRGB(62, 196, 214),
    }
    local function close()
        if popup then popup:Destroy(); popup = nil end
        if self.Window._dropdownClose == close then self.Window._dropdownClose = nil end
    end
    local function choose(color)
        handle.Value = color
        swatch.BackgroundColor3 = color
        close()
        if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, color) end) end
    end
    local function open()
        close()
        popup = new("Frame", {
            BackgroundColor3 = self.Window.Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.fromOffset(170, 82),
            ZIndex = 70,
        }, self.Window.Gui)
        corner(popup, 7); stroke(popup, self.Window.Theme.Border, 0.05, 1); pad(popup, 8, 8, 8, 8)
        popup.Position = UDim2.fromOffset(swatch.AbsolutePosition.X - 118, swatch.AbsolutePosition.Y + swatch.AbsoluteSize.Y + 4)
        local grid = new("UIGridLayout", { CellPadding = UDim2.fromOffset(6, 6), CellSize = UDim2.fromOffset(26, 26), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
        for _, color in ipairs(palette) do
            local colorButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = color, BorderSizePixel = 0, Text = "", ZIndex = 71 }, popup)
            corner(colorButton, 6); stroke(colorButton, self.Window.Theme.Border, 0.2, 1)
            connect(self.Window, colorButton.MouseButton1Click, function() choose(color) end)
        end
        self.Window._dropdownClose = close
    end
    function handle:Set(color, silent)
        if typeof(color) ~= "Color3" then return end
        handle.Value = color
        swatch.BackgroundColor3 = color
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, color) end) end
    end
    function handle:Get() return handle.Value end
    connect(self.Window, swatch.MouseButton1Click, open)
    pressAnimation(self.Window, swatch)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

AxelUI.SectionMethods.AddColorpicker = AxelUI.SectionMethods.AddColorPicker

function AxelUI.SectionMethods:AddInput(data)
    data = data or {}
    data.Icon = data.Icon or "search"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 42)
    local box = new("TextBox", { BackgroundColor3 = self.Window.Theme.Element, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = tostring(data.Placeholder or "Input"), PlaceholderColor3 = self.Window.Theme.Muted, Text = tostring(data.Default or ""), TextColor3 = self.Window.Theme.Text, TextSize = 11, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(160, 25), Position = UDim2.new(1, -170, 0.5, -12), ZIndex = 8 }, inner)
    corner(box, 5); pad(box, 8, 8, 0, 0)
    local handle = { Instance = box, Value = box.Text }
    function handle:Set(value, silent)
        self.Value = tostring(value or ""); box.Text = self.Value
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, self.Value) end) end
    end
    function handle:Get() return box.Text end
    connect(self.Window, box.FocusLost, function() handle:Set(box.Text) end)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

AxelUI.SectionMethods.AddTextbox = AxelUI.SectionMethods.AddInput

function AxelUI.SectionMethods:AddKeybind(data)
    data = data or {}
    data.Icon = data.Icon or "settings"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local initialKey = keyName(data.Default or "None")
    local keyButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Window.Theme.Element, BorderSizePixel = 0, Text = initialKey, TextColor3 = self.Window.Theme.Text, TextSize = 11, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(100, 25), Position = UDim2.new(1, -110, 0.5, -12), ZIndex = 8 }, inner)
    corner(keyButton, 5)
    local handle = { Value = initialKey, Listening = false }
    function handle:Set(value, silent)
        self.Value = keyName(value)
        keyButton.Text = self.Value
        if not silent and type(data.OnChange) == "function" then task.spawn(function() pcall(data.OnChange, self.Value) end) end
    end
    function handle:Get() return self.Value end
    connect(self.Window, keyButton.MouseButton1Click, function()
        handle.Listening = true; keyButton.Text = "Press key..."
    end)
    connect(self.Window, UserInputService.InputBegan, function(input, processed)
        if handle.Listening and not processed then
            local key = input.KeyCode ~= Enum.KeyCode.Unknown and input.KeyCode.Name or input.UserInputType.Name
            handle.Listening = false; handle:Set(key)
            if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, key) end) end
        elseif not processed and keyMatches(input, handle.Value) then
            local press = data.OnPress or data.Press or data.onPress
            if type(press) == "function" then task.spawn(function() pcall(press, handle.Value) end) end
        end
    end)
    if (data.OnPress or data.Press or data.onPress) and keyName(data.Default or "None") == keyName(self.Window.ToggleKeybind) then
        self.Window._keybindOwner = handle
    end
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddStatus(data)
    data = data or {}
    data.Icon = data.Icon or "check"
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 34)
    local status = textLabel(inner, data.Text or data.Status or "Ready", 11, data.Color or self.Window.Theme.Success, true)
    status.Size = UDim2.new(0, 180, 0, 24)
    status.Position = UDim2.new(1, -180, 0, 0)
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.ZIndex = 8
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

AxelUI.SectionMethods.Text = AxelUI.SectionMethods.AddText
AxelUI.SectionMethods.Label = AxelUI.SectionMethods.AddLabel
AxelUI.SectionMethods.Paragraph = AxelUI.SectionMethods.AddParagraph
AxelUI.SectionMethods.Button = AxelUI.SectionMethods.AddButton
AxelUI.SectionMethods.AddActions = AxelUI.SectionMethods.AddActionBar
AxelUI.SectionMethods.ActionBar = AxelUI.SectionMethods.AddActionBar
AxelUI.SectionMethods.Toggle = AxelUI.SectionMethods.AddToggle
AxelUI.SectionMethods.Slider = AxelUI.SectionMethods.AddSlider
AxelUI.SectionMethods.Dropdown = AxelUI.SectionMethods.AddDropdown
AxelUI.SectionMethods.MultiDropdown = AxelUI.SectionMethods.AddMultiDropdown
AxelUI.SectionMethods.ColorPicker = AxelUI.SectionMethods.AddColorPicker
AxelUI.SectionMethods.Colorpicker = AxelUI.SectionMethods.AddColorPicker
AxelUI.SectionMethods.TextBox = AxelUI.SectionMethods.AddInput
AxelUI.SectionMethods.Textbox = AxelUI.SectionMethods.AddInput
AxelUI.SectionMethods.Input = AxelUI.SectionMethods.AddInput
AxelUI.SectionMethods.Bind = AxelUI.SectionMethods.AddKeybind
AxelUI.SectionMethods.Keybind = AxelUI.SectionMethods.AddKeybind
AxelUI.SectionMethods.Status = AxelUI.SectionMethods.AddStatus
AxelUI.SectionMethods.Separator = AxelUI.SectionMethods.AddDivider

function AxelUI.TabMethods:Section(data)
    return self:AddSection(data)
end

function AxelUI.TabMethods:Tab(data)
    return self:AddSubTab(data)
end

function AxelUI:Tab(data)
    return self:AddTab(data)
end

function AxelUI:CreateTab(data)
    return self:AddTab(data)
end

function AxelUI:Unload()
    if self._destroyed then return end
    self._destroyed = true
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    self._connections = {}
    if self._dropdownClose then pcall(self._dropdownClose) end
    if self.Window and self.Window.Parent then
        tween(self.Scale, { Scale = 0.92 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(self.Window, { BackgroundTransparency = 1 }, 0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        for _, object in ipairs(self.Window:GetDescendants()) do
            pcall(function()
                if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then tween(object, { TextTransparency = 1 }, 0.18) end
                if object:IsA("ImageLabel") or object:IsA("ImageButton") then tween(object, { ImageTransparency = 1 }, 0.18) end
            end)
        end
    end
    task.delay(0.25, function()
        if self.Gui then pcall(function() self.Gui:Destroy() end) end
    end)
    if self._globalKey and _G[self._globalKey] == self then _G[self._globalKey] = nil end
    if AxelUI._activeWindow == self then AxelUI._activeWindow = nil end
    return true
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
        Theme = normalizeTheme(options.Theme, AxelUI._pendingTheme),
        Tabs = {},
        ActiveTab = nil,
        _font = options.Font,
        ToggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightControl,
        DesktopSize = options.Size or UDim2.fromOffset(926, 616),
        AssetFolder = options.AssetFolder or options.AssetRoot or "",
        ConfigFolder = options.ConfigFolder or "AxelUIConfigs",
        _flags = {},
    }, AxelUI)
    ACTIVE_FONT = options.Font
    ACTIVE_ASSET_FOLDER = self.AssetFolder
    self.TabMethods = AxelUI.TabMethods
    self.Gui = new("ScreenGui", { Name = globalKey, IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global }, resolveParent())
    _G[globalKey] = self
    AxelUI._activeWindow = self

    self.Window = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), Size = self.DesktopSize, ClipsDescendants = true }, self.Gui)
    corner(self.Window, 12)
    self.GlowStroke = stroke(self.Window, self.Theme.Accent, 0.42, 1.25)
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
    if options.Background or options.BackgroundImage then
        self:SetBackground(options.Background or options.BackgroundImage, options.BackgroundTransparency, options.BackgroundScaleType)
    end

    local header = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -170, 0, 58), ZIndex = 5 }, self.Window)
    self.Header = header
    new("UIGradient", {
        Color = ColorSequence.new(self.Theme.Surface, self.Theme.Background),
        Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.02), NumberSequenceKeypoint.new(1, 0.2) }),
        Rotation = 0,
    }, header)
    local logoHolder = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(16, 15) }, header)
    corner(logoHolder, 8); local logoIcon = icon(logoHolder, options.Logo or "dashboard", 20, self.Theme.Accent2); logoIcon.Position = UDim2.fromOffset(6, 6)
    local brand = textLabel(header, options.Name or "Axel UI", 14, self.Theme.Text, true); brand.Position = UDim2.fromOffset(58, 15); brand.Size = UDim2.fromOffset(150, 20)
    local subtitle = textLabel(header, options.Subtitle or "Clean, animated interface", 10, self.Theme.SubText, false); subtitle.Position = UDim2.fromOffset(58, 35); subtitle.Size = UDim2.fromOffset(180, 16)
    self.Brand, self.HeaderSubtitle = brand, subtitle
    local search = new("TextBox", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Search features, settings, or help...", PlaceholderColor3 = self.Theme.Muted, Text = "", TextColor3 = self.Theme.Text, TextSize = 12, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(300, 34), Position = UDim2.fromOffset(16, 12) }, header)
    corner(search, 8); stroke(search, self.Theme.Border, 0.25, 1); pad(search, 10, 34, 0, 0)
    self.SearchIcon = icon(header, "search", 15, self.Theme.Muted); self.SearchIcon.Position = UDim2.fromOffset(292, 21)
    self.Search = search
    self.StatusDot = new("Frame", { BackgroundColor3 = self.Theme.Success, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), Position = UDim2.new(1, -140, 0, 21) }, header); corner(self.StatusDot, 4)
    self.StatusText = textLabel(header, "Ready", 10, self.Theme.Success, true); self.StatusText.Position = UDim2.new(1, -126, 0, 14); self.StatusText.Size = UDim2.fromOffset(76, 20); self.StatusText.TextXAlignment = Enum.TextXAlignment.Left
    self.FpsText = textLabel(header, "FPS --", 10, self.Theme.SubText, true); self.FpsText.Position = UDim2.new(1, -232, 0, 14); self.FpsText.Size = UDim2.fromOffset(82, 20); self.FpsText.TextXAlignment = Enum.TextXAlignment.Right
    local function headerControl(text, offset, callback)
        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Element,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            Text = text,
            TextColor3 = self.Theme.SubText,
            TextSize = text == "×" and 20 or 15,
            FontFace = fontFace(nil, false),
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, offset, 0, 11),
        }, header)
        corner(button, 7)
        pressAnimation(self, button)
        connect(self, button.MouseButton1Click, callback)
        return button
    end
    local minimizeButton = headerControl("—", -102, function() self:SetOpen(false) end)
    local maximizeButton = headerControl("□", -70, function() self:SetMaximized(not self._maximized) end)
    local unloadButton = headerControl("×", -38, function() self:Unload() end)
    self.MinimizeButton, self.MaximizeButton, self.UnloadButton = minimizeButton, maximizeButton, unloadButton

    local sidebar = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 170, 1, 0), ZIndex = 6 }, self.Window)
    self.Sidebar = sidebar
    new("Frame", { BackgroundColor3 = self.Theme.Border, BackgroundTransparency = 0.25, BorderSizePixel = 0, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 7 }, sidebar)
    logoHolder.Parent = sidebar; logoHolder.Position = UDim2.fromOffset(18, 16); logoHolder.Size = UDim2.fromOffset(38, 38); logoHolder.ZIndex = 8; logoIcon.ZIndex = 9
    brand.Parent = sidebar; brand.Position = UDim2.fromOffset(66, 15); brand.Size = UDim2.new(1, -78, 0, 20); brand.ZIndex = 8
    subtitle.Parent = sidebar; subtitle.Position = UDim2.fromOffset(66, 36); subtitle.Size = UDim2.new(1, -78, 0, 16); subtitle.ZIndex = 8
    new("Frame", { BackgroundColor3 = self.Theme.Border, BackgroundTransparency = 0.35, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 0, 1) }, sidebar)
    local navTitle = textLabel(sidebar, "NAVIGATION", 9, self.Theme.Muted, true); navTitle.Position = UDim2.fromOffset(14, 84); navTitle.Size = UDim2.new(1, -28, 0, 16)
    self.NavTitle = navTitle
    self.TabList = new("ScrollingFrame", { Active = true, AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), Position = UDim2.fromOffset(8, 108), ScrollBarImageColor3 = self.Theme.Accent, ScrollBarThickness = 2, Size = UDim2.new(1, -16, 1, -188) }, sidebar)
    new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, self.TabList)
    local profile = new("Frame", { BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0.15, BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -104), Size = UDim2.new(1, -24, 0, 48) }, sidebar)
    corner(profile, 10); stroke(profile, self.Theme.Border, 0.55, 1)
    local avatar = new("ImageLabel", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(8, 9), Image = "", ScaleType = Enum.ScaleType.Crop }, profile)
    corner(avatar, 15)
    pcall(function()
        local player = Players.LocalPlayer
        if player then avatar.Image = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end
    end)
    local profileName = textLabel(profile, Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Axel User", 11, self.Theme.Text, true); profileName.Position = UDim2.fromOffset(46, 7); profileName.Size = UDim2.new(1, -54, 0, 17); profileName.TextTruncate = Enum.TextTruncate.AtEnd
    local profileState = textLabel(profile, "Ready to play", 9, self.Theme.SubText, false); profileState.Position = UDim2.fromOffset(46, 25); profileState.Size = UDim2.new(1, -54, 0, 14)
    local footer = textLabel(sidebar, options.Footer or "AxelUI Library", 9, self.Theme.Muted, false); footer.Position = UDim2.new(0, 14, 1, -42); footer.Size = UDim2.new(1, -28, 0, 20)
    self.ProfileCard, self.ProfileAvatar, self.ProfileName = profile, avatar, profileName
    self.Footer = footer

    self.PageHolder = new("Frame", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(170, 58), Size = UDim2.new(1, -170, 1, -58), ZIndex = 1 }, self.Window)
    local tabHeader = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46) }, self.PageHolder)
    self.TabHeader = tabHeader
    self.TabTitle = textLabel(tabHeader, "Dashboard", 15, self.Theme.Text, true); self.TabTitle.Position = UDim2.fromOffset(18, 5); self.TabTitle.Size = UDim2.new(1, -32, 0, 19)
    self.TabSubtitle = textLabel(tabHeader, "", 10, self.Theme.SubText, false); self.TabSubtitle.Position = UDim2.fromOffset(18, 24); self.TabSubtitle.Size = UDim2.new(1, -32, 0, 15)
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
        if keyMatches(input, self.ToggleKeybind) and not self._keybindOwner then self:Toggle() end
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

    local overlay = new("Frame", { BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 0.02, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 100 }, self.Window)
    local loaderCard = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(326, 156), ZIndex = 101 }, overlay)
    corner(loaderCard, 12); stroke(loaderCard, self.Theme.Accent, 0.42, 1)
    new("UIGradient", { Color = ColorSequence.new(self.Theme.Surface, self.Theme.Background), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.12) }), Rotation = 35 }, loaderCard)
    local loaderScale = new("UIScale", { Scale = 0.78 }, loaderCard)
    local overlayIcon = icon(loaderCard, options.Logo or "dashboard", 42, self.Theme.Accent2); overlayIcon.Position = UDim2.fromOffset(22, 23); overlayIcon.ZIndex = 102
    local loadingTitle = textLabel(loaderCard, options.LoadingText or options.Name or "Axel Hub", 16, self.Theme.Text, true); loadingTitle.Position = UDim2.fromOffset(78, 20); loadingTitle.Size = UDim2.new(1, -96, 0, 24); loadingTitle.ZIndex = 102
    local loadingText = textLabel(loaderCard, options.LoadingSubtitle or "Preparing your workspace", 10, self.Theme.SubText, false); loadingText.Position = UDim2.fromOffset(78, 46); loadingText.Size = UDim2.new(1, -96, 0, 18); loadingText.ZIndex = 102
    local loadingBar = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.new(1, -44, 0, 5), Position = UDim2.fromOffset(22, 104), ZIndex = 102 }, loaderCard); corner(loadingBar, 4)
    local loadingFill = new("Frame", { BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), ZIndex = 103 }, loadingBar); corner(loadingFill, 4)
    local loadingHint = textLabel(loaderCard, "Loading modules", 9, self.Theme.Muted, false); loadingHint.Position = UDim2.fromOffset(22, 119); loadingHint.Size = UDim2.new(1, -44, 0, 16); loadingHint.ZIndex = 102
    tween(self.Scale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
    tween(loaderScale, { Scale = 1 }, 0.48, Enum.EasingStyle.Back)
    tween(loadingFill, { Size = UDim2.fromScale(1, 1) }, 0.72, Enum.EasingStyle.Quint)
    task.delay(0.78, function()
        if self._destroyed or not overlay.Parent then return end
        tween(loaderScale, { Scale = 0.94 }, 0.16, Enum.EasingStyle.Quad)
        tween(overlay, { BackgroundTransparency = 1 }, 0.28)
        tween(loaderCard, { BackgroundTransparency = 1 }, 0.22)
        tween(overlayIcon, { ImageTransparency = 1 }, 0.2)
        tween(loadingTitle, { TextTransparency = 1 }, 0.2)
        tween(loadingText, { TextTransparency = 1 }, 0.2)
        tween(loadingHint, { TextTransparency = 1 }, 0.2)
        tween(loadingBar, { BackgroundTransparency = 1 }, 0.2)
        tween(loadingFill, { BackgroundTransparency = 1 }, 0.2)
        task.delay(0.3, function() if overlay.Parent then overlay:Destroy() end end)
    end)

    function self:CreateTab(data) return self:AddTab(data) end
    function self:WindowToggle() return self:Toggle() end
    self._globalKey = globalKey
    return self
end

function AxelUI:RegisterIcon(name, source)
    if name and source then ICONS[string.lower(tostring(name))] = tostring(source) end
    return self
end

function AxelUI:RegisterIcons(map)
    for name, source in pairs(map or {}) do self:RegisterIcon(name, source) end
    return self
end

AxelUI.Version = 5.7

function AxelUI.CreateWindow(first, second)
    return AxelUI.new(second or first)
end

return AxelUI
