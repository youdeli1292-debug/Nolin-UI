--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                      NOLIN-UI v1.0                           ║
    ║       Профессиональная UI-библиотека для Roblox              ║
    ║       Совместимость: Xeno, Synapse, Fluxus, Delta, KRNL     ║
    ║                                                               ║
    ║   Использование:                                              ║
    ║   local NolinUI = loadstring(game:HttpGet("URL"))()          ║
    ║   local Win = NolinUI:CreateWindow({Name = "Test"})          ║
    ╚═══════════════════════════════════════════════════════════════╝
--]]

-- Очистка старого UI
if _G.NolinUIInstance then
    pcall(function() _G.NolinUIInstance:Destroy() end)
    _G.NolinUIInstance = nil
end
if _G.NolinConnections then
    for _, conn in pairs(_G.NolinConnections) do
        pcall(function() conn:Disconnect() end)
    end
end
_G.NolinConnections = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ============================================================================
-- ТЕМА
-- ============================================================================

local Theme = {
    Bg = Color3.fromRGB(15, 15, 22),
    BgSec = Color3.fromRGB(20, 20, 30),
    BgTer = Color3.fromRGB(28, 28, 40),
    Sidebar = Color3.fromRGB(12, 12, 18),
    SbIdle = Color3.fromRGB(20, 20, 30),
    SbHover = Color3.fromRGB(32, 32, 48),
    SbActive = Color3.fromRGB(88, 101, 242),
    Accent = Color3.fromRGB(88, 101, 242),
    AccentDark = Color3.fromRGB(68, 78, 200),
    AccentLight = Color3.fromRGB(120, 130, 250),
    Text = Color3.fromRGB(235, 235, 245),
    TextSec = Color3.fromRGB(155, 155, 175),
    TextMut = Color3.fromRGB(95, 95, 115),
    Elem = Color3.fromRGB(25, 25, 38),
    ElemHov = Color3.fromRGB(32, 32, 48),
    Border = Color3.fromRGB(42, 42, 60),
    Track = Color3.fromRGB(35, 35, 50),
    TogOff = Color3.fromRGB(50, 50, 68),
    Div = Color3.fromRGB(38, 38, 55),
    Ok = Color3.fromRGB(67, 181, 129),
    Warn = Color3.fromRGB(250, 166, 26),
    Err = Color3.fromRGB(237, 66, 69),
}

-- ============================================================================
-- УТИЛИТЫ
-- ============================================================================

local function Tw(obj, props, dur, style, dir, cb)
    if not obj then return nil end
    local ok = pcall(function() return obj.Parent end)
    if not ok then return nil end
    local info = TweenInfo.new(dur or 0.3, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out)
    local tw = TweenService:Create(obj, info, props)
    if cb then tw.Completed:Connect(cb) end
    tw:Play()
    return tw
end

local function Corner(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = r or UDim.new(0, 8)
    c.Parent = p
    return c
end

local function Stroke(p, col, th, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Theme.Border
    s.Thickness = th or 1
    s.Transparency = tr or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
    return s
end

local function Pad(p, t, b, l, r)
    local pd = Instance.new("UIPadding")
    pd.PaddingTop = UDim.new(0, t or 0)
    pd.PaddingBottom = UDim.new(0, b or 0)
    pd.PaddingLeft = UDim.new(0, l or 0)
    pd.PaddingRight = UDim.new(0, r or 0)
    pd.Parent = p
    return pd
end

local function List(p, d, pad, ha, va)
    local lay = Instance.new("UIListLayout")
    lay.FillDirection = d or Enum.FillDirection.Vertical
    lay.Padding = pad or UDim.new(0, 6)
    lay.HorizontalAlignment = ha or Enum.HorizontalAlignment.Center
    lay.VerticalAlignment = va or Enum.VerticalAlignment.Top
    lay.SortOrder = Enum.SortOrder.LayoutOrder
    lay.Parent = p
    return lay
end

local function SafeGui(gui)
    local ok = false
    pcall(function()
        if gethui then
            gui.Parent = gethui()
            ok = true
        end
    end)
    if ok then return end
    pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(gui)
            gui.Parent = CoreGui
            ok = true
        end
    end)
    if ok then return end
    pcall(function()
        gui.Parent = CoreGui
        ok = true
    end)
    if ok then return end
    pcall(function()
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end)
end

local function DoRipple(parent)
    if not parent or not parent.Parent then return end
    local rip = Instance.new("Frame")
    rip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    rip.BackgroundTransparency = 0.75
    rip.BorderSizePixel = 0
    rip.ZIndex = parent.ZIndex + 10
    rip.AnchorPoint = Vector2.new(0.5, 0.5)
    rip.Size = UDim2.new(0, 0, 0, 0)
    local ap = parent.AbsolutePosition
    rip.Position = UDim2.new(0, Mouse.X - ap.X, 0, Mouse.Y - ap.Y)
    rip.Parent = parent
    Corner(rip, UDim.new(1, 0))
    local mx = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.5
    Tw(rip, {Size = UDim2.new(0, mx, 0, mx), BackgroundTransparency = 1}, 0.5, nil, nil, function()
        if rip and rip.Parent then rip:Destroy() end
    end)
end

-- ============================================================================
-- УВЕДОМЛЕНИЯ
-- ============================================================================

local Notifs = {}
Notifs.__index = Notifs

function Notifs.new(gui)
    local self = setmetatable({}, Notifs)
    self.Gui = gui
    self.Items = {}
    self.Box = Instance.new("Frame")
    self.Box.Name = "Notifs"
    self.Box.BackgroundTransparency = 1
    self.Box.Size = UDim2.new(0, 300, 1, -20)
    self.Box.Position = UDim2.new(1, -310, 0, 10)
    self.Box.Parent = gui
    local lay = List(self.Box, Enum.FillDirection.Vertical, UDim.new(0, 8))
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Right
    lay.VerticalAlignment = Enum.VerticalAlignment.Bottom
    return self
end

function Notifs:Send(cfg)
    local title = cfg.Title or "Уведомление"
    local content = cfg.Content or ""
    local dur = cfg.Duration or 4
    local ntype = cfg.Type or "Info"

    local ac = Theme.Accent
    if ntype == "Success" then ac = Theme.Ok
    elseif ntype == "Warning" then ac = Theme.Warn
    elseif ntype == "Error" then ac = Theme.Err end

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.BgSec
    fr.Size = UDim2.new(1, 0, 0, 0)
    fr.AutomaticSize = Enum.AutomaticSize.Y
    fr.ClipsDescendants = true
    fr.Parent = self.Box
    Corner(fr, UDim.new(0, 10))
    Stroke(fr, Theme.Border, 1, 0.6)

    local bar = Instance.new("Frame")
    bar.BackgroundColor3 = ac
    bar.BorderSizePixel = 0
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.Parent = fr

    local inner = Instance.new("Frame")
    inner.BackgroundTransparency = 1
    inner.Size = UDim2.new(1, -18, 0, 0)
    inner.AutomaticSize = Enum.AutomaticSize.Y
    inner.Position = UDim2.new(0, 14, 0, 0)
    inner.Parent = fr
    Pad(inner, 10, 10, 4, 4)
    List(inner, Enum.FillDirection.Vertical, UDim.new(0, 3), Enum.HorizontalAlignment.Left)

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 0, 0)
    tl.AutomaticSize = Enum.AutomaticSize.Y
    tl.Font = Enum.Font.GothamBold
    tl.Text = title
    tl.TextColor3 = Theme.Text
    tl.TextSize = 13
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextWrapped = true
    tl.Parent = inner

    if content ~= "" then
        local cl = Instance.new("TextLabel")
        cl.BackgroundTransparency = 1
        cl.Size = UDim2.new(1, 0, 0, 0)
        cl.AutomaticSize = Enum.AutomaticSize.Y
        cl.Font = Enum.Font.Gotham
        cl.Text = content
        cl.TextColor3 = Theme.TextSec
        cl.TextSize = 11
        cl.TextXAlignment = Enum.TextXAlignment.Left
        cl.TextWrapped = true
        cl.Parent = inner
    end

    local pbg = Instance.new("Frame")
    pbg.BackgroundColor3 = Theme.Track
    pbg.Size = UDim2.new(1, 0, 0, 2)
    pbg.Position = UDim2.new(0, 0, 1, -2)
    pbg.BorderSizePixel = 0
    pbg.Parent = fr

    local pf = Instance.new("Frame")
    pf.BackgroundColor3 = ac
    pf.Size = UDim2.new(1, 0, 1, 0)
    pf.BorderSizePixel = 0
    pf.Parent = pbg

    fr.Position = UDim2.new(1, 40, 0, 0)
    Tw(fr, {Position = UDim2.new(0, 0, 0, 0)}, 0.4)

    Tw(pf, {Size = UDim2.new(0, 0, 1, 0)}, dur, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, function()
        Tw(fr, {Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1}, 0.35, nil, nil, function()
            if fr and fr.Parent then fr:Destroy() end
        end)
    end)

    table.insert(self.Items, fr)
    if #self.Items > 5 then
        local old = table.remove(self.Items, 1)
        if old and old.Parent then old:Destroy() end
    end
