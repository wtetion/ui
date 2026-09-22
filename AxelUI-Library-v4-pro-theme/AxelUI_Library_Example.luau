-- AxelUI dashboard showcase
-- Entry point: run this file to build the dashboard. Running only the library
-- returns the API module; it does not add tabs or example controls.
-- The old example called loadstring(...) immediately, so a missing URL or a
-- non-executor environment produced: "attempt to call a nil value" on line 3.
-- The GitHub URL below is the primary source. The bundled library is used as a
-- fallback if that path still serves an older AxelUI version.
local function hasMethods(owner, names)
    if type(owner) ~= "table" then return false end
    for _, name in ipairs(names) do
        if type(owner[name]) ~= "function" then return false end
    end
    return true
end

local function supportsShowcase(library)
    if type(library) ~= "table" or (tonumber(library.Version) or 0) < 6.8 then return false end
    return hasMethods(library, {
        "CreateWindow", "AddTab", "Notify", "SetStatus", "SetGlass", "SetTheme",
        "SetFont", "SetBackground", "SaveConfig", "LoadConfig", "SetOpen", "Toggle",
        "SetMaximized", "SetToggleKeybind", "ConfirmUnload", "Unload", "RegisterIcon",
        "RegisterIcons",
    })
        and hasMethods(library.TabMethods, {
            "AddHero", "AddPill", "AddSection", "AddSubTab", "SetBadge", "SetStatus",
        })
        and hasMethods(library.SectionMethods, {
            "AddDescription", "AddText", "AddTextLabel", "AddLabel", "AddParagraph",
            "AddBanner", "AddImage", "AddButton", "AddActionBar", "AddToggle", "AddSlider",
            "AddDropdown", "AddMultiDropdown", "AddColorPicker", "AddInput", "AddKeybind",
            "AddStatus", "AddDivider", "CreateToggle", "CreateSlider", "CreateDropdown",
            "CreateMultiDropdown", "CreateButton", "CreateInput", "CreateKeybind",
            "CreateColorPicker", "CreateImage", "CreateBanner", "CreateActionBar",
            "CreateText", "CreateParagraph", "CreateLabel", "CreateDivider",
        })
end

local function loadAxelUI()
    local environment = _G
    pcall(function()
        if type(getgenv) == "function" then environment = getgenv() end
    end)
    if supportsShowcase(environment.AxelUI) then return environment.AxelUI end
    if type(environment.AxelUI) == "table" then
        warn("[AxelUI] Preloaded library is older than the dashboard example; updating from the configured GitHub URL.")
    end

    local compiler = loadstring or load
    if type(compiler) ~= "function" then
        warn("[AxelUI] loadstring is unavailable. Run this from an executor or preload AxelUI_Library.luau first.")
        return nil
    end

    local function compileAndRun(source)
        local compileOk, chunk, compileError = pcall(compiler, source)
        if not compileOk then return false, nil, "compiler threw: " .. tostring(chunk) end
        if type(chunk) ~= "function" then
            return false, nil, tostring(compileError or "compiler returned " .. type(chunk) .. " instead of a function")
        end
        local runOk, result = pcall(chunk)
        if not runOk then return false, nil, "library runtime error: " .. tostring(result) end
        return true, result, nil
    end

    -- User supplied raw GitHub URL. This is the same source format accepted by
    -- loadstring(game:HttpGet(url))(), so use it as the primary source.
    local hostedUrl = "https://raw.githubusercontent.com/wtetion/ui/refs/heads/main/AxelUI-Library-v4-pro-theme/AxelUI_Library.luau"
    local httpOk, source = pcall(function() return game:HttpGet(hostedUrl) end)
    if httpOk and type(source) == "string" and #source > 0 then
        local compiledOk, library, compileError = compileAndRun(source)
        if compiledOk and supportsShowcase(library) then return library end
        if compiledOk and type(library) == "table" then
            warn("[AxelUI] GitHub URL returned AxelUI v" .. tostring(library.Version or "unknown") .. ", which lacks the v6.8 image retry fix or full showcase API. Upload the bundled v6.8 library to that path.")
        else
            warn("[AxelUI] GitHub source could not be loaded: " .. tostring(compileError or library))
        end
    else
        warn("[AxelUI] GitHub download failed: " .. tostring(source))
    end

    -- Local and preloaded fallbacks keep the example usable when HTTP is off.
    if type(readfile) == "function" then
        local fileOk, localSource = pcall(readfile, "AxelUI_Library.luau")
        if fileOk and type(localSource) == "string" and #localSource > 0 then
            local compiledOk, library, compileError = compileAndRun(localSource)
            if compiledOk and supportsShowcase(library) then return library end
            if compiledOk and type(library) == "table" then
                warn("[AxelUI] Local file is an older AxelUI version and does not support the full dashboard example.")
            else
                warn("[AxelUI] Local library could not be loaded: " .. tostring(compileError or library))
            end
        end
    end
    return nil
