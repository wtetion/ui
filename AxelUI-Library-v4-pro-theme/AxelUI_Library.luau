-- AxelUI Library
-- A small, dependency-free Roblox/Luau UI library for executor scripts.
-- Features: font fallback, Lucide-style icons with text fallback, animated
-- window, hover/press effects, tabs, status cards, search, descriptions,
-- toggles, buttons, sliders, dropdowns, inputs, keybinds, labels and notifications.
-- Includes responsive desktop/mobile layout, theme and config support,
-- Oxide-compatible aliases, and Unload() cleanup for tracked connections.
-- Quick start is included in AxelUI_Library_Example.luau.

local AxelUI = {}
AxelUI.__index = AxelUI
AxelUI.TabMethods = {}
AxelUI.SectionMethods = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LOW_END_TOUCH_CLIENT = UserInputService.TouchEnabled == true
local ACTIVE_FONT
local ACTIVE_ASSET_FOLDER
local GOLD_GRADIENT_ANIMATIONS = setmetatable({}, { __mode = "k" })

local function getSharedEnvironment()
    local environment = _G
    pcall(function()
        if type(getgenv) == "function" then environment = getgenv() end
    end)
    if type(environment) ~= "table" then environment = _G end
    return environment
end

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
    Accent = Color3.fromRGB(255, 193, 7),
    Accent2 = Color3.fromRGB(255, 224, 115),
    Accent3 = Color3.fromRGB(184, 126, 0),
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

-- Semantic icon names are rendered with local vector primitives below. This
-- avoids missing-font tofu squares and makes built-in icons independent of
-- Roblox asset permissions. The values are retained as aliases for old scripts.
local BUILTIN_ICONS = {
    dashboard = true, grid = true, home = true, player = true, person = true, user = true, users = true,
    world = true, globe = true, map = true, compass = true, eye = true, eyeoff = true, visible = true, render = true, esp = true,
    utilities = true, wrench = true, configs = true, folder = true, file = true, shop = true, cart = true, marketplace = true,
    running = true, speed = true, arrows = true, move = true, teleport = true, target = true, crosshair = true, aim = true,
    shield = true, lock = true, unlock = true, star = true, sparkle = true, favorite = true, crown = true,
    clock = true, time = true, timer = true, chart = true, activity = true, cpu = true, monitor = true, gamepad = true,
    save = true, download = true, upload = true, refresh = true, server = true, settings = true, gear = true, sliders = true,
    power = true, check = true, x = true, plus = true, minus = true, bolt = true, fire = true, flame = true, swords = true, sword = true, combat = true,
    webhook = true, bell = true, info = true, alert = true, warning = true, search = true, copy = true, clipboard = true,
    chevron = true, list = true, palette = true, layers = true, contrast = true, heart = true, volume = true, camera = true,
    code = true, terminal = true, bug = true, inventory = true, backpack = true, gift = true, gem = true, coin = true, skull = true, eggs = true, discord = true, team = true, group = true,
    sun = true,
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

local function imageThumbnailSource(source, width, height)
    local text = tostring(source or "")
    local id = text:match("^rbxassetid://(%d+)$") or text:match("^(%d+)$")
    if not id then return nil end
    return string.format("rbxthumb://type=Asset&id=%s&w=%d&h=%d", id, tonumber(width) or 420, tonumber(height) or 420)
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

local ICON_ALIASES = {
    dashboard = "grid", configs = "file", marketplace = "cart", shop = "cart", users = "user",
    person = "user", player = "user", team = "user", group = "user", globe = "world", compass = "world", map = "world",
    visible = "eye", render = "eye", esp = "eye", eyeoff = "eye", hidden = "eye", wrench = "settings",
    sliders = "settings", utilities = "settings", gear = "settings", speed = "gauge", activity = "gauge",
    wifi = "wifi",
    running = "move", arrows = "move", teleport = "move", aim = "target", crosshair = "target",
    favorite = "star", sparkle = "star", logo = "star", time = "clock", timer = "clock", chart = "gauge",
    download = "save", upload = "save", clipboard = "file", list = "file", inventory = "file",
    backpack = "file", server = "world", monitor = "grid", gamepad = "grid", contrast = "eye", refresh = "refresh",
    menu = "grid", power = "bolt", fire = "bolt", flame = "bolt", swords = "move", sword = "move",
    combat = "move", webhook = "bolt", info = "target", alert = "target", warning = "target",
    copy = "file", palette = "star", layers = "grid", camera = "eye", bug = "target", gift = "star",
    gem = "star", coin = "star", skull = "target", eggs = "star", discord = "world", heart = "star",
    volume = "bolt", check = "check", x = "close", plus = "plus", minus = "minus", save = "save",
    folder = "file", file = "file", eyeoff = "eye", lock = "shield", unlock = "shield",
    caret = "chevron", dropdown = "chevron", angle = "chevron", expand = "maximize", collapse = "minus",
}

local function canonicalIcon(value)
    local name = string.lower(tostring(value or "sparkle")):gsub("[%s%-]", "")
    if ICON_ALIASES[name] then name = ICON_ALIASES[name] end
    if name == "star" or name == "sparkle" or name == "logo" then return "star" end
    if name == "home" or name == "user" or name == "world" or name == "eye" or name == "settings"
        or name == "gauge" or name == "clock" or name == "move" or name == "target" or name == "grid"
        or name == "file" or name == "cart" or name == "shield" or name == "save" or name == "bolt"
        or name == "check" or name == "close" or name == "plus" or name == "minus" or name == "search"
        or name == "maximize" or name == "chevron" or name == "sun" or name == "resize" or name == "refresh"
        or name == "wifi" then
        return name
    end
    return "star"
end

local function vectorIcon(parent, name, size, tint)
    local dimension = math.max(8, tonumber(size) or 18)
    local scale = dimension / 24
    local root = new("Frame", {
        Name = "AxelVectorIcon",
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(dimension, dimension),
    }, parent)
    local function segment(x1, y1, x2, y2, thickness)
        local dx, dy = (x2 - x1) * scale, (y2 - y1) * scale
        local length = math.sqrt(dx * dx + dy * dy)
        local angle = math.deg(math.atan2(dy, dx))
        local line = new("Frame", {
            Name = "AxelIconLine",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = tint or Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Position = UDim2.fromOffset((x1 + x2) * 0.5 * scale, (y1 + y2) * 0.5 * scale),
            Rotation = angle,
            Size = UDim2.fromOffset(length, math.max(1, (thickness or 1.8) * scale)),
        }, root)
        corner(line, 2)
        return line
    end
    local function outline(x, y, w, h, radius)
        local shape = new("Frame", {
            Name = "AxelIconShape",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset((x + w / 2) * scale, (y + h / 2) * scale),
            Size = UDim2.fromOffset(w * scale, h * scale),
        }, root)
        corner(shape, math.max(1, (radius or 4) * scale))
        stroke(shape, tint or Color3.new(1, 1, 1), 0, math.max(1, 1.7 * scale))
        return shape
    end
    local function dot(x, y, diameter, filled)
        local shape = new("Frame", {
            Name = "AxelIconDot",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = tint or Color3.new(1, 1, 1),
            BackgroundTransparency = filled and 0 or 1,
            BorderSizePixel = 0,
            Position = UDim2.fromOffset(x * scale, y * scale),
            Size = UDim2.fromOffset(diameter * scale, diameter * scale),
        }, root)
        corner(shape, diameter * scale / 2)
        if not filled then stroke(shape, tint or Color3.new(1, 1, 1), 0, math.max(1, 1.7 * scale)) end
        return shape
    end

    if name == "search" then
        dot(10, 10, 12, false); segment(14.5, 14.5, 21, 21, 2)
    elseif name == "home" then
        segment(3, 11, 12, 3, 2); segment(12, 3, 21, 11, 2)
        segment(5, 10, 5, 21, 2); segment(19, 10, 19, 21, 2); segment(5, 21, 19, 21, 2)
        segment(10, 21, 10, 14, 2); segment(10, 14, 14, 14, 2); segment(14, 14, 14, 21, 2)
    elseif name == "user" then
        dot(12, 7, 7, false); segment(4, 21, 5, 18, 2); segment(5, 18, 9, 15, 2)
        segment(9, 15, 15, 15, 2); segment(15, 15, 19, 18, 2); segment(19, 18, 20, 21, 2)
        segment(4, 21, 20, 21, 2)
    elseif name == "world" then
        dot(12, 12, 19, false); segment(3, 12, 21, 12, 1.4); segment(12, 3, 12, 21, 1.4)
        segment(8, 4, 7, 12, 1.2); segment(7, 12, 8, 20, 1.2)
        segment(16, 4, 17, 12, 1.2); segment(17, 12, 16, 20, 1.2)
    elseif name == "wifi" then
        segment(3, 8, 7, 5, 1.8); segment(7, 5, 12, 3.5, 1.8); segment(12, 3.5, 17, 5, 1.8); segment(17, 5, 21, 8, 1.8)
        segment(7, 13, 9, 11, 1.8); segment(9, 11, 12, 10, 1.8); segment(12, 10, 15, 11, 1.8); segment(15, 11, 17, 13, 1.8)
        dot(12, 19, 3, true)
    elseif name == "eye" then
        segment(2, 12, 7, 6, 1.8); segment(7, 6, 12, 4, 1.8); segment(12, 4, 17, 6, 1.8)
        segment(17, 6, 22, 12, 1.8); segment(22, 12, 17, 18, 1.8); segment(17, 18, 12, 20, 1.8)
        segment(12, 20, 7, 18, 1.8); segment(7, 18, 2, 12, 1.8); dot(12, 12, 6, false)
    elseif name == "settings" then
        dot(12, 12, 7, false)
        for i = 0, 7 do
            local a = math.rad(i * 45)
            local x1, y1 = 12 + math.cos(a) * 6.5, 12 + math.sin(a) * 6.5
            local x2, y2 = 12 + math.cos(a) * 10, 12 + math.sin(a) * 10
            segment(x1, y1, x2, y2, 2.2)
        end
    elseif name == "gauge" then
        segment(3, 19, 4, 12, 1.8); segment(4, 12, 8, 6, 1.8); segment(8, 6, 12, 4, 1.8)
        segment(12, 4, 16, 6, 1.8); segment(16, 6, 20, 12, 1.8); segment(20, 12, 21, 19, 1.8)
        segment(3, 19, 21, 19, 1.8); segment(12, 17, 17, 10, 2)
    elseif name == "clock" then
        dot(12, 12, 19, false); segment(12, 6, 12, 12, 2); segment(12, 12, 17, 15, 2)
    elseif name == "move" then
        segment(12, 3, 12, 21, 1.8); segment(3, 12, 21, 12, 1.8)
        segment(12, 3, 8, 7, 1.8); segment(12, 3, 16, 7, 1.8)
        segment(12, 21, 8, 17, 1.8); segment(12, 21, 16, 17, 1.8)
        segment(3, 12, 7, 8, 1.8); segment(3, 12, 7, 16, 1.8)
        segment(21, 12, 17, 8, 1.8); segment(21, 12, 17, 16, 1.8)
    elseif name == "target" then
        dot(12, 12, 16, false); dot(12, 12, 6, false); segment(12, 1, 12, 5, 1.8)
        segment(12, 19, 12, 23, 1.8); segment(1, 12, 5, 12, 1.8); segment(19, 12, 23, 12, 1.8)
    elseif name == "grid" then
        for _, point in ipairs({{4,4},{14,4},{4,14},{14,14}}) do outline(point[1], point[2], 6, 6, 1.4) end
    elseif name == "file" then
        segment(6, 3, 15, 3, 1.8); segment(15, 3, 19, 7, 1.8); segment(19, 7, 19, 21, 1.8)
        segment(19, 21, 5, 21, 1.8); segment(5, 21, 5, 4, 1.8); segment(5, 4, 6, 3, 1.8)
        segment(15, 3, 15, 7, 1.5); segment(15, 7, 19, 7, 1.5)
        segment(8, 12, 16, 12, 1.4); segment(8, 16, 16, 16, 1.4)
    elseif name == "cart" then
        segment(3, 5, 6, 5, 1.8); segment(6, 5, 8, 16, 1.8); segment(8, 16, 19, 16, 1.8)
        segment(19, 16, 22, 8, 1.8); segment(7, 9, 21, 9, 1.8); dot(10, 20, 3, true); dot(18, 20, 3, true)
    elseif name == "shield" then
        segment(12, 3, 20, 6, 1.8); segment(20, 6, 19, 15, 1.8); segment(19, 15, 12, 21, 1.8)
        segment(12, 21, 5, 15, 1.8); segment(5, 15, 4, 6, 1.8); segment(4, 6, 12, 3, 1.8)
        segment(8, 12, 11, 15, 1.8); segment(11, 15, 16, 9, 1.8)
    elseif name == "save" then
        segment(4, 3, 20, 3, 1.8); segment(20, 3, 20, 21, 1.8); segment(20, 21, 4, 21, 1.8)
        segment(4, 21, 4, 3, 1.8); segment(8, 3, 8, 10, 1.5); segment(8, 10, 16, 10, 1.5)
        segment(16, 10, 16, 3, 1.5); segment(8, 15, 8, 19, 1.5); segment(8, 19, 16, 19, 1.5)
        segment(16, 19, 16, 15, 1.5)
    elseif name == "bolt" then
        segment(14, 2, 6, 13, 2); segment(6, 13, 12, 13, 2); segment(12, 13, 10, 22, 2)
        segment(10, 22, 19, 10, 2); segment(19, 10, 13, 10, 2); segment(13, 10, 14, 2, 2)
    elseif name == "check" then
        segment(4, 13, 10, 19, 2.4); segment(10, 19, 21, 5, 2.4)
    elseif name == "close" then
        segment(6, 6, 18, 18, 2); segment(18, 6, 6, 18, 2)
    elseif name == "plus" then
        segment(12, 4, 12, 20, 2); segment(4, 12, 20, 12, 2)
    elseif name == "minus" then
        segment(4, 12, 20, 12, 2)
    elseif name == "maximize" then
        outline(4, 4, 16, 16, 2)
    elseif name == "resize" then
        segment(6, 18, 18, 6, 1.8); segment(12, 18, 18, 12, 1.8); segment(12, 6, 18, 6, 1.8)
        segment(18, 6, 18, 12, 1.8)
    elseif name == "refresh" then
        segment(18, 8, 17, 5, 1.8); segment(17, 5, 20, 5, 1.8); segment(20, 5, 20, 8, 1.8)
        segment(19, 7, 17, 5, 1.8); segment(17, 5, 13, 4, 1.8); segment(13, 4, 8, 6, 1.8)
        segment(8, 6, 5, 10, 1.8); segment(5, 10, 5, 15, 1.8); segment(5, 15, 8, 19, 1.8)
        segment(8, 19, 13, 20, 1.8); segment(13, 20, 18, 17, 1.8); segment(18, 17, 20, 13, 1.8)
    elseif name == "chevron" then
        segment(6, 9, 12, 15, 1.8); segment(12, 15, 18, 9, 1.8)
    elseif name == "sun" then
        dot(12, 12, 8, false)
        for i = 0, 7 do
            local a = math.rad(i * 45)
            segment(12 + math.cos(a) * 7, 12 + math.sin(a) * 7, 12 + math.cos(a) * 10, 12 + math.sin(a) * 10, 1.7)
        end
    elseif name == "star" then
        segment(12, 2, 14, 9, 2); segment(14, 9, 22, 12, 2); segment(22, 12, 14, 14, 2)
        segment(14, 14, 12, 22, 2); segment(12, 22, 10, 14, 2); segment(10, 14, 2, 12, 2)
        segment(2, 12, 10, 9, 2); segment(10, 9, 12, 2, 2)
    end

    local function updateZIndex()
        for _, child in ipairs(root:GetDescendants()) do
            if child:IsA("GuiObject") then child.ZIndex = root.ZIndex + 1 end
        end
    end
    root:GetPropertyChangedSignal("ZIndex"):Connect(updateZIndex)
    updateZIndex()
    return root
end

local function setIconTint(object, color, duration)
    if not object then return end
    local instant = LOW_END_TOUCH_CLIENT or tonumber(duration) == 0
    local function apply(target, property, value)
        if instant then
            pcall(function() target[property] = value end)
        else
            tween(target, { [property] = value }, duration or 0.18)
        end
    end
    if object:IsA("ImageLabel") or object:IsA("ImageButton") then
        apply(object, "ImageColor3", color)
        local fallback = object.Parent and object.Parent:FindFirstChild("AxelVectorIcon")
        if fallback then setIconTint(fallback, color, duration) end
        return
    end
    if object:IsA("GuiObject") then
        for _, child in ipairs(object:GetDescendants()) do
            if child:IsA("GuiObject") and child.Name ~= "AxelVectorIcon" then apply(child, "BackgroundColor3", color) end
            if child:IsA("UIStroke") then apply(child, "Color", color) end
        end
    end
end

local function fadeIcon(object, duration)
    if not object then return end
    if object:IsA("ImageLabel") or object:IsA("ImageButton") then
        tween(object, { ImageTransparency = 1 }, duration or 0.2)
        local fallback = object.Parent and object.Parent:FindFirstChild("AxelVectorIcon")
        if fallback then fadeIcon(fallback, duration) end
        return
    end
    if object:IsA("GuiObject") then
        for _, child in ipairs(object:GetDescendants()) do
            if child:IsA("GuiObject") then tween(child, { BackgroundTransparency = 1 }, duration or 0.2) end
            if child:IsA("UIStroke") then tween(child, { Transparency = 1 }, duration or 0.2) end
        end
    end
end

local function watchImage(imageLabel, onLoaded, onTimeout, timeout, fallbackSources)
    if not imageLabel then return end
    local state = "pending"
    local timeoutSeconds = tonumber(timeout) or 5
    local fallbackIndex = 0
    local timeoutGeneration = 0
    local function refresh()
        if not imageLabel.Parent then return end
        local ok, loaded = pcall(function() return imageLabel.IsLoaded end)
        if ok and loaded and state ~= "loaded" then
            state = "loaded"
            if type(onLoaded) == "function" then pcall(onLoaded) end
        end
    end
    local function watchProperty(property)
        pcall(function()
            imageLabel:GetPropertyChangedSignal(property):Connect(refresh)
        end)
    end
    watchProperty("IsLoaded")
    watchProperty("Image")
    local function armTimeout()
        timeoutGeneration = timeoutGeneration + 1
        local generation = timeoutGeneration
        task.delay(timeoutSeconds, function()
            if not imageLabel.Parent or state ~= "pending" or generation ~= timeoutGeneration then return end
            while type(fallbackSources) == "table" and fallbackIndex < #fallbackSources do
                fallbackIndex = fallbackIndex + 1
                local candidate = fallbackSources[fallbackIndex]
                local current = ""
                pcall(function() current = imageLabel.Image end)
                if type(candidate) == "string" and candidate ~= "" and candidate ~= current then
                    local ok = pcall(function() imageLabel.Image = candidate end)
                    if ok then
                        state = "pending"
                        armTimeout()
                        refresh()
                        return
                    end
                end
            end
            state = "failed"
            if type(onTimeout) == "function" then pcall(onTimeout) end
        end)
    end
    armTimeout()
    refresh()
end

local function icon(parent, value, size, tint)
    local config = type(value) == "table" and value or nil
    local source = config and (config.Image or config.Asset or config.Id or config.Source) or value
    local sourceText = string.lower(tostring(source or "sparkle"))
    local iconSize = (config and tonumber(config.Size)) or tonumber(size) or 18
    local iconTint = (config and config.Color) or tint or Color3.new(1, 1, 1)
    local semantic = BUILTIN_ICONS[sourceText] ~= nil or sourceText:match("^[%a_%-]+$") ~= nil
    local forceImage = config and config.UseImage == true
    if semantic and not forceImage then return vectorIcon(parent, canonicalIcon(sourceText), iconSize, iconTint) end

    local image = imageSource(source, ACTIVE_ASSET_FOLDER)
    if image then
        local fallback = vectorIcon(parent, canonicalIcon(config and config.Fallback or "star"), iconSize, iconTint)
        fallback.Name = "AxelVectorIcon"
        fallback.Visible = true
        local imageLabel = new("ImageLabel", {
            BackgroundTransparency = 1,
            Image = image,
            ImageColor3 = iconTint,
            Size = UDim2.fromOffset(iconSize, iconSize),
            ScaleType = (config and config.ScaleType) or Enum.ScaleType.Fit,
            Visible = false,
        }, parent)
        if config and config.ImageRectOffset then imageLabel.ImageRectOffset = config.ImageRectOffset end
        if config and config.ImageRectSize then imageLabel.ImageRectSize = config.ImageRectSize end
        local function syncFallback()
            if not imageLabel.Parent or not fallback.Parent then return end
            fallback.Position = imageLabel.Position
            fallback.AnchorPoint = imageLabel.AnchorPoint
            fallback.Size = imageLabel.Size
            fallback.ZIndex = imageLabel.ZIndex + 1
        end
        imageLabel:GetPropertyChangedSignal("Position"):Connect(syncFallback)
        imageLabel:GetPropertyChangedSignal("AnchorPoint"):Connect(syncFallback)
        imageLabel:GetPropertyChangedSignal("Size"):Connect(syncFallback)
        imageLabel:GetPropertyChangedSignal("ZIndex"):Connect(syncFallback)
        watchImage(imageLabel, function()
            if imageLabel.Parent and fallback.Parent then imageLabel.Visible = true; fallback.Visible = false end
        end, function()
            if imageLabel.Parent and fallback.Parent then imageLabel.Visible = false; fallback.Visible = true end
        end)
        return imageLabel
    end
    return vectorIcon(parent, canonicalIcon(sourceText), iconSize, iconTint)
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

local function placePopup(popup, anchor, width, height, preferBelow)
    if not popup or not anchor then return end
    local viewport = Vector2.new(1280, 720)
    pcall(function()
        if workspace.CurrentCamera then viewport = workspace.CurrentCamera.ViewportSize end
    end)
    local anchorPosition = anchor.AbsolutePosition
    local anchorSize = anchor.AbsoluteSize
    local x = math.clamp(anchorPosition.X, 8, math.max(8, viewport.X - width - 8))
    local below = anchorPosition.Y + anchorSize.Y + 4
    local availableBelow = viewport.Y - below - 8
    if preferBelow and availableBelow >= 30 then
        local fittedHeight = math.min(height, availableBelow)
        popup.Size = UDim2.fromOffset(width, fittedHeight)
        popup.Position = UDim2.fromOffset(x, below)
        return
    end
    local y = below + height <= viewport.Y - 8 and below or anchorPosition.Y - height - 4
    y = math.clamp(y, 8, math.max(8, viewport.Y - height - 8))
    popup.Position = UDim2.fromOffset(x, y)
end

local function animatePopupOpen(popup)
    if not popup or not popup.Parent then return end
    local targetSize = popup.Size
    local outline = popup:FindFirstChildOfClass("UIStroke")
    popup.Size = UDim2.fromOffset(targetSize.X.Offset, 0)
    popup.BackgroundTransparency = 0.16
    if outline then outline.Transparency = 0.62 end
    tween(popup, { Size = targetSize, BackgroundTransparency = 0 }, 0.15, Enum.EasingStyle.Quint)
    if outline then tween(outline, { Transparency = 0.08 }, 0.15, Enum.EasingStyle.Quint) end
end

local function animatePopupClose(popup)
    if not popup or not popup.Parent then return end
    local width = popup.Size.X.Offset
    local outline = popup:FindFirstChildOfClass("UIStroke")
    tween(popup, { Size = UDim2.fromOffset(width, 0), BackgroundTransparency = 1 }, 0.12, Enum.EasingStyle.Quad)
    if outline then tween(outline, { Transparency = 1 }, 0.1, Enum.EasingStyle.Quad) end
    task.delay(0.14, function()
        if popup.Parent then popup:Destroy() end
    end)
end

local function pressAnimation(self, button, scaleObject)
    if not button then return end
    -- Low-end touch devices benefit more from fewer live GUI objects and
    -- input connections than from decorative press scaling.
    if self.ReduceEffects then return end
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

local function addButtonGlass(self, button, restingTransparency)
    if not button then return end
    if self.ReduceEffects then return end
    restingTransparency = restingTransparency or 0
    connect(self, button.MouseEnter, function()
        tween(button, { BackgroundTransparency = math.max(restingTransparency, 0.12) }, 0.12)
    end)
    connect(self, button.MouseLeave, function()
        tween(button, { BackgroundTransparency = restingTransparency }, 0.16)
    end)
    connect(self, button.MouseButton1Down, function()
        tween(button, { BackgroundTransparency = math.max(restingTransparency, 0.24) }, 0.07)
    end)
    connect(self, button.MouseButton1Up, function()
        tween(button, { BackgroundTransparency = math.max(restingTransparency, 0.16) }, 0.1)
    end)
end

local function addGoldGradient(self, button)
    local gradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Accent3),
            ColorSequenceKeypoint.new(0.24, self.Theme.Accent),
            ColorSequenceKeypoint.new(0.52, self.Theme.Accent2),
            ColorSequenceKeypoint.new(0.78, self.Theme.Accent),
            ColorSequenceKeypoint.new(1, self.Theme.Accent3),
        }),
        -- Keep disabled gradients from washing out the button text. A fully
        -- transparent gradient still affects the text rendered by the button.
        Transparency = NumberSequence.new(0),
        Enabled = false,
        Rotation = 0,
        Offset = Vector2.new(-1, 0),
    }, button)
    if self.AnimateAccents then
        self._accentTweens = self._accentTweens or {}
        local ok, animation = pcall(function()
            return TweenService:Create(gradient, TweenInfo.new(2.8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true), {
                Offset = Vector2.new(1, 0),
            })
        end)
        if ok and animation then
            local entry = { Gradient = gradient, Tween = animation, Window = self }
            table.insert(self._accentTweens, entry)
            GOLD_GRADIENT_ANIMATIONS[gradient] = entry
        end
    end
    return gradient