end

-- ============================================================================
-- КЛАСС TAB
-- ============================================================================

local Tab = {}
Tab.__index = Tab

function Tab.new(cfg, win)
    local self = setmetatable({}, Tab)
    self.Name = cfg.Name or "Tab"
    self.Icon = cfg.Icon or ""
    self.Ord = cfg.Order or 1
    self.W = win
    self.Elems = {}
    self.On = false
    self:_Make()
    return self
end

function Tab:_Make()
    local w = self.W

    self.Btn = Instance.new("TextButton")
    self.Btn.BackgroundColor3 = Theme.SbIdle
    self.Btn.BackgroundTransparency = 0.4
    self.Btn.Size = UDim2.new(1, -16, 0, 36)
    self.Btn.Text = ""
    self.Btn.AutoButtonColor = false
    self.Btn.LayoutOrder = self.Ord
    self.Btn.Parent = w.TabScroll
    Corner(self.Btn, UDim.new(0, 7))

    self.Ind = Instance.new("Frame")
    self.Ind.BackgroundColor3 = Theme.Accent
    self.Ind.Size = UDim2.new(0, 3, 0, 0)
    self.Ind.Position = UDim2.new(0, 0, 0.5, 0)
    self.Ind.AnchorPoint = Vector2.new(0, 0.5)
    self.Ind.BorderSizePixel = 0
    self.Ind.Parent = self.Btn
    Corner(self.Ind, UDim.new(0, 2))

    local tx = 12
    if self.Icon ~= "" then
        self.Ico = Instance.new("ImageLabel")
        self.Ico.BackgroundTransparency = 1
        self.Ico.Size = UDim2.new(0, 16, 0, 16)
        self.Ico.Position = UDim2.new(0, 10, 0.5, 0)
        self.Ico.AnchorPoint = Vector2.new(0, 0.5)
        self.Ico.Image = self.Icon
        self.Ico.ImageColor3 = Theme.TextSec
        self.Ico.Parent = self.Btn
        tx = 34
    end

    self.Lbl = Instance.new("TextLabel")
    self.Lbl.BackgroundTransparency = 1
    self.Lbl.Size = UDim2.new(1, -(tx + 6), 1, 0)
    self.Lbl.Position = UDim2.new(0, tx, 0, 0)
    self.Lbl.Font = Enum.Font.GothamMedium
    self.Lbl.Text = self.Name
    self.Lbl.TextColor3 = Theme.TextSec
    self.Lbl.TextSize = 13
    self.Lbl.TextXAlignment = Enum.TextXAlignment.Left
    self.Lbl.TextTruncate = Enum.TextTruncate.AtEnd
    self.Lbl.Parent = self.Btn

    self.Page = Instance.new("ScrollingFrame")
    self.Page.BackgroundTransparency = 1
    self.Page.Size = UDim2.new(1, 0, 1, 0)
    self.Page.Visible = false
    self.Page.ScrollBarThickness = 3
    self.Page.ScrollBarImageColor3 = Theme.Accent
    self.Page.ScrollBarImageTransparency = 0.5
    self.Page.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.Page.BorderSizePixel = 0
    self.Page.ScrollingDirection = Enum.ScrollingDirection.Y
    self.Page.Parent = w.Pages
    Pad(self.Page, 12, 12, 12, 12)
    List(self.Page, Enum.FillDirection.Vertical, UDim.new(0, 7), Enum.HorizontalAlignment.Center)

    self.Btn.MouseEnter:Connect(function()
        if not self.On then
            Tw(self.Btn, {BackgroundColor3 = Theme.SbHover, BackgroundTransparency = 0.15}, 0.12)
            Tw(self.Lbl, {TextColor3 = Theme.Text}, 0.12)
            if self.Ico then Tw(self.Ico, {ImageColor3 = Theme.Text}, 0.12) end
        end
    end)

    self.Btn.MouseLeave:Connect(function()
        if not self.On then
            Tw(self.Btn, {BackgroundColor3 = Theme.SbIdle, BackgroundTransparency = 0.4}, 0.12)
            Tw(self.Lbl, {TextColor3 = Theme.TextSec}, 0.12)
            if self.Ico then Tw(self.Ico, {ImageColor3 = Theme.TextSec}, 0.12) end
        end
    end)

    self.Btn.MouseButton1Click:Connect(function()
        w:_Switch(self)
    end)
end

function Tab:_On()
    self.On = true
    Tw(self.Btn, {BackgroundColor3 = Theme.SbActive, BackgroundTransparency = 0.85}, 0.25)
    Tw(self.Lbl, {TextColor3 = Theme.Text}, 0.25)
    if self.Ico then Tw(self.Ico, {ImageColor3 = Theme.AccentLight}, 0.25) end
    Tw(self.Ind, {Size = UDim2.new(0, 3, 0, 18)}, 0.25)
    self.Page.Visible = true
end

function Tab:_Off()
    self.On = false
    Tw(self.Btn, {BackgroundColor3 = Theme.SbIdle, BackgroundTransparency = 0.4}, 0.2)
    Tw(self.Lbl, {TextColor3 = Theme.TextSec}, 0.2)
    if self.Ico then Tw(self.Ico, {ImageColor3 = Theme.TextSec}, 0.2) end
    Tw(self.Ind, {Size = UDim2.new(0, 3, 0, 0)}, 0.2)
    self.Page.Visible = false
end

-- ============================================================================
-- ЭЛЕМЕНТЫ
-- ============================================================================

function Tab:CreateSection(cfg)
    local fr = Instance.new("Frame")
    fr.BackgroundTransparency = 1
    fr.Size = UDim2.new(1, 0, 0, 26)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page

    local dv = Instance.new("Frame")
    dv.BackgroundColor3 = Theme.Div
    dv.BackgroundTransparency = 0.5
    dv.Size = UDim2.new(1, 0, 0, 1)
    dv.BorderSizePixel = 0
    dv.Parent = fr

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, 0, 0, 16)
    lb.Position = UDim2.new(0, 0, 0, 6)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = string.upper(cfg.Name or "SECTION")
    lb.TextColor3 = Theme.TextMut
    lb.TextSize = 10
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    table.insert(self.Elems, fr)
    return fr
