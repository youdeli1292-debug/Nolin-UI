local NolinUI = loadstring(game:HttpGet(https://raw.githubusercontent.com/youdeli1292-debug/Nolin-UI/refs/heads/main/NolinUI.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer

local Window = NolinUI:CreateWindow({
    Name = "Nolin-UI | Demo",
    LoadingText = "Инициализация модулей...",
    LoadingDuration = 2.5,
    DiscordInvite = "discord.gg/nolin-ui",
    KeybindToToggle = Enum.KeyCode.RightShift,
    SizeX = 580,
    SizeY = 420,
    IncludeSettings = true,
})

-- ========== ГЛАВНАЯ ==========
local Main = Window:CreateTab({Name = "Главная"})

Main:CreateParagraph({
    Title = "Добро пожаловать!",
    Content = "Nolin-UI v2.0 — полностью переработанная библиотека.",
})

Main:CreateSection({Name = "Тесты"})

Main:CreateButton({
    Name = "Тестовая кнопка",
    Description = "Простой callback",
    Callback = function()
        print("Кнопка нажата!")
        Window:Notify({Title = "OK", Content = "Работает!", Duration = 3, Type = "Success"})
    end,
})

Main:CreateButton({
    Name = "4 типа уведомлений",
    Callback = function()
        Window:Notify({Title = "Info", Content = "Информация", Duration = 3, Type = "Info"})
        task.wait(0.3)
        Window:Notify({Title = "Success", Content = "Успех", Duration = 3, Type = "Success"})
        task.wait(0.3)
        Window:Notify({Title = "Warning", Content = "Внимание", Duration = 3, Type = "Warning"})
        task.wait(0.3)
        Window:Notify({Title = "Error", Content = "Ошибка", Duration = 3, Type = "Error"})
    end,
})

-- ========== ИГРОК ==========
local Player = Window:CreateTab({Name = "Игрок"})

Player:CreateSection({Name = "Передвижение"})

Player:CreateSlider({
    Name = "Скорость",
    Description = "WalkSpeed персонажа",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Suffix = " s/s",
    Callback = function(v)
        pcall(function()
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = v end
            end
        end)
    end,
})

Player:CreateSlider({
    Name = "Прыжок",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 5,
    Callback = function(v)
        pcall(function()
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.UseJumpPower = true h.JumpPower = v end
            end
        end)
    end,
})

Player:CreateSlider({
    Name = "FOV",
    Min = 30,
    Max = 120,
    Default = 70,
    Suffix = "°",
    Callback = function(v)
        pcall(function() workspace.CurrentCamera.FieldOfView = v end)
    end,
})

Player:CreateSection({Name = "Читы"})

Player:CreateToggle({
    Name = "Бесконечный прыжок",
    Callback = function(s)
        if _G._InfJump then pcall(function() _G._InfJump:Disconnect() end) _G._InfJump = nil end
        if s then
            _G._InfJump = UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    local c = LP.Character
                    if c then
                        local h = c:FindFirstChildOfClass("Humanoid")
                        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end)
        end
    end,
})

Player:CreateToggle({
    Name = "Noclip",
    Callback = function(s)
        if _G._Noclip then pcall(function() _G._Noclip:Disconnect() end) _G._Noclip = nil end
        if s then
            _G._Noclip = RunService.Stepped:Connect(function()
                pcall(function()
                    local c = LP.Character
                    if c then
                        for _, p in ipairs(c:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end
                    end
                end)
            end)
        end
    end,
})

-- ========== ВИЗУАЛЫ ==========
local Vis = Window:CreateTab({Name = "Визуалы"})

Vis:CreateSection({Name = "Освещение"})

Vis:CreateToggle({
    Name = "Fullbright",
    Callback = function(s)
        pcall(function()
            if s then
                Lighting.Brightness = 2
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
            else
                Lighting.Brightness = 1
                Lighting.FogEnd = 10000
                Lighting.GlobalShadows = true
            end
        end)
    end,
})

Vis:CreateSlider({
    Name = "Время суток",
    Min = 0,
    Max = 24,
    Default = 14,
    Increment = 0.5,
    Suffix = " ч",
    Callback = function(v)
        pcall(function() Lighting.ClockTime = v end)
    end,
})

Vis:CreateSection({Name = "Опции"})

Vis:CreateDropdown({
    Name = "Тип ESP",
    Options = {"Box", "Chams", "Highlight", "Outline"},
    Default = "Box",
    Callback = function(v) print("ESP:", v) end,
})

Vis:CreateDropdown({
    Name = "Цели",
    Description = "Множественный выбор",
    Options = {"Enemies", "Teammates", "NPCs"},
    MultiSelect = true,
    Callback = function(s) print("Цели:", table.concat(s, ", ")) end,
})

-- ========== УТИЛИТЫ ==========
local Util = Window:CreateTab({Name = "Утилиты"})

Util:CreateSection({Name = "Инструменты"})

Util:CreateTextBox({
    Name = "Команда",
    PlaceholderText = "Введите...",
    Callback = function(t) print("Text:", t) end,
})

Util:CreateKeybind({
    Name = "Клавиша Fly",
    Default = Enum.KeyCode.F,
    Callback = function() Window:Notify({Title = "Fly", Content = "Нажато!", Duration = 2, Type = "Info"}) end,
})

Util:CreateButton({
    Name = "Респавн",
    Callback = function()
        pcall(function()
            local c = LP.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.Health = 0 end
            end
        end)
    end,
})

Util:CreateLabel({Name = "Nolin-UI v2.0 работает!"})

print("[Nolin-UI v2.0] Загружен!")
