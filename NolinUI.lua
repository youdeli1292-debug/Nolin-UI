--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                      NOLIN-UI v1.0                           ║
    ║       Профессиональная UI-библиотека для Roblox              ║
    ║       Совместимость: Xeno, Synapse, Fluxus, Delta           ║
    ╚═══════════════════════════════════════════════════════════════╝
--]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local NolinUI = {}

-- ============================================================================
-- ТЕМА / ЦВЕТА
-- ============================================================================

local Theme = {}
Theme.Background = Color3.fromRGB(15, 15, 22)
Theme.BackgroundSecondary = Color3.fromRGB(20, 20, 30)
Theme.BackgroundTertiary = Color3.fromRGB(28, 28, 40)
Theme.Sidebar = Color3.fromRGB(12, 12, 18)
Theme.SidebarBtnIdle = Color3.fromRGB(20, 20, 30)
Theme.SidebarBtnHover = Color3.fromRGB(32, 32, 48)
Theme.SidebarBtnActive = Color3.fromRGB(88, 101, 242)
Theme.Accent = Color3.fromRGB(88, 101, 242)
Theme.AccentDark = Color3.fromRGB(68, 78, 200)
Theme.AccentLight = Color3.fromRGB(120, 130, 250)
Theme.TextPrimary = Color3.fromRGB(235, 235, 245)
Theme.TextSecondary = Color3.fromRGB(155, 155, 175)
Theme.TextMuted = Color3.fromRGB(95, 95, 115)
Theme.Element = Color3.fromRGB(25, 25, 38)
Theme.ElementHover = Color3.fromRGB(32, 32, 48)
Theme.Border = Color3.fromRGB(42, 42, 60)
Theme.SliderTrack = Color3.fromRGB(35, 35, 50)
Theme.ToggleOff = Color3.fromRGB(50, 50, 68)
Theme.Divider = Color3.fromRGB(38, 38, 55)
Theme.Success = Color3.fromRGB(67, 181, 129)
Theme.Warning = Color3.fromRGB(250, 166, 26)
Theme.Error = Color3.fromRGB(237, 66, 69)

-- ============================================================================
-- УТИЛИТЫ
-- ============================================================================

local function Tween(obj, props, duration, easingStyle, easingDir, callback)
    if not obj or not obj.Parent then return nil end
    local info = TweenInfo.new(
        duration or 0.3,
        easingStyle or Enum.EasingStyle.Quint,
        easingDir or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, info, props)
    if callback then
        tw.Completed:Once(function()
            callback()
        end)
    end
    tw:Play()
    return tw
end

local function MakeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0, 8)
    c.Parent = parent
    return c
end

local function MakeStroke(parent, color, thick, transp)
    local s = Instance.new("UIStroke")
    s.Color = color or Theme.Border
    s.Thickness = thick or 1
    s.Transparency = transp or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function MakePadding(parent, t, b, l, r)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

local function MakeList(parent, dir, pad, hAlign, vAlign)
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = dir or Enum.FillDirection.Vertical
    lay.Padding = pad or UDim.new(0, 6)
    lay.HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Center
    lay.VerticalAlignment = vAlign or Enum.VerticalAlignment.Top
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = parent
    return lay
end

local function ProtectGui(gui)
    local ok = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
            return
        end
    end)
    if ok then return end

    ok = pcall(function()
        if gethui then
            gui.Parent = gethui()
            return
        end
    end)
    if ok then return end

    ok = pcall(function()
        gui.Parent = CoreGui
    end)
    if ok then return end

    pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local function Ripple(parent, posX, posY)
    if not parent or not parent.Parent then return end
    local rip = Instance.new("Frame")
    rip.Name = "Ripple"
    rip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    rip.BackgroundTransparency = 0.75
    rip.BorderSizePixel = 0
    rip.ZIndex = parent.ZIndex + 10
    rip.AnchorPoint = Vector2.new(0.5, 0.5)
    rip.Size = UDim2.new(0, 0, 0, 0)

    local absPos = parent.AbsolutePosition
    rip.Position = UDim2.new(0, posX - absPos.X, 0, posY - absPos.Y)
    rip.Parent = parent

    MakeCorner(rip, UDim.new(1, 0))

    local maxDim = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5

    Tween(rip, {
        Size = UDim2.new(0, maxDim, 0, maxDim),
        BackgroundTransparency = 1
    }, 0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, function()
        rip:Destroy()
    end)
end

-- ============================================================================
-- СИСТЕМА УВЕДОМЛЕНИЙ
-- ============================================================================

local NotifSystem = {}
NotifSystem.__index = NotifSystem

function NotifSystem.new(screenGui)
    local self = setmetatable({}, NotifSystem)
    self.Gui = screenGui
    self.List = {}

    self.Container = Instance.new("Frame")
    self.Container.Name = "Notifications"
    self.Container.BackgroundTransparency = 1
    self.Container.Size = UDim2.new(0, 310, 1, -20)
    self.Container.Position = UDim2.new(1, -320, 0, 10)
    self.Container.Parent = screenGui

    local lay = MakeList(self.Container, Enum.FillDirection.Vertical, UDim.new(0, 8))
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom

    return self
end

function NotifSystem:Push(cfg)
    local title = cfg.Title or "Уведомление"
    local content = cfg.Content or ""
    local duration = cfg.Duration or 4
    local ntype = cfg.Type or "Info"

    local accentCol = Theme.Accent
    if ntype == "Success" then accentCol = Theme.Success
    elseif ntype == "Warning" then accentCol = Theme.Warning
    elseif ntype == "Error" then accentCol = Theme.Error end

    local frame = Instance.new("Frame")
    frame.Name = "Notif"
    frame.BackgroundColor3 = Theme.BackgroundSecondary
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.ClipsDescendants = true
    frame.Parent = self.Container
    MakeCorner(frame, UDim.new(0, 10))
    MakeStroke(frame, Theme.Border, 1, 0.6)

    local accentBar = Instance.new("Frame")
    accentBar.Name = "Accent"
    accentBar.BackgroundColor3 = accentCol
    accentBar.BorderSizePixel = 0
    accentBar.Size = UDim2.new(0, 3, 1, 0)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.Parent = frame

    local inner = Instance.new("Frame")
    inner.Name = "Inner"
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, -18, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Position = UDim2.new(0, 14, 0, 0)
    inner.Parent = frame
    MakePadding(inner, 10, 10, 4, 4)
    MakeList(inner, Enum.FillDirection.Vertical, UDim.new(0, 3), Enum.HorizontalAlignment.Left)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, 0, 0, 0)
    titleLbl.AutomaticSize = Enum.AutomaticSize.Y
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = title
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.TextWrapped = true
    titleLbl.Parent = inner

    if content ~= "" then
        local cLbl = Instance.new("TextLabel")
        cLbl.Name = "Content"
        cLbl.BackgroundTransparency = 1
        cLbl.Size = UDim2.new(1, 0, 0, 0)
        cLbl.AutomaticSize = Enum.AutomaticSize.Y
        cLbl.Font = Enum.Font.Gotham
        cLbl.Text = content
        cLbl.TextColor3 = Theme.TextSecondary
        cLbl.TextSize = 11
        cLbl.TextXAlignment = Enum.TextXAlignment.Left
        cLbl.TextWrapped = true
        cLbl.Parent = inner
    end

    local progBg = Instance.new("Frame")
    progBg.Name = "ProgBg"
    progBg.BackgroundColor3 = Theme.SliderTrack
    progBg.Size = UDim2.new(1, 0, 0, 2)
    progBg.Position = UDim2.new(0, 0, 1, -2)
    progBg.BorderSizePixel = 0
    progBg.Parent = frame

    local progFill = Instance.new("Frame")
    progFill.Name = "ProgFill"
    progFill.BackgroundColor3 = accentCol
    progFill.Size = UDim2.new(1, 0, 1, 0)
    progFill.BorderSizePixel = 0
    progFill.Parent = progBg
    MakeCorner(progFill, UDim.new(0, 1))

    frame.Position = UDim2.new(1, 40, 0, 0)
    frame.BackgroundTransparency = 0.3

    Tween(frame, {Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0}, 0.4)

    Tween(progFill, {Size = UDim2.new(0, 0, 1, 0)}, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, function()
        Tween(frame, {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1}, 0.35, nil, nil, function()
            frame:Destroy()
        end)
    end)

    table.insert(self.List, frame)
    if #self.List > 5 then
        local old = table.remove(self.List, 1)
        if old and old.Parent then old:Destroy() end
    end
end

-- ============================================================================
-- КЛАСС TAB
-- ============================================================================

local Tab = {}
Tab.__index = Tab

function Tab.new(cfg, windowRef)
    local self = setmetatable({}, Tab)
    self.Name = cfg.Name or "Tab"
    self.Icon = cfg.Icon or ""
    self.Order = cfg.Order or 1
    self.Window = windowRef
    self.Elements = {}
    self.Active = false
    self:_Build()
    return self
end

