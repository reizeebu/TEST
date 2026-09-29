-- ====================================================================
-- RAYFIELD TEST HUB - DEADLY DELIVERY (versão corrigida)
-- ====================================================================

local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok or not Rayfield then
    warn("Falha ao carregar o Rayfield: " .. tostring(Rayfield))
    return
end

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Jogador local
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Estado
local tpWalkSpeed = 5
local tpWalkEnabled = false
local tpConnection = nil
local espEnabled = false
local espConnection = nil
local godConnection = nil

player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- ====================================================================
-- FUNÇÕES
-- ====================================================================

local function getAbsoluteElevator()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and (v.Name == "ElevatorFloor" or v.Name == "LiftFloor" or v.Name == "SpawnPlatform") then
            return v
        end
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():match("elevator") or v.Name:lower():match("lift")) then
            local mainPart = v:FindFirstChild("Floor") or v:FindFirstChild("Main") or v:FindFirstChildOfClass("BasePart")
            if mainPart then return mainPart end
        end
    end
    return nil
end

local function applyESP(model)
    if model:FindFirstChild("MonsterESP") then return end
    local lname = model.Name:lower()
    if lname:match("package") or lname:match("letter") or lname:match("egg") then return end

    local part = model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    -- Highlight envolve o modelo inteiro e aparece através das paredes
    local hl = Instance.new("Highlight")
    hl.Name = "MonsterESP"
    hl.Adornee = model
    hl.FillColor = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency = 0.6
    hl.OutlineColor = Color3.fromRGB(255, 0, 0)
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = model

    -- BillboardGui PRECISA de Adornee (uma BasePart) para aparecer
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MonsterTag"
    billboard.Adornee = part
    billboard.Size = UDim2.new(0, 120, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "MONSTRO!"
    label.TextColor3 = Color3.fromRGB(255, 65, 65)
    label.TextSize = 14
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    task.spawn(function()
        while espEnabled and model.Parent and part.Parent do
            if rootPart then
                local dist = math.floor((rootPart.Position - part.Position).Magnitude)
                label.Text = "MONSTRO [" .. dist .. "m]"
            end
            task.wait(0.2)
        end
    end)
end

local function startMonsterESP()
    if espConnection then espConnection:Disconnect() end

    local function checkAndApply(v)
        if not espEnabled then return end
        if v:IsA("Model") and v ~= character and not Players:GetPlayerFromCharacter(v) then
            local lname = v.Name:lower()
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum or lname:match("monster") or lname:match("bot") or lname:match("killer") or lname:match("crocodile") then
                applyESP(v)
            end
        end
    end

    for _, v in pairs(workspace:GetDescendants()) do checkAndApply(v) end
    espConnection = workspace.DescendantAdded:Connect(function(v)
        task.delay(0.5, checkAndApply, v)
    end)
end

local function stopMonsterESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "MonsterESP" or v.Name == "MonsterTag" then
            v:Destroy()
        end
    end
end

local function startTpWalk()
    if tpConnection then tpConnection:Disconnect() end
    tpConnection = RunService.Heartbeat:Connect(function()
        if tpWalkEnabled and character and rootPart and humanoid and tpWalkSpeed > 0 then
            if humanoid.MoveDirection.Magnitude > 0 then
                rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (tpWalkSpeed / 10))
            end
        end
    end)
end

-- ====================================================================
-- INTERFACE (RAYFIELD)
-- ====================================================================

local Window = Rayfield:CreateWindow({
    Name = "Hub de Testes - Deadly Delivery",
    LoadingTitle = "Carregando Módulos de Teste...",
    LoadingSubtitle = "Rayfield UI",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ------------------------- ABA: JOGADOR -------------------------
local PlayerTab = Window:CreateTab("Jogador", 4483362458)

PlayerTab:CreateSection("Movimentação do Personagem")

PlayerTab:CreateToggle({
    Name = "Ativar TPWalk",
    CurrentValue = false,
    Flag = "TPWalkToggle",
    Callback = function(Value)
        tpWalkEnabled = Value
        if Value then
            startTpWalk()
        elseif tpConnection then
            tpConnection:Disconnect()
            tpConnection = nil
        end
    end,
})

PlayerTab:CreateSlider({
    Name = "Velocidade TPWalk",
    Range = {0, 15},
    Increment = 1,
    Suffix = " Nível",
    CurrentValue = 5,
    Flag = "TPWalkSpeedSlider",
    Callback = function(Value)
        tpWalkSpeed = Value
    end,
})

PlayerTab:CreateSection("Atributos & Imortalidade")

PlayerTab:CreateToggle({
    Name = "Modo Deus (Hardcore / Invencibilidade)",
    CurrentValue = false,
    Flag = "GodModeToggle",
    Callback = function(Value)
        if godConnection then
            godConnection:Disconnect()
            godConnection = nil
        end
        if Value then
            godConnection = RunService.Heartbeat:Connect(function()
                pcall(function()
                    if character then
                        character:SetAttribute("Health", 100)
                        player:SetAttribute("Health", 100)

                        local hv = character:FindFirstChild("Health")
                        if hv and hv:IsA("NumberValue") then
                            hv.Value = 100
                        end

                        for _, part in pairs(character:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanTouch = false
                            end
                        end
                    end
                end)
            end)
        end
    end,
})

-- ------------------------- ABA: MONSTROS -------------------------
local MonsterTab = Window:CreateTab("Monstros", 4483362458)

MonsterTab:CreateSection("Detecção e Visão (ESP)")

MonsterTab:CreateToggle({
    Name = "ESP de Monstros (Destaque Vermelho & Distância)",
    CurrentValue = false,
    Flag = "MonsterESPToggle",
    Callback = function(Value)
        espEnabled = Value
        if Value then
            startMonsterESP()
        else
            stopMonsterESP()
        end
    end,
})

-- ------------------------- ABA: TELEPORTE / LOOT -------------------------
local TeleportTab = Window:CreateTab("Teleporte / Loot", 4483362458)

TeleportTab:CreateSection("Localização e Fuga")

TeleportTab:CreateButton({
    Name = "Teleportar para o Elevador / Plataforma",
    Callback = function()
        if not rootPart then return end
        local realLift = getAbsoluteElevator()
        if realLift then
            rootPart.CFrame = realLift.CFrame + Vector3.new(0, 3, 0)
            Rayfield:Notify({
                Title = "Sucesso!",
                Content = "Teleportado para o elevador.",
                Duration = 3,
                Image = 4483362458,
            })
        else
            Rayfield:Notify({
                Title = "Aviso",
                Content = "Elevador não encontrado no mapa atual.",
                Duration = 3,
                Image = 4483362458,
            })
        end
    end,
})