end

local AxelUI = loadAxelUI()
if not AxelUI then return end
if not supportsShowcase(AxelUI) then
    warn("[AxelUI] No compatible library found. Use the bundled v6.8 AxelUI_Library.luau, or upload it to the configured raw GitHub path.")
    return
end

local Window = AxelUI.CreateWindow({
    Name = "Axel Hub",
    Subtitle = "Play Further",
    Footer = "v1.0.0\nReady when you are",
    GuiName = "AxelHubUI",
    ToggleKeybind = "RightControl",
    -- Start on the centered Axel star launcher; clicking/tapping opens the UI.
    StartMinimized = true,
    RestoreButtonPosition = UDim2.new(0.5, -94, 0.5, -24),
    -- Set this when your executor stores AxelLogo.png in a subfolder.
    -- AssetFolder = "AxelUI",
    Theme = {
        Accent = Color3.fromRGB(255, 193, 7),
        Accent2 = Color3.fromRGB(255, 224, 115),
        Accent3 = Color3.fromRGB(184, 126, 0),
        Background = Color3.fromRGB(10, 10, 12),
        Surface = Color3.fromRGB(17, 17, 19),
        Surface2 = Color3.fromRGB(24, 24, 27),
        Element = Color3.fromRGB(30, 29, 28),
        -- Reference cards use a quiet graphite border; gold is reserved for
        -- the active state, focus glow and primary actions.
        Border = Color3.fromRGB(58, 59, 67),
    },
    -- Built-in logo renders from vector UI primitives; no font glyph or remote
    -- icon pack is needed. Pass an rbxassetid://... here for your own image.
    Logo = "star",
    -- Only the shell and empty page backdrop are translucent. Sidebar, cards
    -- and controls are explicitly solid for the reference look.
    Glass = { Enabled = true, Transparency = 0.24, AnimatedBorder = true, AnimationDuration = 3.2 },
    TabAnimation = true,
    TabAnimationDuration = 0.2,
    Background = nil,
    BackgroundTransparency = 0.94,
    LoadingText = "Axel Hub",
    LoadingSubtitle = "AxelUI 6.8  •  Preparing your workspace",
})

-- Home follows the reference composition: hero, pill tabs, then two columns of cards.
local Home = Window:AddTab({ Name = "Home", Description = "Live status and quick actions", Icon = "home" })
local function safeElement(owner, methodName, data)
    local method = owner and owner[methodName]
    if type(method) ~= "function" then
        warn("[AxelUI] Missing method: " .. tostring(methodName) .. " (library is older than the example)")
        return nil
    end
    local ok, result = pcall(method, owner, data)
    if not ok then
        warn("[AxelUI] " .. tostring(methodName) .. " failed: " .. tostring(result))
        return nil
    end
    return result
end

local function safeSection(tab, data)
    local actual = safeElement(tab, "AddSection", data)
    return setmetatable({}, {
        __index = function(_, key)
            local value = actual and actual[key]
            if type(value) == "function" and (string.sub(key, 1, 3) == "Add" or string.sub(key, 1, 6) == "Create") then
                return function(_, payload) return safeElement(actual, key, payload) end
            end
            return value
        end,
    })
end

safeElement(Home, "AddHero", {
    Image = "rbxassetid://86949082023913", -- replace with a wide banner asset for the reference sunset scene
    -- Fit preserves the full image when users import a square PNG/logo.
    ScaleType = Enum.ScaleType.Fit,
    WelcomeLabel = "Welcome to",
    WelcomeTitle = "Axel Hub",
    WelcomeContent = "Powerful tools. A smoother way to play.",
    BannerTitle = "Customize your experience",
    Title = "Customize your experience",
    Content = "Simple. Powerful. Yours. Build your own control center with clean, readable controls.",
    Button = "Get Started",
    Height = 104,
    Callback = function() Window:Notify("Axel Hub", "Your dashboard is ready.", "info") end,
})