end

function Tab:CreateLabel(cfg)
    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, 34)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, -20, 1, 0)
    lb.Position = UDim2.new(0, 10, 0, 0)
    lb.Font = Enum.Font.GothamMedium
    lb.Text = cfg.Name or "Label"
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(t) lb.Text = t end
    return o
end

function Tab:CreateParagraph(cfg)
    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, 0)
    fr.AutomaticSize = Enum.AutomaticSize.Y
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)
    Pad(fr, 10, 10, 12, 12)
    List(fr, Enum.FillDirection.Vertical, UDim.new(0, 4), Enum.HorizontalAlignment.Left)

    local tl = Instance.new("TextLabel")
    tl.BackgroundTransparency = 1
    tl.Size = UDim2.new(1, 0, 0, 0)
    tl.AutomaticSize = Enum.AutomaticSize.Y
    tl.Font = Enum.Font.GothamBold
    tl.Text = cfg.Title or ""
    tl.TextColor3 = Theme.Text
    tl.TextSize = 14
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.TextWrapped = true
    tl.Parent = fr

    local cl = Instance.new("TextLabel")
    cl.BackgroundTransparency = 1
    cl.Size = UDim2.new(1, 0, 0, 0)
    cl.AutomaticSize = Enum.AutomaticSize.Y
    cl.Font = Enum.Font.Gotham
    cl.Text = cfg.Content or ""
    cl.TextColor3 = Theme.TextSec
    cl.TextSize = 12
    cl.TextXAlignment = Enum.TextXAlignment.Left
    cl.TextWrapped = true
    cl.Parent = fr

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(c)
        if c.Title then tl.Text = c.Title end
        if c.Content then cl.Text = c.Content end
    end
    return o
end

function Tab:CreateButton(cfg)
    local name = cfg.Name or "Button"
    local desc = cfg.Description
    local cb = cfg.Callback or function() end
    local h = desc and 48 or 36

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, h)
    fr.LayoutOrder = #self.Elems + 1
    fr.ClipsDescendants = true
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    local st = Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, -60, 0, 16)
    lb.Position = UDim2.new(0, 12, 0, desc and 6 or 10)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    if desc then
        local dl = Instance.new("TextLabel")
        dl.BackgroundTransparency = 1
        dl.Size = UDim2.new(1, -60, 0, 14)
        dl.Position = UDim2.new(0, 12, 0, 26)
        dl.Font = Enum.Font.Gotham
        dl.Text = desc
        dl.TextColor3 = Theme.TextMut
        dl.TextSize = 11
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.TextTruncate = Enum.TextTruncate.AtEnd
        dl.Parent = fr
    end

    local ar = Instance.new("TextLabel")
    ar.BackgroundTransparency = 1
    ar.Size = UDim2.new(0, 16, 0, 16)
    ar.Position = UDim2.new(1, -28, 0.5, 0)
    ar.AnchorPoint = Vector2.new(0, 0.5)
    ar.Font = Enum.Font.GothamBold
    ar.Text = ">"
    ar.TextColor3 = Theme.TextMut
    ar.TextSize = 14
    ar.Parent = fr

    local ck = Instance.new("TextButton")
    ck.BackgroundTransparency = 1
    ck.Size = UDim2.new(1, 0, 1, 0)
    ck.Text = ""
    ck.AutoButtonColor = false
    ck.ZIndex = 5
    ck.Parent = fr

    ck.MouseEnter:Connect(function()
        Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.1)
        Tw(st, {Color = Theme.Accent, Transparency = 0.4}, 0.1)
        Tw(ar, {TextColor3 = Theme.Accent, Position = UDim2.new(1, -24, 0.5, 0)}, 0.1)
    end)
    ck.MouseLeave:Connect(function()
        Tw(fr, {BackgroundColor3 = Theme.Elem}, 0.1)
        Tw(st, {Color = Theme.Border, Transparency = 0.7}, 0.1)
        Tw(ar, {TextColor3 = Theme.TextMut, Position = UDim2.new(1, -28, 0.5, 0)}, 0.1)
    end)
    ck.MouseButton1Click:Connect(function()
        DoRipple(fr)
        Tw(fr, {BackgroundColor3 = Theme.AccentDark}, 0.07)
        task.delay(0.1, function()
            Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.12)
        end)
        task.spawn(cb)
    end)

    table.insert(self.Elems, fr)
    local o = {}
    function o:SetText(t) lb.Text = t end
    return o
end

function Tab:CreateToggle(cfg)
    local name = cfg.Name or "Toggle"
    local desc = cfg.Description
    local def = cfg.Default or false
    local cb = cfg.Callback or function() end
    local state = def
    local h = desc and 48 or 36

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, h)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(1, -65, 0, 16)
    lb.Position = UDim2.new(0, 12, 0, desc and 6 or 10)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    if desc then
        local dl = Instance.new("TextLabel")
        dl.BackgroundTransparency = 1
        dl.Size = UDim2.new(1, -65, 0, 14)
        dl.Position = UDim2.new(0, 12, 0, 26)
        dl.Font = Enum.Font.Gotham
        dl.Text = desc
        dl.TextColor3 = Theme.TextMut
        dl.TextSize = 11
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.TextTruncate = Enum.TextTruncate.AtEnd
        dl.Parent = fr
    end

    local track = Instance.new("Frame")
    track.BackgroundColor3 = state and Theme.Accent or Theme.TogOff
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -52, 0.5, 0)
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Parent = fr
    Corner(track, UDim.new(1, 0))

    local knob = Instance.new("Frame")
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = state and UDim2.new(1, -17, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Parent = track
    Corner(knob, UDim.new(1, 0))

    local function upd()
        if state then
            Tw(track, {BackgroundColor3 = Theme.Accent}, 0.2)
            Tw(knob, {Position = UDim2.new(1, -17, 0.5, 0)}, 0.2)
        else
            Tw(track, {BackgroundColor3 = Theme.TogOff}, 0.2)
            Tw(knob, {Position = UDim2.new(0, 3, 0.5, 0)}, 0.2)
        end
    end

    local ck = Instance.new("TextButton")
    ck.BackgroundTransparency = 1
    ck.Size = UDim2.new(1, 0, 1, 0)
    ck.Text = ""
    ck.AutoButtonColor = false
    ck.ZIndex = 5
    ck.Parent = fr

    ck.MouseEnter:Connect(function() Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.1) end)
    ck.MouseLeave:Connect(function() Tw(fr, {BackgroundColor3 = Theme.Elem}, 0.1) end)
    ck.MouseButton1Click:Connect(function()
        state = not state
        upd()
        task.spawn(function() cb(state) end)
    end)

    if def then task.spawn(function() cb(true) end) end

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(v) state = v upd() task.spawn(function() cb(state) end) end
    function o:Get() return state end
    return o
end