end

local function setGoldGradientActive(gradient, active)
    if gradient then
        active = active == true
        pcall(function() gradient.Enabled = active end)
        local entry = GOLD_GRADIENT_ANIMATIONS[gradient]
        if entry and entry.Tween then
            pcall(function()
                local shouldPlay = active and entry.Window and entry.Window.AnimateAccents and entry.Window._open
                if shouldPlay and entry.Tween.PlaybackState ~= Enum.PlaybackState.Playing then
                    entry.Tween:Play()
                elseif not shouldPlay and entry.Tween.PlaybackState == Enum.PlaybackState.Playing then
                    entry.Tween:Pause()
                end
            end)
        end
    end
end

local function setAccentAnimations(self, enabled)
    local shouldRun = enabled == true and self.AnimateAccents == true and self._open == true
    local function setTweenState(animation, play)
        if not animation then return end
        pcall(function()
            if play and animation.PlaybackState ~= Enum.PlaybackState.Playing then
                animation:Play()
            elseif not play and animation.PlaybackState == Enum.PlaybackState.Playing then
                animation:Pause()
            end
        end)
    end

    setTweenState(self._edgeTween, shouldRun)
    for _, animation in ipairs(self._glintTweens or {}) do
        setTweenState(animation, shouldRun)
    end
    for _, entry in ipairs(self._accentTweens or {}) do
        setTweenState(entry.Tween, shouldRun and entry.Gradient and entry.Gradient.Enabled == true)
    end
end

local function setTextColor(instance, color)
    if instance then pcall(function() instance.TextColor3 = color end) end
end

local function searchMatches(value, query)
    if query == "" then return true end
    value = string.lower(tostring(value or ""))
    if value:find(query, 1, true) then return true end
    -- Search multi-word queries in any order (e.g. "movement speed").
    for word in query:gmatch("%S+") do
        if not value:find(word, 1, true) then return false end
    end
    return true
end

function AxelUI:_registerSearch(row, query, titleLabel, options)
    if not row then return end
    local entry = {
        Text = string.lower(tostring(query or "")),
        Title = titleLabel,
        BaseTitleColor = titleLabel and titleLabel.TextColor3 or nil,
        Container = options and options.Container == true or false,
    }
    local ancestor = row.Parent
    while ancestor do
        local ancestorEntry = self._searchData[ancestor]
        if ancestorEntry and ancestorEntry.Container then
            entry.ContainerOwner = ancestor
            break
        end
        ancestor = ancestor.Parent
    end
    self._searchData[row] = entry
    table.insert(self._searchRows, row)
    connect(self, row.Destroying, function()
        self._searchData[row] = nil
        for index, registered in ipairs(self._searchRows) do
            if registered == row then table.remove(self._searchRows, index); break end
        end
    end)
    local text = string.lower(self.Search and self.Search.Text or "")
    local matches = searchMatches(entry.Text, text)
    row.Visible = text == "" or matches
    if titleLabel then
        titleLabel.TextColor3 = text ~= "" and matches and self.Theme.Accent2 or entry.BaseTitleColor
    end
    if text ~= "" then self:_refreshSearch(text) end
end

function AxelUI:_refreshSearch(text)
    text = string.lower(tostring(text or ""))
    local containerTextMatches, containerChildMatches = {}, {}
    if text ~= "" then
        for _, row in ipairs(self._searchRows) do
            local entry = self._searchData[row]
            if entry and entry.Container then containerTextMatches[row] = searchMatches(entry.Text, text) end
        end
        for _, row in ipairs(self._searchRows) do
            local entry = self._searchData[row]
            if entry and entry.ContainerOwner and searchMatches(entry.Text, text) then
                containerChildMatches[entry.ContainerOwner] = true
            end
        end
    end
    for _, row in ipairs(self._searchRows) do
        local entry = self._searchData[row]
        if row and row.Parent and entry then
            local matches = searchMatches(entry.Text, text)
            if entry.Container then
                matches = text == "" or containerTextMatches[row] or containerChildMatches[row] == true
            elseif entry.ContainerOwner and containerTextMatches[entry.ContainerOwner] then
                matches = true
            end
            row.Visible = text == "" or matches
            if entry.Title and entry.Title.Parent then
                local target = text ~= "" and matches and self.Theme.Accent2 or entry.BaseTitleColor
                tween(entry.Title, { TextColor3 = target or self.Theme.Text }, 0.12)
            end
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
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.new(1, 0, 0, rowHeight),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(row, 8)
    local rowStroke = stroke(row, data.Primary and self.Theme.Accent2 or self.Theme.Border, 0.4, 1)
    local hoverGlass
    if not self.ReduceEffects then
        new("UIGradient", {
            Color = ColorSequence.new(data.Primary and self.Theme.Accent or self.Theme.Surface2, data.Primary and self.Theme.Accent2 or self.Theme.Element),
            Transparency = NumberSequence.new(0),
            Rotation = 0,
        }, row)
        hoverGlass = new("Frame", {
            BackgroundColor3 = self.Theme.Accent2,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            ZIndex = (tonumber(row.ZIndex) or 0) + 1,
        }, row)
        corner(hoverGlass, 8)
        new("UIGradient", {
            Color = ColorSequence.new(Color3.new(1, 1, 1), self.Theme.Accent2),
            Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.34), NumberSequenceKeypoint.new(1, 0.9) }),
            Rotation = 0,
        }, hoverGlass)
    end
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
    local rightReserved = tonumber(data.RightReserved) or 145
    local rowTitleSize = self.IsMobile and 12 or 13
    local title = textLabel(inner, data.Name or "Element", rowTitleSize, data.Primary and self.Theme.Background or self.Theme.Text, true)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.Size = UDim2.new(1, -rightReserved - textOffset, 0, data.Description and 17 or 26)
    title.Position = UDim2.fromOffset(textOffset, data.Description and 0 or 0)
    local descriptionLabel
    if data.Description then
        descriptionLabel = textLabel(inner, data.Description, 10, data.Primary and self.Theme.Background or self.Theme.SubText, false)
        descriptionLabel.TextWrapped = false
        descriptionLabel.TextTruncate = Enum.TextTruncate.AtEnd
        descriptionLabel.Size = UDim2.new(1, -rightReserved - textOffset, 0, 16)
        descriptionLabel.Position = UDim2.fromOffset(textOffset, 17)
    end
    pressAnimation(self, row)
    if not self.ReduceEffects then
        connect(self, row.MouseEnter, function()
            tween(row, { BackgroundColor3 = self.Theme.ElementHover }, 0.12)
            tween(rowStroke, { Transparency = 0.05 }, 0.12)
            tween(hoverGlass, { BackgroundTransparency = 0.9 }, 0.12)
        end)
        connect(self, row.MouseLeave, function()
            tween(row, { BackgroundColor3 = data.Primary and self.Theme.Accent or self.Theme.Surface2 }, 0.18)
            tween(rowStroke, { Transparency = 0.4 }, 0.18)
            tween(hoverGlass, { BackgroundTransparency = 1 }, 0.18)
        end)
    end
    self:_registerSearch(row, (data.Name or "") .. " " .. (data.Description or ""), title)
    return row, inner, title, descriptionLabel
end

function AxelUI:_setActiveTab(tab, active)
    if not tab or not tab.Button then return end
    local color = active and self.Theme.Background or self.Theme.SubText
    local background = active and self.Theme.Accent or self.Theme.Surface
    tween(tab.Button, { BackgroundColor3 = background }, 0.18)
    tab.Button.BackgroundTransparency = active and 0.02 or 0
    setGoldGradientActive(tab.GoldGradient, active)
    if tab.TabStroke then
        tween(tab.TabStroke, { Transparency = active and 0.05 or 0.9, Color = active and self.Theme.Accent or self.Theme.Border }, 0.18)
    end
    setTextColor(tab.Title, color)
    if tab.Icon then setIconTint(tab.Icon, color, 0.18) end
    if tab.Indicator then
        tween(tab.Indicator, {
            BackgroundTransparency = active and 0 or 1,
            Size = UDim2.new(0, active and 3 or 0, 0.64, 0),
        }, 0.2, Enum.EasingStyle.Quint)
    end
end

function AxelUI:SelectTab(tab)
    if self._destroyed or not tab then return end
    if self._tabTween then pcall(function() self._tabTween:Cancel() end); self._tabTween = nil end
    local previous = self.ActiveTab
    local changed = previous ~= tab
    if changed and self._dropdownClose then pcall(self._dropdownClose) end
    local slide = tonumber(self.TabSlideOffset) or 18
    local direction = previous and tab.PageIndex and previous.PageIndex and tab.PageIndex < previous.PageIndex and -1 or 1
    for _, other in ipairs(self.Tabs) do
        local active = other == tab
        if active then
            other.Page.Visible = true
            if changed and self.TabAnimation then
                other.Page.Position = UDim2.fromOffset(slide * direction, 0)
                self._tabTween = tween(other.Page, { Position = UDim2.fromOffset(0, 0) }, self.TabAnimationDuration, Enum.EasingStyle.Quint)
            else
                other.Page.Position = UDim2.fromOffset(0, 0)
            end
        else
            other.Page.Visible = false
            other.Page.Position = UDim2.fromOffset(0, 0)
        end
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
    -- Keep dashboard navigation in sync with the regular sidebar. Pills are
    -- optional; tabs without a matching TargetTab continue to work normally.
    for _, dashboard in ipairs(self.Tabs) do
        local linkedPill
        for _, pill in ipairs(dashboard.Pills or {}) do
            if pill.TargetTab == tab then linkedPill = pill; break end
        end
        if linkedPill and dashboard.ActivePill ~= linkedPill then
            dashboard:SelectPill(linkedPill, true)
        end
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
    local status = tostring(text or "Ready")
    self.StatusText.Text = status
    local tint = color or self.Theme.Success
    self.StatusDot.BackgroundColor3 = tint
    self.StatusText.TextColor3 = tint
    if self.RestoreStatusText then
        self.RestoreStatusText.Text = status
        self.RestoreStatusText.TextColor3 = tint
    end
    if self.RestoreStatusDot then self.RestoreStatusDot.BackgroundColor3 = tint end
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
    self._open = visible
    if visible then
        self.Window.Visible = true
        self.Window.BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0
        if self.Scale then
            if self.AnimateOpenClose then
                self.Scale.Scale = 0.97
                tween(self.Scale, { Scale = 1 }, 0.14, Enum.EasingStyle.Quint)
            else
                self.Scale.Scale = 1
            end
        end
        if self.GlowStroke then
            tween(self.GlowStroke, { Transparency = 0.015, Thickness = 2 }, 0.14, Enum.EasingStyle.Quint)
            task.delay(0.62, function()
                if not self._destroyed and self._open then tween(self.GlowStroke, { Transparency = 0.2, Thickness = 1.5 }, 0.3) end
            end)
        end
        if self.RestoreButton and self.RestoreButton.Visible then
            tween(self.RestoreScale, { Scale = 0.65 }, 0.12)
            task.delay(0.13, function() if self._open and self.RestoreButton then self.RestoreButton.Visible = false end end)
        end
    else
        tween(self.GlowStroke, { Transparency = 0.72, Thickness = 1 }, 0.18)
        local function finishClose()
            if not self._destroyed and not self._open then
                self.Window.Visible = false
                if self.Scale then self.Scale.Scale = 1 end
                if self.RestoreButton then
                    self.RestoreButton.Position = UDim2.new(0.5, -94, 0.5, -24)
                    self.RestoreButton.Visible = true
                    self.RestoreButton.BackgroundTransparency = 0.08
                    local restoreStroke = self.RestoreButton:FindFirstChildOfClass("UIStroke")
                    if restoreStroke then restoreStroke.Transparency = 0.04 end
                    if self.RestoreScale then self.RestoreScale.Scale = 0.72; tween(self.RestoreScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back) end
                end
            end
        end
        if self.AnimateOpenClose then
            if self.Scale then tween(self.Scale, { Scale = 0.97 }, 0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.In) end
            task.delay(0.13, finishClose)
        else
            finishClose()
        end
    end
    setAccentAnimations(self, visible)
    if self.TouchButton and self.TouchButton ~= self.RestoreButton then self.TouchButton.Visible = not visible end