safeElement(Home, "AddPill", { Name = "Overview", Active = true })
safeElement(Home, "AddPill", { Name = "Player", Callback = function() Window:Notify("Overview", "Player tools are below.", "info") end })
safeElement(Home, "AddPill", { Name = "World", Callback = function() Window:Notify("Overview", "World settings are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Visuals", Callback = function() Window:Notify("Overview", "Visual controls are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Utilities", Callback = function() Window:Notify("Overview", "Utility controls are below.", "info") end })
safeElement(Home, "AddPill", { Name = "Configs", Callback = function() Window:Notify("Overview", "Configuration is below.", "info") end })

local PlayerTools = safeSection(Home, { Name = "Player Tools", Description = "Fine tune your movement and abilities.", Side = "Left" })
PlayerTools:AddToggle({ Name = "Enable Movement Mods", Description = "Unlock advanced movement options.", Icon = "running", Default = true })
PlayerTools:AddSlider({ Name = "Walk Speed", Icon = "speed", Min = 1, Max = 50, Default = 16, Flag = "walk_speed" })
PlayerTools:AddSlider({ Name = "Jump Power", Icon = "arrows", Min = 1, Max = 100, Default = 50, Flag = "jump_power" })
PlayerTools:AddToggle({ Name = "Infinite Jump", Description = "Keep going higher.", Icon = "move", Default = false })
PlayerTools:AddToggle({ Name = "No Fall Damage", Description = "Land without limits.", Icon = "shield", Default = true })

local WorldSettings = safeSection(Home, { Name = "World Settings", Description = "Adjust how you see and interact with the world.", Side = "Right" })
WorldSettings:AddToggle({ Name = "Full Bright", Description = "Light up dark areas.", Icon = "star", Default = true })
WorldSettings:AddToggle({ Name = "Remove Fog", Description = "See further, play clearer.", Icon = "eyeoff", Default = false })
WorldSettings:AddDropdown({ Name = "Time of Day", Description = "Choose a world lighting preset.", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })
WorldSettings:AddSlider({ Name = "Field of View", Icon = "eye", Min = 40, Max = 120, Default = 70, Suffix = "°" })
WorldSettings:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })

local Config = safeSection(Home, { Name = "Configuration", Description = "Save and load your favorite setups.", Side = "Left" })
Config:AddDropdown({ Name = "Preset", Icon = "folder", Options = { "Default", "Farm", "Combat" }, Default = "Default" })
safeElement(Config, "AddActionBar", { Actions = {
    { Name = "Save", Primary = true, Callback = function()
        local ok, err = Window:SaveConfig("axelhub-demo")
        Window:Notify("Configuration", ok and "Configuration saved." or tostring(err), ok and "success" or "error")
    end },
    { Name = "Load", Callback = function()
        local ok, err = Window:LoadConfig("axelhub-demo")
        Window:Notify("Configuration", ok and "Configuration loaded." or tostring(err), ok and "success" or "error")
    end },
    { Name = "...", Callback = function() Window:Notify("Configuration", "More configuration actions are available through the library API.", "info") end },
} })

local Quick = safeSection(Home, { Name = "Quick Actions", Description = "Common features, one click away.", Side = "Right" })
safeElement(Quick, "AddActionBar", { Actions = {
    { Name = "Rejoin", Callback = function() Window:Notify("Quick Action", "Rejoin requested.", "info") end },
    { Name = "Reset Character", Callback = function() Window:Notify("Quick Action", "Character reset requested.", "info") end },
    { Name = "Server Hop", Callback = function() Window:Notify("Quick Action", "Server hop requested.", "info") end },
} })