function Tab:CreateSlider(cfg)
    local name = cfg.Name or "Slider"
    local desc = cfg.Description
    local mn = cfg.Min or 0
    local mx = cfg.Max or 100
    local def = cfg.Default or mn
    local inc = cfg.Increment or 1
    local suf = cfg.Suffix or ""
    local cb = cfg.Callback or function() end

    local cur = math.clamp(def, mn, mx)
    local dragging = false
    local h = desc and 66 or 54

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, h)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(0.6, -12, 0, 16)
    lb.Position = UDim2.new(0, 12, 0, desc and 5 or 4)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    local vl = Instance.new("TextLabel")
    vl.BackgroundTransparency = 1
    vl.Size = UDim2.new(0.4, -12, 0, 16)
    vl.Position = UDim2.new(0.6, 0, 0, desc and 5 or 4)
    vl.Font = Enum.Font.GothamMedium
    vl.Text = tostring(cur) .. suf
    vl.TextColor3 = Theme.Accent
    vl.TextSize = 13
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = fr

    if desc then
        local dl = Instance.new("TextLabel")
        dl.BackgroundTransparency = 1
        dl.Size = UDim2.new(1, -24, 0, 14)
        dl.Position = UDim2.new(0, 12, 0, 23)
        dl.Font = Enum.Font.Gotham
        dl.Text = desc
        dl.TextColor3 = Theme.TextMut
        dl.TextSize = 11
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.TextTruncate = Enum.TextTruncate.AtEnd
        dl.Parent = fr
    end

    local tY = desc and 44 or 30

    local trk = Instance.new("Frame")
    trk.BackgroundColor3 = Theme.Track
    trk.Size = UDim2.new(1, -24, 0, 8)
    trk.Position = UDim2.new(0, 12, 0, tY)
    trk.BorderSizePixel = 0
    trk.Parent = fr
    Corner(trk, UDim.new(1, 0))

    local pct = (cur - mn) / math.max(mx - mn, 0.001)

    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Theme.Accent
    fill.Size = UDim2.new(pct, 0, 1, 0)
    fill.BorderSizePixel = 0
    fill.Parent = trk
    Corner(fill, UDim.new(1, 0))

    local kn = Instance.new("Frame")
    kn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    kn.Size = UDim2.new(0, 16, 0, 16)
    kn.Position = UDim2.new(pct, 0, 0.5, 0)
    kn.AnchorPoint = Vector2.new(0.5, 0.5)
    kn.ZIndex = 5
    kn.Parent = trk
    Corner(kn, UDim.new(1, 0))

    local function setVal(mouseX)
        local tp = trk.AbsolutePosition.X
        local ts = trk.AbsoluteSize.X
        if ts <= 0 then return end
        local rel = math.clamp((mouseX - tp) / ts, 0, 1)
        local raw = mn + (mx - mn) * rel
        local stepped = math.floor(raw / inc + 0.5) * inc
        stepped = math.clamp(stepped, mn, mx)
        if stepped ~= cur then
            cur = stepped
            local p2 = (cur - mn) / math.max(mx - mn, 0.001)
            fill.Size = UDim2.new(p2, 0, 1, 0)
            kn.Position = UDim2.new(p2, 0, 0.5, 0)
            vl.Text = tostring(cur) .. suf
            task.spawn(function() cb(cur) end)
        end
    end

    trk.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setVal(input.Position.X)
        end
    end)

    local c1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setVal(input.Position.X)
        end
    end)
    table.insert(_G.NolinConnections, c1)

    local c2 = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    table.insert(_G.NolinConnections, c2)

    local hv = Instance.new("TextButton")
    hv.BackgroundTransparency = 1
    hv.Size = UDim2.new(1, 0, 1, 0)
    hv.Text = ""
    hv.AutoButtonColor = false
    hv.ZIndex = 1
    hv.Parent = fr

    hv.MouseEnter:Connect(function() Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.1) end)
    hv.MouseLeave:Connect(function()
        if not dragging then Tw(fr, {BackgroundColor3 = Theme.Elem}, 0.1) end
    end)

    task.spawn(function() cb(cur) end)

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(v)
        cur = math.clamp(v, mn, mx)
        local p2 = (cur - mn) / math.max(mx - mn, 0.001)
        fill.Size = UDim2.new(p2, 0, 1, 0)
        kn.Position = UDim2.new(p2, 0, 0.5, 0)
        vl.Text = tostring(cur) .. suf
        task.spawn(function() cb(cur) end)
    end
    function o:Get() return cur end
    return o
end