function Tab:_Build()
    local w = self.Window

    -- Кнопка в сайдбаре
    self.Btn = Instance.new("TextButton")
    self.Btn.Name = "Tab_" .. self.Name
    self.Btn.BackgroundColor3 = Theme.SidebarBtnIdle
    self.Btn.BackgroundTransparency = 0.4
    self.Btn.Size = UDim2.new(1, -16, 0, 38)
    self.Btn.Text = ""
    self.Btn.AutoButtonColor = false
    self.Btn.LayoutOrder = self.Order
    self.Btn.Parent = w.TabList

    MakeCorner(self.Btn, UDim.new(0, 7))

    -- Индикатор активной вкладки
    self.Indicator = Instance.new("Frame")
    self.Indicator.Name = "Indicator"
    self.Indicator.BackgroundColor3 = Theme.Accent
    self.Indicator.Size = UDim2.new(0, 3, 0, 0)
    self.Indicator.Position = UDim2.new(0, 0, 0.5, 0)
    self.Indicator.AnchorPoint = Vector2.new(0, 0.5)
    self.Indicator.BorderSizePixel = 0
    self.Indicator.Parent = self.Btn
    MakeCorner(self.Indicator, UDim.new(0, 2))

    -- Иконка
    local textX = 12
    if self.Icon ~= "" then
        self.IconImg = Instance.new("ImageLabel")
        self.IconImg.Name = "Icon"
        self.IconImg.BackgroundTransparency = 1
        self.IconImg.Size = UDim2.new(0, 16, 0, 16)
        self.IconImg.Position = UDim2.new(0, 10, 0.5, 0)
        self.IconImg.AnchorPoint = Vector2.new(0, 0.5)
        self.IconImg.Image = self.Icon
        self.IconImg.ImageColor3 = Theme.TextSecondary
        self.IconImg.Parent = self.Btn
        textX = 34
    end

    -- Текст
    self.Label = Instance.new("TextLabel")
    self.Label.Name = "Label"
    self.Label.BackgroundTransparency = 1
    self.Label.Size = UDim2.new(1, -(textX + 6), 1, 0)
    self.Label.Position = UDim2.new(0, textX, 0, 0)
    self.Label.Font = Enum.Font.GothamMedium
    self.Label.Text = self.Name
    self.Label.TextColor3 = Theme.TextSecondary
    self.Label.TextSize = 13
    self.Label.TextXAlignment = Enum.TextXAlignment.Left
    self.Label.TextTruncate = Enum.TextTruncate.AtEnd
    self.Label.Parent = self.Btn

    -- Контент
    self.Content = Instance.new("ScrollingFrame")
    self.Content.Name = "Content_" .. self.Name
    self.Content.BackgroundTransparency = 1
    self.Content.Size = UDim2.new(1, 0, 1, 0)
    self.Content.Visible = false
    self.Content.ScrollBarThickness = 3
    self.Content.ScrollBarImageColor3 = Theme.Accent
    self.Content.ScrollBarImageTransparency = 0.5
    self.Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.Content.BorderSizePixel = 0
    self.Content.ScrollingDirection = Enum.ScrollingDirection.Y
    self.Content.ElasticBehavior = Enum.ElasticBehavior.Always
    self.Content.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.Content.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.Content.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.Content.Parent = w.ContentHolder

    MakePadding(self.Content, 12, 12, 12, 12)
    MakeList(self.Content, Enum.FillDirection.Vertical, UDim.new(0, 7), Enum.HorizontalAlignment.Center)

    -- Hover
    self.Btn.MouseEnter:Connect(function()
        if not self.Active then
            Tween(self.Btn, {BackgroundColor3 = Theme.SidebarBtnHover, BackgroundTransparency = 0.15}, 0.15)
            Tween(self.Label, {TextColor3 = Theme.TextPrimary}, 0.15)
            if self.IconImg then Tween(self.IconImg, {ImageColor3 = Theme.TextPrimary}, 0.15) end
        end
    end)

    self.Btn.MouseLeave:Connect(function()
        if not self.Active then
            Tween(self.Btn, {BackgroundColor3 = Theme.SidebarBtnIdle, BackgroundTransparency = 0.4}, 0.15)
            Tween(self.Label, {TextColor3 = Theme.TextSecondary}, 0.15)
            if self.IconImg then Tween(self.IconImg, {ImageColor3 = Theme.TextSecondary}, 0.15) end
        end
    end)

    -- Клик
    self.Btn.MouseButton1Click:Connect(function()
        w:_SwitchTab(self)
    end)
end

function Tab:_Activate()
    self.Active = true
    Tween(self.Btn, {BackgroundColor3 = Theme.SidebarBtnActive, BackgroundTransparency = 0.85}, 0.25)
    Tween(self.Label, {TextColor3 = Theme.TextPrimary}, 0.25)
    if self.IconImg then Tween(self.IconImg, {ImageColor3 = Theme.AccentLight}, 0.25) end
    Tween(self.Indicator, {Size = UDim2.new(0, 3, 0, 18)}, 0.25)

    self.Content.Visible = true
    self.Content.GroupTransparency = 1 -- нужен CanvasGroup, но ScrollingFrame не CanvasGroup

    -- Вместо GroupTransparency делаем fade через дочерние элементы
    for i, child in ipairs(self.Content:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            local orig = child:GetAttribute("_origBgTrans") or child.BackgroundTransparency
            child.BackgroundTransparency = 1
            task.delay(i * 0.025, function()
                if child and child.Parent then
                    Tween(child, {BackgroundTransparency = orig}, 0.25)
                end
            end)

            -- Также фейдим текстовые элементы внутри
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    local origTT = desc:GetAttribute("_origTextTrans") or desc.TextTransparency
                    desc.TextTransparency = 1
                    task.delay(i * 0.025, function()
                        if desc and desc.Parent then
                            Tween(desc, {TextTransparency = origTT}, 0.25)
                        end
                    end)
                elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    local origIT = desc:GetAttribute("_origImgTrans") or desc.ImageTransparency
                    desc.ImageTransparency = 1
                    task.delay(i * 0.025, function()
                        if desc and desc.Parent then
                            Tween(desc, {ImageTransparency = origIT}, 0.25)
                        end
                    end)
                elseif desc:IsA("Frame") then
                    local origBT = desc:GetAttribute("_origBgTrans") or desc.BackgroundTransparency
                    desc.BackgroundTransparency = 1
                    task.delay(i * 0.025, function()
                        if desc and desc.Parent then
                            Tween(desc, {BackgroundTransparency = origBT}, 0.25)
                        end
                    end)
                end
            end
        end
    end
end

function Tab:_Deactivate()
    self.Active = false
    Tween(self.Btn, {BackgroundColor3 = Theme.SidebarBtnIdle, BackgroundTransparency = 0.4}, 0.25)
    Tween(self.Label, {TextColor3 = Theme.TextSecondary}, 0.25)
    if self.IconImg then Tween(self.IconImg, {ImageColor3 = Theme.TextSecondary}, 0.25) end
    Tween(self.Indicator, {Size = UDim2.new(0, 3, 0, 0)}, 0.25)

    -- Fade out
    for _, child in ipairs(self.Content:GetChildren()) do
        if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            Tween(child, {BackgroundTransparency = 1}, 0.12)
            for _, desc in ipairs(child:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                    Tween(desc, {TextTransparency = 1}, 0.12)
                elseif desc:IsA("ImageLabel") or desc:IsA("ImageButton") then
                    Tween(desc, {ImageTransparency = 1}, 0.12)
                elseif desc:IsA("Frame") then
                    Tween(desc, {BackgroundTransparency = 1}, 0.12)
                end
            end
        end
    end

    task.delay(0.18, function()
        if self.Content and self.Content.Parent then
            self.Content.Visible = false
        end
    end)
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateSection
-- ============================================================================

function Tab:CreateSection(cfg)
    local name = cfg.Name or "Section"

    local frame = Instance.new("Frame")
    frame.Name = "Section"
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, 0, 0, 28)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 1)

    local divider = Instance.new("Frame")
    divider.Name = "Div"
    divider.BackgroundColor3 = Theme.Divider
    divider.BackgroundTransparency = 0.5
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.BorderSizePixel = 0
    divider.Parent = frame
    divider:SetAttribute("_origBgTrans", 0.5)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Lbl"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Position = UDim2.new(0, 0, 0, 7)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = string.upper(name)
    lbl.TextColor3 = Theme.TextMuted
    lbl.TextSize = 10
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    table.insert(self.Elements, frame)
    return frame
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateLabel
-- ============================================================================

function Tab:CreateLabel(cfg)
    local name = cfg.Name or "Label"

    local frame = Instance.new("Frame")
    frame.Name = "Label"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Text"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -20, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.Font = Enum.Font.GothamMedium
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(t)
        lbl.Text = t
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateParagraph
-- ============================================================================