end

function AxelUI:SetMaximized(value)
    if self._destroyed or not self.Window then return end
    value = value == true
    if value then
        self._restoreSize = self.Window.Size
        self._maximized = true
    else
        self._maximized = false
        self.Window.Size = self._restoreSize or self.DesktopSize or UDim2.fromOffset(926, 616)
    end
    self:_applyResponsive()
end

function AxelUI:SetToggleKeybind(key)
    self.ToggleKeybind = key or Enum.KeyCode.RightControl
end

-- Glass is limited to the shell and the empty page backdrop. Header, sidebar,
-- cards and controls remain solid so their text and states stay readable.
function AxelUI:SetGlass(value, transparency)
    if type(value) == "table" then
        if value.Enabled ~= nil then self.GlassEnabled = value.Enabled == true end
        if value.Transparency ~= nil then transparency = value.Transparency end
    else
        self.GlassEnabled = value == true
    end
    if transparency ~= nil then
        self.GlassTransparency = math.clamp(tonumber(transparency) or 0, 0, 0.45)
    end
    if self.Window then
        self.Window.BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0
    end
    if self.PageHolder then
        self.PageHolder.BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0
        for _, cap in ipairs(self.PageCornerCaps or {}) do
            cap.BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0
        end
    end
    return self
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
        { old.Accent2, nextTheme.Accent2 }, { old.Accent3, nextTheme.Accent3 }, { old.Success, nextTheme.Success },
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
        pcall(function()
            if object:IsA("UIGradient") then
                local remapped, changed = {}, false
                for _, keypoint in ipairs(object.Color.Keypoints) do
                    local color = keypoint.Value
                    for _, pair in ipairs(palette) do
                        if sameColor(color, pair[1]) then color = pair[2]; changed = true; break end
                    end
                    table.insert(remapped, ColorSequenceKeypoint.new(keypoint.Time, color))
                end
                if changed then object.Color = ColorSequence.new(remapped) end
            end
        end)
    end
    for _, entry in pairs(self._searchData or {}) do
        if entry.BaseTitleColor then
            for _, pair in ipairs(palette) do
                if sameColor(entry.BaseTitleColor, pair[1]) then entry.BaseTitleColor = pair[2]; break end
            end
        end
    end
    pcall(function() self.Window.BackgroundColor3 = self.Theme.Background end)
    pcall(function() self.GlowStroke.Color = self.Theme.Accent end)
    pcall(function()
        if self.EdgeGradient then
            self.EdgeGradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, self.Theme.Accent3),
                ColorSequenceKeypoint.new(0.22, self.Theme.Accent),
                ColorSequenceKeypoint.new(0.5, self.Theme.Accent2),
                ColorSequenceKeypoint.new(0.78, self.Theme.Accent),
                ColorSequenceKeypoint.new(1, self.Theme.Accent3),
            })
        end
    end)
    self:_refreshSearch(self.Search and self.Search.Text or "")
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
    local desktopWidth

    if mobile then
        local maxWidth = math.max(180, math.min(480, viewport.X - 18))
        local maxHeight = math.max(220, math.min(720, viewport.Y - 26))
        local mobileSize = self.MobileSize
        local width = self._maximized and maxWidth or (mobileSize and math.clamp(mobileSize.X.Offset, math.min(300, maxWidth), maxWidth) or maxWidth)
        local height = self._maximized and maxHeight or (mobileSize and math.clamp(mobileSize.Y.Offset, math.min(360, maxHeight), maxHeight) or maxHeight)
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
        self.DragHandle.Visible = self.Draggable
        self.DragHandle.Position = UDim2.new(1, -132, 0, 5)
        self.DragHandle.Size = UDim2.fromOffset(24, 40)
        self.ResizeHandle.Visible = self.Resizable and not self._maximized
        self.ResizeHandle.Size = UDim2.fromOffset(28, 28)
        self.FpsText.Visible = false
        self.FpsValue.Visible = false
        self.StatusSeparator.Visible = false
        self.StatusDot.Visible = false
        self.StatusText.Visible = false
        self.Search.Position = UDim2.fromOffset(8, 9)
        self.Search.Size = UDim2.new(1, -146, 0, 32)
        self.SearchIcon.Position = UDim2.fromOffset(18, 17)
        self.TabTitle.TextSize = 13
        self.TabSubtitle.Visible = false
        self.TabHeader.Size = UDim2.new(1, 0, 0, 38)
        self.TabTitle.Position = UDim2.fromOffset(16, 8)
        if self.RestoreButton then self.RestoreButton.Visible = not self._open end
        self.NotificationHolder.Size = UDim2.fromOffset(220, 0)
        self.NotificationHolder.Position = UDim2.new(1, -10, 0, 58)
    else
        local maxWidth = math.max(320, math.min(1440, viewport.X - 32))
        local maxHeight = math.max(280, math.min(1000, viewport.Y - 32))
        if self._maximized then
            desktopWidth = math.max(1, viewport.X - 32)
            self.Window.Size = UDim2.new(1, -32, 1, -32)
        else
            local desired = self.DesktopSize or UDim2.fromOffset(926, 616)
            local desiredWidth = desired.X.Scale == 0 and desired.X.Offset or self.Window.AbsoluteSize.X
            local desiredHeight = desired.Y.Scale == 0 and desired.Y.Offset or self.Window.AbsoluteSize.Y
            desktopWidth = math.clamp(desiredWidth, math.min(760, maxWidth), maxWidth)
            self.Window.Size = UDim2.fromOffset(
                desktopWidth,
                math.clamp(desiredHeight, math.min(480, maxHeight), maxHeight)
            )
        end
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
        self.DragHandle.Visible = self.Draggable
        self.DragHandle.Position = UDim2.fromOffset(404, 0)
        self.DragHandle.Size = UDim2.new(1, -536, 1, 0)
        self.ResizeHandle.Visible = self.Resizable and not self._maximized
        self.ResizeHandle.Size = UDim2.fromOffset(24, 24)
        self.FpsText.Visible = true
        self.FpsValue.Visible = true
        self.StatusSeparator.Visible = true
        self.StatusDot.Visible = true
        self.StatusText.Visible = true
        self.Search.Position = UDim2.fromOffset(20, 14)
        self.Search.Size = UDim2.fromOffset(math.min(374, math.max(160, (desktopWidth or self.Window.AbsoluteSize.X) - 526)), 34)
        self.SearchIcon.Position = UDim2.fromOffset(31, 23)
        self.TabTitle.TextSize = 15
        self.TabSubtitle.Visible = true
        self.TabHeader.Size = UDim2.new(1, 0, 0, 46)
        self.TabTitle.Position = UDim2.fromOffset(22, 6)
        if self.RestoreButton then self.RestoreButton.Visible = not self._open end
        self.NotificationHolder.Size = UDim2.fromOffset(300, 0)
        self.NotificationHolder.Position = UDim2.new(1, -18, 0, 62)
    end

    -- Keep the rounded outer shell fully on-screen on short viewports and
    -- after a screen-orientation change, without resetting a valid drag.
    if not self._dragging then
        local absolute, size = self.Window.AbsolutePosition, self.Window.AbsoluteSize
        local left = math.clamp(absolute.X, 8, math.max(8, viewport.X - size.X - 8))
        local top = math.clamp(absolute.Y, 8, math.max(8, viewport.Y - size.Y - 8))
        if math.abs(left - absolute.X) > 1 or math.abs(top - absolute.Y) > 1 then
            self.Window.Position = UDim2.new(0.5, left + size.X / 2 - viewport.X / 2, 0.5, top + size.Y / 2 - viewport.Y / 2)
        end
    end

    for _, tab in ipairs(self.Tabs) do
        if tab.Title then tab.Title.Visible = not mobile end
        if tab.Subtitle then tab.Subtitle.Visible = not mobile end
        if tab.IconHolder then
            tab.IconHolder.Position = UDim2.fromOffset(mobile and 20 or 12, 7)
        end
        if tab.Hero and tab.PageBody and not tab.SubTabBar then
            local heroHeight = mobile and (tab.HeroMobileHeight or tab.HeroHeight or 104) or (tab.HeroHeight or 104)
            local heroTop = tab.HideHeader and (mobile and 16 or 18) or 50
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
            local heroTop = tab.HideHeader and (mobile and 16 or 18) or 50
            local pillY = heroHeight > 0 and (heroTop + heroHeight + 4) or 50
            tab.SubTabBar.Position = UDim2.fromOffset(mobile and 8 or 13, pillY)
            tab.SubTabBar.Size = UDim2.new(1, mobile and -16 or -26, 0, 42)
        end
        for _, subtab in ipairs(tab.SubTabs or {}) do
            if subtab.PageBody then
                local heroHeight = tab.Hero and (mobile and (tab.HeroMobileHeight or tab.HeroHeight or 104) or (tab.HeroHeight or 104)) or 0
                local heroTop = tab.HideHeader and (mobile and 16 or 18) or 50
                local contentY = heroHeight > 0 and (heroTop + heroHeight + 54) or 98
                local contentBottom = heroHeight > 0 and (heroTop + heroHeight + 64) or 108
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
    if self.Gui then
        for _, object in ipairs(self.Gui:GetDescendants()) do
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                pcall(function()
                    local weight = object.FontFace and object.FontFace.Weight
                    local bold = weight and weight.Value >= Enum.FontWeight.SemiBold.Value or false
                    object.FontFace = fontFace(font, bold)
                end)
            end
        end
    end
    return self
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
    local syncQueued = false
    local function queueSync()
        if syncQueued then return end
        syncQueued = true
        task.defer(function()
            syncQueued = false
            if window._destroyed then return end
            sync()
        end)
    end
    local function watch(child)
        if not child or not child:IsA("GuiObject") then return end
        connect(window, child:GetPropertyChangedSignal("Size"), queueSync)
        connect(window, child:GetPropertyChangedSignal("Visible"), queueSync)
    end
    connect(window, layout:GetPropertyChangedSignal("AbsoluteContentSize"), queueSync)
    connect(window, parent.ChildAdded, function(child) watch(child); queueSync() end)
    connect(window, parent.ChildRemoved, queueSync)
    for _, child in ipairs(parent:GetChildren()) do watch(child) end
    queueSync()
    return sync
end

local function makePageColumns(window, page, topOffset)
    -- AddTab is called on the window, while AddSubTab is called on a tab.
    -- Normalize both owners here so layout helpers always receive the window
    -- (Theme, connection registry, mobile state), never the tab wrapper.
    if not window.Theme and window.Window and window.Window.Theme then
        window = window.Window
    end
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
    local columnsSyncQueued = false
    local function queueSyncColumns()
        if columnsSyncQueued then return end
        columnsSyncQueued = true
        task.defer(function()
            columnsSyncQueued = false
            if window._destroyed then return end
            syncColumns()
        end)
    end
    connect(window, leftLayout:GetPropertyChangedSignal("AbsoluteContentSize"), queueSyncColumns)
    connect(window, rightLayout:GetPropertyChangedSignal("AbsoluteContentSize"), queueSyncColumns)
    connect(window, columnLayout:GetPropertyChangedSignal("AbsoluteContentSize"), queueSyncColumns)
    connect(window, leftColumn.ChildAdded, queueSyncColumns)
    connect(window, leftColumn.ChildRemoved, queueSyncColumns)
    connect(window, rightColumn.ChildAdded, queueSyncColumns)
    connect(window, rightColumn.ChildRemoved, queueSyncColumns)
    queueSyncColumns()
    return pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout
end

local function makeSubTabCard(window, parent, title)
    local card = new("Frame", {
        BackgroundColor3 = window.Theme.Surface,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, -5, 0, 0),
    }, parent)
    corner(card, 8)
    stroke(card, window.Theme.Border, 0.28, 1)
    if not window.ReduceEffects then
        new("UIGradient", {
            Color = ColorSequence.new(window.Theme.Surface, window.Theme.Background),
            Transparency = NumberSequence.new(0),
            Rotation = 90,
        }, card)
    end
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
        Size = UDim2.new(1, 0, 0, 40),
    }, self.TabList)
    corner(button, 11)
    local tabStroke = stroke(button, self.Theme.Border, 0.62, 1)
    tab.GoldGradient = addGoldGradient(self, button)
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
    tab.PageIndex = #self.Tabs

    connect(self, button.MouseButton1Click, function() self:SelectTab(tab) end)
    connect(self, button.MouseEnter, function()
        if self.ActiveTab ~= tab and tab.TabStroke then tween(tab.TabStroke, { Transparency = 0.24, Color = self.Theme.Accent2 }, 0.14) end
    end)
    connect(self, button.MouseLeave, function()
        if self.ActiveTab ~= tab and tab.TabStroke then tween(tab.TabStroke, { Transparency = 0.9, Color = self.Theme.Border }, 0.16) end
    end)
    addButtonGlass(self, button, 0)
    pressAnimation(self, button)
    if #self.Tabs == 1 then self:SelectTab(tab) end
    if self._applyResponsive then self:_applyResponsive() end
    if self.EmptyState then self.EmptyState.Visible = false end
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
    local heroTop = self.Window.IsMobile and 16 or 18
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
    local picture = new("ImageLabel", { BackgroundTransparency = 1, Image = source or "", ImageTransparency = tonumber(data.ImageTransparency) or 0.08, ScaleType = data.ScaleType or (data.ImageFit == true and Enum.ScaleType.Fit or Enum.ScaleType.Crop), Size = UDim2.fromScale(1, 1), ZIndex = 4 }, banner)
    local shade = new("Frame", { BackgroundColor3 = self.Window.Theme.Background, BackgroundTransparency = source and 0.28 or 0.04, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, banner)
    new("UIGradient", { Color = ColorSequence.new(self.Window.Theme.Background, self.Window.Theme.Element), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.04), NumberSequenceKeypoint.new(0.58, 0.22), NumberSequenceKeypoint.new(1, 0.78) }), Rotation = 0 }, shade)
    local bannerTextZ = math.max(tonumber(picture.ZIndex) or 0, tonumber(shade.ZIndex) or 0) + 2
    local fallback = textLabel(banner, data.FallbackText or "AXEL HUB", 11, source and self.Window.Theme.Muted or self.Window.Theme.Accent2, true)
    fallback.AnchorPoint = Vector2.new(0.5, 0.5); fallback.Position = UDim2.fromScale(0.78, 0.82); fallback.Size = UDim2.fromOffset(150, 18); fallback.TextXAlignment = Enum.TextXAlignment.Center; fallback.Visible = source == nil; fallback.ZIndex = bannerTextZ
    local fallbackIcon = icon(banner, "star", 32, self.Window.Theme.Accent2)
    fallbackIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    fallbackIcon.Position = UDim2.fromScale(0.78, 0.48)
    fallbackIcon.Visible = source == nil
    fallbackIcon.ZIndex = bannerTextZ
    if source then
        watchImage(picture, function()
            picture.Visible = true
            fallback.Visible = false
            fallbackIcon.Visible = false
        end, function()
            picture.Visible = false
            shade.BackgroundTransparency = 0.04
            fallback.Visible = true
            fallbackIcon.Visible = true
        end, 5, { imageThumbnailSource(source, 420, 420) })
    end
    local title = textLabel(banner, data.BannerTitle or data.Title or "Customize your experience", 14, self.Window.Theme.Text, true)
    title.Position = UDim2.fromOffset(14, 13); title.Size = UDim2.new(0.62, 0, 0, 22); title.ZIndex = bannerTextZ
    local content = textLabel(banner, data.Content or data.Description or "Simple. Powerful. Yours.", 10, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(14, 38); content.Size = UDim2.new(0.58, 0, 0, 26); content.TextWrapped = true; content.ZIndex = bannerTextZ
    local action
    if data.Button or data.ActionText then
        action = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = self.Window.Theme.Accent, BorderSizePixel = 0, Text = tostring(data.Button or data.ActionText), TextColor3 = self.Window.Theme.Background, TextSize = 10, FontFace = fontFace(nil, true), Size = UDim2.fromOffset(92, 27), Position = UDim2.fromOffset(14, math.max(62, height - 39)), ZIndex = 7 }, banner)
        action.ZIndex = bannerTextZ + 1
        corner(action, 8); pressAnimation(self.Window, action)
        connect(self.Window, action.MouseButton1Click, function() if type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback) end) end end)
    end
    self.Hero, self.HeroWelcome, self.HeroBanner = hero, welcome, banner
    self.HeroWelcomeLabel, self.HeroWelcomeTitle, self.HeroWelcomeContent = welcomeLabel, welcomeTitle, welcomeContent
    self.HeroImage, self.HeroFallback, self.HeroHeight, self.HeroMobileHeight = picture, fallback, height, mobileHeight
    self.Window:_registerSearch(hero, tostring(data.Title or "") .. " " .. tostring(data.Content or ""))
    if self.Window.ActiveTab == self and self.Window.TabHeader then self.Window.TabHeader.Visible = not self.HideHeader end
    if self.Window._applyResponsive then self.Window:_applyResponsive() end
    return { Instance = hero, Banner = banner, Image = picture, Fallback = fallback, FallbackIcon = fallbackIcon, Title = title, Content = content, WelcomeTitle = welcomeTitle, Button = action }
end

-- Lightweight dashboard pills. Unlike AddSubTab, these keep one dashboard
-- body intact. A pill may filter dashboard sections and/or route to a sidebar
-- tab through TargetTab, which also keeps selection synchronized both ways.
function AxelUI.TabMethods:LayoutPills()
    if not self.PillBar or not self.PageBody then return end
    local mobile = self.Window.IsMobile
    local heroHeight = self.Hero and (mobile and (self.HeroMobileHeight or self.HeroHeight or 104) or (self.HeroHeight or 104)) or 0
    local heroTop = self.HideHeader and (mobile and 16 or 18) or 50
    -- Give the pills a little more room from the hero and from the card row
    -- below so the outlines don't look crowded or collide with nearby edges.
    local pillY = heroHeight > 0 and (heroTop + heroHeight + 4) or 50
    local bodyY = heroHeight > 0 and (heroTop + heroHeight + 48) or 92
    local bodyBottom = heroHeight > 0 and (heroTop + heroHeight + 58) or 102
    self.PillBar.Position = UDim2.fromOffset(mobile and 8 or 13, pillY)
    self.PillBar.Size = UDim2.new(1, mobile and -16 or -26, 0, 42)
    self.PageBody.Position = UDim2.fromOffset(mobile and 8 or 13, bodyY)
    self.PageBody.Size = UDim2.new(1, mobile and -16 or -26, 1, -bodyBottom)