function Tab:CreateDropdown(cfg)
    local name = cfg.Name or "Dropdown"
    local desc = cfg.Description
    local opts = cfg.Options or {}
    local def = cfg.Default
    local multi = cfg.MultiSelect or false
    local cb = cfg.Callback or function() end

    local open = false
    local sel = {}
    local curSel = def
    local hH = desc and 48 or 36
    local oBtns = {}

    if multi and type(def) == "table" then
        for _, v in ipairs(def) do sel[v] = true end
    end

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, hH)
    fr.LayoutOrder = #self.Elems + 1
    fr.ClipsDescendants = true
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    local ds = Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(0.5, -12, 0, 16)
    lb.Position = UDim2.new(0, 12, 0, desc and 6 or 10)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    if desc then
        local dl = Instance.new("TextLabel")
        dl.BackgroundTransparency = 1
        dl.Size = UDim2.new(1, -65, 0, 14)
        dl.Position = UDim2.new(0, 12, 0, 26)
        dl.Font = Enum.Font.Gotham
        dl.Text = desc
        dl.TextColor3 = Theme.TextMut
        dl.TextSize = 11
        dl.TextXAlignment = Enum.TextXAlignment.Left
        dl.TextTruncate = Enum.TextTruncate.AtEnd
        dl.Parent = fr
    end

    local function getSelText()
        if multi then
            local r = {}
            for k, v in pairs(sel) do if v then table.insert(r, k) end end
            return #r > 0 and table.concat(r, ", ") or "Выбрать..."
        end
        return curSel or "Выбрать..."
    end

    local sLbl = Instance.new("TextLabel")
    sLbl.BackgroundTransparency = 1
    sLbl.Size = UDim2.new(0.42, -24, 0, 16)
    sLbl.Position = UDim2.new(0.5, 0, 0, desc and 6 or 10)
    sLbl.Font = Enum.Font.GothamMedium
    sLbl.Text = getSelText()
    sLbl.TextColor3 = Theme.TextSec
    sLbl.TextSize = 12
    sLbl.TextXAlignment = Enum.TextXAlignment.Right
    sLbl.TextTruncate = Enum.TextTruncate.AtEnd
    sLbl.Parent = fr

    local arw = Instance.new("TextLabel")
    arw.BackgroundTransparency = 1
    arw.Size = UDim2.new(0, 12, 0, 12)
    arw.Position = UDim2.new(1, -20, 0, desc and 8 or 12)
    arw.Font = Enum.Font.GothamBold
    arw.Text = "v"
    arw.TextColor3 = Theme.TextMut
    arw.TextSize = 11
    arw.Rotation = 0
    arw.Parent = fr

    local optBox = Instance.new("Frame")
    optBox.BackgroundColor3 = Theme.BgTer
    optBox.Size = UDim2.new(1, -16, 0, 0)
    optBox.AutomaticSize = Enum.AutomaticSize.Y
    optBox.Position = UDim2.new(0, 8, 0, hH + 4)
    optBox.ClipsDescendants = true
    optBox.Parent = fr
    Corner(optBox, UDim.new(0, 5))
    Pad(optBox, 3, 3, 3, 3)
    List(optBox, Enum.FillDirection.Vertical, UDim.new(0, 2), Enum.HorizontalAlignment.Center)

    local function mkOpt(txt)
        local isSel = multi and sel[txt] or (not multi and curSel == txt)
        local ob = Instance.new("TextButton")
        ob.Name = "O_" .. txt
        ob.BackgroundColor3 = isSel and Theme.Accent or Color3.fromRGB(0, 0, 0)
        ob.BackgroundTransparency = isSel and 0.7 or 1
        ob.Size = UDim2.new(1, 0, 0, 28)
        ob.Font = Enum.Font.GothamMedium
        ob.Text = txt
        ob.TextColor3 = isSel and Theme.AccentLight or Theme.TextSec
        ob.TextSize = 12
        ob.AutoButtonColor = false
        ob.Parent = optBox
        Corner(ob, UDim.new(0, 5))

        ob.MouseEnter:Connect(function()
            local s2 = multi and sel[txt] or (not multi and curSel == txt)
            if not s2 then
                Tw(ob, {BackgroundColor3 = Theme.ElemHov, BackgroundTransparency = 0.3, TextColor3 = Theme.Text}, 0.08)
            end
        end)
        ob.MouseLeave:Connect(function()
            local s2 = multi and sel[txt] or (not multi and curSel == txt)
            if not s2 then
                Tw(ob, {BackgroundTransparency = 1, TextColor3 = Theme.TextSec}, 0.08)
            end
        end)
        ob.MouseButton1Click:Connect(function()
            if multi then
                sel[txt] = not sel[txt]
                if sel[txt] then
                    Tw(ob, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7}, 0.1)
                    ob.TextColor3 = Theme.AccentLight
                else
                    Tw(ob, {BackgroundTransparency = 1}, 0.1)
                    ob.TextColor3 = Theme.TextSec
                end
                sLbl.Text = getSelText()
                local r = {}
                for k, v in pairs(sel) do if v then table.insert(r, k) end end
                task.spawn(function() cb(r) end)
            else
                curSel = txt
                for _, b in ipairs(oBtns) do
                    local bn = string.gsub(b.Name, "O_", "")
                    if bn == txt then
                        Tw(b, {BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.7}, 0.1)
                        b.TextColor3 = Theme.AccentLight
                    else
                        Tw(b, {BackgroundTransparency = 1}, 0.1)
                        b.TextColor3 = Theme.TextSec
                    end
                end
                sLbl.Text = txt
                task.spawn(function() cb(txt) end)
                task.delay(0.1, function()
                    open = false
                    Tw(fr, {Size = UDim2.new(1, 0, 0, hH)}, 0.25)
                    Tw(arw, {Rotation = 0}, 0.25)
                    Tw(ds, {Color = Theme.Border, Transparency = 0.7}, 0.25)
                end)
            end
        end)
        table.insert(oBtns, ob)
    end

    for _, o in ipairs(opts) do mkOpt(o) end

    local hBtn = Instance.new("TextButton")
    hBtn.BackgroundTransparency = 1
    hBtn.Size = UDim2.new(1, 0, 0, hH)
    hBtn.Text = ""
    hBtn.AutoButtonColor = false
    hBtn.ZIndex = 5
    hBtn.Parent = fr

    hBtn.MouseEnter:Connect(function() Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.1) end)
    hBtn.MouseLeave:Connect(function() Tw(fr, {BackgroundColor3 = Theme.Elem}, 0.1) end)
    hBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            local tH = #opts * 30 + 14
            Tw(fr, {Size = UDim2.new(1, 0, 0, hH + tH + 12)}, 0.28)
            Tw(arw, {Rotation = 180}, 0.28)
            Tw(ds, {Color = Theme.Accent, Transparency = 0.4}, 0.28)
        else
            Tw(fr, {Size = UDim2.new(1, 0, 0, hH)}, 0.22)
            Tw(arw, {Rotation = 0}, 0.22)
            Tw(ds, {Color = Theme.Border, Transparency = 0.7}, 0.22)
        end
    end)

    table.insert(self.Elems, fr)
    local obj = {}
    function obj:Set(v)
        if multi and type(v) == "table" then
            sel = {}
            for _, val in ipairs(v) do sel[val] = true end
            sLbl.Text = getSelText()
        elseif not multi then
            curSel = v
            sLbl.Text = v
        end
    end
    function obj:Get()
        if multi then
            local r = {}
            for k, v in pairs(sel) do if v then table.insert(r, k) end end
            return r
        end
        return curSel
    end
    return obj
end

function Tab:CreateTextBox(cfg)
    local name = cfg.Name or "Input"
    local ph = cfg.PlaceholderText or "Введите..."
    local def = cfg.Default or ""
    local clr = cfg.ClearOnFocus or false
    local cb = cfg.Callback or function() end

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, 40)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(0.45, -12, 1, 0)
    lb.Position = UDim2.new(0, 12, 0, 0)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    local ibg = Instance.new("Frame")
    ibg.BackgroundColor3 = Theme.BgTer
    ibg.Size = UDim2.new(0.48, -12, 0, 26)
    ibg.Position = UDim2.new(0.52, 0, 0.5, 0)
    ibg.AnchorPoint = Vector2.new(0, 0.5)
    ibg.Parent = fr
    Corner(ibg, UDim.new(0, 5))
    local is = Stroke(ibg, Theme.Border, 1, 0.5)

    local tb = Instance.new("TextBox")
    tb.BackgroundTransparency = 1
    tb.Size = UDim2.new(1, -12, 1, 0)
    tb.Position = UDim2.new(0, 6, 0, 0)
    tb.Font = Enum.Font.Gotham
    tb.Text = def
    tb.PlaceholderText = ph
    tb.PlaceholderColor3 = Theme.TextMut
    tb.TextColor3 = Theme.Text
    tb.TextSize = 12
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = clr
    tb.ClipsDescendants = true
    tb.Parent = ibg

    tb.Focused:Connect(function() Tw(is, {Color = Theme.Accent, Transparency = 0.2}, 0.1) end)
    tb.FocusLost:Connect(function(enter)
        Tw(is, {Color = Theme.Border, Transparency = 0.5}, 0.1)
        if enter then task.spawn(function() cb(tb.Text) end) end
    end)

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(t) tb.Text = t end
    function o:Get() return tb.Text end
    return o
end