function Tab:CreateParagraph(cfg)
    local title = cfg.Title or "Title"
    local content = cfg.Content or ""

    local frame = Instance.new("Frame")
    frame.Name = "Paragraph"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, 0)
    frame.AutomaticSize = Enum.AutomaticSize.Y
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)
    MakePadding(frame, 10, 10, 12, 12)
    MakeList(frame, Enum.FillDirection.Vertical, UDim.new(0, 4), Enum.HorizontalAlignment.Left)

    local tLbl = Instance.new("TextLabel")
    tLbl.Name = "Title"
    tLbl.BackgroundTransparency = 1
    tLbl.Size = UDim2.new(1, 0, 0, 0)
    tLbl.AutomaticSize = Enum.AutomaticSize.Y
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Theme.TextPrimary
    tLbl.TextSize = 14
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.TextWrapped = true
    tLbl.Parent = frame
    tLbl:SetAttribute("_origTextTrans", 0)

    local cLbl = Instance.new("TextLabel")
    cLbl.Name = "Content"
    cLbl.BackgroundTransparency = 1
    cLbl.Size = UDim2.new(1, 0, 0, 0)
    cLbl.AutomaticSize = Enum.AutomaticSize.Y
    cLbl.Font = Enum.Font.Gotham
    cLbl.Text = content
    cLbl.TextColor3 = Theme.TextSecondary
    cLbl.TextSize = 12
    cLbl.TextXAlignment = Enum.TextXAlignment.Left
    cLbl.TextWrapped = true
    cLbl.Parent = frame
    cLbl:SetAttribute("_origTextTrans", 0)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(c)
        if c.Title then tLbl.Text = c.Title end
        if c.Content then cLbl.Text = c.Content end
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateButton
-- ============================================================================

function Tab:CreateButton(cfg)
    local name = cfg.Name or "Button"
    local desc = cfg.Description or nil
    local callback = cfg.Callback or function() end

    local h = desc and 50 or 38

    local frame = Instance.new("Frame")
    frame.Name = "Button"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, h)
    frame.LayoutOrder = #self.Elements + 1
    frame.ClipsDescendants = true
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    local stroke = MakeStroke(frame, Theme.Border, 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, desc and 7 or 10)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    if desc then
        local dLbl = Instance.new("TextLabel")
        dLbl.Name = "Desc"
        dLbl.BackgroundTransparency = 1
        dLbl.Size = UDim2.new(1, -70, 0, 14)
        dLbl.Position = UDim2.new(0, 12, 0, 27)
        dLbl.Font = Enum.Font.Gotham
        dLbl.Text = desc
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextSize = 11
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.TextTruncate = Enum.TextTruncate.AtEnd
        dLbl.Parent = frame
        dLbl:SetAttribute("_origTextTrans", 0)
    end

    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.BackgroundTransparency = 1
    arrow.Size = UDim2.new(0, 18, 0, 18)
    arrow.Position = UDim2.new(1, -30, 0.5, 0)
    arrow.AnchorPoint = Vector2.new(0, 0.5)
    arrow.Font = Enum.Font.GothamBold
    arrow.Text = "→"
    arrow.TextColor3 = Theme.TextMuted
    arrow.TextSize = 15
    arrow.Parent = frame
    arrow:SetAttribute("_origTextTrans", 0)

    local click = Instance.new("TextButton")
    click.Name = "Click"
    click.BackgroundTransparency = 1
    click.Size = UDim2.new(1, 0, 1, 0)
    click.Text = ""
    click.AutoButtonColor = false
    click.ZIndex = 5
    click.Parent = frame

    click.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.12)
        Tween(stroke, {Color = Theme.Accent, Transparency = 0.4}, 0.12)
        Tween(arrow, {TextColor3 = Theme.Accent, Position = UDim2.new(1, -26, 0.5, 0)}, 0.12)
    end)

    click.MouseLeave:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.Element}, 0.12)
        Tween(stroke, {Color = Theme.Border, Transparency = 0.7}, 0.12)
        Tween(arrow, {TextColor3 = Theme.TextMuted, Position = UDim2.new(1, -30, 0.5, 0)}, 0.12)
    end)

    click.MouseButton1Click:Connect(function()
        Ripple(frame, Mouse.X, Mouse.Y)

        Tween(frame, {BackgroundColor3 = Theme.AccentDark}, 0.08)
        task.delay(0.12, function()
            Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.15)
        end)

        task.spawn(callback)
    end)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:SetText(t)
        lbl.Text = t
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateToggle
-- ============================================================================

function Tab:CreateToggle(cfg)
    local name = cfg.Name or "Toggle"
    local desc = cfg.Description or nil
    local default = cfg.Default or false
    local callback = cfg.Callback or function() end

    local state = default
    local h = desc and 50 or 38

    local frame = Instance.new("Frame")
    frame.Name = "Toggle"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, h)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, -70, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, desc and 7 or 10)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    if desc then
        local dLbl = Instance.new("TextLabel")
        dLbl.Name = "Desc"
        dLbl.BackgroundTransparency = 1
        dLbl.Size = UDim2.new(1, -70, 0, 14)
        dLbl.Position = UDim2.new(0, 12, 0, 27)
        dLbl.Font = Enum.Font.Gotham
        dLbl.Text = desc
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextSize = 11
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.TextTruncate = Enum.TextTruncate.AtEnd
        dLbl.Parent = frame
        dLbl:SetAttribute("_origTextTrans", 0)
    end

    -- Switch track
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = state and Theme.Accent or Theme.ToggleOff
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -56, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Parent = frame
    track:SetAttribute("_origBgTrans", 0)
    MakeCorner(track, UDim.new(1, 0))

    -- Knob
    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Parent = track
    knob:SetAttribute("_origBgTrans", 0)
    MakeCorner(knob, UDim.new(1, 0))

    local function updateVisual()
        if state then
            Tween(track, {BackgroundColor3 = Theme.Accent}, 0.25)
            Tween(knob, {Position = UDim2.new(1, -19, 0.5, 0)}, 0.25)
        else
            Tween(track, {BackgroundColor3 = Theme.ToggleOff}, 0.25)
            Tween(knob, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.25)
        end
    end

    local click = Instance.new("TextButton")
    click.Name = "Click"
    click.BackgroundTransparency = 1
    click.Size = UDim2.new(1, 0, 1, 0)
    click.Text = ""
    click.AutoButtonColor = false
    click.ZIndex = 5
    click.Parent = frame

    click.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.12)
    end)
    click.MouseLeave:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.Element}, 0.12)
    end)

    click.MouseButton1Click:Connect(function()
        state = not state
        updateVisual()

        -- Stretch анимация knob
        Tween(knob, {Size = UDim2.new(0, 20, 0, 16)}, 0.08)
        task.delay(0.08, function()
            Tween(knob, {Size = UDim2.new(0, 16, 0, 16)}, 0.12)
        end)

        task.spawn(function() callback(state) end)
    end)

    if default then
        task.spawn(function() callback(true) end)
    end

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(v)
        state = v
        updateVisual()
        task.spawn(function() callback(state) end)
    end
    function obj:Get()
        return state
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateSlider
-- ============================================================================

