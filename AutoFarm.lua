--[[
    💎 SkyWars Season 3 - Auto Gems UI Premium
    Compatível com: Delta Executor (Android / iOS / PC)
--]]

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- REMOTES
-- ============================================================
local RemotesFolder = ReplicatedStorage:WaitForChild("SkyWarsS3_Remotes", 30)
if not RemotesFolder then
    warn("[SkyWars S3] Servidor não inicializou. Verifique ServerScriptService.")
    return
end

local RF_GetGems   = RemotesFolder:WaitForChild("GetGems")
local RE_ToggleGem = RemotesFolder:WaitForChild("ToggleAutoGems")

-- ============================================================
-- ESTADO
-- ============================================================
local State = {
    AutoGems = false,
    Gems     = 0,
}

-- ============================================================
-- HELPERS (compatível com Delta)
-- ============================================================
local function getHiddenUI()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if syn and syn.protect_gui then
        -- Delta suporta syn.protect_gui
        return CoreGui
    end
    return CoreGui
end

local function readGems()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then
        local g = ls:FindFirstChild("Gems")
        if g then
            State.Gems = g.Value
            return
        end
    end
    -- fallback: pergunta ao servidor
    local ok, val = pcall(function() return RF_GetGems:InvokeServer() end)
    if ok and type(val) == "number" then
        State.Gems = val
    end
end