function Tab:CreateKeybind(cfg)
    local name = cfg.Name or "Keybind"
    local def = cfg.Default or Enum.KeyCode.Unknown
    local cb = cfg.Callback or function() end
    local chg = cfg.ChangedCallback or function() end

    local curKey = def
    local listening = false

    local fr = Instance.new("Frame")
    fr.BackgroundColor3 = Theme.Elem
    fr.Size = UDim2.new(1, 0, 0, 36)
    fr.LayoutOrder = #self.Elems + 1
    fr.Parent = self.Page
    Corner(fr, UDim.new(0, 7))
    Stroke(fr, Theme.Border, 1, 0.7)

    local lb = Instance.new("TextLabel")
    lb.BackgroundTransparency = 1
    lb.Size = UDim2.new(0.6, -12, 1, 0)
    lb.Position = UDim2.new(0, 12, 0, 0)
    lb.Font = Enum.Font.GothamSemibold
    lb.Text = name
    lb.TextColor3 = Theme.Text
    lb.TextSize = 13
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = fr

    local kt = curKey == Enum.KeyCode.Unknown and "None" or curKey.Name

    local kb = Instance.new("TextButton")
    kb.BackgroundColor3 = Theme.BgTer
    kb.Size = UDim2.new(0, 65, 0, 24)
    kb.Position = UDim2.new(1, -77, 0.5, 0)
    kb.AnchorPoint = Vector2.new(0, 0.5)
    kb.Font = Enum.Font.GothamMedium
    kb.Text = kt
    kb.TextColor3 = Theme.TextSec
    kb.TextSize = 12
    kb.AutoButtonColor = false
    kb.Parent = fr
    Corner(kb, UDim.new(0, 5))
    local ks = Stroke(kb, Theme.Border, 1, 0.5)

    kb.MouseButton1Click:Connect(function()
        if listening then return end
        listening = true
        kb.Text = "..."
        Tw(ks, {Color = Theme.Accent, Transparency = 0.2}, 0.1)
        Tw(kb, {TextColor3 = Theme.Accent}, 0.1)
        local conn
        conn = UserInputService.InputBegan:Connect(function(inp, gp)
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                if inp.KeyCode == Enum.KeyCode.Escape then
                    curKey = Enum.KeyCode.Unknown
                    kb.Text = "None"
                else
                    curKey = inp.KeyCode
                    kb.Text = curKey.Name
                end
                Tw(ks, {Color = Theme.Border, Transparency = 0.5}, 0.1)
                Tw(kb, {TextColor3 = Theme.TextSec}, 0.1)
                listening = false
                conn:Disconnect()
                task.spawn(function() chg(curKey) end)
            end
        end)
    end)

    local hv = Instance.new("TextButton")
    hv.BackgroundTransparency = 1
    hv.Size = UDim2.new(1, 0, 1, 0)
    hv.Text = ""
    hv.AutoButtonColor = false
    hv.ZIndex = 1
    hv.Parent = fr

    hv.MouseEnter:Connect(function() Tw(fr, {BackgroundColor3 = Theme.ElemHov}, 0.1) end)
    hv.MouseLeave:Connect(function() Tw(fr, {BackgroundColor3 = Theme.Elem}, 0.1) end)

    local keyConn = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp or listening then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == curKey and curKey ~= Enum.KeyCode.Unknown then
            task.spawn(function() cb(curKey) end)
        end
    end)
    table.insert(_G.NolinConnections, keyConn)

    table.insert(self.Elems, fr)
    local o = {}
    function o:Set(k) curKey = k kb.Text = k == Enum.KeyCode.Unknown and "None" or k.Name task.spawn(function() chg(curKey) end) end
    function o:Get() return curKey end
    return o
end

-- ============================================================================
-- WINDOW
-- ============================================================================

local Win = {}
Win.__index = Win

function Win.new(cfg)
    local self = setmetatable({}, Win)
    self.Name = cfg.Name or "Nolin-UI"
    self.LoadText = cfg.LoadingText or "Загрузка..."
    self.LoadDur = cfg.LoadingDuration or 3
    self.Discord = cfg.DiscordInvite or "discord.gg/nolin"
    self.TogKey = cfg.KeybindToToggle or Enum.KeyCode.RightShift
    self.SX = cfg.SizeX or 560
    self.SY = cfg.SizeY or 400
    self.Tabs = {}
    self.CurTab = nil
    self.Vis = true
    self.Ready = false
    self._destroyed = false

    self:_Init()
    return self
end

function Win:_Init()
    self.Gui = Instance.new("ScreenGui")
    self.Gui.Name = "NolinUI_" .. tostring(math.random(100000, 999999))
    self.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.Gui.ResetOnSpawn = false
    self.Gui.DisplayOrder = 999
    SafeGui(self.Gui)

    _G.NolinUIInstance = self.Gui

    self.NF = Notifs.new(self.Gui)
    self:_MakeWin()
    self:_MakeLoad()

    -- Toggle keybind (используем замыкание на self)
    local winRef = self
    local tc = UserInputService.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.KeyCode == winRef.TogKey then
            winRef:_Tog()
        end
    end)
    table.insert(_G.NolinConnections, tc)

    self:_RunLoad()
end

function Win:_MakeLoad()
    self.LF = Instance.new("Frame")
    self.LF.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
    self.LF.Size = UDim2.new(0, self.SX, 0, self.SY)
    self.LF.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.LF.AnchorPoint = Vector2.new(0.5, 0.5)
    self.LF.BorderSizePixel = 0
    self.LF.ZIndex = 201
    self.LF.Parent = self.Gui
    Corner(self.LF, UDim.new(0, 12))
    local lfs = Stroke(self.LF, Theme.Accent, 1, 0.4)
    self._loadStroke = lfs

    local ctr = Instance.new("Frame")
    ctr.BackgroundTransparency = 1
    ctr.Size = UDim2.new(0, 280, 0, 180)
    ctr.Position = UDim2.new(0.5, 0, 0.5, 0)
    ctr.AnchorPoint = Vector2.new(0.5, 0.5)
    ctr.ZIndex = 202
    ctr.Parent = self.LF

    self._lt = Instance.new("TextLabel")
    self._lt.BackgroundTransparency = 1
    self._lt.Size = UDim2.new(1, 0, 0, 34)
    self._lt.Position = UDim2.new(0, 0, 0, 20)
    self._lt.Font = Enum.Font.GothamBold
    self._lt.Text = "NOLIN-UI"
    self._lt.TextColor3 = Theme.Accent
    self._lt.TextSize = 30
    self._lt.TextTransparency = 1
    self._lt.ZIndex = 202
    self._lt.Parent = ctr

    self._ls = Instance.new("TextLabel")
    self._ls.BackgroundTransparency = 1
    self._ls.Size = UDim2.new(1, 0, 0, 14)
    self._ls.Position = UDim2.new(0, 0, 0, 58)
    self._ls.Font = Enum.Font.Gotham
    self._ls.Text = "v1.0"
    self._ls.TextColor3 = Theme.TextMut
    self._ls.TextSize = 11
    self._ls.TextTransparency = 1
    self._ls.ZIndex = 202
    self._ls.Parent = ctr

    self._lx = Instance.new("TextLabel")
    self._lx.BackgroundTransparency = 1
    self._lx.Size = UDim2.new(1, 0, 0, 16)
    self._lx.Position = UDim2.new(0, 0, 0, 96)
    self._lx.Font = Enum.Font.GothamMedium
    self._lx.Text = self.LoadText
    self._lx.TextColor3 = Theme.TextSec
    self._lx.TextSize = 12
    self._lx.TextTransparency = 1
    self._lx.ZIndex = 202
    self._lx.Parent = ctr

    self._lbb = Instance.new("Frame")
    self._lbb.BackgroundColor3 = Theme.Track
    self._lbb.BackgroundTransparency = 1
    self._lbb.Size = UDim2.new(0.7, 0, 0, 4)
    self._lbb.Position = UDim2.new(0.15, 0, 0, 128)
    self._lbb.BorderSizePixel = 0
    self._lbb.ZIndex = 202
    self._lbb.Parent = ctr
    Corner(self._lbb, UDim.new(1, 0))

    self._lbf = Instance.new("Frame")
    self._lbf.BackgroundColor3 = Theme.Accent
    self._lbf.BackgroundTransparency = 1
    self._lbf.Size = UDim2.new(0, 0, 1, 0)
    self._lbf.BorderSizePixel = 0
    self._lbf.ZIndex = 203
    self._lbf.Parent = self._lbb
    Corner(self._lbf, UDim.new(1, 0))
end