function Tab:CreateSlider(cfg)
    local name = cfg.Name or "Slider"
    local desc = cfg.Description or nil
    local min = cfg.Min or 0
    local max = cfg.Max or 100
    local default = cfg.Default or min
    local increment = cfg.Increment or 1
    local suffix = cfg.Suffix or ""
    local callback = cfg.Callback or function() end

    local current = math.clamp(default, min, max)
    local dragging = false
    local h = desc and 68 or 56

    local frame = Instance.new("Frame")
    frame.Name = "Slider"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, h)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)

    -- Имя
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, -12, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, desc and 6 or 5)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    -- Значение
    local valLbl = Instance.new("TextLabel")
    valLbl.Name = "Value"
    valLbl.BackgroundTransparency = 1
    valLbl.Size = UDim2.new(0.4, -12, 0, 18)
    valLbl.Position = UDim2.new(0.6, 0, 0, desc and 6 or 5)
    valLbl.Font = Enum.Font.GothamMedium
    valLbl.Text = tostring(current) .. suffix
    valLbl.TextColor3 = Theme.Accent
    valLbl.TextSize = 13
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = frame
    valLbl:SetAttribute("_origTextTrans", 0)

    -- Описание
    if desc then
        local dLbl = Instance.new("TextLabel")
        dLbl.Name = "Desc"
        dLbl.BackgroundTransparency = 1
        dLbl.Size = UDim2.new(1, -24, 0, 14)
        dLbl.Position = UDim2.new(0, 12, 0, 25)
        dLbl.Font = Enum.Font.Gotham
        dLbl.Text = desc
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextSize = 11
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.TextTruncate = Enum.TextTruncate.AtEnd
        dLbl.Parent = frame
        dLbl:SetAttribute("_origTextTrans", 0)
    end

    -- Track
    local trackY = desc and 46 or 32

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = Theme.SliderTrack
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, trackY)
    track.Parent = frame
    track:SetAttribute("_origBgTrans", 0)
    MakeCorner(track, UDim.new(1, 0))

    -- Fill
    local fillPct = (current - min) / (max - min)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Theme.Accent
    fill.Size = UDim2.new(fillPct, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = track
    fill:SetAttribute("_origBgTrans", 0)
    MakeCorner(fill, UDim.new(1, 0))

    -- Knob
    local knobOuter = Instance.new("Frame")
    knobOuter.Name = "Knob"
    knobOuter.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knobOuter.Size = UDim2.new(0, 14, 0, 14)
    knobOuter.Position = UDim2.new(fillPct, 0, 0.5, 0)
    knobOuter.AnchorPoint = Vector2.new(0.5, 0.5)
    knobOuter.ZIndex = 3
    knobOuter.Parent = track
    knobOuter:SetAttribute("_origBgTrans", 0)
    MakeCorner(knobOuter, UDim.new(1, 0))

    -- Glow
    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.BackgroundColor3 = Theme.Accent
    glow.BackgroundTransparency = 1
    glow.Size = UDim2.new(0, 26, 0, 26)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.ZIndex = 2
    glow.Parent = knobOuter
    glow:SetAttribute("_origBgTrans", 1)
    MakeCorner(glow, UDim.new(1, 0))

    -- Hitbox
    local hitbox = Instance.new("TextButton")
    hitbox.Name = "Hitbox"
    hitbox.BackgroundTransparency = 1
    hitbox.Size = UDim2.new(1, 10, 0, 24)
    hitbox.Position = UDim2.new(0, -5, 0.5, 0)
    hitbox.AnchorPoint = Vector2.new(0, 0.5)
    hitbox.Text = ""
    hitbox.AutoButtonColor = false
    hitbox.ZIndex = 10
    hitbox.Parent = track

    local function updateSlider(inputX)
        local tPos = track.AbsolutePosition.X
        local tSize = track.AbsoluteSize.X
        if tSize == 0 then return end

        local rel = math.clamp((inputX - tPos) / tSize, 0, 1)
        local raw = min + (max - min) * rel
        local stepped = math.floor(raw / increment + 0.5) * increment
        stepped = math.clamp(stepped, min, max)

        if stepped ~= current then
            current = stepped
            local pct = (current - min) / (max - min)

            Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.04)
            Tween(knobOuter, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.04)
            valLbl.Text = tostring(current) .. suffix

            task.spawn(function() callback(current) end)
        end
    end

    hitbox.MouseButton1Down:Connect(function()
        dragging = true
        Tween(glow, {BackgroundTransparency = 0.55}, 0.1)
        Tween(knobOuter, {Size = UDim2.new(0, 18, 0, 18)}, 0.1)
        updateSlider(Mouse.X)
    end)

    local inputMovedConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)

    local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            Tween(glow, {BackgroundTransparency = 1}, 0.2)
            Tween(knobOuter, {Size = UDim2.new(0, 14, 0, 14)}, 0.15)
        end
    end)

    -- Hover на основном фрейме
    local hoverBtn = Instance.new("TextButton")
    hoverBtn.Name = "Hover"
    hoverBtn.BackgroundTransparency = 1
    hoverBtn.Size = UDim2.new(1, 0, 1, 0)
    hoverBtn.Text = ""
    hoverBtn.AutoButtonColor = false
    hoverBtn.ZIndex = 1
    hoverBtn.Parent = frame

    hoverBtn.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.12)
    end)
    hoverBtn.MouseLeave:Connect(function()
        if not dragging then
            Tween(frame, {BackgroundColor3 = Theme.Element}, 0.12)
        end
    end)

    -- Начальный callback
    task.spawn(function() callback(current) end)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(v)
        current = math.clamp(v, min, max)
        local pct = (current - min) / (max - min)
        Tween(fill, {Size = UDim2.new(pct, 0, 1, 0)}, 0.25)
        Tween(knobOuter, {Position = UDim2.new(pct, 0, 0.5, 0)}, 0.25)
        valLbl.Text = tostring(current) .. suffix
        task.spawn(function() callback(current) end)
    end
    function obj:Get()
        return current
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateDropdown
-- ============================================================================

function Tab:CreateDropdown(cfg)
    local name = cfg.Name or "Dropdown"
    local desc = cfg.Description or nil
    local options = cfg.Options or {}
    local default = cfg.Default or nil
    local multi = cfg.MultiSelect or false
    local callback = cfg.Callback or function() end

    local isOpen = false
    local selected = {}
    local currentSel = default
    local headerH = desc and 50 or 38
    local optionBtns = {}

    if multi and type(default) == "table" then
        for _, v in ipairs(default) do
            selected[v] = true
        end
    end

    local frame = Instance.new("Frame")
    frame.Name = "Dropdown"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, headerH)
    frame.LayoutOrder = #self.Elements + 1
    frame.ClipsDescendants = true
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    local dStroke = MakeStroke(frame, Theme.Border, 1, 0.7)

    -- Название
    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.55, -12, 0, 18)
    lbl.Position = UDim2.new(0, 12, 0, desc and 7 or 10)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    if desc then
        local dLbl = Instance.new("TextLabel")
        dLbl.Name = "Desc"
        dLbl.BackgroundTransparency = 1
        dLbl.Size = UDim2.new(1, -70, 0, 14)
        dLbl.Position = UDim2.new(0, 12, 0, 27)
        dLbl.Font = Enum.Font.Gotham
        dLbl.Text = desc
        dLbl.TextColor3 = Theme.TextMuted
        dLbl.TextSize = 11
        dLbl.TextXAlignment = Enum.TextXAlignment.Left
        dLbl.TextTruncate = Enum.TextTruncate.AtEnd
        dLbl.Parent = frame
        dLbl:SetAttribute("_origTextTrans", 0)
    end

    -- Выбранное значение
    local selLbl = Instance.new("TextLabel")
    selLbl.Name = "Selected"
    selLbl.BackgroundTransparency = 1
    selLbl.Size = UDim2.new(0.4, -28, 0, 18)
    selLbl.Position = UDim2.new(0.55, 0, 0, desc and 7 or 10)
    selLbl.Font = Enum.Font.GothamMedium
    selLbl.Text = currentSel or "Выбрать..."
    selLbl.TextColor3 = Theme.TextSecondary
    selLbl.TextSize = 12
    selLbl.TextXAlignment = Enum.TextXAlignment.Right
    selLbl.TextTruncate = Enum.TextTruncate.AtEnd
    selLbl.Parent = frame
    selLbl:SetAttribute("_origTextTrans", 0)

    -- Стрелка
    local arrowLbl = Instance.new("TextLabel")
    arrowLbl.Name = "Arrow"
    arrowLbl.BackgroundTransparency = 1
    arrowLbl.Size = UDim2.new(0, 14, 0, 14)
    arrowLbl.Position = UDim2.new(1, -22, 0, desc and 9 or 12)
    arrowLbl.Font = Enum.Font.GothamBold
    arrowLbl.Text = "▼"
    arrowLbl.TextColor3 = Theme.TextMuted
    arrowLbl.TextSize = 9
    arrowLbl.Rotation = 0
    arrowLbl.Parent = frame
    arrowLbl:SetAttribute("_origTextTrans", 0)

    -- Контейнер опций
    local optContainer = Instance.new("Frame")
    optContainer.Name = "Options"
    optContainer.BackgroundColor3 = Theme.BackgroundTertiary
    optContainer.Size = UDim2.new(1, -16, 0, 0)
    optContainer.AutomaticSize = Enum.AutomaticSize.Y
    optContainer.Position = UDim2.new(0, 8, 0, headerH + 4)
    optContainer.ClipsDescendants = true
    optContainer.Parent = frame
    optContainer:SetAttribute("_origBgTrans", 0)

    MakeCorner(optContainer, UDim.new(0, 5))
    MakePadding(optContainer, 3, 3, 3, 3)
    MakeList(optContainer, Enum.FillDirection.Vertical, UDim.new(0, 2), Enum.HorizontalAlignment.Center)

    local function getSelectedText()
        if multi then
            local list = {}
            for k, v in pairs(selected) do
                if v then table.insert(list, k) end
            end
            return #list > 0 and table.concat(list, ", ") or "Выбрать..."
        else
            return currentSel or "Выбрать..."
        end
    end

    local function makeOption(optText)
        local isSel = multi and selected[optText] or (not multi and currentSel == optText)

        local btn = Instance.new("TextButton")
        btn.Name = "Opt_" .. optText
        btn.BackgroundColor3 = isSel and Theme.Accent or Color3.fromRGB(0, 0, 0)
        btn.BackgroundTransparency = isSel and 0.7 or 1
        btn.Size = UDim2.new(1, 0, 0, 28)
        btn.Font = Enum.Font.GothamMedium
        btn.Text = optText
        btn.TextColor3 = isSel and Theme.AccentLight or Theme.TextSecondary
        btn.TextSize = 12
        btn.AutoButtonColor = false
        btn.Parent = optContainer
        btn:SetAttribute("_origTextTrans", 0)
        btn:SetAttribute("_origBgTrans", isSel and 0.7 or 1)

        MakeCorner(btn, UDim.new(0, 5))

        btn.MouseEnter:Connect(function()
            local s = multi and selected[optText] or (not multi and currentSel == optText)
            if not s then
                Tween(btn, {BackgroundColor3 = Theme.ElementHover, BackgroundTransparency = 0.3}, 0.1)
                Tween(btn, {TextColor3 = Theme.TextPrimary}, 0.1)
            end
        end)

        btn.MouseLeave:Connect(function()
            local s = multi and selected[optText] or (not multi and currentSel == optText)
            if not s then
                Tween(btn, {BackgroundTransparency = 1}, 0.1)
                Tween(btn, {TextColor3 = Theme.TextSecondary}, 0.1)
            end
        end)

        btn.MouseButton1Click:Connect(function()
            if multi then
                selected[optText] = not selected[optText]
                local s = selected[optText]

                if s then
                    Tween(btn, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7}, 0.12)
                    btn.TextColor3 = Theme.AccentLight
                    btn:SetAttribute("_origBgTrans", 0.7)
                else
                    Tween(btn, {BackgroundTransparency = 1}, 0.12)
                    btn.TextColor3 = Theme.TextSecondary
                    btn:SetAttribute("_origBgTrans", 1)
                end

                selLbl.Text = getSelectedText()

                local list = {}
                for k, v in pairs(selected) do
                    if v then table.insert(list, k) end
                end
                task.spawn(function() callback(list) end)
            else
                currentSel = optText

                for _, ob in ipairs(optionBtns) do
                    local oName = string.gsub(ob.Name, "Opt_", "")
                    if oName == optText then
                        Tween(ob, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7}, 0.12)
                        ob.TextColor3 = Theme.AccentLight
                        ob:SetAttribute("_origBgTrans", 0.7)
                    else
                        Tween(ob, {BackgroundTransparency = 1}, 0.12)
                        ob.TextColor3 = Theme.TextSecondary
                        ob:SetAttribute("_origBgTrans", 1)
                    end
                end

                selLbl.Text = optText
                task.spawn(function() callback(optText) end)

                -- Закрываем
                task.delay(0.12, function()
                    isOpen = false
                    Tween(frame, {Size = UDim2.new(1, 0, 0, headerH)}, 0.25)
                    Tween(arrowLbl, {Rotation = 0}, 0.25)
                    Tween(dStroke, {Color = Theme.Border, Transparency = 0.7}, 0.25)
                end)
            end
        end)

        table.insert(optionBtns, btn)
    end

    for _, opt in ipairs(options) do
        makeOption(opt)
    end

    -- Header click
    local headerBtn = Instance.new("TextButton")
    headerBtn.Name = "HeaderBtn"
    headerBtn.BackgroundTransparency = 1
    headerBtn.Size = UDim2.new(1, 0, 0, headerH)
    headerBtn.Text = ""
    headerBtn.AutoButtonColor = false
    headerBtn.ZIndex = 5
    headerBtn.Parent = frame

    headerBtn.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.12)
    end)
    headerBtn.MouseLeave:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.Element}, 0.12)
    end)

    headerBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        if isOpen then
            local totalH = #options * 30 + 14
            Tween(frame, {Size = UDim2.new(1, 0, 0, headerH + totalH + 12)}, 0.3)
            Tween(arrowLbl, {Rotation = 180}, 0.3)
            Tween(dStroke, {Color = Theme.Accent, Transparency = 0.4}, 0.3)
        else
            Tween(frame, {Size = UDim2.new(1, 0, 0, headerH)}, 0.25)
            Tween(arrowLbl, {Rotation = 0}, 0.25)
            Tween(dStroke, {Color = Theme.Border, Transparency = 0.7}, 0.25)
        end
    end)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(v)
        if multi and type(v) == "table" then
            selected = {}
            for _, val in ipairs(v) do selected[val] = true end
            selLbl.Text = getSelectedText()
            local list = {}
            for k, vv in pairs(selected) do if vv then table.insert(list, k) end end
            task.spawn(function() callback(list) end)
        elseif not multi then
            currentSel = v
            selLbl.Text = v
            for _, ob in ipairs(optionBtns) do
                local oName = string.gsub(ob.Name, "Opt_", "")
                if oName == v then
                    ob.BackgroundColor3 = Theme.Accent
                    ob.BackgroundTransparency = 0.7
                    ob.TextColor3 = Theme.AccentLight
                else
                    ob.BackgroundTransparency = 1
                    ob.TextColor3 = Theme.TextSecondary
                end
            end
            task.spawn(function() callback(v) end)
        end
    end
    function obj:Get()
        if multi then
            local r = {}
            for k, v in pairs(selected) do if v then table.insert(r, k) end end
            return r
        end
        return currentSel
    end
    function obj:Refresh(newOpts)
        for _, b in ipairs(optionBtns) do b:Destroy() end
        optionBtns = {}
        options = newOpts
        for _, opt in ipairs(newOpts) do makeOption(opt) end
        if not multi then currentSel = nil selLbl.Text = "Выбрать..." else selected = {} selLbl.Text = "Выбрать..." end
        if isOpen then
            local totalH = #newOpts * 30 + 14
            Tween(frame, {Size = UDim2.new(1, 0, 0, headerH + totalH + 12)}, 0.25)
        end
    end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateTextBox
-- ============================================================================

function Tab:CreateTextBox(cfg)
    local name = cfg.Name or "Input"
    local placeholder = cfg.PlaceholderText or "Введите..."
    local default = cfg.Default or ""
    local clearFocus = cfg.ClearOnFocus or false
    local callback = cfg.Callback or function() end

    local frame = Instance.new("Frame")
    frame.Name = "TextBox"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, 42)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.45, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    local inputBg = Instance.new("Frame")
    inputBg.Name = "InputBg"
    inputBg.BackgroundColor3 = Theme.BackgroundTertiary
    inputBg.Size = UDim2.new(0.5, -12, 0, 28)
    inputBg.Position = UDim2.new(0.5, 0, 0.5, 0)
    inputBg.AnchorPoint = Vector2.new(0, 0.5)
    inputBg.Parent = frame
    inputBg:SetAttribute("_origBgTrans", 0)

    MakeCorner(inputBg, UDim.new(0, 5))
    local iStroke = MakeStroke(inputBg, Theme.Border, 1, 0.5)

    local tbox = Instance.new("TextBox")
    tbox.Name = "Input"
    tbox.BackgroundTransparency = 1
    tbox.Size = UDim2.new(1, -14, 1, 0)
    tbox.Position = UDim2.new(0, 7, 0, 0)
    tbox.Font = Enum.Font.Gotham
    tbox.Text = default
    tbox.PlaceholderText = placeholder
    tbox.PlaceholderColor3 = Theme.TextMuted
    tbox.TextColor3 = Theme.TextPrimary
    tbox.TextSize = 12
    tbox.TextXAlignment = Enum.TextXAlignment.Left
    tbox.ClearTextOnFocus = clearFocus
    tbox.ClipsDescendants = true
    tbox.Parent = inputBg
    tbox:SetAttribute("_origTextTrans", 0)

    tbox.Focused:Connect(function()
        Tween(iStroke, {Color = Theme.Accent, Transparency = 0.2}, 0.12)
        Tween(inputBg, {BackgroundColor3 = Color3.fromRGB(30, 30, 44)}, 0.12)
    end)

    tbox.FocusLost:Connect(function(enter)
        Tween(iStroke, {Color = Theme.Border, Transparency = 0.5}, 0.12)
        Tween(inputBg, {BackgroundColor3 = Theme.BackgroundTertiary}, 0.12)
        if enter then
            task.spawn(function() callback(tbox.Text) end)
        end
    end)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(t) tbox.Text = t end
    function obj:Get() return tbox.Text end
    return obj
end

-- ============================================================================
-- ЭЛЕМЕНТЫ: CreateKeybind
-- ============================================================================

function Tab:CreateKeybind(cfg)
    local name = cfg.Name or "Keybind"
    local default = cfg.Default or Enum.KeyCode.Unknown
    local callback = cfg.Callback or function() end
    local changed = cfg.ChangedCallback or function() end

    local currentKey = default
    local listening = false

    local frame = Instance.new("Frame")
    frame.Name = "Keybind"
    frame.BackgroundColor3 = Theme.Element
    frame.Size = UDim2.new(1, 0, 0, 38)
    frame.LayoutOrder = #self.Elements + 1
    frame.Parent = self.Content
    frame:SetAttribute("_origBgTrans", 0)

    MakeCorner(frame, UDim.new(0, 7))
    MakeStroke(frame, Theme.Border, 1, 0.7)

    local lbl = Instance.new("TextLabel")
    lbl.Name = "Label"
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.6, -12, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.Font = Enum.Font.GothamSemibold
    lbl.Text = name
    lbl.TextColor3 = Theme.TextPrimary
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    lbl:SetAttribute("_origTextTrans", 0)

    local keyText = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name

    local keyBtn = Instance.new("TextButton")
    keyBtn.Name = "KeyBtn"
    keyBtn.BackgroundColor3 = Theme.BackgroundTertiary
    keyBtn.Size = UDim2.new(0, 68, 0, 26)
    keyBtn.Position = UDim2.new(1, -80, 0.5, 0)
    keyBtn.AnchorPoint = Vector2.new(0, 0.5)
    keyBtn.Font = Enum.Font.GothamMedium
    keyBtn.Text = keyText
    keyBtn.TextColor3 = Theme.TextSecondary
    keyBtn.TextSize = 12
    keyBtn.AutoButtonColor = false
    keyBtn.Parent = frame
    keyBtn:SetAttribute("_origTextTrans", 0)
    keyBtn:SetAttribute("_origBgTrans", 0)

    MakeCorner(keyBtn, UDim.new(0, 5))
    local kStroke = MakeStroke(keyBtn, Theme.Border, 1, 0.5)

    keyBtn.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        keyBtn.Text = "..."
        Tween(kStroke, {Color = Theme.Accent, Transparency = 0.2}, 0.12)
        Tween(keyBtn, {TextColor3 = Theme.Accent}, 0.12)

        local conn
        conn = UserInputService.InputBegan:Connect(function(input, gp)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                if input.KeyCode == Enum.KeyCode.Escape then
                    currentKey = Enum.KeyCode.Unknown
                    keyBtn.Text = "None"
                else
                    currentKey = input.KeyCode
                    keyBtn.Text = currentKey.Name
                end

                Tween(kStroke, {Color = Theme.Border, Transparency = 0.5}, 0.12)
                Tween(keyBtn, {TextColor3 = Theme.TextSecondary}, 0.12)

                listening = false
                conn:Disconnect()
                task.spawn(function() changed(currentKey) end)
            end
        end)
    end)

    -- Hover
    local hoverBtn = Instance.new("TextButton")
    hoverBtn.Name = "Hover"
    hoverBtn.BackgroundTransparency = 1
    hoverBtn.Size = UDim2.new(1, 0, 1, 0)
    hoverBtn.Text = ""
    hoverBtn.AutoButtonColor = false
    hoverBtn.ZIndex = 1
    hoverBtn.Parent = frame

    hoverBtn.MouseEnter:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.ElementHover}, 0.12)
    end)
    hoverBtn.MouseLeave:Connect(function()
        Tween(frame, {BackgroundColor3 = Theme.Element}, 0.12)
    end)

    -- Global keybind trigger
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if listening then return end
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == currentKey then
            task.spawn(function() callback(currentKey) end)
        end
    end)

    table.insert(self.Elements, frame)

    local obj = {}
    function obj:Set(k)
        currentKey = k
        keyBtn.Text = k == Enum.KeyCode.Unknown and "None" or k.Name
        task.spawn(function() changed(currentKey) end)
    end
    function obj:Get()
        return currentKey
    end
    return obj