-- ============================================================
-- UI
-- ============================================================
local function createUI()
    local parent = getHiddenUI()
    local existing = parent:FindFirstChild("SkyWarsS3_AutoGemsUI")
    if existing then existing:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "SkyWarsS3_AutoGemsUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999
    gui.Parent = parent

    -- Proteção (Delta/syn)
    if syn and syn.protect_gui then
        pcall(function() syn.protect_gui(gui) end)
    end

    -- ============ JANELA ============
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 320, 0, 260)
    main.Position = UDim2.new(0.5, -160, 0.5, -130)
    main.BackgroundColor3 = Color3.fromRGB(16, 14, 28)
    main.BackgroundTransparency = 0.05
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = gui

    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 20)

    local stroke = Instance.new("UIStroke", main)
    stroke.Color = Color3.fromRGB(150, 100, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3

    local bgGrad = Instance.new("UIGradient", main)
    bgGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(34, 26, 62)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 10, 24)),
    }
    bgGrad.Rotation = 135

    -- Brilho decorativo no topo
    local glow = Instance.new("Frame", main)
    glow.Size = UDim2.new(1, -40, 0, 2)
    glow.Position = UDim2.new(0, 20, 0, 0)
    glow.BackgroundColor3 = Color3.fromRGB(180, 130, 255)
    glow.BorderSizePixel = 0
    glow.ZIndex = 2
    local glowGrad = Instance.new("UIGradient", glow)
    glowGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    }

    -- ============ TOP BAR ============
    local topBar = Instance.new("Frame", main)
    topBar.Size = UDim2.new(1, 0, 0, 46)
    topBar.BackgroundTransparency = 1

    local title = Instance.new("TextLabel", topBar)
    title.Text = "💎  SkyWars S3 • Auto Gems"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(235, 225, 255)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, -100, 1, 0)
    title.Position = UDim2.new(0, 16, 0, 0)
    title.TextXAlignment = Enum.TextXAlignment.Left

    local function makeTopBtn(text, normal, hover, xOff)
        local b = Instance.new("TextButton", topBar)
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 15
        b.TextColor3 = Color3.fromRGB(220, 210, 240)
        b.BackgroundColor3 = normal
        b.BorderSizePixel = 0
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, xOff, 0, 9)
        b.AutoButtonColor = false
        Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
        b.MouseEnter:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play()
        end)
        b.MouseLeave:Connect(function()
            TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = normal}):Play()
        end)
        return b
    end

    local minBtn   = makeTopBtn("–", Color3.fromRGB(45, 40, 70), Color3.fromRGB(75, 65, 115), -66)
    local closeBtn = makeTopBtn("✕", Color3.fromRGB(70, 30, 40), Color3.fromRGB(125, 45, 60), -34)

    -- ============ PAINEL DE GEMAS ============
    local gemPanel = Instance.new("Frame", main)
    gemPanel.Size = UDim2.new(1, -32, 0, 72)
    gemPanel.Position = UDim2.new(0, 16, 0, 54)
    gemPanel.BackgroundColor3 = Color3.fromRGB(26, 22, 46)
    gemPanel.BackgroundTransparency = 0.15
    gemPanel.BorderSizePixel = 0
    Instance.new("UICorner", gemPanel).CornerRadius = UDim.new(0, 14)

    local gemIcon = Instance.new("TextLabel", gemPanel)
    gemIcon.Text = "💎"
    gemIcon.Font = Enum.Font.GothamBold
    gemIcon.TextSize = 30
    gemIcon.TextColor3 = Color3.fromRGB(130, 210, 255)
    gemIcon.BackgroundTransparency = 1
    gemIcon.Size = UDim2.new(0, 50, 1, 0)
    gemIcon.Position = UDim2.new(0, 12, 0, 0)

    local gemCount = Instance.new("TextLabel", gemPanel)
    gemCount.Text = "0"
    gemCount.Font = Enum.Font.GothamBold
    gemCount.TextSize = 26
    gemCount.TextColor3 = Color3.fromRGB(180, 220, 255)
    gemCount.BackgroundTransparency = 1
    gemCount.Size = UDim2.new(1, -70, 0.6, 0)
    gemCount.Position = UDim2.new(0, 66, 0, 8)
    gemCount.TextXAlignment = Enum.TextXAlignment.Left

    local gemStatus = Instance.new("TextLabel", gemPanel)
    gemStatus.Text = "● Inativo"
    gemStatus.Font = Enum.Font.GothamMedium
    gemStatus.TextSize = 12
    gemStatus.TextColor3 = Color3.fromRGB(150, 140, 180)
    gemStatus.BackgroundTransparency = 1
    gemStatus.Size = UDim2.new(1, -70, 0.4, 0)
    gemStatus.Position = UDim2.new(0, 66, 0.6, 0)
    gemStatus.TextXAlignment = Enum.TextXAlignment.Left

    -- ============ BOTÃO PRINCIPAL ============
    local mainBtn = Instance.new("TextButton", main)
    mainBtn.Text = "💎  Auto Gems  •  OFF"
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.TextSize = 16
    mainBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    mainBtn.BackgroundColor3 = Color3.fromRGB(115, 70, 240)
    mainBtn.BorderSizePixel = 0
    mainBtn.Size = UDim2.new(1, -32, 0, 62)
    mainBtn.Position = UDim2.new(0, 16, 0, 138)
    mainBtn.AutoButtonColor = false
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(0, 14)

    local btnGrad = Instance.new("UIGradient", mainBtn)
    btnGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 210)),
    }
    btnGrad.Rotation = 90

    local btnStroke = Instance.new("UIStroke", mainBtn)
    btnStroke.Color = Color3.fromRGB(200, 170, 255)
    btnStroke.Thickness = 1
    btnStroke.Transparency = 0.5

    -- Partículas de brilho (decorativo quando ativo)
    local shine = Instance.new("Frame", mainBtn)
    shine.Size = UDim2.new(0, 40, 1, 0)
    shine.Position = UDim2.new(0, -50, 0, 0)
    shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shine.BackgroundTransparency = 0.7
    shine.BorderSizePixel = 0
    shine.ZIndex = 2
    local shineGrad = Instance.new("UIGradient", shine)
    shineGrad.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    }

    -- ============ FOOTER ============
    local footer = Instance.new("TextLabel", main)
    footer.Text = "Arraste pela barra superior"
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.TextColor3 = Color3.fromRGB(140, 130, 170)
    footer.BackgroundTransparency = 1
    footer.Size = UDim2.new(1, -32, 0, 18)
    footer.Position = UDim2.new(0, 16, 1, -24)
    footer.TextXAlignment = Enum.TextXAlignment.Center

    -- ========================================================
    -- ANIMAÇÃO DE BRILHO no botão quando ativo
    -- ========================================================
    local shineConn
    local function startShine()
        if shineConn then shineConn:Disconnect() end
        shineConn = RunService.RenderStepped:Connect(function(dt)
            local pos = shine.Position.X.Offset + dt * 500
            if pos > mainBtn.AbsoluteSize.X + 50 then pos = -50 end
            shine.Position = UDim2.new(0, pos, 0, 0)
        end)
    end
    local function stopShine()
        if shineConn then shineConn:Disconnect(); shineConn = nil end
        shine.Position = UDim2.new(0, -50, 0, 0)
    end

    -- ========================================================
    -- ESTADO VISUAL
    -- ========================================================
    local function setUIState(active)
        if active then
            mainBtn.Text = "⏹  Auto Gems  •  ON"
            TweenService:Create(mainBtn, TweenInfo.new(0.25), {
                BackgroundColor3 = Color3.fromRGB(40, 200, 120)
            }):Play()
            TweenService:Create(btnGrad, TweenInfo.new(0.25), {Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 240, 160)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 170, 110)),
            }}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.25), {
                Color = Color3.fromRGB(180, 255, 210)
            }):Play()
            gemStatus.Text = "● Farm ativo"
            gemStatus.TextColor3 = Color3.fromRGB(120, 255, 170)
            gemIcon.TextColor3 = Color3.fromRGB(120, 255, 200)
            startShine()
        else
            mainBtn.Text = "💎  Auto Gems  •  OFF"
            TweenService:Create(mainBtn, TweenInfo.new(0.25), {
                BackgroundColor3 = Color3.fromRGB(115, 70, 240)
            }):Play()
            TweenService:Create(btnGrad, TweenInfo.new(0.25), {Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 90, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 50, 210)),
            }}):Play()
            TweenService:Create(btnStroke, TweenInfo.new(0.25), {
                Color = Color3.fromRGB(200, 170, 255)
            }):Play()
            gemStatus.Text = "● Inativo"
            gemStatus.TextColor3 = Color3.fromRGB(150, 140, 180)
            gemIcon.TextColor3 = Color3.fromRGB(130, 210, 255)
            stopShine()
        end
    end

    -- ========================================================
    -- AÇÃO DO BOTÃO
    -- ========================================================
    mainBtn.MouseButton1Click:Connect(function()
        State.AutoGems = not State.AutoGems

        -- animação de clique
        TweenService:Create(mainBtn, TweenInfo.new(0.08), {
            Size = UDim2.new(1, -40, 0, 58)
        }):Play()
        task.wait(0.09)
        TweenService:Create(mainBtn, TweenInfo.new(0.12), {
            Size = UDim2.new(1, -32, 0, 62)
        }):Play()

        RE_ToggleGem:FireServer(State.AutoGems)
        setUIState(State.AutoGems)
    end)

    -- Hover
    mainBtn.MouseEnter:Connect(function()
        if not State.AutoGems then
            TweenService:Create(mainBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(140, 90, 255)
            }):Play()
        end
    end)
    mainBtn.MouseLeave:Connect(function()
        if not State.AutoGems then
            TweenService:Create(mainBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(115, 70, 240)
            }):Play()
        end
    end)

    -- ========================================================
    -- MINIMIZAR
    -- ========================================================
    local minimized = false
    local originalSize = main.Size

    minBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            originalSize = main.Size
            TweenService:Create(main, TweenInfo.new(0.25), {Size = UDim2.new(0, 320, 0, 46)}):Play()
            gemPanel.Visible = false; mainBtn.Visible = false; footer.Visible = false
            minBtn.Text = "+"
        else
            TweenService:Create(main, TweenInfo.new(0.25), {Size = originalSize}):Play()
            task.delay(0.15, function()
                gemPanel.Visible = true; mainBtn.Visible = true; footer.Visible = true
            end)
            minBtn.Text = "–"
        end
    end)

    -- ========================================================
    -- FECHAR
    -- ========================================================
    closeBtn.MouseButton1Click:Connect(function()
        if State.AutoGems then
            State.AutoGems = false
            RE_ToggleGem:FireServer(false)
        end
        stopShine()
        TweenService:Create(main, TweenInfo.new(0.2), {
            Size = UDim2.new(0, 0, 0, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.22)
        gui:Destroy()
    end)

    -- ========================================================
    -- ARRASTO (mouse + toque — funciona no Delta mobile)
    -- ========================================================
    local dragging, dragStart, startPos

    local function beginDrag(input)
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end)

    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            updateDrag(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    -- ========================================================
    -- ATUALIZAÇÃO EM TEMPO REAL DO CONTADOR
    -- ========================================================
    local lastGems = -1
    task.spawn(function()
        while gui.Parent do
            readGems()
            if State.Gems ~= lastGems then
                lastGems = State.Gems
                gemCount.Text = tostring(State.Gems)

                -- pulso visual
                TweenService:Create(gemCount, TweenInfo.new(0.1), {
                    TextColor3 = Color3.fromRGB(255, 240, 160)
                }):Play()
                task.delay(0.15, function()
                    TweenService:Create(gemCount, TweenInfo.new(0.2), {
                        TextColor3 = Color3.fromRGB(180, 220, 255)
                    }):Play()
                end)
            end
            task.wait(0.2)
        end
    end)

    return gui
end

createUI()
print("[💎 SkyWars S3] UI Auto Gems carregada (Delta).")