end

function AxelUI.TabMethods:SelectPill(pill, silent)
    if not pill then return end
    for _, other in ipairs(self.Pills or {}) do
        local active = other == pill
        other.Active = active
        tween(other.Button, { BackgroundColor3 = active and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
        other.Button.BackgroundTransparency = active and 0.02 or 0
        setGoldGradientActive(other.GoldGradient, active)
        if other.Stroke then tween(other.Stroke, { Transparency = active and 0.02 or 0.38, Color = active and self.Window.Theme.Accent2 or self.Window.Theme.Border, Thickness = active and 1.15 or 0.75 }, 0.16) end
        setTextColor(other.Title, active and self.Window.Theme.Background or self.Window.Theme.Accent2)
    end
    self.ActivePill = pill
    local selectedFilter = string.lower(tostring(pill.Filter or pill.Name or "overview"))
    local showAll = selectedFilter == "" or selectedFilter == "overview" or selectedFilter == "all"
    for _, section in ipairs(self.Sections or {}) do
        local sectionFilter = section.PillFilter
        if section.Card and sectionFilter ~= nil then
            section.Card.Visible = showAll or string.lower(tostring(sectionFilter)) == selectedFilter
        elseif section.Card and not showAll then
            -- Unassigned sections are part of the overview, not unrelated
            -- category pages. This keeps each pill scoped to its own controls.
            section.Card.Visible = false
        elseif section.Card then
            section.Card.Visible = true
        end
    end
    if not silent and pill.TargetTab and self.Window.ActiveTab ~= pill.TargetTab then
        self.Window:SelectTab(pill.TargetTab)
    end
    if not silent and type(pill.Callback) == "function" then
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
            ClipsDescendants = true,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, -26, 0, 34),
            Position = UDim2.fromOffset(13, 50),
            ZIndex = 3,
        }, self.Page)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
        }, self.PillBar)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder }, self.PillBar)
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
        Size = UDim2.fromOffset(buttonWidth, 30),
        ZIndex = 4,
    }, self.PillBar)
    corner(button, 15)
    local pillStroke = stroke(button, self.Window.Theme.Border, 0.38, 0.75)
    local goldGradient = addGoldGradient(self.Window, button)
    local title = button
    local pill = {
        Tab = self,
        Button = button,
        Title = title,
        Stroke = pillStroke,
        GoldGradient = goldGradient,
        Name = name,
        Filter = data.Filter or data.Category or name,
        TargetTab = data.TargetTab or data.Tab,
        Callback = data.Callback or data.callback,
        Active = false,
    }
    table.insert(self.Pills, pill)
    connect(self.Window, button.MouseButton1Click, function() self:SelectPill(pill) end)
    connect(self.Window, button.MouseEnter, function()
        if not pill.Active then
            tween(pillStroke, { Transparency = 0.08, Color = self.Window.Theme.Accent2, Thickness = 1.05 }, 0.13)
            tween(button, { BackgroundColor3 = self.Window.Theme.Surface2 }, 0.13)
        end
    end)
    connect(self.Window, button.MouseLeave, function()
        if not pill.Active then
            tween(pillStroke, { Transparency = 0.38, Color = self.Window.Theme.Border, Thickness = 0.75 }, 0.16)
            tween(button, { BackgroundColor3 = self.Window.Theme.Element }, 0.16)
        end
    end)
    addButtonGlass(self.Window, button, 0)
    pressAnimation(self.Window, button)
    if #self.Pills == 1 or data.Active or pill.TargetTab == self.Window.ActiveTab then self:SelectPill(pill) end
    self:LayoutPills()
    return pill
end