end

-- ============================================================================
-- КЛАСС WINDOW
-- ============================================================================

local Window = {}
Window.__index = Window

function Window.new(cfg)
    local self = setmetatable({}, Window)

    self.Name = cfg.Name or "Nolin-UI"
    self.LoadingText = cfg.LoadingText or "Загрузка..."
    self.LoadDuration = cfg.LoadingDuration or 3
    self.Discord = cfg.DiscordInvite or "discord.gg/nolin"
    self.ToggleKey = cfg.KeybindToToggle or Enum.KeyCode.RightShift
    self.SizeX = cfg.SizeX or 560
    self.SizeY = cfg.SizeY or 400
    self.Tabs = {}
    self.ActiveTab = nil
    self.Visible = true
    self.Loaded = false
    self._connections = {}

    self:_Init()

    return self
end

function Window:_Init()
    -- ScreenGui
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "NolinUI_" .. HttpService:GenerateGUID(false):sub(1, 8)
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Gui.ResetOnSpawn = false
    self.Gui.DisplayOrder = 999

    ProtectGui(self.Gui)

    -- Notifs
    self.Notifs = NotifSystem.new(self.Gui)

    -- Loading
    self:_BuildLoading()

    -- Main window (скрыто)
    self:_BuildWindow()

    -- Toggle keybind
    table.insert(self._connections, UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == self.ToggleKey then
            self:_Toggle()
        end
    end))

    -- Запуск загрузки
    self:_RunLoading()
end

function Window:_BuildLoading()
    self.LoadFrame = Instance.new("Frame")
    self.LoadFrame.Name = "Loading"
    self.LoadFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    self.LoadFrame.Size = UDim2.new(1, 0, 1, 0)
    self.LoadFrame.ZIndex = 100
    self.LoadFrame.Parent = self.Gui

    local center = Instance.new("Frame")
    center.Name = "Center"
    center.BackgroundTransparency = 1
    center.Size = UDim2.new(0, 280, 0, 180)
    center.Position = UDim2.new(0.5, 0, 0.5, 0)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Parent = self.LoadFrame

    self._loadTitle = Instance.new("TextLabel")
    self._loadTitle.Name = "Title"
    self._loadTitle.BackgroundTransparency = 1
    self._loadTitle.Size = UDim2.new(1, 0, 0, 36)
    self._loadTitle.Position = UDim2.new(0, 0, 0, 20)
    self._loadTitle.Font = Enum.Font.GothamBold
    self._loadTitle.Text = "NOLIN-UI"
    self._loadTitle.TextColor3 = Theme.Accent
    self._loadTitle.TextSize = 30
    self._loadTitle.TextTransparency = 1
    self._loadTitle.Parent = center

    self._loadSub = Instance.new("TextLabel")
    self._loadSub.Name = "Sub"
    self._loadSub.BackgroundTransparency = 1
    self._loadSub.Size = UDim2.new(1, 0, 0, 16)
    self._loadSub.Position = UDim2.new(0, 0, 0, 60)
    self._loadSub.Font = Enum.Font.Gotham
    self._loadSub.Text = "v1.0 — Premium UI Library"
    self._loadSub.TextColor3 = Theme.TextMuted
    self._loadSub.TextSize = 11
    self._loadSub.TextTransparency = 1
    self._loadSub.Parent = center

    self._loadStatus = Instance.new("TextLabel")
    self._loadStatus.Name = "Status"
    self._loadStatus.BackgroundTransparency = 1
    self._loadStatus.Size = UDim2.new(1, 0, 0, 18)
    self._loadStatus.Position = UDim2.new(0, 0, 0, 100)
    self._loadStatus.Font = Enum.Font.GothamMedium
    self._loadStatus.Text = self.LoadingText
    self._loadStatus.TextColor3 = Theme.TextSecondary
    self._loadStatus.TextSize = 12
    self._loadStatus.TextTransparency = 1
    self._loadStatus.Parent = center

    -- Progress bar
    self._loadBarBg = Instance.new("Frame")
    self._loadBarBg.Name = "BarBg"
    self._loadBarBg.BackgroundColor3 = Theme.SliderTrack
    self._loadBarBg.BackgroundTransparency = 1
    self._loadBarBg.Size = UDim2.new(0.65, 0, 0, 4)
    self._loadBarBg.Position = UDim2.new(0.175, 0, 0, 132)
    self._loadBarBg.Parent = center
    MakeCorner(self._loadBarBg, UDim.new(1, 0))

    self._loadBarFill = Instance.new("Frame")
    self._loadBarFill.Name = "Fill"
    self._loadBarFill.BackgroundColor3 = Theme.Accent
    self._loadBarFill.BackgroundTransparency = 1
    self._loadBarFill.Size = UDim2.new(0, 0, 1, 0)
    self._loadBarFill.BorderSizePixel = 0
    self._loadBarFill.Parent = self._loadBarBg
    MakeCorner(self._loadBarFill, UDim.new(1, 0))

    -- Dots
    self._dots = {}
    for i = 1, 3 do
        local dot = Instance.new("Frame")
        dot.Name = "Dot" .. i
        dot.BackgroundColor3 = Theme.Accent
        dot.BackgroundTransparency = 1
        dot.Size = UDim2.new(0, 7, 0, 7)
        dot.Position = UDim2.new(0.5, (i - 2) * 18, 0, 155)
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Parent = center
        MakeCorner(dot, UDim.new(1, 0))
        table.insert(self._dots, dot)
    end
end

