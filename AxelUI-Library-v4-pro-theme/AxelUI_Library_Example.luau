-- AxelUI Library example
-- Replace this URL with your own hosted/local loader when distributing it.
local AxelUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/wtetion/ui/refs/heads/main/AxelUI-Library-v4-pro-theme/AxelUI_Library.luau"))()

local Window = AxelUI.new({
    Name = "Axel Hub",
    Subtitle = "Steal an Egg - Control Center",
    GuiName = "AxelHubUI",
    ToggleKeybind = "RightControl",
    Theme = { Accent = Color3.fromRGB(255, 193, 7), Accent2 = Color3.fromRGB(255, 220, 110) },
    -- Put AxelLogo.png beside the script, or replace this with an asset id.
    Logo = "AxelLogo.png",
    -- Background accepts a local getcustomasset path or an rbxassetid:// value.
    Background = "AxelLogo.png",
    BackgroundTransparency = 0.9,
    LoadingText = "Preparing dashboard...",
})

Window:Notify({
    Title = "Axel Hub",
    Content = "Press RightControl or use the floating touch button to show or hide the UI.",
    Type = "success",
})

local Dashboard = Window:AddTab({
    Name = "Dashboard",
    Description = "Live status and quick actions",
    Icon = "dashboard",
    Badge = "LIVE",
})
local DashboardSection = Dashboard:AddSection({
    Name = "System overview",
    Description = "A compact overview with readable explanations.",
    Side = "Left",
})
DashboardSection:AddStatus({ Name = "Runner status", Text = "Online", Color = Window.Theme.Success })
DashboardSection:AddImage({ Image = "AxelLogo.png", Caption = "AXEL HUB", Height = 138 })
DashboardSection:AddParagraph({
    Title = "How it works",
    Content = "Use the search box to filter controls. Each option can include a description so users know what it changes.",
})
DashboardSection:AddButton({
    Name = "Copy Discord link",
    Description = "Copies the community invite to your clipboard.",
    Icon = "copy",
    Callback = function()
        local copy = setclipboard or toclipboard
        if copy then copy("https://discord.gg/axelhub") end
    end,
})
DashboardSection:AddButton({
    Name = "Show notification",
    Description = "Demonstrates the built-in notification stack.",
    Icon = "info",
    Callback = function()
        Window:Notify("Status", "The notification system is working.", "info")
    end,
})

local Automation = Window:AddTab({
    Name = "Automation",
    Description = "Actions and filters",
    Icon = "target",
})
local AutomationSection = Automation:AddSection({ Name = "Controls", Description = "Every control supports an optional Description field.", Side = "Left" })
local VisualSection = Automation:AddSection({ Name = "Visual status", Description = "A second column keeps the page easy to scan.", Side = "Right" })
AutomationSection:AddToggle({ Name = "Auto Steal", Icon = "target", Description = "Runs the selected steal route.", Default = false, Callback = function(value) print("Auto Steal", value) end })
AutomationSection:AddDropdown({ Name = "Travel method", Icon = "move", Description = "Choose how the character travels.", Options = { "Teleport", "Fly Glide", "Safe Walk", "Anti Guard" }, Default = "Teleport" })
AutomationSection:AddSlider({ Name = "Check delay", Icon = "refresh", Description = "How often the worker checks for a new target.", Min = 0.1, Max = 10, Default = 1, Suffix = "s", Callback = function(value) print(value) end })
AutomationSection:AddInput({ Name = "Target name", Icon = "search", Placeholder = "Type a target..." })
AutomationSection:AddKeybind({ Name = "Toggle UI", Icon = "settings", Default = "RightControl" })
AutomationSection:AddMultiDropdown({ Name = "Feature filters", Icon = "chart", Options = { "Movement", "Visuals", "Server" }, Default = { "Visuals" }, Flag = "feature_filters" })
AutomationSection:AddColorPicker({ Name = "Accent color", Description = "Choose a preset accent for this control.", Flag = "accent_color" })
VisualSection:AddStatus({ Name = "Library state", Text = "Ready", Color = Window.Theme.Success })
VisualSection:AddParagraph({ Title = "Built-in", Content = "Icon support, live FPS, tab animation, search and unload are part of the library." })

local Compatibility = Window:AddTab({ Name = "Compatibility", Description = "Subtabs and common controls", Icon = "wrench" })
local CompatibilitySub = Compatibility:AddSubTab("Preview")
CompatibilitySub:AddParagraph({ Title = "Oxide-style compatibility", Content = "AddSubTab, AddMultiDropdown, Flag, config, theme and background APIs are available." })
CompatibilitySub:AddToggle({ Name = "Preview mode", Default = true, Flag = "preview_mode" })
CompatibilitySub:AddButton({ Name = "Preview notification", Primary = true, Icon = "info", Callback = function() Window:Notify("Preview", "Subtab controls are working.", "success") end })

local Settings = Window:AddTab({ Name = "Settings", Description = "Appearance and cleanup", Icon = "settings" })
local SettingsSection = Settings:AddSection({ Name = "Interface", Description = "Tune the UI or remove it safely." })
SettingsSection:AddButton({ Name = "Unload UI", Description = "Stops connections and removes the whole interface.", Icon = "power", Callback = function() Window:Unload() end })
SettingsSection:AddButton({ Name = "Set online status", Icon = "check", Callback = function() Window:SetStatus("Online", Window.Theme.Success) end })
SettingsSection:AddButton({ Name = "Save config", Icon = "download", Callback = function()
    local ok, err = Window:SaveConfig("axelhub-demo")
    Window:Notify("Config", ok and "Configuration saved." or tostring(err), ok and "success" or "error")
end })
SettingsSection:AddButton({ Name = "Load config", Icon = "upload", Callback = function()
    local ok, err = Window:LoadConfig("axelhub-demo")
    Window:Notify("Config", ok and "Configuration loaded." or tostring(err), ok and "success" or "error")
end })
SettingsSection:AddButton({ Name = "Clear background", Icon = "x", Callback = function() Window:ClearBackground() end })

return Window