function AxelUI.TabMethods:SelectSubTab(subtab)
    if not subtab then return end
    for _, other in ipairs(self.SubTabs or {}) do
        local active = other == subtab
        other.Active = active
        if other.PageBody then other.PageBody.Visible = active end
        if other.Button then
            tween(other.Button, { BackgroundColor3 = active and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
            other.Button.BackgroundTransparency = active and 0.02 or 0
            setGoldGradientActive(other.GoldGradient, active)
            if other.Stroke then tween(other.Stroke, { Transparency = active and 0.02 or 0.38, Color = active and self.Window.Theme.Accent2 or self.Window.Theme.Border, Thickness = active and 1.15 or 0.75 }, 0.16) end
            setTextColor(other.Title, active and self.Window.Theme.Background or self.Window.Theme.Accent2)
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
            ClipsDescendants = true,
            ScrollBarThickness = 0,
            Size = UDim2.new(1, -26, 0, 42),
            Visible = true,
        }, self.Page)
        new("UIPadding", {
            PaddingLeft = UDim.new(0, 10),
            PaddingRight = UDim.new(0, 10),
            PaddingTop = UDim.new(0, 2),
            PaddingBottom = UDim.new(0, 2),
        }, self.SubTabBar)
        new("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            Padding = UDim.new(0, 12),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }, self.SubTabBar)
    end

    local buttonWidth = math.max(70, math.min(132, #subtab.Name * 7 + 28))
    local button = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        LayoutOrder = #self.SubTabs + 1,
        Text = subtab.Name,
        TextColor3 = self.Window.Theme.Accent2,
        TextSize = 10,
        FontFace = fontFace(nil, true),
        TextXAlignment = Enum.TextXAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextWrapped = false,
        TextStrokeColor3 = self.Window.Theme.Background,
        TextStrokeTransparency = 0.72,
        Size = UDim2.fromOffset(buttonWidth, 30),
        ZIndex = 4,
    }, self.SubTabBar)
    corner(button, 15)
    local subtabStroke = stroke(button, self.Window.Theme.Border, 0.38, 0.75)
    local goldGradient = addGoldGradient(self.Window, button)
    local title = button
    subtab.Button, subtab.Title = button, title
    subtab.Stroke, subtab.GoldGradient = subtabStroke, goldGradient
local pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout
    if #self.SubTabs == 0 then
        pageBody, columns, leftColumn, rightColumn, columnLayout = self.PageBody, self.Columns, self.LeftBody, self.RightBody, self.ColumnLayout
        leftLayout, rightLayout = self.Layout, self.RightBody and self.RightBody:FindFirstChildOfClass("UIListLayout")
        local heroHeight = self.Hero and (self.Window.IsMobile and (self.HeroMobileHeight or self.HeroHeight or 104) or (self.HeroHeight or 104)) or 0
        local heroTop = self.HideHeader and (self.Window.IsMobile and 16 or 18) or 50
        local contentY = heroHeight > 0 and (heroTop + heroHeight + 54) or 98
        local contentBottom = heroHeight > 0 and (heroTop + heroHeight + 64) or 108
        self.PageBody.Position = UDim2.fromOffset(13, contentY)
        self.PageBody.Size = UDim2.new(1, -26, 1, -contentBottom)
    else
        pageBody, columns, leftColumn, rightColumn, columnLayout, leftLayout, rightLayout = makePageColumns(self.Window, self.Page, 98)
    end
    local card, body, layout = makeSubTabCard(self.Window, leftColumn, subtab.Name)
    subtab.PageBody, subtab.Columns = pageBody, columns
    subtab.LeftBody, subtab.RightBody = leftColumn, rightColumn
    subtab.ColumnLayout, subtab.Layout = columnLayout, layout
    subtab.Body, subtab.Card = body, card
    subtab._nextSide = "Left"
    table.insert(self.SubTabs, subtab)

    connect(self.Window, button.MouseButton1Click, function() self:SelectSubTab(subtab) end)
    connect(self.Window, button.MouseEnter, function()
        if not subtab.Active then
            tween(subtabStroke, { Transparency = 0.08, Color = self.Window.Theme.Accent2, Thickness = 1.05 }, 0.13)
            tween(button, { BackgroundColor3 = self.Window.Theme.Surface2 }, 0.13)
        end
    end)
    connect(self.Window, button.MouseLeave, function()
        if not subtab.Active then
            tween(subtabStroke, { Transparency = 0.38, Color = self.Window.Theme.Border, Thickness = 0.75 }, 0.16)
            tween(button, { BackgroundColor3 = self.Window.Theme.Element }, 0.16)
        end
    end)
    addButtonGlass(self.Window, button, 0)
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
        PillFilter = data.Pill or data.Category or data.Filter,
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
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Size = UDim2.new(1, -5, 0, 0),
        LayoutOrder = data.LayoutOrder or 0,
    }, parent)
    corner(card, 9)
    stroke(card, self.Window.Theme.Border, 0.28, 1)
    if not self.Window.ReduceEffects then
        new("UIGradient", {
            Color = ColorSequence.new(self.Window.Theme.Surface, self.Window.Theme.Background),
            Transparency = NumberSequence.new(0),
            Rotation = 90,
        }, card)
    end
    local headerHeight = data.Description ~= "" and 48 or 35
    local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, headerHeight) }, card)
    pad(header, 12, 12, 8, 4)
    local title = textLabel(header, section.Name, 14, self.Window.Theme.Text, true)
    title.Size = UDim2.new(1, -52, 0, 18)
    local collapseButton = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(24, 22),
        Position = UDim2.new(1, -34, 0, 5),
    }, header)
    corner(collapseButton, 8)
    local collapseGlyph = icon(collapseButton, "plus", 14, self.Window.Theme.Accent2)
    collapseGlyph.AnchorPoint = Vector2.new(0.5, 0.5)
    collapseGlyph.Position = UDim2.fromScale(0.5, 0.5)
    local collapseVertical = nil
    for _, part in ipairs(collapseGlyph:GetChildren()) do
        if part.Name == "AxelIconLine" and math.abs(part.Rotation) > 45 then
            collapseVertical = part
            break
        end
    end
    if collapseVertical then collapseVertical.Visible = false end
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
    section.CollapseGlyph, section.CollapseVertical = collapseGlyph, collapseVertical
    function section:SetCollapsed(value)
        self.Collapsed = value == true
        if self.CollapseVertical then self.CollapseVertical.Visible = self.Collapsed end
        if self.Window.ReduceEffects then
            collapseButton.BackgroundColor3 = self.Collapsed and self.Window.Theme.Surface2 or self.Window.Theme.Element
        else
            tween(collapseButton, { BackgroundColor3 = self.Collapsed and self.Window.Theme.Surface2 or self.Window.Theme.Element }, 0.16)
        end
        if self.Collapsed then
            if self.Window.ReduceEffects then
                body.BackgroundTransparency = 1
            else
                tween(body, { BackgroundTransparency = 1 }, 0.12)
            end
            preserveHeight(card, headerHeight)
            if self.Window.ReduceEffects then
                body.Visible = false
            else
                task.delay(0.12, function() if body.Parent and self.Collapsed then body.Visible = false end end)
            end
        else
            body.Visible = true
            if self.Window.ReduceEffects then
                body.BackgroundTransparency = 1
            else
                tween(body, { BackgroundTransparency = 1 }, 0.14)
            end
            if syncBodyHeight then syncBodyHeight() end
        end
    end
    connect(self.Window, collapseButton.MouseButton1Click, function() section:SetCollapsed(not section.Collapsed) end)
    pressAnimation(self.Window, collapseButton)
    if not self.Window.ReduceEffects then
        connect(self.Window, collapseButton.MouseEnter, function()
            tween(collapseButton, { BackgroundColor3 = self.Window.Theme.Surface2 }, 0.12)
        end)
        connect(self.Window, collapseButton.MouseLeave, function()
            tween(collapseButton, { BackgroundColor3 = self.Window.Theme.Element }, 0.16)
        end)
    end
    self.Window:_registerSearch(card, section.Name .. " " .. section.Description, title, { Container = true })
    table.insert(self.Sections, section)
    if self.ActivePill then self:SelectPill(self.ActivePill, true) end
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
        ScaleType = data.ScaleType or (data.ImageFit == true and Enum.ScaleType.Fit or Enum.ScaleType.Crop),
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
    fallback.ZIndex = (tonumber(shade.ZIndex) or tonumber(picture.ZIndex) or 0) + 2
    fallback.Visible = source == nil
    if source then
        watchImage(picture, function()
            picture.Visible = true
            fallback.Visible = false
        end, function()
            picture.Visible = false
            shade.BackgroundTransparency = 0.08
            fallback.Visible = true
        end, 5, { imageThumbnailSource(source, 420, 420) })
    end
    local title = textLabel(holder, data.Title or data.Name or "Welcome", 14, self.Window.Theme.Text, true)
    local bannerTextZ = math.max(tonumber(picture.ZIndex) or 0, tonumber(shade.ZIndex) or 0) + 2
    title.Position = UDim2.fromOffset(14, 14); title.Size = UDim2.new(1, -28, 0, 22); title.ZIndex = bannerTextZ
    local content = textLabel(holder, data.Content or data.Description or "", 10, self.Window.Theme.SubText, false)
    content.Position = UDim2.fromOffset(14, 39); content.Size = UDim2.new(1, -170, 0, 34); content.TextWrapped = true; content.ZIndex = bannerTextZ
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
        action.ZIndex = bannerTextZ + 1
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
        ScaleType = data.ScaleType or (data.ImageFit == false and Enum.ScaleType.Crop or Enum.ScaleType.Fit),
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
    if source then
        watchImage(picture, function()
            picture.Visible = true
            fallback.Visible = false
        end, function()
            picture.Visible = false
            fallback.Visible = true
        end, 5, { imageThumbnailSource(source, 150, 150) })
    end
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
    data.RightReserved = data.RightReserved or 48
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
        corner(button, 8)
        local actionStroke = stroke(button, item.Primary and self.Window.Theme.Accent2 or self.Window.Theme.Border, 0.24, 1)
        pressAnimation(self.Window, button)
        addButtonGlass(self.Window, button, 0)
        connect(self.Window, button.MouseEnter, function()
            tween(button, { BackgroundColor3 = item.Primary and self.Window.Theme.Accent2 or self.Window.Theme.ElementHover }, 0.12)
            tween(actionStroke, { Transparency = 0.02, Color = self.Window.Theme.Accent2 }, 0.12)
        end)
        connect(self.Window, button.MouseLeave, function()
            tween(button, { BackgroundColor3 = item.Primary and self.Window.Theme.Accent or self.Window.Theme.Element }, 0.16)
            tween(actionStroke, { Transparency = 0.24, Color = item.Primary and self.Window.Theme.Accent2 or self.Window.Theme.Border }, 0.16)
        end)
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
    data.RightReserved = data.RightReserved or 68
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local track = new("Frame", {
        BackgroundColor3 = self.Window.Theme.Element,
        Size = UDim2.fromOffset(42, 22),
        Position = UDim2.new(1, -52, 0.5, -11),
        ZIndex = 8,
    }, inner)
    corner(track, 11)
    local trackStroke = stroke(track, self.Window.Theme.Border, 0.28, 1)
    local knob = new("Frame", { BackgroundColor3 = self.Window.Theme.Text, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3), ZIndex = 9 }, track)
    corner(knob, 8)
    local handle = { Value = data.Default == true, Row = row, Window = self.Window }
    local callbackRevision = 0
    local callbackScheduled = false
    local callbackRunning = false
    local function dispatchToggleCallback()
        local callback = data.Callback or data.callback
        if type(callback) ~= "function" then return end
        callbackRevision = callbackRevision + 1
        if callbackScheduled or callbackRunning then return end
        callbackScheduled = true
        -- Let the input event and the toggle's visual state settle first. A
        -- short per-toggle queue also collapses duplicate touch/mouse signals
        -- so a burst cannot start overlapping copies of the same feature.
        task.delay(0.06, function()
            callbackScheduled = false
            if not self.Window or self.Window._destroyed then return end
            local dispatchedRevision = callbackRevision
            local callbackValue = handle.Value
            callbackRunning = true
            task.spawn(function()
                if not self.Window or self.Window._destroyed then
                    callbackRunning = false
                    return
                end
                pcall(callback, callbackValue)
                callbackRunning = false
                if callbackRevision ~= dispatchedRevision then
                    dispatchToggleCallback()
                end
            end)
        end)
    end
    function handle:Set(value, silent)
        self.Value = value == true
        local x = self.Value and 23 or 3
        local knobPosition = UDim2.fromOffset(x, 3)
        local trackColor = self.Value and self.Window.Theme.Accent or self.Window.Theme.Element
        local strokeColor = self.Value and self.Window.Theme.Accent2 or self.Window.Theme.Border
        local strokeTransparency = self.Value and 0.04 or 0.28
        local strokeThickness = self.Value and 1.5 or 1
        if self.Window.ReduceEffects then
            knob.Position = knobPosition
            knob.BackgroundColor3 = self.Window.Theme.Text
            track.BackgroundColor3 = trackColor
            trackStroke.Color = strokeColor
            trackStroke.Transparency = strokeTransparency
            trackStroke.Thickness = strokeThickness
        else
            tween(knob, { Position = knobPosition, BackgroundColor3 = self.Window.Theme.Text }, 0.16)
            tween(track, { BackgroundColor3 = trackColor }, 0.16)
            tween(trackStroke, { Color = strokeColor, Transparency = strokeTransparency, Thickness = strokeThickness }, 0.16)
        end
        if not silent then dispatchToggleCallback() end
    end
    function handle:Get() return self.Value end
    local function activateToggle()
        if self.Window and self.Window._destroyed then return end
        handle:Set(not handle.Value)
    end
    local toggleConnection
    local activatedOk, activatedSignal = pcall(function() return row.Activated end)
    if activatedOk and activatedSignal then
        toggleConnection = connect(self.Window, activatedSignal, activateToggle)
    end
    if not toggleConnection then
        connect(self.Window, row.MouseButton1Click, activateToggle)
    end
    handle:Set(handle.Value, true)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddSlider(data)
    data = data or {}
    data.Icon = data.Icon or "chart"
    data.RightReserved = data.RightReserved or 145
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local minimum = tonumber(data.Min or data.Minimum) or 0
    local maximum = math.max(minimum, tonumber(data.Max or data.Maximum) or 100)
    local value = math.clamp(tonumber(data.Default) or minimum, minimum, maximum)
    local precision = tonumber(data.Decimals)
    if precision == nil then precision = minimum % 1 == 0 and maximum % 1 == 0 and 0 or 1 end
    precision = math.clamp(math.floor(precision), 0, 4)
    local valuePower = 10 ^ precision
    local function normalizeValue(number)
        number = math.clamp(tonumber(number) or minimum, minimum, maximum)
        return math.floor(number * valuePower + 0.5) / valuePower
    end
    local function formatValue(number)
        local formatted = string.format("%." .. tostring(precision) .. "f", number)
        if precision > 0 then formatted = formatted:gsub("(%..-)0+$", "%1"):gsub("%.$", "") end
        return formatted .. tostring(data.Suffix or "")
    end
    local valueText = textLabel(inner, "", 11, self.Window.Theme.Text, true)
    valueText.Size = UDim2.fromOffset(36, 18)
    valueText.Position = UDim2.new(1, -151, 0.5, -9)
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.TextTruncate = Enum.TextTruncate.AtEnd
    valueText.TextStrokeColor3 = self.Window.Theme.Background
    valueText.TextStrokeTransparency = 0.72
    valueText.Visible = data.ShowValue ~= false
    valueText.ZIndex = 12
    local bar = new("Frame", { BackgroundColor3 = self.Window.Theme.Element, Size = UDim2.fromOffset(92, 5), Position = UDim2.new(1, -106, 0.5, -2), ZIndex = 8 }, inner)
    corner(bar, 4)
    local fill = new("Frame", { BackgroundColor3 = self.Window.Theme.Accent, Size = UDim2.new(0, 0, 1, 0), ZIndex = 9 }, bar)
    corner(fill, 4)
    local thumb = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Window.Theme.Accent2,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        ZIndex = 10,
    }, bar)
    corner(thumb, 7); stroke(thumb, self.Window.Theme.Background, 0.12, 1)
    local dragArea = new("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Position = UDim2.new(1, -112, 0.5, -10),
        Size = UDim2.fromOffset(108, 20),
        ZIndex = 30,
    }, inner)
    local handle = { Value = value, Row = row }
    local function setFromX(x, silent)
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        local nextValue = minimum + (maximum - minimum) * ratio
        nextValue = normalizeValue(nextValue)
        handle.Value = nextValue
        valueText.Text = formatValue(nextValue)
        local snappedRatio = math.clamp((nextValue - minimum) / math.max(0.0001, maximum - minimum), 0, 1)
        fill.Size = UDim2.new(snappedRatio, 0, 1, 0)
        thumb.Position = UDim2.new(snappedRatio, 0, 0.5, 0)
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, nextValue) end)
        end
    end
    function handle:Set(nextValue, silent)
        nextValue = normalizeValue(nextValue)
        local ratio = (nextValue - minimum) / math.max(0.0001, maximum - minimum)
        handle.Value = nextValue
        valueText.Text = formatValue(nextValue)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        thumb.Position = UDim2.new(ratio, 0, 0.5, 0)
        if not silent and type(data.Callback or data.callback) == "function" then
            task.spawn(function() pcall(data.Callback or data.callback, nextValue) end)
        end
    end
    function handle:Get() return handle.Value end
    local sliding = false
    connect(self.Window, dragArea.InputBegan, function(input)
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
    data.RightReserved = data.RightReserved or 165
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local selected = data.Default
    local options = data.Options or data.Items or {}
    if type(options) ~= "table" then options = { options } end
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
    local selectorStroke = stroke(selector, self.Window.Theme.Border, 0.38, 1)
    pad(selector, 9, 26, 0, 0)
    selector.TextXAlignment = Enum.TextXAlignment.Left
    selector.TextTruncate = Enum.TextTruncate.AtEnd
    local arrow = icon(selector, "chevron", 13, self.Window.Theme.SubText)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.new(1, -14, 0.5, 0)
    arrow.ZIndex = selector.ZIndex + 1
    local popup
    local handle = { Value = selected, Row = row }
    local function setSelectorOpen(isOpen)
        tween(selector, {
            BackgroundColor3 = isOpen and self.Window.Theme.Background or self.Window.Theme.Element,
            TextColor3 = isOpen and self.Window.Theme.Accent2 or self.Window.Theme.Text,
        }, 0.12)
        tween(selectorStroke, {
            Color = isOpen and self.Window.Theme.Accent or self.Window.Theme.Border,
            Transparency = isOpen and 0.04 or 0.38,
            Thickness = isOpen and 1.25 or 1,
        }, 0.12)
        setIconTint(arrow, isOpen and self.Window.Theme.Accent2 or self.Window.Theme.SubText, 0.12)
    end
    local function close()
        if popup then
            local closingPopup = popup
            popup = nil
            animatePopupClose(closingPopup)
            tween(arrow, { Rotation = 0 }, 0.14)
            setSelectorOpen(false)
        end
        if self.Window._dropdownClose == close then self.Window._dropdownClose = nil end
    end
    local function open()
        if popup then close(); return end
        if self.Window._dropdownClose and self.Window._dropdownClose ~= close then pcall(self.Window._dropdownClose) end
        local popupWidth = 145
        local popupHeight = math.min(math.max(#options, 1) * 21 + 8, 150)
        popup = new("ScrollingFrame", {
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Window.Theme.Background,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarImageColor3 = self.Window.Theme.Accent,
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.fromOffset(popupWidth, popupHeight),
            ZIndex = 50,
        }, self.Window.Gui)
        corner(popup, 7); stroke(popup, self.Window.Theme.Accent, 0.08, 1.15); pad(popup, 3, 3, 3, 3)
        placePopup(popup, selector, popupWidth, popupHeight, true)
        animatePopupOpen(popup)
        setSelectorOpen(true)
        tween(arrow, { Rotation = 180 }, 0.16, Enum.EasingStyle.Quint)
        new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
        local function styleOption(button, option)
            local isSelected = tostring(option) == tostring(handle.Value)
            button.BackgroundColor3 = isSelected and self.Window.Theme.Accent or self.Window.Theme.Surface2
            button.TextColor3 = isSelected and self.Window.Theme.Background or self.Window.Theme.Text
        end
        if #options == 0 then
            new("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = fontFace(nil, false),
                Size = UDim2.new(1, 0, 0, 21),
                Text = "No options",
                TextColor3 = self.Window.Theme.SubText,
                TextSize = 10,
                ZIndex = 51,
            }, popup)
        end
        for _, option in ipairs(options) do
            local optionButton = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = tostring(option) == tostring(handle.Value) and self.Window.Theme.Accent or self.Window.Theme.Surface2,
                BorderSizePixel = 0,
                Text = tostring(option),
                TextColor3 = tostring(option) == tostring(handle.Value) and self.Window.Theme.Background or self.Window.Theme.Text,
                TextSize = 10,
                FontFace = fontFace(nil, false),
                Size = UDim2.new(1, 0, 0, 21),
                ZIndex = 51,
            }, popup)
            corner(optionButton, 4)
            pressAnimation(self.Window, optionButton)
            connect(self.Window, optionButton.MouseEnter, function()
                tween(optionButton, { BackgroundColor3 = self.Window.Theme.ElementHover, TextColor3 = self.Window.Theme.Accent2 }, 0.1)
            end)
            connect(self.Window, optionButton.MouseLeave, function() styleOption(optionButton, option) end)
            connect(self.Window, optionButton.Activated, function()
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
    function handle:SetOptions(nextOptions)
        if popup then close() end
        if type(nextOptions) ~= "table" then nextOptions = { nextOptions } end
        options = nextOptions
        local stillAvailable = false
        for _, option in ipairs(options) do
            if option == handle.Value then
                stillAvailable = true
                break
            end
        end
        if not stillAvailable then
            handle.Value = options[1]
            selector.Text = tostring(handle.Value or "Select")
        end
    end
    handle.SetItems = handle.SetOptions
    connect(self.Window, selector.Activated, open)
    pressAnimation(self.Window, selector)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddMultiDropdown(data)
    data = data or {}
    data.Icon = data.Icon or "chevron"
    data.RightReserved = data.RightReserved or 175
    local row, inner = self.Window:_makeRow(self.Body, data, data.Height or 40)
    local options = data.Options or data.Items or {}
    if type(options) ~= "table" then options = { options } end
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
    local selectorStroke = stroke(selector, self.Window.Theme.Border, 0.38, 1)
    pad(selector, 9, 27, 0, 0)
    selector.TextXAlignment = Enum.TextXAlignment.Left
    local popup
    local arrow = icon(selector, "chevron", 13, self.Window.Theme.SubText)
    arrow.AnchorPoint = Vector2.new(0.5, 0.5)
    arrow.Position = UDim2.new(1, -15, 0.5, 0)
    arrow.ZIndex = selector.ZIndex + 1
    local optionButtons = {}
    local handle = { Value = selected, Row = row }
    local function setSelectorOpen(isOpen)
        tween(selector, {
            BackgroundColor3 = isOpen and self.Window.Theme.Background or self.Window.Theme.Element,
            TextColor3 = isOpen and self.Window.Theme.Accent2 or self.Window.Theme.Text,
        }, 0.12)
        tween(selectorStroke, {
            Color = isOpen and self.Window.Theme.Accent or self.Window.Theme.Border,
            Transparency = isOpen and 0.04 or 0.38,
            Thickness = isOpen and 1.25 or 1,
        }, 0.12)
        setIconTint(arrow, isOpen and self.Window.Theme.Accent2 or self.Window.Theme.SubText, 0.12)
    end
    local function close()
        if popup then
            local closingPopup = popup
            popup = nil
            animatePopupClose(closingPopup)
            tween(arrow, { Rotation = 0 }, 0.14)
            setSelectorOpen(false)
        end
        optionButtons = {}
        if self.Window._dropdownClose == close then self.Window._dropdownClose = nil end
    end
    local function refreshButtons(animatedValue)
        for value, button in pairs(optionButtons) do
            if button and button.Parent then
                local isSelected = selectedSet[tostring(value)] == true
                button.Text = (isSelected and "ON  " or "OFF  ") .. tostring(value)
                local background = isSelected and self.Window.Theme.Accent or self.Window.Theme.Surface2
                local textColor = isSelected and self.Window.Theme.Background or self.Window.Theme.Text
                if animatedValue ~= nil and tostring(value) == tostring(animatedValue) then
                    tween(button, { BackgroundColor3 = background, TextColor3 = textColor }, 0.1)
                else
                    button.BackgroundColor3 = background
                    button.TextColor3 = textColor
                end
            end
        end
    end
    local function open()
        if popup then close(); return end
        if self.Window._dropdownClose and self.Window._dropdownClose ~= close then pcall(self.Window._dropdownClose) end
        local popupWidth = 140
        local popupHeight = math.min(math.max(#options, 1) * 21 + 8, 150)
        popup = new("ScrollingFrame", {
            Active = true,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            BackgroundColor3 = self.Window.Theme.Background,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(),
            ScrollBarImageColor3 = self.Window.Theme.Accent,
            ScrollBarThickness = 2,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            Size = UDim2.fromOffset(popupWidth, popupHeight),
            ZIndex = 60,
        }, self.Window.Gui)
        corner(popup, 7); stroke(popup, self.Window.Theme.Accent, 0.08, 1.15); pad(popup, 3, 3, 3, 3)
        placePopup(popup, selector, popupWidth, popupHeight, true)
        animatePopupOpen(popup)
        setSelectorOpen(true)
        tween(arrow, { Rotation = 180 }, 0.16, Enum.EasingStyle.Quint)
        new("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, popup)
        if #options == 0 then
            new("TextLabel", {
                BackgroundTransparency = 1,
                FontFace = fontFace(nil, false),
                Size = UDim2.new(1, 0, 0, 21),
                Text = "No options",
                TextColor3 = self.Window.Theme.SubText,
                TextSize = 10,
                ZIndex = 61,
            }, popup)
        end
        for _, option in ipairs(options) do
            local value = tostring(option)
            local optionButton = new("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = selectedSet[value] and self.Window.Theme.Accent or self.Window.Theme.Surface2,
                BorderSizePixel = 0,
                Text = (selectedSet[value] and "ON  " or "OFF  ") .. value,
                TextColor3 = selectedSet[value] and self.Window.Theme.Background or self.Window.Theme.Text,
                TextSize = 10,
                FontFace = fontFace(nil, false),
                Size = UDim2.new(1, 0, 0, 21),
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 61,
            }, popup)
            corner(optionButton, 4)
            pressAnimation(self.Window, optionButton)
            connect(self.Window, optionButton.MouseEnter, function()
                tween(optionButton, { BackgroundColor3 = self.Window.Theme.ElementHover, TextColor3 = self.Window.Theme.Accent2 }, 0.1)
            end)
            connect(self.Window, optionButton.MouseLeave, function()
                local isSelected = selectedSet[value] == true
                tween(optionButton, {
                    BackgroundColor3 = isSelected and self.Window.Theme.Accent or self.Window.Theme.Surface2,
                    TextColor3 = isSelected and self.Window.Theme.Background or self.Window.Theme.Text,
                }, 0.12)
            end)
            optionButtons[value] = optionButton
            connect(self.Window, optionButton.Activated, function()
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
                refreshButtons(value)
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
    connect(self.Window, selector.Activated, open)
    pressAnimation(self.Window, selector)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

function AxelUI.SectionMethods:AddColorPicker(data)
    data = data or {}
    data.Icon = data.Icon or "chart"
    data.RightReserved = data.RightReserved or 54
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
            Size = UDim2.fromOffset(196, 122),
            ZIndex = 70,
        }, self.Window.Gui)
        corner(popup, 7); stroke(popup, self.Window.Theme.Border, 0.05, 1); pad(popup, 8, 8, 8, 8)
        placePopup(popup, swatch, 196, 122)
        local paletteHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 58), ZIndex = 71 }, popup)
        local grid = new("UIGridLayout", { CellPadding = UDim2.fromOffset(6, 6), CellSize = UDim2.fromOffset(26, 26), SortOrder = Enum.SortOrder.LayoutOrder }, paletteHolder)
        for _, color in ipairs(palette) do
            local colorButton = new("TextButton", { AutoButtonColor = false, BackgroundColor3 = color, BorderSizePixel = 0, Text = "", ZIndex = 72 }, paletteHolder)
            corner(colorButton, 6); stroke(colorButton, self.Window.Theme.Border, 0.2, 1)
            pressAnimation(self.Window, colorButton)
            connect(self.Window, colorButton.MouseButton1Click, function() choose(color) end)
        end
        local hexBox = new("TextBox", {
            BackgroundColor3 = self.Window.Theme.Element,
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            FontFace = fontFace(nil, false),
            PlaceholderColor3 = self.Window.Theme.Muted,
            PlaceholderText = "#RRGGBB",
            Size = UDim2.fromOffset(112, 25),
            Position = UDim2.fromOffset(0, 72),
            Text = "",
            TextColor3 = self.Window.Theme.Text,
            TextSize = 11,
            ZIndex = 72,
        }, popup)
        corner(hexBox, 5); stroke(hexBox, self.Window.Theme.Border, 0.2, 1); pad(hexBox, 7, 7, 0, 0)
        local applyHex = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.Window.Theme.Accent,
            BorderSizePixel = 0,
            FontFace = fontFace(nil, true),
            Position = UDim2.fromOffset(120, 72),
            Size = UDim2.fromOffset(60, 25),
            Text = "Apply",
            TextColor3 = self.Window.Theme.Background,
            TextSize = 10,
            ZIndex = 72,
        }, popup)
        corner(applyHex, 5); pressAnimation(self.Window, applyHex)
        local function commitHex()
            local value = hexBox.Text:gsub("#", ""):gsub("%s", "")
            if not value:match("^%x%x%x%x%x%x$") then
                tween(hexBox, { BackgroundColor3 = self.Window.Theme.Danger }, 0.1)
                task.delay(0.25, function() if hexBox.Parent then tween(hexBox, { BackgroundColor3 = self.Window.Theme.Element }, 0.16) end end)
                return
            end
            choose(Color3.fromRGB(tonumber(value:sub(1, 2), 16), tonumber(value:sub(3, 4), 16), tonumber(value:sub(5, 6), 16)))
        end
        connect(self.Window, applyHex.MouseButton1Click, commitHex)
        connect(self.Window, hexBox.FocusLost, function(enterPressed) if enterPressed then commitHex() end end)
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
    local fullWidth = data.FullWidth == true or data.Layout == "Stacked"
    data.RightReserved = data.RightReserved or (fullWidth and 18 or 170)
    local row, inner, title = self.Window:_makeRow(self.Body, data, data.Height or (fullWidth and 60 or 42))
    local titleX = title and title.Position.X.Offset or 27
    local box = new("TextBox", {
        BackgroundColor3 = self.Window.Theme.Element,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        MultiLine = false,
        PlaceholderText = tostring(data.Placeholder or "Input"),
        PlaceholderColor3 = self.Window.Theme.Muted,
        Text = tostring(data.Default or ""),
        TextColor3 = self.Window.Theme.Text,
        TextSize = 11,
        TextWrapped = false,
        TextScaled = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        FontFace = fontFace(nil, false),
        Size = fullWidth and UDim2.new(1, -(titleX + 18), 0, 24) or UDim2.fromOffset(160, 25),
        Position = fullWidth and UDim2.new(0, titleX, 0, 28) or UDim2.new(1, -170, 0.5, -12),
        ZIndex = 8,
    }, inner)
    corner(box, 5)
    pad(box, 8, 8, 0, 0)
    local boxStroke = stroke(box, self.Window.Theme.Border, 0.35, 1)
    local handle = { Instance = box, Value = box.Text }
    function handle:Set(value, silent)
        self.Value = tostring(value or ""); box.Text = self.Value
        if not silent and type(data.Callback or data.callback) == "function" then task.spawn(function() pcall(data.Callback or data.callback, self.Value) end) end
    end
    function handle:Get() return box.Text end
    connect(self.Window, box.Focused, function()
        tween(boxStroke, { Color = self.Window.Theme.Accent, Transparency = 0.04, Thickness = 1.15 }, 0.12)
    end)
    connect(self.Window, box.FocusLost, function() handle:Set(box.Text) end)
    connect(self.Window, box.FocusLost, function()
        tween(boxStroke, { Color = self.Window.Theme.Border, Transparency = 0.35, Thickness = 1 }, 0.14)
    end)
    self.Window:_registerFlag(data.Flag, handle)
    table.insert(self.Controls, handle)
    return handle
end

AxelUI.SectionMethods.AddTextbox = AxelUI.SectionMethods.AddInput