-- Sidebar pages keep the library useful beyond the visual showcase.
local Player = Window:AddTab({ Name = "Player", Description = "Movement and automation", Icon = "player", Badge = "LIVE" })
local Travel = safeSection(Player, { Name = "Player Tools", Description = "Movement and travel controls.", Side = "Left" })
Travel:AddToggle({ Name = "Auto travel", Description = "Run the selected travel method.", Icon = "teleport", Default = false, Flag = "auto_travel" })
Travel:AddDropdown({ Name = "Travel method", Description = "Teleport, safe walk or guarded movement.", Icon = "move", Options = { "Teleport", "Safe Walk", "Anti Guard", "Fly Glide" }, Default = "Teleport", Flag = "travel_method" })
Travel:AddSlider({ Name = "Check delay", Description = "How often the worker checks for a target.", Icon = "timer", Min = 0.1, Max = 10, Default = 1, Suffix = "s" })
Travel:AddKeybind({ Name = "Toggle automation", Icon = "bolt", Default = "RightShift" })
local PlayerStatus = safeSection(Player, { Name = "Runner status", Description = "Live state of the current workspace.", Side = "Right" })
PlayerStatus:AddStatus({ Name = "Library state", Text = "Online", Color = Window.Theme.Success, Icon = "check" })
PlayerStatus:AddStatus({ Name = "Current profile", Text = "Default", Color = Window.Theme.Accent2, Icon = "user" })
PlayerStatus:AddParagraph({ Title = "Readable by design", Content = "Every control accepts a description, icon and flag. Cards resize from their real content so nothing overlaps or disappears." })

local World = Window:AddTab({ Name = "World", Description = "Lighting and environment", Icon = "world" })
local WorldCard = safeSection(World, { Name = "Environment", Description = "Tune the current world.", Side = "Left" })
WorldCard:AddToggle({ Name = "Full Bright", Icon = "sun", Default = true })
WorldCard:AddToggle({ Name = "Remove Fog", Icon = "eyeoff", Default = false })
WorldCard:AddDropdown({ Name = "Time of Day", Icon = "clock", Options = { "Day", "Sunset", "Night" }, Default = "Day" })

local Visuals = Window:AddTab({ Name = "Visuals", Description = "Clean visual controls", Icon = "eye" })
local VisualCard = safeSection(Visuals, { Name = "Visuals", Description = "Optional visual helpers.", Side = "Left" })
VisualCard:AddToggle({ Name = "Show Hitboxes", Description = "Visualize important objects.", Icon = "grid", Default = false })
VisualCard:AddToggle({ Name = "Monochrome screen", Description = "Toggle the black and white display effect.", Icon = "contrast", Default = false })
VisualCard:CreateMultiDropdown({ Name = "Visible overlays", Description = "Choose several visual layers at once.", Icon = "layers", Options = { "Boxes", "Names", "Distance", "Tracers" }, Default = { "Boxes", "Names" }, Flag = "visual_overlays" })
VisualCard:CreateColorPicker({ Name = "Highlight color", Description = "Choose a UI accent for this visual group.", Icon = "palette", Default = Color3.fromRGB(255, 193, 7) })
VisualCard:CreateInput({ Name = "Filter visuals", Description = "A searchable text field with a callback.", Icon = "search", Placeholder = "Type a filter...", Flag = "visual_filter" })

local Utilities = Window:AddTab({ Name = "Utilities", Description = "Useful one-click tools", Icon = "utilities" })
local UtilityCard = safeSection(Utilities, { Name = "Quick Actions", Description = "Common features, one click away.", Side = "Left" })
UtilityCard:AddButton({ Name = "Copy Discord link", Description = "Copy the Axel Hub community invite.", Icon = "discord", Callback = function()
    local copy = setclipboard or toclipboard
    if copy then copy("https://discord.gg/axelhub") end
end })
UtilityCard:AddButton({ Name = "Unload UI", Description = "Ask before removing the interface and its listeners.", Icon = "power", Callback = function() Window:ConfirmUnload() end })
UtilityCard:CreateToggle({ Name = "Glass outer shell", Description = "Only the outside shell changes; controls stay solid.", Icon = "layers", Default = Window.GlassEnabled, Callback = function(enabled) Window:SetGlass(enabled) end })

local Configs = Window:AddTab({ Name = "Configs", Description = "Save and load setups", Icon = "configs" })
local ConfigCard = safeSection(Configs, { Name = "Configuration", Description = "Keep your favorite setups ready.", Side = "Left" })
ConfigCard:AddButton({ Name = "Save current configuration", Icon = "save", Callback = function() Window:SaveConfig("axelhub-demo") end })
ConfigCard:AddButton({ Name = "Load saved configuration", Icon = "download", Callback = function() Window:LoadConfig("axelhub-demo") end })

Window:AddTab({ Name = "Marketplace", Description = "More tools coming soon", Icon = "shop" })

return Window