function Window:_RunLoading()
    task.delay(0.2, function() Tween(self._loadTitle, {TextTransparency = 0}, 0.7) end)
    task.delay(0.5, function() Tween(self._loadSub, {TextTransparency = 0}, 0.5) end)
    task.delay(0.8, function() Tween(self._loadStatus, {TextTransparency = 0}, 0.4) end)

    task.delay(0.9, function()
        Tween(self._loadBarBg, {BackgroundTransparency = 0}, 0.3)
        Tween(self._loadBarFill, {BackgroundTransparency = 0}, 0.3)
        Tween(self._loadBarFill, {Size = UDim2.new(1, 0, 1, 0)}, self.LoadDuration - 1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    end)

    -- Dot animation
    task.spawn(function()
        local t0 = tick()
        while tick() - t0 < self.LoadDuration + 0.5 do
            for i, dot in ipairs(self._dots) do
                task.delay((i - 1) * 0.12, function()
                    Tween(dot, {BackgroundTransparency = 0, Size = UDim2.new(0, 9, 0, 9)}, 0.25)
                    task.delay(0.25, function()
                        Tween(dot, {BackgroundTransparency = 0.6, Size = UDim2.new(0, 7, 0, 7)}, 0.25)
                    end)
                end)
            end
            task.wait(0.8)
        end
    end)

    -- Finish loading
    task.delay(self.LoadDuration, function()
        -- Fade out
        for _, desc in ipairs(self.LoadFrame:GetDescendants()) do
            if desc:IsA("TextLabel") then
                Tween(desc, {TextTransparency = 1}, 0.35)
            elseif desc:IsA("Frame") then
                Tween(desc, {BackgroundTransparency = 1}, 0.35)
            end
        end
        Tween(self.LoadFrame, {BackgroundTransparency = 1}, 0.5)

        task.delay(0.55, function()
            self.LoadFrame:Destroy()
            self:_ShowWindow()
        end)
    end)
end

function Window:_BuildWindow()
    -- Shadow
    self.Shadow = Instance.new("Frame")
    self.Shadow.Name = "Shadow"
    self.Shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.Shadow.BackgroundTransparency = 1
    self.Shadow.Size = UDim2.new(0, self.SizeX + 10, 0, self.SizeY + 10)
    self.Shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
    self.Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Shadow.Visible = false
    self.Shadow.ZIndex = 0
    self.Shadow.Parent = self.Gui
    MakeCorner(self.Shadow, UDim.new(0, 14))

    -- Main CanvasGroup
    self.Main = Instance.new("CanvasGroup")
    self.Main.Name = "Main"
    self.Main.BackgroundColor3 = Theme.Background
    self.Main.Size = UDim2.new(0, self.SizeX, 0, self.SizeY)
    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Visible = false
    self.Main.GroupTransparency = 1
    self.Main.Parent = self.Gui
    MakeCorner(self.Main, UDim.new(0, 12))
    MakeStroke(self.Main, Theme.Border, 1, 0.4)

    -- ====== TITLEBAR ======
    local tbH = 44

    self.TitleBar = Instance.new("Frame")
    self.TitleBar.Name = "TitleBar"
    self.TitleBar.BackgroundColor3 = Theme.Sidebar
    self.TitleBar.Size = UDim2.new(1, 0, 0, tbH)
    self.TitleBar.BorderSizePixel = 0
    self.TitleBar.ZIndex = 10
    self.TitleBar.Parent = self.Main
    MakeCorner(self.TitleBar, UDim.new(0, 12))

    -- Bottom fill to cover rounded corners at bottom of titlebar
    local tbFill = Instance.new("Frame")
    tbFill.Name = "BotFill"
    tbFill.BackgroundColor3 = Theme.Sidebar
    tbFill.Size = UDim2.new(1, 0, 0, 14)
    tbFill.Position = UDim2.new(0, 0, 1, -14)
    tbFill.BorderSizePixel = 0
    tbFill.ZIndex = 9
    tbFill.Parent = self.TitleBar

    -- Divider
    local tbDiv = Instance.new("Frame")
    tbDiv.Name = "Div"
    tbDiv.BackgroundColor3 = Theme.Divider
    tbDiv.BackgroundTransparency = 0.5
    tbDiv.Size = UDim2.new(1, 0, 0, 1)
    tbDiv.Position = UDim2.new(0, 0, 1, -1)
    tbDiv.BorderSizePixel = 0
    tbDiv.ZIndex = 11
    tbDiv.Parent = self.TitleBar

    -- Logo dot
    local logoDot = Instance.new("Frame")
    logoDot.Name = "LogoDot"
    logoDot.BackgroundColor3 = Theme.Accent
    logoDot.Size = UDim2.new(0, 9, 0, 9)
    logoDot.Position = UDim2.new(0, 14, 0.5, 0)
    logoDot.AnchorPoint = Vector2.new(0, 0.5)
    logoDot.ZIndex = 12
    logoDot.Parent = self.TitleBar
    MakeCorner(logoDot, UDim.new(1, 0))

    -- Pulse animation
    task.spawn(function()
        while self.Gui and self.Gui.Parent do
            Tween(logoDot, {BackgroundTransparency = 0.35, Size = UDim2.new(0, 11, 0, 11)}, 1.3)
            task.wait(1.3)
            Tween(logoDot, {BackgroundTransparency = 0, Size = UDim2.new(0, 9, 0, 9)}, 1.3)
            task.wait(1.3)
        end
    end)

    -- Title text
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name = "Title"
    titleLbl.BackgroundTransparency = 1
    titleLbl.Size = UDim2.new(1, -130, 0, tbH)
    titleLbl.Position = UDim2.new(0, 30, 0, 0)
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.Text = self.Name
    titleLbl.TextColor3 = Theme.TextPrimary
    titleLbl.TextSize = 14
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.ZIndex = 12
    titleLbl.Parent = self.TitleBar

    -- Minimize button
    local minBtn = Instance.new("TextButton")
    minBtn.Name = "Min"
    minBtn.BackgroundColor3 = Theme.Element
    minBtn.BackgroundTransparency = 0.5
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -70, 0.5, 0)
    minBtn.AnchorPoint = Vector2.new(0, 0.5)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.Text = "—"
    minBtn.TextColor3 = Theme.TextSecondary
    minBtn.TextSize = 15
    minBtn.AutoButtonColor = false
    minBtn.ZIndex = 12
    minBtn.Parent = self.TitleBar
    MakeCorner(minBtn, UDim.new(0, 6))

    minBtn.MouseEnter:Connect(function()
        Tween(minBtn, {BackgroundTransparency = 0.2, TextColor3 = Theme.TextPrimary}, 0.12)
    end)
    minBtn.MouseLeave:Connect(function()
        Tween(minBtn, {BackgroundTransparency = 0.5, TextColor3 = Theme.TextSecondary}, 0.12)
    end)
    minBtn.MouseButton1Click:Connect(function()
        self:_Toggle()
    end)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "Close"
    closeBtn.BackgroundColor3 = Theme.Error
    closeBtn.BackgroundTransparency = 0.7
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0.5, 0)
    closeBtn.AnchorPoint = Vector2.new(0, 0.5)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Theme.TextSecondary
    closeBtn.TextSize = 13
    closeBtn.AutoButtonColor = false
    closeBtn.ZIndex = 12
    closeBtn.Parent = self.TitleBar
    MakeCorner(closeBtn, UDim.new(0, 6))

    closeBtn.MouseEnter:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0.2, TextColor3 = Color3.new(1, 1, 1)}, 0.12)
    end)
    closeBtn.MouseLeave:Connect(function()
        Tween(closeBtn, {BackgroundTransparency = 0.7, TextColor3 = Theme.TextSecondary}, 0.12)
    end)
    closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    -- ====== DRAG ======
    self:_SetupDrag()

    -- ====== BODY ======
    local body = Instance.new("Frame")
    body.Name = "Body"
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 1, -tbH)
    body.Position = UDim2.new(0, 0, 0, tbH)
    body.Parent = self.Main

    -- ====== SIDEBAR ======
    local sbW = 150

    self.SidebarFrame = Instance.new("Frame")
    self.SidebarFrame.Name = "Sidebar"
    self.SidebarFrame.BackgroundColor3 = Theme.Sidebar
    self.SidebarFrame.BackgroundTransparency = 0.1
    self.SidebarFrame.Size = UDim2.new(0, sbW, 1, 0)
    self.SidebarFrame.BorderSizePixel = 0
    self.SidebarFrame.Parent = body

    -- Sidebar divider
    local sbDiv = Instance.new("Frame")
    sbDiv.Name = "Div"
    sbDiv.BackgroundColor3 = Theme.Divider
    sbDiv.BackgroundTransparency = 0.5
    sbDiv.Size = UDim2.new(0, 1, 1, 0)
    sbDiv.Position = UDim2.new(1, 0, 0, 0)
    sbDiv.BorderSizePixel = 0
    sbDiv.Parent = self.SidebarFrame

    -- Tab list
    self.TabList = Instance.new("ScrollingFrame")
    self.TabList.Name = "TabList"
    self.TabList.BackgroundTransparency = 1
    self.TabList.Size = UDim2.new(1, 0, 1, -44)
    self.TabList.Position = UDim2.new(0, 0, 0, 6)
    self.TabList.ScrollBarThickness = 2
    self.TabList.ScrollBarImageColor3 = Theme.Accent
    self.TabList.ScrollBarImageTransparency = 0.7
    self.TabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabList.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabList.BorderSizePixel = 0
    self.TabList.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabList.TopImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.TabList.BottomImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.TabList.MidImage = "rbxasset://textures/ui/Scroll/scroll-middle.png"
    self.TabList.Parent = self.SidebarFrame

    MakePadding(self.TabList, 4, 4, 8, 8)
    MakeList(self.TabList, Enum.FillDirection.Vertical, UDim.new(0, 4), Enum.HorizontalAlignment.Center)

    -- Sidebar bottom
    local sbBot = Instance.new("Frame")
    sbBot.Name = "Bottom"
    sbBot.BackgroundTransparency = 1
    sbBot.Size = UDim2.new(1, 0, 0, 36)
    sbBot.Position = UDim2.new(0, 0, 1, -36)
    sbBot.Parent = self.SidebarFrame

    local sbBotDiv = Instance.new("Frame")
    sbBotDiv.BackgroundColor3 = Theme.Divider
    sbBotDiv.BackgroundTransparency = 0.5
    sbBotDiv.Size = UDim2.new(1, -14, 0, 1)
    sbBotDiv.Position = UDim2.new(0, 7, 0, 0)
    sbBotDiv.BorderSizePixel = 0
    sbBotDiv.Parent = sbBot

    local verLbl = Instance.new("TextLabel")
    verLbl.BackgroundTransparency = 1
    verLbl.Size = UDim2.new(1, -14, 0, 28)
    verLbl.Position = UDim2.new(0, 7, 0, 6)
    verLbl.Font = Enum.Font.Gotham
    verLbl.Text = "Nolin-UI v1.0"
    verLbl.TextColor3 = Theme.TextMuted
    verLbl.TextSize = 9
    verLbl.TextXAlignment = Enum.TextXAlignment.Center
    verLbl.Parent = sbBot

    -- ====== CONTENT AREA ======
    local contentArea = Instance.new("Frame")
    contentArea.Name = "ContentArea"
    contentArea.BackgroundColor3 = Theme.Background
    contentArea.BackgroundTransparency = 0.3
    contentArea.Size = UDim2.new(1, -sbW, 1, 0)
    contentArea.Position = UDim2.new(0, sbW, 0, 0)
    contentArea.BorderSizePixel = 0
    contentArea.ClipsDescendants = true
    contentArea.Parent = body

    -- Header
    self.ContentHeaderFrame = Instance.new("Frame")
    self.ContentHeaderFrame.Name = "Header"
    self.ContentHeaderFrame.BackgroundTransparency = 1
    self.ContentHeaderFrame.Size = UDim2.new(1, 0, 0, 36)
    self.ContentHeaderFrame.Parent = contentArea

    self.ContentHeaderLbl = Instance.new("TextLabel")
    self.ContentHeaderLbl.Name = "Lbl"
    self.ContentHeaderLbl.BackgroundTransparency = 1
    self.ContentHeaderLbl.Size = UDim2.new(1, -28, 0, 36)
    self.ContentHeaderLbl.Position = UDim2.new(0, 14, 0, 0)
    self.ContentHeaderLbl.Font = Enum.Font.GothamBold
    self.ContentHeaderLbl.Text = ""
    self.ContentHeaderLbl.TextColor3 = Theme.TextPrimary
    self.ContentHeaderLbl.TextSize = 15
    self.ContentHeaderLbl.TextXAlignment = Enum.TextXAlignment.Left
    self.ContentHeaderLbl.Parent = self.ContentHeaderFrame

    local hDiv = Instance.new("Frame")
    hDiv.BackgroundColor3 = Theme.Divider
    hDiv.BackgroundTransparency = 0.6
    hDiv.Size = UDim2.new(1, -28, 0, 1)
    hDiv.Position = UDim2.new(0, 14, 1, -1)
    hDiv.BorderSizePixel = 0
    hDiv.Parent = self.ContentHeaderFrame

    -- Content body (tabs go here)
    self.ContentHolder = Instance.new("Frame")
    self.ContentHolder.Name = "ContentHolder"
    self.ContentHolder.BackgroundTransparency = 1
    self.ContentHolder.Size = UDim2.new(1, 0, 1, -36)
    self.ContentHolder.Position = UDim2.new(0, 0, 0, 36)
    self.ContentHolder.ClipsDescendants = true
    self.ContentHolder.Parent = contentArea