function AxelUI.SectionMethods:AddKeybind(data)
    data = data or {}
    data.Icon = data.Icon or "settings"
    data.RightReserved = data.RightReserved or 110
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
    local copyable = data.Copyable == true or data.Copy == true
    local inlineValue = data.ValueInDescription == true
    local initialText = tostring(data.Text or data.Status or "Ready")
    if inlineValue then
        data.Description = data.Description or (tostring(data.ValuePrefix or "") .. initialText)
        data.RightReserved = tonumber(data.RightReserved) or (copyable and 36 or 8)
    else
        data.RightReserved = math.max(tonumber(data.RightReserved) or 180, copyable and 206 or 180)
    end
    local row, inner, _, descriptionLabel = self.Window:_makeRow(self.Body, data, data.Height or 34)
    local status = textLabel(inner, data.Text or data.Status or "Ready", 11, data.Color or self.Window.Theme.Success, true)
    local statusWidth = copyable and 176 or 180
    status.Size = UDim2.new(0, statusWidth, 0, 24)
    status.Position = UDim2.new(1, copyable and -206 or -180, 0, 0)
    status.TextXAlignment = Enum.TextXAlignment.Right
    status.TextTruncate = Enum.TextTruncate.AtEnd
    status.ZIndex = 8
    status.Visible = not inlineValue
    if inlineValue and descriptionLabel and data.ValueDescriptionColor then
        descriptionLabel.TextColor3 = data.ValueDescriptionColor
    end
    local copyIcon
    if copyable then
        copyIcon = icon(inner, "copy", 13, data.CopyColor or self.Window.Theme.Accent2)
        copyIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        copyIcon.Position = UDim2.new(1, -9, 0.5, 0)
        copyIcon.ZIndex = 9
    end
    local handle = {
        Instance = status,
        Row = row,
        Window = self.Window,
        Text = tostring(data.Text or data.Status or "Ready"),
        Color = data.Color or self.Window.Theme.Success,
        Copyable = copyable,
        CopyValue = data.CopyValue ~= nil and tostring(data.CopyValue) or tostring(data.Text or data.Status or "Ready"),
        CopyIcon = copyIcon,
        DescriptionInstance = descriptionLabel,
    }
    function handle:Set(value, color, copyValue, description)
        self.Text = tostring(value or "Ready")
        self.Color = color or self.Color
        self.CopyValue = copyValue ~= nil and tostring(copyValue) or self.Text
        status.Text = self.Text
        status.TextColor3 = self.Color
        if inlineValue and descriptionLabel then
            descriptionLabel.Text = tostring(description ~= nil and description or (tostring(data.ValuePrefix or "") .. self.Text))
            descriptionLabel.TextColor3 = data.ValueDescriptionColor or self.Color
        end
    end
    function handle:Get() return self.Text end
    function handle:Copy()
        if not self.Copyable then return false end
        local value = tostring(self.CopyValue or self.Text or "")
        if value == "" then
            pcall(function() self.Window:Notify("Copy unavailable", "There is no value to copy.", "warning") end)
            return false
        end
        local ok, result
        if type(data.CopyCallback) == "function" then
            ok, result = pcall(data.CopyCallback, value)
            ok = ok and result ~= false
        else
            local copier = setclipboard or toclipboard
            if type(copier) == "function" then
                ok, result = pcall(copier, value)
                ok = ok and result ~= false
            else
                ok = false
            end
        end
        if ok then
            pcall(function() self.Window:Notify(data.CopyTitle or "Copied", tostring(data.CopyLabel or data.Name or "Value") .. " copied to clipboard.", "success") end)
        else
            pcall(function() self.Window:Notify("Copy unavailable", "Clipboard access is unavailable.", "warning") end)
        end
        if type(data.Callback) == "function" then task.spawn(function() pcall(data.Callback, value, ok) end) end
        return ok
    end
    if copyable then connect(self.Window, row.MouseButton1Click, function() handle:Copy() end) end
    table.insert(self.Controls, handle)
    return handle
end

-- Profile card for session dashboards. It keeps the avatar, account name and
-- account metadata together, while allowing the caller to refresh the fields.
function AxelUI.SectionMethods:AddProfileCard(data)
    data = data or {}
    local window = self.Window
    local card = new("Frame", {
        BackgroundColor3 = window.Theme.Background,
        BorderSizePixel = 0,
        LayoutOrder = data.LayoutOrder or 0,
        Size = UDim2.new(1, 0, 0, 72),
    }, self.Body)
    corner(card, 8); stroke(card, window.Theme.Border, 0.22, 1)

    local avatarHolder = new("Frame", {
        BackgroundColor3 = window.Theme.Element,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Position = UDim2.new(0, 10, 0.5, -25),
        Size = UDim2.fromOffset(50, 50),
    }, card)
    corner(avatarHolder, 25); stroke(avatarHolder, data.AvatarBorderColor or window.Theme.Accent2, 0.18, 1)
    local avatar = new("ImageLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Image = "",
        ScaleType = Enum.ScaleType.Crop,
        Size = UDim2.fromScale(1, 1),
        Visible = false,
        ZIndex = 7,
    }, avatarHolder)
    corner(avatar, 25)
    local avatarFallback = icon(avatarHolder, data.Icon or "user", 21, data.IconColor or window.Theme.Accent2)
    avatarFallback.AnchorPoint = Vector2.new(0.5, 0.5)
    avatarFallback.Position = UDim2.fromScale(0.5, 0.5)
    avatarFallback.ZIndex = 6

    local nameLabel = textLabel(card, "Player", 12, window.Theme.Text, true)
    nameLabel.Position = UDim2.fromOffset(72, 7)
    nameLabel.Size = UDim2.new(1, -82, 0, 17)
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local usernameLabel = textLabel(card, "@player", 9, window.Theme.SubText, false)
    usernameLabel.Position = UDim2.fromOffset(72, 25)
    usernameLabel.Size = UDim2.new(1, -82, 0, 14)
    usernameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    local accountLabel = textLabel(card, "Account Age: -- days", 9, window.Theme.Accent2, true)
    accountLabel.Position = UDim2.fromOffset(72, 43)
    accountLabel.Size = UDim2.new(1, -82, 0, 14)
    accountLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local handle = { Instance = card, Avatar = avatar, Name = nameLabel, Username = usernameLabel, Account = accountLabel }
    local avatarIdentity
    local function updateAvatar(values)
        local userId = tonumber(values.AvatarUserId or values.UserId or values.AccountId)
        local requestedImage = values.AvatarImage or values.Image
        local identity = tostring(requestedImage or userId or "")
        if identity == avatarIdentity then return end
        avatarIdentity = identity
        local source = imageSource(requestedImage, window.AssetFolder)
        local retries = {}
        if userId then
            local headshot = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
            local avatarImage = string.format("rbxthumb://type=Avatar&id=%d&w=150&h=150", userId)
            if not source then source = headshot elseif source ~= headshot then table.insert(retries, headshot) end
            if source ~= avatarImage then table.insert(retries, avatarImage) end
        end
        if source then
            avatar.Image = source
            watchImage(avatar, function()
                avatar.Visible = true
            end, function()
                avatar.Visible = false
                avatarFallback.Visible = true
            end, 5, retries)
        else
            avatar.Image = ""
            avatar.Visible = false
            avatarFallback.Visible = true
        end
    end
    function handle:Set(values)
        values = type(values) == "table" and values or { DisplayName = values }
        local displayName = values.DisplayName or values.Name or "Player"
        local username = tostring(values.Username or values.UserName or values.Name or "player")
        if username:sub(1, 1) ~= "@" then username = "@" .. username end
        local userId = values.UserId or values.AccountId
        if userId ~= nil then username = username .. " · ID: " .. tostring(userId) end
        local age = values.AccountAge or values.Age
        local ageText = age == nil and "Account Age: --" or "Account Age: " .. tostring(age) .. (type(age) == "number" and " days" or "")
        nameLabel.Text = tostring(displayName)
        usernameLabel.Text = username
        accountLabel.Text = tostring(values.AccountText or ageText)
        accountLabel.TextColor3 = values.AccountColor or window.Theme.Accent2
        updateAvatar(values)
        self.DisplayName = tostring(displayName)
        self.UserId = userId and tostring(userId) or ""
        self.AccountAge = age
    end
    function handle:Get()
        return { DisplayName = self.DisplayName, UserId = self.UserId, AccountAge = self.AccountAge }
    end
    handle:Set(data)
    window:_registerSearch(card, tostring(data.DisplayName or data.Name or "") .. " " .. tostring(data.Username or data.UserName or "") .. " " .. tostring(data.UserId or ""))
    table.insert(self.Controls, handle)
    return handle
end