function Win:_RunLoad()
    task.delay(0.15, function() Tw(self._lt, {TextTransparency = 0}, 0.5) end)
    task.delay(0.35, function() Tw(self._ls, {TextTransparency = 0}, 0.4) end)
    task.delay(0.55, function() Tw(self._lx, {TextTransparency = 0}, 0.4) end)
    task.delay(0.7, function()
        Tw(self._lbb, {BackgroundTransparency = 0}, 0.25)
        Tw(self._lbf, {BackgroundTransparency = 0}, 0.25)
        Tw(self._lbf, {Size = UDim2.new(1, 0, 1, 0)}, self.LoadDur - 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
    end)

    task.delay(self.LoadDur, function()
        if not self.LF or not self.LF.Parent then return end
        for _, desc in ipairs(self.LF:GetDescendants()) do
            pcall(function()
                if desc:IsA("TextLabel") then
                    Tw(desc, {TextTransparency = 1}, 0.3)
                elseif desc:IsA("Frame") then
                    Tw(desc, {BackgroundTransparency = 1}, 0.3)
                end
            end)
        end
        Tw(self.LF, {BackgroundTransparency = 1}, 0.4)
        if self._loadStroke then self._loadStroke.Transparency = 1 end

        task.delay(0.45, function()
            if self.LF and self.LF.Parent then self.LF:Destroy() end
            self:_Show()
        end)
    end)
end

function Win:_MakeWin()
    self.Main = Instance.new("Frame")
    self.Main.Name = "Main"
    self.Main.BackgroundColor3 = Theme.Bg
    self.Main.Size = UDim2.new(0, self.SX, 0, self.SY)
    self.Main.Position = UDim2.new(0.5, 0, 0.5, 0)
    self.Main.AnchorPoint = Vector2.new(0.5, 0.5)
    self.Main.Visible = false
    self.Main.BackgroundTransparency = 1
    self.Main.BorderSizePixel = 0
    self.Main.Parent = self.Gui
    Corner(self.Main, UDim.new(0, 12))
    Stroke(self.Main, Theme.Border, 1, 0.4)

    local tbH = 42

    self.TB = Instance.new("Frame")
    self.TB.BackgroundColor3 = Theme.Sidebar
    self.TB.Size = UDim2.new(1, 0, 0, tbH)
    self.TB.BorderSizePixel = 0
    self.TB.ZIndex = 10
    self.TB.Parent = self.Main
    Corner(self.TB, UDim.new(0, 12))

    local tbFill = Instance.new("Frame")
    tbFill.BackgroundColor3 = Theme.Sidebar
    tbFill.Size = UDim2.new(1, 0, 0, 14)
    tbFill.Position = UDim2.new(0, 0, 1, -14)
    tbFill.BorderSizePixel = 0
    tbFill.ZIndex = 9
    tbFill.Parent = self.TB

    local tbDv = Instance.new("Frame")
    tbDv.BackgroundColor3 = Theme.Div
    tbDv.BackgroundTransparency = 0.5
    tbDv.Size = UDim2.new(1, 0, 0, 1)
    tbDv.Position = UDim2.new(0, 0, 1, -1)
    tbDv.BorderSizePixel = 0
    tbDv.ZIndex = 11
    tbDv.Parent = self.TB

    local ld = Instance.new("Frame")
    ld.BackgroundColor3 = Theme.Accent
    ld.Size = UDim2.new(0, 9, 0, 9)
    ld.Position = UDim2.new(0, 13, 0.5, 0)
    ld.AnchorPoint = Vector2.new(0, 0.5)
    ld.ZIndex = 12
    ld.Parent = self.TB
    Corner(ld, UDim.new(1, 0))

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Size = UDim2.new(1, -120, 0, tbH)
    ttl.Position = UDim2.new(0, 28, 0, 0)
    ttl.Font = Enum.Font.GothamBold
    ttl.Text = self.Name
    ttl.TextColor3 = Theme.Text
    ttl.TextSize = 14
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 12
    ttl.Parent = self.TB

    local mnb = Instance.new("TextButton")
    mnb.BackgroundColor3 = Theme.Elem
    mnb.BackgroundTransparency = 0.5
    mnb.Size = UDim2.new(0, 26, 0, 26)
    mnb.Position = UDim2.new(1, -66, 0.5, 0)
    mnb.AnchorPoint = Vector2.new(0, 0.5)
    mnb.Font = Enum.Font.GothamBold
    mnb.Text = "-"
    mnb.TextColor3 = Theme.TextSec
    mnb.TextSize = 16
    mnb.AutoButtonColor = false
    mnb.ZIndex = 15
    mnb.Parent = self.TB
    Corner(mnb, UDim.new(0, 6))
    mnb.MouseEnter:Connect(function() Tw(mnb, {BackgroundTransparency = 0.2, TextColor3 = Theme.Text}, 0.1) end)
    mnb.MouseLeave:Connect(function() Tw(mnb, {BackgroundTransparency = 0.5, TextColor3 = Theme.TextSec}, 0.1) end)

    local winRef = self
    mnb.MouseButton1Click:Connect(function() winRef:_Tog() end)

    local clb = Instance.new("TextButton")
    clb.BackgroundColor3 = Theme.Err
    clb.BackgroundTransparency = 0.7
    clb.Size = UDim2.new(0, 26, 0, 26)
    clb.Position = UDim2.new(1, -34, 0.5, 0)
    clb.AnchorPoint = Vector2.new(0, 0.5)
    clb.Font = Enum.Font.GothamBold
    clb.Text = "X"
    clb.TextColor3 = Theme.TextSec
    clb.TextSize = 13
    clb.AutoButtonColor = false
    clb.ZIndex = 15
    clb.Parent = self.TB
    Corner(clb, UDim.new(0, 6))
    clb.MouseEnter:Connect(function() Tw(clb, {BackgroundTransparency = 0.2, TextColor3 = Color3.new(1, 1, 1)}, 0.1) end)
    clb.MouseLeave:Connect(function() Tw(clb, {BackgroundTransparency = 0.7, TextColor3 = Theme.TextSec}, 0.1) end)
    clb.MouseButton1Click:Connect(function() winRef:Destroy() end)

    self:_Drag()

    local body = Instance.new("Frame")
    body.BackgroundTransparency = 1
    body.Size = UDim2.new(1, 0, 1, -tbH)
    body.Position = UDim2.new(0, 0, 0, tbH)
    body.Parent = self.Main

    local sbW = 145

    local sb = Instance.new("Frame")
    sb.BackgroundColor3 = Theme.Sidebar
    sb.BackgroundTransparency = 0.1
    sb.Size = UDim2.new(0, sbW, 1, 0)
    sb.BorderSizePixel = 0
    sb.Parent = body

    local sbDv = Instance.new("Frame")
    sbDv.BackgroundColor3 = Theme.Div
    sbDv.BackgroundTransparency = 0.5
    sbDv.Size = UDim2.new(0, 1, 1, 0)
    sbDv.Position = UDim2.new(1, 0, 0, 0)
    sbDv.BorderSizePixel = 0
    sbDv.Parent = sb

    self.TabScroll = Instance.new("ScrollingFrame")
    self.TabScroll.BackgroundTransparency = 1
    self.TabScroll.Size = UDim2.new(1, 0, 1, -40)
    self.TabScroll.Position = UDim2.new(0, 0, 0, 4)
    self.TabScroll.ScrollBarThickness = 2
    self.TabScroll.ScrollBarImageColor3 = Theme.Accent
    self.TabScroll.ScrollBarImageTransparency = 0.7
    self.TabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    self.TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    self.TabScroll.BorderSizePixel = 0
    self.TabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
    self.TabScroll.Parent = sb
    Pad(self.TabScroll, 4, 4, 8, 8)
    List(self.TabScroll, Enum.FillDirection.Vertical, UDim.new(0, 4), Enum.HorizontalAlignment.Center)

    local sbBot = Instance.new("Frame")
    sbBot.BackgroundTransparency = 1
    sbBot.Size = UDim2.new(1, 0, 0, 32)
    sbBot.Position = UDim2.new(0, 0, 1, -32)
    sbBot.Parent = sb

    local sbBD = Instance.new("Frame")
    sbBD.BackgroundColor3 = Theme.Div
    sbBD.BackgroundTransparency = 0.5
    sbBD.Size = UDim2.new(1, -14, 0, 1)
    sbBD.Position = UDim2.new(0, 7, 0, 0)
    sbBD.BorderSizePixel = 0
    sbBD.Parent = sbBot

    local vLbl = Instance.new("TextLabel")
    vLbl.BackgroundTransparency = 1
    vLbl.Size = UDim2.new(1, -14, 0, 24)
    vLbl.Position = UDim2.new(0, 7, 0, 5)
    vLbl.Font = Enum.Font.Gotham
    vLbl.Text = "Nolin-UI v1.0"
    vLbl.TextColor3 = Theme.TextMut
    vLbl.TextSize = 9
    vLbl.TextXAlignment = Enum.TextXAlignment.Center
    vLbl.Parent = sbBot

    local ca = Instance.new("Frame")
    ca.BackgroundColor3 = Theme.Bg
    ca.BackgroundTransparency = 0.3
    ca.Size = UDim2.new(1, -sbW, 1, 0)
    ca.Position = UDim2.new(0, sbW, 0, 0)
    ca.BorderSizePixel = 0
    ca.ClipsDescendants = true
    ca.Parent = body

    local hdr = Instance.new("Frame")
    hdr.BackgroundTransparency = 1
    hdr.Size = UDim2.new(1, 0, 0, 34)
    hdr.Parent = ca

    self.HdrLbl = Instance.new("TextLabel")
    self.HdrLbl.BackgroundTransparency = 1
    self.HdrLbl.Size = UDim2.new(1, -24, 0, 34)
    self.HdrLbl.Position = UDim2.new(0, 12, 0, 0)
    self.HdrLbl.Font = Enum.Font.GothamBold
    self.HdrLbl.Text = ""
    self.HdrLbl.TextColor3 = Theme.Text
    self.HdrLbl.TextSize = 15
    self.HdrLbl.TextXAlignment = Enum.TextXAlignment.Left
    self.HdrLbl.Parent = hdr

    local hDv = Instance.new("Frame")
    hDv.BackgroundColor3 = Theme.Div
    hDv.BackgroundTransparency = 0.6
    hDv.Size = UDim2.new(1, -24, 0, 1)
    hDv.Position = UDim2.new(0, 12, 1, -1)
    hDv.BorderSizePixel = 0
    hDv.Parent = hdr

    self.Pages = Instance.new("Frame")
    self.Pages.BackgroundTransparency = 1
    self.Pages.Size = UDim2.new(1, 0, 1, -34)
    self.Pages.Position = UDim2.new(0, 0, 0, 34)
    self.Pages.ClipsDescendants = true
    self.Pages.Parent = ca
end

function Win:_Drag()
    local dragging = false
    local dragStart = nil
    local startPos = nil
    local dragInp = nil

    self.TB.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = self.Main.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    self.TB.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragInp = inp
        end
    end)

    local dc = UserInputService.InputChanged:Connect(function(inp)
        if inp == dragInp and dragging and startPos and dragStart then
            local delta = inp.Position - dragStart
            self.Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    table.insert(_G.NolinConnections, dc)
end

function Win:_Show()
    self.Main.Visible = true
    self.Ready = true
    self.Main.BackgroundTransparency = 1
    self.Main.Size = UDim2.new(0, self.SX * 0.93, 0, self.SY * 0.93)

    Tw(self.Main, {BackgroundTransparency = 0, Size = UDim2.new(0, self.SX, 0, self.SY)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    if #self.Tabs > 0 then
        self:_Switch(self.Tabs[1])
    end

    self.NF:Send({
        Title = self.Name,
        Content = "UI загружен! " .. self.TogKey.Name .. " - скрыть/показать.",
        Duration = 5,
        Type = "Success",
    })
end

function Win:_Switch(tab)
    if self.CurTab == tab then return end
    if self.CurTab then self.CurTab:_Off() end
    self.CurTab = tab
    tab:_On()
    self.HdrLbl.Text = tab.Name
end

function Win:_Tog()
    if not self.Ready or self._destroyed then return end
    self.Vis = not self.Vis
    if self.Vis then
        self.Main.Visible = true
        Tw(self.Main, {BackgroundTransparency = 0, Size = UDim2.new(0, self.SX, 0, self.SY)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    else
        Tw(self.Main, {BackgroundTransparency = 1, Size = UDim2.new(0, self.SX * 0.93, 0, self.SY * 0.93)}, 0.25, nil, nil, function()
            if self.Main and self._destroyed == false then self.Main.Visible = false end
        end)
    end
end

function Win:CreateTab(cfg)
    cfg.Order = #self.Tabs + 1
    local tab = Tab.new(cfg, self)
    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 and self.Ready then
        self:_Switch(tab)
    end
    return tab
end

function Win:Notify(cfg)
    self.NF:Send(cfg)
end

function Win:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    if self.Main and self.Main.Parent then
        Tw(self.Main, {BackgroundTransparency = 1, Size = UDim2.new(0, self.SX * 0.88, 0, self.SY * 0.88)}, 0.3)
    end

    task.delay(0.35, function()
        if _G.NolinConnections then
            for _, conn in pairs(_G.NolinConnections) do
                pcall(function() conn:Disconnect() end)
            end
            _G.NolinConnections = {}
        end
        _G.NolinUIInstance = nil
        if self.Gui then
            pcall(function() self.Gui:Destroy() end)
            self.Gui = nil
        end
    end)
end

-- ============================================================================
-- NOLIN-UI ГЛАВНАЯ ТАБЛИЦА
-- ============================================================================

local NolinUI = {}

function NolinUI:CreateWindow(cfg)
    cfg = cfg or {}
    local win = Win.new(cfg)

    if cfg.IncludeSettings ~= false then
        task.delay(0.05, function()
            local t = win:CreateTab({Name = "Настройки"})

            t:CreateSection({Name = "О программе"})
            t:CreateParagraph({
                Title = "Nolin-UI v1.0",
                Content = "Профессиональная UI-библиотека для Roblox.\nСовместимость: Xeno, Synapse, Fluxus, Delta.",
            })

            t:CreateSection({Name = "Управление"})
            t:CreateKeybind({
                Name = "Клавиша скрытия",
                Default = win.TogKey,
                ChangedCallback = function(k)
                    win.TogKey = k
                    win:Notify({Title = "Настройки", Content = "Клавиша: " .. k.Name, Duration = 3, Type = "Info"})
                end,
            })

            t:CreateSection({Name = "Ссылки"})
            t:CreateButton({
                Name = "Скопировать Discord",
                Description = cfg.DiscordInvite or "discord.gg/nolin",
                Callback = function()
                    local ok = pcall(function()
                        if setclipboard then setclipboard(cfg.DiscordInvite or "discord.gg/nolin")
                        elseif toclipboard then toclipboard(cfg.DiscordInvite or "discord.gg/nolin") end
                    end)
                    win:Notify({
                        Title = "Discord",
                        Content = ok and "Скопировано!" or "Не удалось скопировать",
                        Duration = 3,
                        Type = ok and "Success" or "Warning",
                    })
                end,
            })

            t:CreateSection({Name = "Выход"})
            t:CreateButton({
                Name = "Закрыть UI",
                Description = "Полностью удалить интерфейс",
                Callback = function()
                    win:Notify({Title = "Выход", Content = "UI закроется...", Duration = 1.5, Type = "Warning"})
                    task.delay(1.5, function() win:Destroy() end)
                end,
            })
        end)
    end

    return win
end

return NolinUI