end

function Window:_SetupDrag()
    local isDragging = false
    local dragStart = nil
    local startPos = nil
    local dragInputObj = nil

    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isDragging = true
            dragStart = input.Position
            startPos = self.Main.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    isDragging = false
                end
            end)
        end
    end)

    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInputObj = input
        end
    end)

    table.insert(self._connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInputObj and isDragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            Tween(self.Main, {Position = newPos}, 0.06)
            Tween(self.Shadow, {Position = UDim2.new(newPos.X.Scale, newPos.X.Offset, newPos.Y.Scale, newPos.Y.Offset + 3)}, 0.06)
        end
    end))
end

function Window:_ShowWindow()
    self.Main.Visible = true
    self.Shadow.Visible = true
    self.Loaded = true

    self.Main.GroupTransparency = 1
    self.Main.Size = UDim2.new(0, self.SizeX * 0.92, 0, self.SizeY * 0.92)

    self.Shadow.BackgroundTransparency = 1
    self.Shadow.Size = UDim2.new(0, self.SizeX * 0.92 + 10, 0, self.SizeY * 0.92 + 10)

    Tween(self.Main, {GroupTransparency = 0, Size = UDim2.new(0, self.SizeX, 0, self.SizeY)}, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(self.Shadow, {BackgroundTransparency = 0.6, Size = UDim2.new(0, self.SizeX + 10, 0, self.SizeY + 10)}, 0.45)

    if #self.Tabs > 0 then
        self:_SwitchTab(self.Tabs[1])
    end

    self.Notifs:Push({
        Title = self.Name,
        Content = "Интерфейс загружен! Нажмите " .. self.ToggleKey.Name .. " чтобы скрыть.",
        Duration = 5,
        Type = "Success",
    })
end

function Window:_SwitchTab(tab)
    if self.ActiveTab == tab then return end

    if self.ActiveTab then
        self.ActiveTab:_Deactivate()
    end

    self.ActiveTab = tab
    tab:_Activate()

    Tween(self.ContentHeaderLbl, {TextTransparency = 1}, 0.12, nil, nil, function()
        self.ContentHeaderLbl.Text = tab.Name
        Tween(self.ContentHeaderLbl, {TextTransparency = 0}, 0.18)
    end)
end

function Window:_Toggle()
    if not self.Loaded then return end
    self.Visible = not self.Visible

    if self.Visible then
        self.Main.Visible = true
        self.Shadow.Visible = true
        Tween(self.Main, {GroupTransparency = 0, Size = UDim2.new(0, self.SizeX, 0, self.SizeY)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        Tween(self.Shadow, {BackgroundTransparency = 0.6, Size = UDim2.new(0, self.SizeX + 10, 0, self.SizeY + 10)}, 0.35)
    else
        Tween(self.Main, {GroupTransparency = 1, Size = UDim2.new(0, self.SizeX * 0.92, 0, self.SizeY * 0.92)}, 0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In, function()
            self.Main.Visible = false
        end)
        Tween(self.Shadow, {BackgroundTransparency = 1, Size = UDim2.new(0, self.SizeX * 0.92 + 10, 0, self.SizeY * 0.92 + 10)}, 0.3, nil, nil, function()
            self.Shadow.Visible = false
        end)
    end
end

function Window:CreateTab(cfg)
    cfg.Order = #self.Tabs + 1
    local tab = Tab.new(cfg, self)
    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 and self.Loaded then
        self:_SwitchTab(tab)
    end

    return tab
end

function Window:Notify(cfg)
    self.Notifs:Push(cfg)
end

function Window:Destroy()
    Tween(self.Main, {GroupTransparency = 1, Size = UDim2.new(0, self.SizeX * 0.88, 0, self.SizeY * 0.88)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    Tween(self.Shadow, {BackgroundTransparency = 1}, 0.35)

    task.delay(0.4, function()
        for _, conn in ipairs(self._connections) do
            pcall(function() conn:Disconnect() end)
        end
        if self.Gui then
            self.Gui:Destroy()
        end
    end)
end

-- ============================================================================
-- ВСТРОЕННАЯ ВКЛАДКА НАСТРОЕК
-- ============================================================================

local function BuildSettingsTab(window, discord)
    local tab = window:CreateTab({Name = "Настройки", Icon = ""})

    tab:CreateSection({Name = "Информация"})

    tab:CreateParagraph({
        Title = "О Nolin-UI",
        Content = "Nolin-UI v1.0 — UI-библиотека для Roblox.\nFluent-стиль с плавными анимациями.\nСовместимость: Xeno, Synapse, Fluxus, Delta.",
    })

    tab:CreateSection({Name = "Управление"})

    tab:CreateKeybind({
        Name = "Клавиша скрытия UI",
        Default = window.ToggleKey,
        ChangedCallback = function(newKey)
            window.ToggleKey = newKey
            window:Notify({
                Title = "Настройки",
                Content = "Клавиша изменена на: " .. newKey.Name,
                Duration = 3,
                Type = "Info",
            })
        end,
    })

    tab:CreateSection({Name = "Социальные сети"})

    tab:CreateButton({
        Name = "Скопировать Discord",
        Description = discord or "discord.gg/nolin",
        Callback = function()
            local ok = pcall(function()
                if setclipboard then
                    setclipboard(discord or "discord.gg/nolin")
                elseif toclipboard then
                    toclipboard(discord or "discord.gg/nolin")
                end
            end)
            if ok then
                window:Notify({Title = "Discord", Content = "Ссылка скопирована!", Duration = 3, Type = "Success"})
            else
                window:Notify({Title = "Discord", Content = "Ссылка: " .. (discord or "discord.gg/nolin"), Duration = 5, Type = "Warning"})
            end
        end,
    })

    tab:CreateSection({Name = "Выход"})

    tab:CreateButton({
        Name = "Закрыть интерфейс",
        Description = "Полностью удаляет UI",
        Callback = function()
            window:Notify({Title = "До свидания!", Content = "UI закроется через 1.5 секунды...", Duration = 1.5, Type = "Warning"})
            task.delay(1.5, function()
                window:Destroy()
            end)
        end,
    })

    return tab
end

-- ============================================================================
-- ГЛАВНЫЙ МЕТОД: NolinUI:CreateWindow
-- ============================================================================

function NolinUI:CreateWindow(cfg)
    cfg = cfg or {}
    local addSettings = cfg.IncludeSettings ~= false

    local window = Window.new(cfg)

    if addSettings then
        task.delay(0.05, function()
            BuildSettingsTab(window, cfg.DiscordInvite)
        end)
    end

    return window
end

return NolinUI
