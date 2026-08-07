--[[
    NOLIN-UI - Пример использования
    Загрузка через loadstring из GitHub
    
    Замени URL на свой (github raw ссылка на NolinUI.lua)
--]]

local NolinUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/ТВОЙ_ЮЗЕР/ТВОЙ_РЕПО/main/NolinUI.lua"))()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer

-- ============================================================================
-- СОЗДАНИЕ ОКНА
-- ============================================================================

local Window = NolinUI:CreateWindow({
    Name = "Nolin-UI | Демо-скрипт",
    LoadingText = "Инициализация модулей...",
    LoadingDuration = 3,
    DiscordInvite = "discord.gg/nolin-ui",
    KeybindToToggle = Enum.KeyCode.RightShift,
    SizeX = 560,
    SizeY = 400,
    IncludeSettings = true,
})

-- ============================================================================
-- ВКЛАДКА: ГЛАВНАЯ
-- ============================================================================

local MainTab = Window:CreateTab({Name = "Главная"})

MainTab:CreateParagraph({
    Title = "Добро пожаловать в Nolin-UI!",
    Content = "Это демонстрационный скрипт со всеми возможностями библиотеки. Используй вкладки слева для навигации.",
})

MainTab:CreateSection({Name = "Тестовые действия"})

MainTab:CreateButton({
    Name = "Простая кнопка",
    Description = "Выводит сообщение в консоль",
    Callback = function()
        print("[Nolin-UI] Кнопка нажата!")
        Window:Notify({
            Title = "Успех",
            Content = "Кнопка работает!",
            Duration = 3,
            Type = "Success",
        })
    end,
})

MainTab:CreateButton({
    Name = "Показать все уведомления",
    Description = "Демонстрация 4 типов уведомлений",
    Callback = function()
        Window:Notify({Title = "Info", Content = "Информация", Duration = 3, Type = "Info"})
        task.wait(0.4)
        Window:Notify({Title = "Success", Content = "Успех", Duration = 3, Type = "Success"})
        task.wait(0.4)
        Window:Notify({Title = "Warning", Content = "Предупреждение", Duration = 3, Type = "Warning"})
        task.wait(0.4)
        Window:Notify({Title = "Error", Content = "Ошибка", Duration = 3, Type = "Error"})
    end,
})

-- ============================================================================
-- ВКЛАДКА: ИГРОК
-- ============================================================================

local PlayerTab = Window:CreateTab({Name = "Игрок"})

PlayerTab:CreateSection({Name = "Передвижение"})

PlayerTab:CreateSlider({
    Name = "Скорость ходьбы",
    Description = "Изменяет WalkSpeed персонажа",
    Min = 16,
    Max = 500,
    Default = 16,
    Increment = 1,
    Suffix = " s/s",
    Callback = function(v)
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.WalkSpeed = v end
            end
        end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Сила прыжка",
    Description = "Изменяет JumpPower персонажа",
    Min = 50,
    Max = 500,
    Default = 50,
    Increment = 5,
    Callback = function(v)
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then
                    h.UseJumpPower = true
                    h.JumpPower = v
                end
            end
        end)
    end,
})

PlayerTab:CreateSlider({
    Name = "Поле зрения",
    Description = "FOV камеры",
    Min = 30,
    Max = 120,
    Default = 70,
    Suffix = " deg",
    Callback = function(v)
        pcall(function() workspace.CurrentCamera.FieldOfView = v end)
    end,
})

PlayerTab:CreateSection({Name = "Читы"})

PlayerTab:CreateToggle({
    Name = "Бесконечный прыжок",
    Description = "Прыгать в воздухе",
    Default = false,
    Callback = function(state)
        if _G._NolinInfJump then
            pcall(function() _G._NolinInfJump:Disconnect() end)
            _G._NolinInfJump = nil
        end
        if state then
            _G._NolinInfJump = UserInputService.JumpRequest:Connect(function()
                pcall(function()
                    local c = LocalPlayer.Character
                    if c then
                        local h = c:FindFirstChildOfClass("Humanoid")
                        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
                    end
                end)
            end)
            table.insert(_G.NolinConnections, _G._NolinInfJump)
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "Noclip",
    Description = "Проходить сквозь стены",
    Default = false,
    Callback = function(state)
        if _G._NolinNoclip then
            pcall(function() _G._NolinNoclip:Disconnect() end)
            _G._NolinNoclip = nil
        end
        if state then
            _G._NolinNoclip = RunService.Stepped:Connect(function()
                pcall(function()
                    local c = LocalPlayer.Character
                    if c then
                        for _, p in ipairs(c:GetDescendants()) do
                            if p:IsA("BasePart") then p.CanCollide = false end
                        end
                    end
                end)
            end)
            table.insert(_G.NolinConnections, _G._NolinNoclip)
        end
    end,
})