-- Compact 2-column status tiles for dashboard telemetry such as FPS, ping,
-- uptime and player counts. Each returned metric has the same Set/Get shape
-- as AddStatus, and can be fetched by Key or Name.
function AxelUI.SectionMethods:AddMetricGrid(data)
    data = data or {}
    local window = self.Window
    local items = data.Items or data.Metrics or {}
    if type(items) ~= "table" then items = {} end
    local columns = math.max(1, math.floor(tonumber(data.Columns) or 2))
    local gap = math.max(0, tonumber(data.Gap) or 8)
    local cellHeight = math.max(42, tonumber(data.CellHeight) or 50)
    local itemCount = #items
    local rowCount = math.max(1, math.ceil(itemCount / columns))
    local gridHeight = itemCount > 0 and (rowCount * cellHeight + math.max(0, rowCount - 1) * gap) or 0
    local grid = new("Frame", {
        BackgroundTransparency = 1,
        LayoutOrder = data.LayoutOrder or 0,
        Size = UDim2.new(1, 0, 0, gridHeight),
    }, self.Body)
    new("UIGridLayout", {
        CellPadding = UDim2.fromOffset(gap, gap),
        CellSize = UDim2.new(1 / columns, -gap * (columns - 1) / columns, 0, cellHeight),
        FillDirection = Enum.FillDirection.Horizontal,
        FillDirectionMaxCells = columns,
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, grid)

    local handle = { Instance = grid, Metrics = {} }
    for index, item in ipairs(items) do
        item = type(item) == "table" and item or { Name = tostring(item), Value = "--" }
        local metricName = tostring(item.Name or item.Title or ("Metric " .. tostring(index)))
        local metricColor = item.Color or window.Theme.Accent2
        local tile = new("Frame", {
            BackgroundColor3 = window.Theme.Background,
            BorderSizePixel = 0,
            LayoutOrder = item.LayoutOrder or index,
        }, grid)
        corner(tile, 7); stroke(tile, window.Theme.Border, 0.22, 1)
        local metricIcon = icon(tile, item.Icon or "activity", 15, item.IconColor or metricColor)
        metricIcon.Position = UDim2.fromOffset(8, 6)
        -- Keep this icon above the tile under global ScreenGui ZIndex.
        metricIcon.ZIndex = (tonumber(tile.ZIndex) or 0) + 1
        local metricTitle = textLabel(tile, metricName, 9, window.Theme.SubText, false)
        metricTitle.Position = UDim2.fromOffset(26, 5)
        metricTitle.Size = UDim2.new(1, -32, 0, 15)
        metricTitle.TextTruncate = Enum.TextTruncate.AtEnd
        local metricValue = textLabel(tile, tostring(item.Value or item.Text or "--"), 13, metricColor, true)
        metricValue.Position = UDim2.fromOffset(8, 24)
        metricValue.Size = UDim2.new(1, -16, 0, 19)
        metricValue.TextTruncate = Enum.TextTruncate.AtEnd
        local metric = { Instance = metricValue, Tile = tile, Title = metricTitle, Icon = metricIcon, Text = metricValue.Text, Color = metricColor }
        function metric:Set(value, color)
            self.Text = tostring(value or "--")
            self.Color = color or self.Color
            metricValue.Text = self.Text
            metricValue.TextColor3 = self.Color
            if item.IconColor == nil then setIconTint(metricIcon, self.Color, window.ReduceEffects and 0 or nil) end
        end
        function metric:Get() return self.Text end
        local key = tostring(item.Key or metricName)
        handle.Metrics[key] = metric
        handle.Metrics[metricName] = metric
        table.insert(self.Controls, metric)
        window:_registerSearch(tile, metricName .. " " .. tostring(item.Description or ""))
    end
    function handle:Get(key)
        return self.Metrics[tostring(key or "")]
    end
    function handle:Set(key, value, color)
        local metric = self:Get(key)
        if metric then metric:Set(value, color) end
        return metric
    end
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
AxelUI.SectionMethods.ProfileCard = AxelUI.SectionMethods.AddProfileCard
AxelUI.SectionMethods.MetricGrid = AxelUI.SectionMethods.AddMetricGrid
AxelUI.SectionMethods.Separator = AxelUI.SectionMethods.AddDivider
AxelUI.SectionMethods.CreateToggle = AxelUI.SectionMethods.AddToggle
AxelUI.SectionMethods.CreateSlider = AxelUI.SectionMethods.AddSlider
AxelUI.SectionMethods.CreateDropdown = AxelUI.SectionMethods.AddDropdown
AxelUI.SectionMethods.CreateMultiDropdown = AxelUI.SectionMethods.AddMultiDropdown
AxelUI.SectionMethods.CreateButton = AxelUI.SectionMethods.AddButton
AxelUI.SectionMethods.CreateInput = AxelUI.SectionMethods.AddInput
AxelUI.SectionMethods.CreateKeybind = AxelUI.SectionMethods.AddKeybind
AxelUI.SectionMethods.CreateColorPicker = AxelUI.SectionMethods.AddColorPicker
AxelUI.SectionMethods.CreateTextbox = AxelUI.SectionMethods.AddInput
AxelUI.SectionMethods.CreateStatus = AxelUI.SectionMethods.AddStatus
AxelUI.SectionMethods.CreateProfileCard = AxelUI.SectionMethods.AddProfileCard
AxelUI.SectionMethods.CreateMetricGrid = AxelUI.SectionMethods.AddMetricGrid
AxelUI.SectionMethods.CreateDivider = AxelUI.SectionMethods.AddDivider
AxelUI.SectionMethods.CreateImage = AxelUI.SectionMethods.AddImage
AxelUI.SectionMethods.CreateBanner = AxelUI.SectionMethods.AddBanner
AxelUI.SectionMethods.CreateActionBar = AxelUI.SectionMethods.AddActionBar
AxelUI.SectionMethods.CreateText = AxelUI.SectionMethods.AddText
AxelUI.SectionMethods.CreateParagraph = AxelUI.SectionMethods.AddParagraph
AxelUI.SectionMethods.CreateLabel = AxelUI.SectionMethods.AddLabel

function AxelUI.TabMethods:Section(data)
    return self:AddSection(data)
end

function AxelUI.TabMethods:CreateSection(data)
    return self:AddSection(data)
end

function AxelUI.TabMethods:CreateSubTab(data)
    return self:AddSubTab(data)
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
    if self._edgeTween then pcall(function() self._edgeTween:Cancel() end); self._edgeTween = nil end
    if self._tabTween then pcall(function() self._tabTween:Cancel() end); self._tabTween = nil end
    for _, entry in ipairs(self._accentTweens or {}) do
        if entry.Gradient then GOLD_GRADIENT_ANIMATIONS[entry.Gradient] = nil end
        if entry.Tween then pcall(function() entry.Tween:Cancel() end) end
    end
    for _, animation in ipairs(self._glintTweens or {}) do pcall(function() animation:Cancel() end) end
    self._accentTweens = {}
    self._glintTweens = {}
    for _, connection in ipairs(self._connections) do pcall(function() connection:Disconnect() end) end
    self._connections = {}
    if self._dropdownClose then pcall(self._dropdownClose) end
    if self.Gui then pcall(function() self.Gui:Destroy() end) end
    if self._globalKey and _G[self._globalKey] == self then _G[self._globalKey] = nil end
    local registry = self._windowRegistry
    if registry and self._globalKey and registry[self._globalKey] == self then
        registry[self._globalKey] = nil
        if next(registry) == nil and self._sharedEnvironment
            and self._sharedEnvironment.__AxelUI_WindowRegistry == registry then
            self._sharedEnvironment.__AxelUI_WindowRegistry = nil
        end
    end
    if AxelUI._activeWindow == self then
        AxelUI._activeWindow = nil
        ACTIVE_FONT = nil
        ACTIVE_ASSET_FOLDER = nil
    end
    self._flags = {}
    self._searchRows = {}
    self._searchData = setmetatable({}, { __mode = "k" })
    self._notifications = {}
    self.Tabs = {}
    self.ActiveTab = nil
    self._loadingOverlay = nil
    self.RestoreButton = nil
    self.TouchButton = nil
    self.Window = nil
    self.Gui = nil
    self._windowRegistry = nil
    self._sharedEnvironment = nil
    return true
end

function AxelUI:Destroy()
    return self:Unload()
end

-- Ask before removing the whole interface. Unload() remains the direct API for
-- scripts that intentionally tear down immediately; visible close controls use
-- this guarded version so an accidental click cannot destroy the UI.
function AxelUI:ConfirmUnload()
    if self._destroyed or not self.Gui then return false end
    if self._confirmOverlay and self._confirmOverlay.Parent then return true end
    local overlay = new("Frame", {
        BackgroundColor3 = self.Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 400,
    }, self.Gui)
    local dimmer = new("Frame", { Active = true, BackgroundColor3 = self.Theme.Background, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 401 }, overlay)
    local card = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(300, 142),
        ZIndex = 401,
    }, overlay)
    corner(card, 12)
    local cardStroke = stroke(card, self.Theme.Accent2, 0.28, 1.2)
    local cardScale = new("UIScale", { Scale = 0.84 }, card)
    local title = textLabel(card, "Unload Axel Hub?", 14, self.Theme.Text, true)
    title.Position = UDim2.fromOffset(18, 16); title.Size = UDim2.new(1, -36, 0, 22); title.ZIndex = 402
    local body = textLabel(card, "The UI and its listeners will be removed.", 10, self.Theme.SubText, false)
    body.Position = UDim2.fromOffset(18, 43); body.Size = UDim2.new(1, -36, 0, 18); body.ZIndex = 402
    local cancel = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Element,
        BorderSizePixel = 0,
        Text = "Cancel",
        TextColor3 = self.Theme.Text,
        TextSize = 10,
        FontFace = fontFace(nil, true),
        Size = UDim2.fromOffset(112, 30),
        Position = UDim2.fromOffset(18, 94),
        ZIndex = 402,
    }, card)
    corner(cancel, 8); stroke(cancel, self.Theme.Border, 0.2, 1); pressAnimation(self, cancel)
    local confirm = new("TextButton", {
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        Text = "Unload",
        TextColor3 = self.Theme.Background,
        TextSize = 10,
        FontFace = fontFace(nil, true),
        Size = UDim2.fromOffset(112, 30),
        Position = UDim2.new(1, -130, 0, 94),
        ZIndex = 402,
    }, card)
    corner(confirm, 8); pressAnimation(self, confirm)
    local closing = false
    local function closePrompt(unload)
        if closing then return end
        closing = true
        tween(dimmer, { BackgroundTransparency = 1 }, 0.14)
        tween(cardScale, { Scale = 0.88 }, 0.14, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tween(cardStroke, { Transparency = 0.65, Thickness = 1 }, 0.14)
        task.delay(0.16, function()
            if overlay.Parent then overlay:Destroy() end
            self._confirmOverlay = nil
            if unload and not self._destroyed then self:Unload() end
        end)
    end
    self._confirmOverlay = overlay
    tween(dimmer, { BackgroundTransparency = 0.42 }, 0.16, Enum.EasingStyle.Quint)
    tween(cardScale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
    tween(cardStroke, { Transparency = 0.04, Thickness = 1.6 }, 0.18, Enum.EasingStyle.Quint)
    connect(self, cancel.MouseButton1Click, function() closePrompt(false) end)
    connect(self, confirm.MouseButton1Click, function() closePrompt(true) end)
    return true
end

AxelUI.RequestUnload = AxelUI.ConfirmUnload

function AxelUI:Toggle()
    if not self.Window then return end
    self:SetOpen(not self._open)
end

function AxelUI.new(options)
    options = options or {}
    local glassOptions = type(options.Glass) == "table" and options.Glass or {}
    local globalKey = tostring(options.GuiName or options.Name or "AxelUI")
    local sharedEnvironment = getSharedEnvironment()
    local windowRegistry = sharedEnvironment.__AxelUI_WindowRegistry
    if type(windowRegistry) ~= "table" then
        windowRegistry = {}
        sharedEnvironment.__AxelUI_WindowRegistry = windowRegistry
    end
    local seenWindows = {}
    local previousWindows = {}
    if windowRegistry[globalKey] then table.insert(previousWindows, windowRegistry[globalKey]) end
    if _G[globalKey] then table.insert(previousWindows, _G[globalKey]) end
    if AxelUI._activeWindow then table.insert(previousWindows, AxelUI._activeWindow) end
    for _, previous in ipairs(previousWindows) do
        if previous and not seenWindows[previous] then
            seenWindows[previous] = true
            local matchesName = previous == windowRegistry[globalKey]
                or (type(previous) == "table" and previous._globalKey == globalKey)
            if matchesName and type(previous) == "table" and type(previous.Unload) == "function" then
                pcall(function() previous:Unload() end)
            end
        end
    end
    sharedEnvironment.__AxelUI_WindowRegistry = windowRegistry
    local guiParent = resolveParent()
    if guiParent then
        local childrenOk, children = pcall(function() return guiParent:GetChildren() end)
        if childrenOk then
            for _, child in ipairs(children) do
                if child.Name == globalKey and child:IsA("ScreenGui") then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
    local self = setmetatable({
        _connections = {},
        _searchRows = {},
        _searchData = setmetatable({}, { __mode = "k" }),
        _notifications = {},
        _destroyed = false,
        _open = true,
        StartMinimized = options.StartMinimized == true,
        _globalKey = globalKey,
        _sharedEnvironment = sharedEnvironment,
        _windowRegistry = windowRegistry,
        Theme = normalizeTheme(options.Theme, AxelUI._pendingTheme),
        Tabs = {},
        ActiveTab = nil,
        _font = options.Font,
        ToggleKeybind = options.ToggleKeybind or Enum.KeyCode.RightControl,
        DesktopSize = options.Size or UDim2.fromOffset(926, 616),
        MobileSize = nil,
        AssetFolder = options.AssetFolder or options.AssetRoot or "",
        ConfigFolder = options.ConfigFolder or "AxelUIConfigs",
        Draggable = options.Draggable ~= false,
        Resizable = options.Resizable ~= false,
        ShowResizeGrip = options.ShowResizeGrip == true,
        GlassEnabled = type(options.Glass) == "boolean" and options.Glass or glassOptions.Enabled == true,
        GlassTransparency = math.clamp(tonumber(glassOptions.Transparency or options.GlassTransparency) or 0.22, 0, 0.45),
        ReduceEffects = options.ReduceEffects == true or (options.ReduceEffects ~= false and LOW_END_TOUCH_CLIENT),
        AnimateAccents = options.AnimateAccents == true or (options.AnimateAccents ~= false and not LOW_END_TOUCH_CLIENT),
        AnimateOpenClose = options.AnimateOpenClose == true or (options.AnimateOpenClose ~= false and not LOW_END_TOUCH_CLIENT),
        AnimatedBorder = options.AnimatedBorder == true or (options.AnimatedBorder ~= false and glassOptions.AnimatedBorder ~= false and not LOW_END_TOUCH_CLIENT),
        BorderAnimationDuration = math.clamp(tonumber(glassOptions.AnimationDuration or options.BorderAnimationDuration) or 3.2, 0.8, 15),
        TabAnimation = options.TabAnimation == true or (options.TabAnimation ~= false and not LOW_END_TOUCH_CLIENT),
        TabAnimationDuration = math.clamp(tonumber(options.TabAnimationDuration) or 0.2, 0.08, 0.7),
        TabSlideOffset = math.clamp(tonumber(options.TabSlideOffset) or 18, 4, 48),
        _flags = {},
        _accentTweens = {},
        _glintTweens = {},
    }, AxelUI)
    ACTIVE_FONT = options.Font
    ACTIVE_ASSET_FOLDER = self.AssetFolder
    self.TabMethods = AxelUI.TabMethods
    self.Gui = new("ScreenGui", { Name = globalKey, IgnoreGuiInset = true, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Global }, guiParent)
    _G[globalKey] = self
    windowRegistry[globalKey] = self
    AxelUI._activeWindow = self

    self.Window = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = self.Theme.Background, BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0, BorderSizePixel = 0, Position = UDim2.fromScale(0.5, 0.5), Size = self.DesktopSize, ClipsDescendants = true }, self.Gui)
    corner(self.Window, 18)
    local glitterLayer = new("Frame", { Name = "AxelGlitterLayer", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2 }, self.Window)
    self.GlitterLayer = glitterLayer
    local glitterPoints = {
        {0.06, 0.15, 3}, {0.19, 0.34, 2}, {0.31, 0.12, 2}, {0.43, 0.71, 3},
        {0.56, 0.2, 2}, {0.68, 0.47, 3}, {0.81, 0.15, 2}, {0.93, 0.36, 3},
        {0.12, 0.62, 2}, {0.27, 0.86, 3}, {0.51, 0.46, 2}, {0.75, 0.83, 3},
        {0.88, 0.68, 2}, {0.37, 0.52, 2}, {0.64, 0.9, 2}, {0.04, 0.87, 2},
    }
    for index, point in ipairs(glitterPoints) do
        if self.AnimateAccents then
            local glint = new("Frame", {
                Name = "AxelGlint",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = self.Theme.Accent2,
                BackgroundTransparency = 0.92,
                BorderSizePixel = 0,
                Position = UDim2.fromScale(point[1], point[2]),
                Rotation = index % 2 == 0 and 45 or 0,
                Size = UDim2.fromOffset(point[3], point[3]),
                ZIndex = 3,
            }, glitterLayer)
            corner(glint, point[3])
            local glintTween = TweenService:Create(glint, TweenInfo.new(1.6 + (index % 5) * 0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { BackgroundTransparency = 0.68 })
            table.insert(self._glintTweens, glintTween)
            if self._open then glintTween:Play() end
        end
    end
    self.GlowStroke = stroke(self.Window, self.Theme.Accent2, 0.38, 1.35)
    self.EdgeGradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, self.Theme.Accent3),
            ColorSequenceKeypoint.new(0.22, self.Theme.Accent),
            ColorSequenceKeypoint.new(0.5, self.Theme.Accent2),
            ColorSequenceKeypoint.new(0.78, self.Theme.Accent),
            ColorSequenceKeypoint.new(1, self.Theme.Accent3),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.38),
            NumberSequenceKeypoint.new(0.22, 0.16),
            NumberSequenceKeypoint.new(0.5, 0.02),
            NumberSequenceKeypoint.new(0.78, 0.16),
            NumberSequenceKeypoint.new(1, 0.38),
        }),
        Offset = Vector2.new(-1, 0),
    }, self.GlowStroke)
    if self.AnimatedBorder and self.AnimateAccents then
        local edgeInfo = TweenInfo.new(self.BorderAnimationDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false)
        local edgeOk, edgeTween = pcall(function()
            return TweenService:Create(self.EdgeGradient, edgeInfo, { Offset = Vector2.new(1, 0) })
        end)
        if edgeOk and edgeTween then self._edgeTween = edgeTween; edgeTween:Play() end
    end
    connect(self, self.Window.MouseEnter, function() tween(self.GlowStroke, { Transparency = 0.025, Thickness = 2 }, 0.18) end)
    connect(self, self.Window.MouseLeave, function() tween(self.GlowStroke, { Transparency = 0.24, Thickness = 1.45 }, 0.2) end)
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

    local header = new("Frame", { BackgroundColor3 = self.Theme.Surface, BackgroundTransparency = 0, BorderSizePixel = 0, Position = UDim2.fromOffset(170, 0), Size = UDim2.new(1, -170, 0, 58), ZIndex = 5 }, self.Window)
    self.Header = header
    corner(header, 18)
    -- Square the header's interior corners without covering the outer top-right radius.
    new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(18, 18), ZIndex = 6 }, header)
    new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -12), Size = UDim2.fromOffset(12, 12), ZIndex = 6 }, header)
    new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(1, -12, 1, -12), Size = UDim2.fromOffset(12, 12), ZIndex = 6 }, header)
    new("UIGradient", {
        Color = ColorSequence.new(self.Theme.Surface, self.Theme.Background),
        Transparency = NumberSequence.new(0),
        Rotation = 0,
    }, header)
    local dragHandle = new("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        Position = UDim2.fromOffset(404, 0),
        Size = UDim2.new(1, -536, 1, 0),
        ZIndex = 6,
    }, header)
    self.DragHandle = dragHandle
    local logoHolder = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.fromOffset(36, 36), Position = UDim2.fromOffset(16, 15), ClipsDescendants = true }, header)
    corner(logoHolder, 10)
    local logoScale = math.clamp(tonumber(options.LogoScale) or 1, 0.65, 1.4)
    local logoSize = math.min(30 * logoScale, 32)
    local logoIcon = icon(logoHolder, options.Logo or "star", logoSize, self.Theme.Accent2)
    logoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    logoIcon.Position = UDim2.fromScale(0.5, 0.5)
    logoIcon.Size = UDim2.fromOffset(logoSize, logoSize)
    local brand = textLabel(header, options.Name or "Axel UI", 14, self.Theme.Text, true); brand.Position = UDim2.fromOffset(58, 15); brand.Size = UDim2.fromOffset(150, 20)
    local subtitle = textLabel(header, options.Subtitle or "Clean, animated interface", 10, self.Theme.SubText, false); subtitle.Position = UDim2.fromOffset(58, 35); subtitle.Size = UDim2.fromOffset(180, 16)
    self.Brand, self.HeaderSubtitle = brand, subtitle
    local search = new("TextBox", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, ClearTextOnFocus = false, PlaceholderText = "Search features, settings, or help...", PlaceholderColor3 = self.Theme.Muted, Text = "", TextColor3 = self.Theme.Text, TextSize = 12, FontFace = fontFace(nil, false), Size = UDim2.fromOffset(300, 34), Position = UDim2.fromOffset(16, 12) }, header)
    corner(search, 9); stroke(search, self.Theme.Border, 0.25, 1); pad(search, 34, 10, 0, 0)
    self.SearchIcon = icon(header, "search", 15, self.Theme.Muted); self.SearchIcon.Position = UDim2.fromOffset(31, 23)
    self.Search = search
    self.FpsText = textLabel(header, "FPS", 10, self.Theme.SubText, true); self.FpsText.Position = UDim2.new(1, -276, 0, 14); self.FpsText.Size = UDim2.fromOffset(29, 20); self.FpsText.TextXAlignment = Enum.TextXAlignment.Right
    self.FpsValue = textLabel(header, "--", 10, self.Theme.Accent2, true); self.FpsValue.Position = UDim2.new(1, -244, 0, 14); self.FpsValue.Size = UDim2.fromOffset(30, 20); self.FpsValue.TextXAlignment = Enum.TextXAlignment.Left
    self.StatusSeparator = textLabel(header, "|", 10, self.Theme.Muted, false); self.StatusSeparator.Position = UDim2.new(1, -211, 0, 14); self.StatusSeparator.Size = UDim2.fromOffset(8, 20); self.StatusSeparator.TextXAlignment = Enum.TextXAlignment.Center
    self.StatusDot = new("Frame", { BackgroundColor3 = self.Theme.Success, BorderSizePixel = 0, Size = UDim2.fromOffset(7, 7), Position = UDim2.new(1, -190, 0, 21) }, header); corner(self.StatusDot, 4)
    self.StatusText = textLabel(header, "Online", 10, self.Theme.Success, true); self.StatusText.Position = UDim2.new(1, -176, 0, 14); self.StatusText.Size = UDim2.fromOffset(60, 20); self.StatusText.TextXAlignment = Enum.TextXAlignment.Left
    local function headerControl(kind, offset, callback)
        local button = new("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = self.Theme.Background,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Text = "",
            Size = UDim2.fromOffset(28, 28),
            Position = UDim2.new(1, offset, 0, 15),
            ZIndex = 10,
        }, header)
        corner(button, 7)
        local buttonStroke = stroke(button, self.Theme.Border, 0.16, 1)
        local buttonIcon = icon(button, kind, 12, self.Theme.Text)
        buttonIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        buttonIcon.Position = UDim2.fromScale(0.5, 0.5)
        buttonIcon.ZIndex = 11
        addButtonGlass(self, button, 0.08)
        pressAnimation(self, button)
        connect(self, button.MouseEnter, function()
            tween(button, { BackgroundColor3 = self.Theme.Element }, 0.12)
            tween(buttonStroke, { Color = self.Theme.Text, Transparency = 0.04 }, 0.12)
        end)
        connect(self, button.MouseLeave, function()
            tween(button, { BackgroundColor3 = self.Theme.Background }, 0.16)
            tween(buttonStroke, { Color = self.Theme.Border, Transparency = 0.16 }, 0.16)
        end)
        connect(self, button.MouseButton1Click, callback)
        return button
    end
    local minimizeButton = headerControl("minus", -102, function() self:SetOpen(false) end)
    local maximizeButton = headerControl("maximize", -70, function() self:SetMaximized(not self._maximized) end)
    local unloadButton = headerControl("close", -38, function() self:ConfirmUnload() end)
    self.MinimizeButton, self.MaximizeButton, self.UnloadButton = minimizeButton, maximizeButton, unloadButton

    local resizeHandle = new("TextButton", {
        Active = true,
        AutoButtonColor = false,
        BackgroundColor3 = self.Theme.Element,
        BackgroundTransparency = self.ShowResizeGrip and 0.12 or 1,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = self.Theme.Muted,
        TextTransparency = self.ShowResizeGrip and 0 or 1,
        TextSize = 12,
        FontFace = fontFace(nil, true),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -3, 1, -3),
        Size = UDim2.fromOffset(24, 24),
        ZIndex = 20,
    }, self.Window)
    corner(resizeHandle, 5)
    local resizeIcon = icon(resizeHandle, "resize", 13, self.Theme.Muted)
    resizeIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    resizeIcon.Position = UDim2.fromScale(0.5, 0.5)
    resizeIcon.Visible = self.ShowResizeGrip
    self.ResizeHandle = resizeHandle
    resizeHandle.Visible = self.Resizable
    connect(self, resizeHandle.MouseEnter, function()
        if not self.ShowResizeGrip then
            resizeIcon.Visible = true
            setIconTint(resizeIcon, self.Theme.SubText, 0.12)
            tween(resizeHandle, { BackgroundTransparency = 0.24 }, 0.12)
        end
    end)
    connect(self, resizeHandle.MouseLeave, function()
        if not self.ShowResizeGrip then
            resizeIcon.Visible = false
            tween(resizeHandle, { BackgroundTransparency = 1 }, 0.16)
        end
    end)
    connect(self, resizeHandle.InputBegan, function(input)
        if not self.Resizable or self._maximized then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._resizing = true
            self._resizeStart = input.Position
            self._resizeSize = self.Window.AbsoluteSize
        end
    end)
    connect(self, dragHandle.InputBegan, function(input)
        if not self.Draggable then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._dragStart = input.Position
            self._windowStart = self.Window.Position
        end
    end)

    local sidebar = new("Frame", { BackgroundColor3 = self.Theme.Surface, BackgroundTransparency = 0, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0, 170, 1, 0), ZIndex = 6 }, self.Window)
    self.Sidebar = sidebar
    corner(sidebar, 18)
    self.SidebarRightTopCap = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(18, 18), ZIndex = 7 }, sidebar)
    self.SidebarRightBottomCap = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(1, -18, 1, -18), Size = UDim2.fromOffset(18, 18), ZIndex = 7 }, sidebar)
    new("Frame", { BackgroundColor3 = self.Theme.Border, BackgroundTransparency = 0.25, BorderSizePixel = 0, Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), ZIndex = 7 }, sidebar)
    logoHolder.Parent = sidebar; logoHolder.Position = UDim2.fromOffset(18, 16); logoHolder.Size = UDim2.fromOffset(38, 38); logoHolder.ZIndex = 8; logoIcon.ZIndex = 9
    brand.Parent = sidebar; brand.Position = UDim2.fromOffset(66, 15); brand.Size = UDim2.new(1, -78, 0, 20); brand.ZIndex = 8
    subtitle.Parent = sidebar; subtitle.Position = UDim2.fromOffset(66, 36); subtitle.Size = UDim2.new(1, -78, 0, 16); subtitle.ZIndex = 8
    new("Frame", { BackgroundColor3 = self.Theme.Border, BackgroundTransparency = 0.35, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 70), Size = UDim2.new(1, -28, 0, 1) }, sidebar)
    local navTitle = textLabel(sidebar, "NAVIGATION", 9, self.Theme.Muted, true); navTitle.Position = UDim2.fromOffset(14, 84); navTitle.Size = UDim2.new(1, -28, 0, 16)
    self.NavTitle = navTitle
    self.TabList = new("ScrollingFrame", { Active = true, AutomaticCanvasSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(), Position = UDim2.fromOffset(8, 112), ScrollBarImageColor3 = self.Theme.Accent, ScrollBarThickness = 2, Size = UDim2.new(1, -16, 1, -192) }, sidebar)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, self.TabList)
    local profile = new("Frame", { BackgroundColor3 = self.Theme.Element, BackgroundTransparency = 0, BorderSizePixel = 0, Position = UDim2.new(0, 12, 1, -112), Size = UDim2.new(1, -24, 0, 52) }, sidebar)
    corner(profile, 11); stroke(profile, self.Theme.Border, 0.28, 1)
    local avatar = new("ImageLabel", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Size = UDim2.fromOffset(30, 30), Position = UDim2.fromOffset(8, 9), Image = "", ScaleType = Enum.ScaleType.Crop }, profile)
    corner(avatar, 15)
    local avatarFallback = icon(profile, "user", 20, self.Theme.SubText)
    avatarFallback.Position = UDim2.fromOffset(13, 14); avatarFallback.ZIndex = avatar.ZIndex + 1
    local avatarRetries = {}
    pcall(function()
        local player = Players.LocalPlayer
        if player then
            avatar.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", player.UserId)
            table.insert(avatarRetries, string.format("rbxthumb://type=Avatar&id=%d&w=150&h=150", player.UserId))
        end
    end)
    watchImage(avatar, function()
        avatar.Visible = true
        avatarFallback.Visible = false
    end, function()
        avatar.Visible = false
        avatarFallback.Visible = true
    end, 5, avatarRetries)
    local localPlayer = Players.LocalPlayer
    local inGameUsername = localPlayer and tostring(localPlayer.Name or "player") or "player"
    local localDisplayName = localPlayer and tostring(localPlayer.DisplayName or localPlayer.Name or "Axel User") or "Axel User"
    local profileName = textLabel(profile, localDisplayName, 11, self.Theme.Text, true); profileName.Position = UDim2.fromOffset(46, 7); profileName.Size = UDim2.new(1, -54, 0, 17); profileName.TextTruncate = Enum.TextTruncate.AtEnd
    local profileUsername = textLabel(profile, "@" .. inGameUsername, 9, self.Theme.Danger, false); profileUsername.Position = UDim2.fromOffset(46, 27); profileUsername.Size = UDim2.new(1, -54, 0, 14); profileUsername.TextTruncate = Enum.TextTruncate.AtEnd
    local footer = textLabel(sidebar, options.Footer or "AxelUI Library", 9, self.Theme.Muted, false); footer.Position = UDim2.new(0, 14, 1, -50); footer.Size = UDim2.new(1, -28, 0, 40); footer.TextWrapped = true; footer.TextYAlignment = Enum.TextYAlignment.Top
    self.ProfileCard, self.ProfileAvatar, self.ProfileName, self.ProfileUsername = profile, avatar, profileName, profileUsername
    self._profileAvatarRetries = avatarRetries
    self.Footer = footer

    self.PageHolder = new("Frame", { BackgroundColor3 = self.Theme.Background, BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0, BorderSizePixel = 0, Position = UDim2.fromOffset(170, 58), Size = UDim2.new(1, -170, 1, -58), ZIndex = 1, ClipsDescendants = true }, self.Window)
    corner(self.PageHolder, 18)
    -- Keep the subtle glitter in the glass backdrop only. Reparenting it below
    -- the page content prevents sparkles from appearing over opaque controls.
    self.GlitterLayer.Parent = self.PageHolder
    self.GlitterLayer.ZIndex = 1
    for _, glint in ipairs(self.GlitterLayer:GetChildren()) do
        if glint.Name == "AxelGlint" then glint.ZIndex = 1 end
    end
    self.PageCornerCaps = {
        new("Frame", { BackgroundColor3 = self.Theme.Background, BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(18, 18), ZIndex = 2 }, self.PageHolder),
        new("Frame", { BackgroundColor3 = self.Theme.Background, BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0, BorderSizePixel = 0, Position = UDim2.new(1, -18, 0, 0), Size = UDim2.fromOffset(18, 18), ZIndex = 2 }, self.PageHolder),
        new("Frame", { BackgroundColor3 = self.Theme.Background, BackgroundTransparency = self.GlassEnabled and self.GlassTransparency or 0, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -18), Size = UDim2.fromOffset(18, 18), ZIndex = 2 }, self.PageHolder),
    }
    local tabHeader = new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 46) }, self.PageHolder)
    corner(tabHeader, 12)
    new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -12), Size = UDim2.fromOffset(12, 12) }, tabHeader)
    new("Frame", { BackgroundColor3 = self.Theme.Surface, BorderSizePixel = 0, Position = UDim2.new(1, -12, 1, -12), Size = UDim2.fromOffset(12, 12) }, tabHeader)
    self.TabHeader = tabHeader
    self.TabTitle = textLabel(tabHeader, "Dashboard", 15, self.Theme.Text, true); self.TabTitle.Position = UDim2.fromOffset(22, 6); self.TabTitle.Size = UDim2.new(1, -36, 0, 19)
    self.TabSubtitle = textLabel(tabHeader, "", 10, self.Theme.SubText, false); self.TabSubtitle.Position = UDim2.fromOffset(22, 24); self.TabSubtitle.Size = UDim2.new(1, -36, 0, 15)
    local separator = new("Frame", { BackgroundColor3 = self.Theme.Border, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1) }, tabHeader)
    local emptyState = new("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.54, 0),
        Size = UDim2.new(1, -36, 0, 112),
        ZIndex = 4,
    }, self.PageHolder)
    corner(emptyState, 12); stroke(emptyState, self.Theme.Border, 0.22, 1)
    local emptyIcon = icon(emptyState, "info", 20, self.Theme.Accent2)
    emptyIcon.Position = UDim2.fromOffset(18, 28); emptyIcon.ZIndex = 5
    local emptyTitle = textLabel(emptyState, "Nothing to show yet", 13, self.Theme.Text, true)
    emptyTitle.Position = UDim2.fromOffset(54, 25); emptyTitle.Size = UDim2.new(1, -70, 0, 20); emptyTitle.ZIndex = 5
    local emptyHint = textLabel(emptyState, "Run AxelUI_Library_Example.luau, or add a page with window:AddTab(...).", 10, self.Theme.SubText, false)
    emptyHint.Position = UDim2.fromOffset(54, 49); emptyHint.Size = UDim2.new(1, -70, 0, 38); emptyHint.TextWrapped = true; emptyHint.ZIndex = 5
    self.EmptyState = emptyState

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
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        Text = "",
        Size = UDim2.fromOffset(188, 48),
        Position = UDim2.new(1, -206, 1, -62),
        Visible = false,
        ZIndex = 250,
    }, self.Gui)
    corner(self.TouchButton, 16)
    stroke(self.TouchButton, self.Theme.Accent, 0.12, 1.25)
    self.TouchButton.Name = "AxelRestoreButton"
    self.RestoreScale = new("UIScale", { Scale = 1 }, self.TouchButton)
    local touchStroke = self.TouchButton:FindFirstChildOfClass("UIStroke")
    if touchStroke then touchStroke.Thickness = 1.5; touchStroke.Transparency = 0.08 end
    local avatarPlate = new("Frame", { BackgroundColor3 = self.Theme.Background, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(32, 32), ZIndex = 251 }, self.TouchButton)
    corner(avatarPlate, 10)
    local restoreAvatar = new("ImageLabel", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Image = "", ScaleType = Enum.ScaleType.Crop, Visible = false, ZIndex = 252 }, avatarPlate)
    corner(restoreAvatar, 10)
    local touchIcon = icon(avatarPlate, "star", 19, self.Theme.Accent2)
    touchIcon.AnchorPoint = Vector2.new(0.5, 0.5); touchIcon.Position = UDim2.fromScale(0.5, 0.5); touchIcon.ZIndex = 253
    if self.ProfileAvatar then
        pcall(function() restoreAvatar.Image = self.ProfileAvatar.Image end)
        watchImage(self.ProfileAvatar, function()
            local imageOk, image = pcall(function() return self.ProfileAvatar.Image end)
            if imageOk and image ~= "" then
                restoreAvatar.Image = image
                restoreAvatar.Visible = true
                touchIcon.Visible = false
            end
        end, function()
            restoreAvatar.Visible = false
            touchIcon.Visible = true
        end, 5, self._profileAvatarRetries)
    end
    self.RestoreAvatar = restoreAvatar
    local launcherTitle = textLabel(self.TouchButton, "Axel Hub", 11, self.Theme.Text, true)
    launcherTitle.Position = UDim2.fromOffset(48, 7); launcherTitle.Size = UDim2.new(1, -58, 0, 16); launcherTitle.ZIndex = 252
    local statusDot = new("Frame", { BackgroundColor3 = self.Theme.Success, BorderSizePixel = 0, Position = UDim2.fromOffset(49, 29), Size = UDim2.fromOffset(6, 6), ZIndex = 252 }, self.TouchButton)
    corner(statusDot, 3)
    self.RestoreStatusDot = statusDot
    local launcherStatus = textLabel(self.TouchButton, "Online", 9, self.Theme.Success, false)
    launcherStatus.Position = UDim2.fromOffset(59, 24); launcherStatus.Size = UDim2.new(0, 41, 0, 16); launcherStatus.ZIndex = 252; launcherStatus.TextTruncate = Enum.TextTruncate.AtEnd
    self.RestoreStatusText = launcherStatus
    local launcherFps = textLabel(self.TouchButton, "-- FPS", 9, self.Theme.Accent2, true)
    launcherFps.Position = UDim2.fromOffset(102, 24); launcherFps.Size = UDim2.fromOffset(43, 16); launcherFps.ZIndex = 252; launcherFps.TextXAlignment = Enum.TextXAlignment.Right
    self.RestoreFpsText = launcherFps
    local launcherPing = textLabel(self.TouchButton, "-- ms", 9, self.Theme.SubText, false)
    launcherPing.Position = UDim2.new(1, -39, 0, 24); launcherPing.Size = UDim2.fromOffset(33, 16); launcherPing.ZIndex = 252; launcherPing.TextXAlignment = Enum.TextXAlignment.Right
    self.RestorePingText = launcherPing
    if typeof(options.RestoreButtonPosition) == "UDim2" then
        self.TouchButton.Position = options.RestoreButtonPosition
    elseif self.StartMinimized then
        self.TouchButton.Position = UDim2.new(0.5, -94, 0.5, -24)
    end
    self.RestoreButton = self.TouchButton
    addButtonGlass(self, self.TouchButton, 0.02)
    pressAnimation(self, self.TouchButton)
    connect(self, self.TouchButton.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
            self._restoreDrag = { Start = input.Position, Origin = self.TouchButton.AbsolutePosition, Moved = false }
        end
    end)
    connect(self, self.TouchButton.MouseButton1Click, function()
        if self._restoreDragged then return end
        self:SetOpen(true)
    end)
    connect(self, search:GetPropertyChangedSignal("Text"), function()
        if self._dropdownClose then pcall(self._dropdownClose) end
        self:_refreshSearch(search.Text)
    end)
    connect(self, UserInputService.InputBegan, function(input, processed)
        if processed or self._destroyed then return end
        if keyMatches(input, self.ToggleKeybind) and not self._keybindOwner then self:Toggle() end
    end)
    self._fpsFrames = 0
    self._fpsLastSample = os.clock()
    connect(self, RunService.RenderStepped, function()
        if self._destroyed then return end
        self._fpsFrames = self._fpsFrames + 1
        local now = os.clock()
        local elapsed = now - self._fpsLastSample
        if elapsed >= 0.5 then
            local fps = math.floor(self._fpsFrames / elapsed + 0.5)
            self._fpsFrames = 0
            self._fpsLastSample = now
            if self.FpsValue then self.FpsValue.Text = tostring(fps) end
            if self.RestoreFpsText then self.RestoreFpsText.Text = tostring(fps) .. " FPS" end
            if self.RestorePingText then
                local player = Players.LocalPlayer
                local pingOk, pingSeconds = pcall(function()
                    return player and player:GetNetworkPing()
                end)
                self.RestorePingText.Text = pingOk and type(pingSeconds) == "number"
                    and (tostring(math.max(0, math.floor(pingSeconds * 1000 + 0.5))) .. " ms")
                    or "-- ms"
            end
        end
    end)
    connect(self, UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = false
            self._resizing = false
            if self._restoreDrag then
                if self._restoreDrag.Moved then
                    self._restoreDragged = true
                    task.delay(0.25, function() self._restoreDragged = false end)
                end
                self._restoreDrag = nil
            end
        end
    end)
    connect(self, UserInputService.InputChanged, function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if self._restoreDrag and self.RestoreButton and self.RestoreButton.Visible then
            local delta = input.Position - self._restoreDrag.Start
            if math.abs(delta.X) + math.abs(delta.Y) > 6 then self._restoreDrag.Moved = true end
            if self._restoreDrag.Moved then
                local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
                local buttonSize = self.RestoreButton.AbsoluteSize
                local x = math.clamp(self._restoreDrag.Origin.X + delta.X, 8, math.max(8, viewport.X - buttonSize.X - 8))
                local y = math.clamp(self._restoreDrag.Origin.Y + delta.Y, 8, math.max(8, viewport.Y - buttonSize.Y - 8))
                self.RestoreButton.Position = UDim2.fromOffset(x, y)
            end
        elseif self._dragging and self._dragStart and self._windowStart then
            local delta = input.Position - self._dragStart
            self.Window.Position = UDim2.new(self._windowStart.X.Scale, self._windowStart.X.Offset + delta.X, self._windowStart.Y.Scale, self._windowStart.Y.Offset + delta.Y)
        elseif self._resizing and self._resizeStart and self._resizeSize then
            local delta = input.Position - self._resizeStart
            local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local minWidth = self.IsMobile and 300 or 760
            local minHeight = self.IsMobile and 360 or 480
            local maxWidth = self.IsMobile and math.max(minWidth, math.min(480, viewport.X - 18)) or math.max(minWidth, math.min(1440, viewport.X - 24))
            local maxHeight = self.IsMobile and math.max(minHeight, math.min(720, viewport.Y - 26)) or math.max(minHeight, math.min(1000, viewport.Y - 24))
            local width = math.clamp(self._resizeSize.X + delta.X, math.min(minWidth, maxWidth), maxWidth)
            local height = math.clamp(self._resizeSize.Y + delta.Y, math.min(minHeight, maxHeight), maxHeight)
            self.Window.Size = UDim2.fromOffset(width, height)
            if self.IsMobile then
                self.MobileSize = self.Window.Size
            else
                self.DesktopSize = self.Window.Size
            end
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
    local overlayIcon = icon(loaderCard, options.Logo or "star", 34, self.Theme.Accent2); overlayIcon.Position = UDim2.fromOffset(26, 27); overlayIcon.ZIndex = 102
    local loadingTitle = textLabel(loaderCard, options.LoadingText or options.Name or "Axel Hub", 16, self.Theme.Text, true); loadingTitle.Position = UDim2.fromOffset(78, 20); loadingTitle.Size = UDim2.new(1, -96, 0, 24); loadingTitle.ZIndex = 102
    local loadingText = textLabel(loaderCard, options.LoadingSubtitle or "Preparing your workspace", 10, self.Theme.SubText, false); loadingText.Position = UDim2.fromOffset(78, 46); loadingText.Size = UDim2.new(1, -96, 0, 18); loadingText.ZIndex = 102
    local loadingBar = new("Frame", { BackgroundColor3 = self.Theme.Element, BorderSizePixel = 0, Size = UDim2.new(1, -44, 0, 5), Position = UDim2.fromOffset(22, 104), ZIndex = 102 }, loaderCard); corner(loadingBar, 4)
    local loadingFill = new("Frame", { BackgroundColor3 = self.Theme.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), ZIndex = 103 }, loadingBar); corner(loadingFill, 4)
    local loadingHint = textLabel(loaderCard, "Loading modules", 9, self.Theme.Muted, false); loadingHint.Position = UDim2.fromOffset(22, 119); loadingHint.Size = UDim2.new(1, -44, 0, 16); loadingHint.ZIndex = 102
    self._loadingOverlay = overlay
    self._loadingFinished = false
    self._loadingStartedAt = os.clock()
    if self.ReduceEffects then
        self.Scale.Scale = 1
        loaderScale.Scale = 1
        loadingFill.Size = UDim2.fromScale(1, 1)
    else
        tween(self.Scale, { Scale = 1 }, 0.45, Enum.EasingStyle.Back)
        tween(loaderScale, { Scale = 1 }, 0.48, Enum.EasingStyle.Back)
        tween(loadingFill, { Size = UDim2.fromScale(1, 1) }, 0.72, Enum.EasingStyle.Quint)
    end
    function self:FinishLoading()
        if self._destroyed or self._loadingFinished then return false end
        self._loadingFinished = true
        local minDisplay = self.ReduceEffects and 0.12 or 0.72
        local remaining = math.max(0, minDisplay - (os.clock() - (self._loadingStartedAt or os.clock())))
        task.delay(remaining, function()
            if self._destroyed or not overlay.Parent then return end
            if self.ReduceEffects then
                overlay:Destroy()
                self._loadingOverlay = nil
                return
            end
            tween(loaderScale, { Scale = 0.94 }, 0.16, Enum.EasingStyle.Quad)
            tween(overlay, { BackgroundTransparency = 1 }, 0.28)
            tween(loaderCard, { BackgroundTransparency = 1 }, 0.22)
            fadeIcon(overlayIcon, 0.2)
            tween(loadingTitle, { TextTransparency = 1 }, 0.2)
            tween(loadingText, { TextTransparency = 1 }, 0.2)
            tween(loadingHint, { TextTransparency = 1 }, 0.2)
            tween(loadingBar, { BackgroundTransparency = 1 }, 0.2)
            tween(loadingFill, { BackgroundTransparency = 1 }, 0.2)
            task.delay(0.3, function()
                if overlay.Parent then overlay:Destroy() end
                if self._loadingOverlay == overlay then self._loadingOverlay = nil end
            end)
        end)
        return true
    end
    local loadingTimeout = math.clamp(tonumber(options.LoadingTimeout) or 1.5, 1, 30)
    task.delay(loadingTimeout, function()
        if not self._loadingFinished and not self._destroyed then self:FinishLoading() end
    end)

    if self.StartMinimized then
        self._open = false
        setAccentAnimations(self, false)
        self.Window.Visible = false
        self.RestoreButton.Visible = true
        self.RestoreButton.BackgroundTransparency = 0.08
        self.RestoreScale.Scale = 0.72
        local restoreStroke = self.RestoreButton:FindFirstChildOfClass("UIStroke")
        if restoreStroke then restoreStroke.Transparency = 0.04 end
        tween(self.RestoreScale, { Scale = 1 }, 0.34, Enum.EasingStyle.Back)
    end

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

AxelUI.Version = 7.9

function AxelUI.CreateWindow(first, second)
    return AxelUI.new(second or first)
end

return AxelUI