-- ============================================================================
-- ВКЛАДКА: ВИЗУАЛЫ
-- ============================================================================

local VisualTab = Window:CreateTab({Name = "Визуалы"})

VisualTab:CreateSection({Name = "Освещение"})

VisualTab:CreateToggle({
    Name = "Fullbright",
    Description = "Максимальная яркость",
    Default = false,
    Callback = function(state)
        pcall(function()
            if state then
                Lighting.Brightness = 2
                Lighting.FogEnd = 100000
                Lighting.GlobalShadows = false
                Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            else
                Lighting.Brightness = 1
                Lighting.FogEnd = 10000
                Lighting.GlobalShadows = true
                Lighting.Ambient = Color3.fromRGB(0, 0, 0)
            end
        end)
    end,
})

VisualTab:CreateSlider({
    Name = "Время суток",
    Description = "0 = ночь, 12 = полдень, 24 = ночь",
    Min = 0,
    Max = 24,
    Default = 14,
    Increment = 0.5,
    Suffix = " ч",
    Callback = function(v)
        pcall(function() Lighting.ClockTime = v end)
    end,
})

VisualTab:CreateSection({Name = "ESP"})

VisualTab:CreateDropdown({
    Name = "Тип ESP",
    Description = "Стиль отображения игроков",
    Options = {"Box", "Corner Box", "Chams", "Highlight"},
    Default = "Box",
    Callback = function(v)
        print("[Nolin-UI] ESP тип:", v)
    end,
})

VisualTab:CreateDropdown({
    Name = "Цели ESP",
    Description = "Множественный выбор",
    Options = {"Враги", "Союзники", "NPC", "Все"},
    MultiSelect = true,
    Callback = function(selected)
        print("[Nolin-UI] Цели:", table.concat(selected, ", "))
    end,
})

-- ============================================================================
-- ВКЛАДКА: УТИЛИТЫ
-- ============================================================================

local UtilTab = Window:CreateTab({Name = "Утилиты"})

UtilTab:CreateSection({Name = "Инструменты"})

UtilTab:CreateTextBox({
    Name = "Команда",
    PlaceholderText = "Введите текст...",
    ClearOnFocus = true,
    Callback = function(text)
        print("[Nolin-UI] Команда:", text)
        Window:Notify({Title = "Команда", Content = "Получено: " .. text, Duration = 3, Type = "Info"})
    end,
})

UtilTab:CreateKeybind({
    Name = "Клавиша полёта",
    Default = Enum.KeyCode.F,
    Callback = function()
        Window:Notify({Title = "Fly", Content = "Клавиша нажата!", Duration = 2, Type = "Info"})
    end,
    ChangedCallback = function(k)
        print("[Nolin-UI] Fly привязан к:", k.Name)
    end,
})

UtilTab:CreateSection({Name = "Действия"})

UtilTab:CreateButton({
    Name = "Телепорт к SpawnLocation",
    Callback = function()
        pcall(function()
            local sp = workspace:FindFirstChild("SpawnLocation")
            if sp then
                local c = LocalPlayer.Character
                if c then
                    local r = c:FindFirstChild("HumanoidRootPart")
                    if r then
                        r.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
                        Window:Notify({Title = "Телепорт", Content = "Готово!", Duration = 2, Type = "Success"})
                    end
                end
            else
                Window:Notify({Title = "Ошибка", Content = "SpawnLocation не найден", Duration = 3, Type = "Error"})
            end
        end)
    end,
})

UtilTab:CreateButton({
    Name = "Респавн персонажа",
    Description = "Убивает персонажа",
    Callback = function()
        pcall(function()
            local c = LocalPlayer.Character
            if c then
                local h = c:FindFirstChildOfClass("Humanoid")
                if h then h.Health = 0 end
            end
        end)
    end,
})

UtilTab:CreateLabel({Name = "Готово! Nolin-UI загружен."})

print("[Nolin-UI] Скрипт готов! Нажмите RightShift для скрытия.")
