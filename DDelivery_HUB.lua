-- Carregar o script no executador
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/reizeebu/TEST/refs/heads/main/DDelivery_HUB.lua"))()

local scriptSource = [[

-- ====================================================================
-- SERVIÇOS E VARIÁVEIS INICIAIS
-- ====================================================================
local Players = game:GetService("Players") -- Serviço para gerenciar jogadores [1]
local TextChatService = game:GetService("TextChatService") -- Serviço do chat de texto [1]
local RunService = game:GetService("RunService") -- Serviço de execução contínua por quadros [1]

local player = Players.LocalPlayer -- Referência ao jogador local [1]
local character = player.Character or player.CharacterAdded:Wait() -- Personagem do jogador [1]
local humanoid = character:WaitForChild("Humanoid") -- Humanoid (saúde e movimento) [1]
local rootPart = character:WaitForChild("HumanoidRootPart") -- Parte central física [1]

local tpWalkSpeed = 0 -- Armazena o valor da velocidade do TPWalk [1]
local tpConnection = nil -- Conexão do evento de velocidade [1]
local espConnection = nil -- Conexão do evento de varredura do ESP [1]
local godConnection = nil -- Conexão do evento do Modo Deus [1]

-- Atualiza as referências quando o jogador renascer (respawn) [1]
player.CharacterAdded:Connect(function(newCharacter) [1]
    character = newCharacter [12]
    humanoid = newCharacter:WaitForChild("Humanoid") [12]
    rootPart = newCharacter:WaitForChild("HumanoidRootPart") [12]
end) [12]

-- ====================================================================
-- FUNÇÃO: LOCALIZAR O ELEVADOR NO MAPA
-- ====================================================================
local function getAbsoluteElevator() [12]
    -- Varre o workspace procurando por nomes específicos da base do elevador [12]
    for _, v in pairs(workspace:GetDescendants()) do [12]
        if v:IsA("BasePart") and (v.Name == "ElevatorFloor" or v.Name == "LiftFloor" or v.Name == "SpawnPlatform") then [12]
            return v [12]
        end [13]
    end [13]

    -- Se não achar por nome exato, procura modelos contendo "elevator" ou "lift" [13]
    for _, v in pairs(workspace:GetDescendants()) do [13]
        if v:IsA("Model") and (v.Name:lower():match("elevator") or v.Name:lower():match("lift")) then [13]
            local mainPart = v:FindFirstChild("Floor") or v:FindFirstChild("Main") or v:FindFirstChildOfClass("BasePart") [13]
            if mainPart then return mainPart end [13]
        end [13]
    end [13]

    return nil [13]
end [13]

-- ====================================================================
-- FUNÇÃO: APLICAR HIGHLIGHT E TEXTO NO MONSTRO (ESP)
-- ====================================================================
local function applyESP(model) [13]
    if model:FindFirstChild("MonsterESP") then return end -- Evita duplicar ESP [13]
    -- Ignora pacotes, cartas ou ovos [8]
    if model.Name:lower():match("package") or model.Name:lower():match("letter") or model.Name:lower():match("egg") then return end [8]

    -- Cria caixa delimitadora vermelha em volta do monstro [8]
    local box = Instance.new("BoxHandleAdornment") [8]
    box.Name = "MonsterESP" [8]
    box.Size = model:GetExtentsSize() + Vector3.new(0.5, 0.5, 0.5) [8]
    box.Color3 = Color3.fromRGB(255, 0, 0) -- Cor Vermelha [8]
    box.AlwaysOnTop = true -- Visível através das paredes [8]
    box.ZIndex = 5 [8]
    box.Adornee = model:FindFirstChildOfClass("BasePart") or model [8]
    box.Transparency = 0.4 [8]
    box.Parent = model [8]

    -- Cria o rótulo de texto flutuante [8, 9]
    local billboard = Instance.new("BillboardGui") [8]
    billboard.Name = "MonsterTag" [8]
    billboard.Size = UDim2.new(0, 100, 0, 30) [9]
    billboard.AlwaysOnTop = true [9]
    billboard.ExtentsOffset = Vector3.new(0, 3, 0) [9]
    billboard.Parent = model [9]

    local label = Instance.new("TextLabel") [9]
    label.Size = UDim2.new(1, 0, 1, 0) [9]
    label.BackgroundTransparency = 1 [9]
    label.Text = "MONSTRO!" [9]
    label.TextColor3 = Color3.fromRGB(255, 65, 65) [9]
    label.TextSize = 12 [9]
    label.Font = Enum.Font.SourceSansBold [9]
    label.Parent = billboard [9]

    -- Loop em segundo plano para atualizar a distância até o monstro [9]
    task.spawn(function() [9]
        while model.Parent and rootPart do [9]
            local part = model:FindFirstChildOfClass("BasePart") [10]
            if part then [10]
                local dist = math.floor((rootPart.Position - part.Position).Magnitude) [10]
                label.Text = "MONSTRO [" .. dist .. "m]" [10]
            end [10]
            task.wait(0.2) [10]
        end [10]
    end) [10]
end [10]

-- ====================================================================
-- FUNÇÃO: MONITORAR E INICIAR ESP DE MONSTROS
-- ====================================================================
local function startMonsterESP() [10]
    if espConnection then espConnection:Disconnect() end [10]

    local function checkAndApply(v) [10]
        if v:IsA("Model") and v ~= character and not Players:GetPlayerFromCharacter(v) then [10]
            local hum = v:FindFirstChildOfClass("Humanoid") [10]
            -- Identifica entidades hostis pelo nome ou presença de Humanoid [10]
            if hum or v.Name:lower():match("monster") or v.Name:lower():match("bot") or v.Name:lower():match("killer") or v.Name:lower():match("crocodile") then [10]
                applyESP(v) [2]
            end [2, 10]
        end [10]
    end [10]

    -- Aplica ESP nos monstros já carregados no workspace [2]
    for _, v in pairs(workspace:GetDescendants()) do checkAndApply(v) end [2]

    -- Monitora novos monstros que forem adicionados ao longo do jogo [2]
    espConnection = workspace.DescendantAdded:Connect(function(v) task.wait(0.5) checkAndApply(v) end) [2]
end [2]

-- ====================================================================
-- CONSTRUÇÃO DA INTERFACE GRÁFICA (GUI)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui") [2]
ScreenGui.Name = "DeadlyDeliveryFinalFix" [2]
ScreenGui.ResetOnSpawn = false [2]
ScreenGui.Parent = player:WaitForChild("PlayerGui") [2]

local MainFrame = Instance.new("Frame") [2]
MainFrame.Size = UDim2.new(0, 260, 0, 280) [2]
MainFrame.Position = UDim2.new(0.5, -130, 0.4, -140) [2]
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 20) [3]
MainFrame.BorderSizePixel = 0 [3]
MainFrame.Visible = true [3]
MainFrame.Active = true [3]
MainFrame.Draggable = true -- Permite arrastar a janela [3]
MainFrame.Parent = ScreenGui [3]

local Title = Instance.new("TextLabel") [3]
Title.Size = UDim2.new(1, 0, 0, 35) [3]
Title.BackgroundTransparency = 1 [3]
Title.Text = "DEADLY DELIVERY REMASTERED" [3]
Title.TextColor3 = Color3.fromRGB(0, 255, 255) [3]
Title.TextSize = 13 [3]
Title.Font = Enum.Font.SourceSansBold [3]
Title.Parent = MainFrame [3]

-- Campo de entrada para definir o valor do TPWalk [3, 15]
local InputBox = Instance.new("TextBox") [3]
InputBox.Size = UDim2.new(0, 140, 0, 35) [15]
InputBox.Position = UDim2.new(0.5, -70, 0.15, 0) [15]
InputBox.BackgroundColor3 = Color3.fromRGB(45, 30, 30) [15]
InputBox.BorderSizePixel = 0 [15]
InputBox.Text = "0" [15]
InputBox.TextColor3 = Color3.fromRGB(255, 200, 0) [15]
InputBox.TextSize = 18 [15]
InputBox.Font = Enum.Font.SourceSansBold [15]
InputBox.Parent = MainFrame [15]

-- Botão para ativar/desativar TPWalk [15, 16]
local ApplyBtn = Instance.new("TextButton") [15]
ApplyBtn.Size = UDim2.new(0, 140, 0, 35) [15]
ApplyBtn.Position = UDim2.new(0.5, -70, 0.32, 5) [15]
ApplyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40) [15]
ApplyBtn.BorderSizePixel = 0 [16]
ApplyBtn.Text = "TPWALK: DESLIGADO" [16]
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255) [16]
ApplyBtn.TextSize = 13 [16]
ApplyBtn.Font = Enum.Font.SourceSansBold [16]
ApplyBtn.Parent = MainFrame [16]

-- Botão para ativar ESP de Monstros [16]
local EspBtn = Instance.new("TextButton") [16]
EspBtn.Size = UDim2.new(0, 220, 0, 35) [16]
EspBtn.Position = UDim2.new(0.5, -110, 0.50, 5) [16]
EspBtn.BackgroundColor3 = Color3.fromRGB(180, 90, 0) [16]
EspBtn.BorderSizePixel = 0 [16]
EspBtn.Text = "ATIVAR ESP MONSTROS" [16]
EspBtn.TextColor3 = Color3.fromRGB(255, 255, 255) [16]
EspBtn.TextSize = 13 [17]
EspBtn.Font = Enum.Font.SourceSansBold [17]
EspBtn.Parent = MainFrame [17]

-- Botão para ativar o Modo Deus (God Mode) [17]
local GodBtn = Instance.new("TextButton") [17]
GodBtn.Size = UDim2.new(0, 220, 0, 35) [17]
GodBtn.Position = UDim2.new(0.5, -110, 0.66, 5) [17]
GodBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30) [17]
GodBtn.BorderSizePixel = 0 [17]
GodBtn.Text = "MODO DEUS HARDCORE: DESLIGADO" [17]
GodBtn.TextColor3 = Color3.fromRGB(255, 255, 255) [17]
GodBtn.TextSize = 12 [17]
GodBtn.Font = Enum.Font.SourceSansBold [17]
GodBtn.Parent = MainFrame [17]

-- Botão para Teleportar ao Elevador [17, 18]
local TeleportEscBtn = Instance.new("TextButton") [17, 18]
TeleportEscBtn.Size = UDim2.new(0, 220, 0, 35) [18]
TeleportEscBtn.Position = UDim2.new(0.5, -110, 0.82, 5) [18]
TeleportEscBtn.BackgroundColor3 = Color3.fromRGB(0, 110, 180) [18]
TeleportEscBtn.BorderSizePixel = 0 [18]
TeleportEscBtn.Text = "TELEPORTAR PARA ELEVADOR" [18]
TeleportEscBtn.TextColor3 = Color3.fromRGB(255, 255, 255) [18]
TeleportEscBtn.TextSize = 12 [18]
TeleportEscBtn.Font = Enum.Font.SourceSansBold [18]
TeleportEscBtn.Parent = MainFrame [18]

-- Aplica cantos arredondados aos elementos visuais [5, 18]
for _, v in pairs({MainFrame, InputBox, ApplyBtn, EspBtn, GodBtn, TeleportEscBtn}) do [18]
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 6) c.Parent = v [5]
end [5]

-- Alterna a visibilidade do menu ao digitar "/speed" no chat [5]
local function toggleMenu(msg) [5]
    if msg:lower() == "/speed" then MainFrame.Visible = not MainFrame.Visible end [5]
end [5]

player.Chatted:Connect(toggleMenu) [5]

pcall(function() [5]
    TextChatService.MessageReceived:Connect(function(message) [5]
        if message.TextSource and message.TextSource.UserId == player.UserId then toggleMenu(message.Text) end [5]
    end) [5]
end) [5]

-- ====================================================================
-- LÓGICA DAS FUNCIONALIDADES DOS BOTÕES
-- ====================================================================

-- Executa o movimento TPWalk acelerado via Heartbeat [5, 6]
local function startTpWalk() [5]
    if tpConnection then tpConnection:Disconnect() end [5, 6]

    tpConnection = RunService.Heartbeat:Connect(function() [6]
        if character and rootPart and humanoid and tpWalkSpeed > 0 then [6]
            if humanoid.MoveDirection.Magnitude > 0 then [6]
                -- Move o CFrame na direção do movimento do personagem [6]
                rootPart.CFrame = rootPart.CFrame + (humanoid.MoveDirection * (tpWalkSpeed / 10)) [6]
            end [6]
        end [6]
    end) [6]
end [6]

-- Evento: Clique no botão de Velocidade (TPWalk) [6]
ApplyBtn.MouseButton1Click:Connect(function() [6]
    local speedValue = tonumber(InputBox.Text) [6]
    if speedValue then [6]
        if speedValue <= 0 then [6]
            tpWalkSpeed = 0 [6]
            if tpConnection then tpConnection:Disconnect() tpConnection = nil end [6]
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(140, 40, 40) [7]
            ApplyBtn.Text = "TPWALK: DESLIGADO" [7]
        else [7]
            if speedValue > 15 then speedValue = 15 InputBox.Text = "15" end -- Limite máximo de segurança [7]
            tpWalkSpeed = speedValue [7]
            startTpWalk() [7]
            ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90) [7]
            ApplyBtn.Text = "TPWALK: " .. speedValue [7]
        end [7]
    end [7]
end) [7]

-- Evento: Clique no botão de Ativar ESP [7]
EspBtn.MouseButton1Click:Connect(function() [7]
    startMonsterESP() [7]
    EspBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90) [7]
    EspBtn.Text = "ESP MONSTROS: LIGADO" [7]
end) [7]

-- Evento: Clique no botão do Modo Deus (Hardcore) [4, 7]
GodBtn.MouseButton1Click:Connect(function() [4, 7]
    if godConnection then [4]
        godConnection:Disconnect() [4]
        godConnection = nil [4]
        GodBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 30) [4]
        GodBtn.Text = "MODO DEUS HARDCORE: DESLIGADO" [4]
    else [4]
        GodBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90) [4]
        GodBtn.Text = "MODO DEUS HARDCORE: LIGADO" [4]

        -- Mantém a saúde congelada em 100 e desativa colisão de toque dos monstros [4]
        godConnection = RunService.Heartbeat:Connect(function() [4]
            pcall(function() [4]
                if character then [4]
                    -- Congela atributos personalizados de vida do Deadly Delivery [4]
                    if character:SetAttribute("Health", 100) then character:SetAttribute("Health", 100) end [4]
                    if player:SetAttribute("Health", 100) then player:SetAttribute("Health", 100) end [11]
                    if character:FindFirstChild("Health") and character.Health:IsA("NumberValue") then [11]
                        character.Health.Value = 100 [11]
                    end [11]

                    -- Impede o contato físico direto do monstro com as partes do jogador [11]
                    for _, part in pairs(character:GetChildren()) do [11]
                        if part:IsA("BasePart") then [11]
                            part.CanTouch = false [11]
                        end [11]
                    end [11]
                end [11]
            end) [11]
        end) [4, 11]
    end [4]
end) [11]

-- Evento: Clique no botão de Teletransporte para o Elevador [11]
TeleportEscBtn.MouseButton1Click:Connect(function() [11]
    if rootPart then [11]
        local realLift = getAbsoluteElevator() [14]
        if realLift then [14]
            -- Posiciona o jogador 3 unidades acima do chão do elevador [14]
            rootPart.CFrame = realLift.CFrame + Vector3.new(0, 3, 0) [14]
            TeleportEscBtn.Text = "CHEGOU AO ELEVADOR!" [14]
            task.wait(1) [14]
            TeleportEscBtn.Text = "TELEPORTAR PARA ELEVADOR" [14]
        else [14]
            TeleportEscBtn.Text = "ELEVADOR NÃO ENCONTRADO!" [14]
            task.wait(1.5) [14]
            TeleportEscBtn.Text = "TELEPORTAR PARA ELEVADOR" [14]
        end [14]
    end [14]
end) [14]

]]

assert(loadstring(scriptSource))() [14]
eu quero uma hub somente para teste de funçoes, dessa forma remova tudo desse script que seja voltado para ui e use o rayfield para criar a ui e cole as funcionalidades separadas do que é para alterar jogador e o que é para monstro e lotear, para diferenciação para cada funcionalidade e agrupe elas

Todo o código de interface gráfica personalizada (como ScreenGui, Frame, TextBox e TextButton) e o comando do chat foram removidos do script original
. Em seu lugar, foi integrada a biblioteca Rayfield UI, criando uma hub organizada em abas distintas para facilitar o teste isolado das funcionalidades do jogo
.
As funcionalidades foram agrupadas em três categorias principais: Jogador (TPWalk e Modo Deus)
, Monstros (ESP de Wallhack e Marcador de Distância)
 e Teleporte / Loot (Teletransporte direto ao Elevador)
.
Script Lua (Rayfield UI Test Hub)
-- ====================================================================
-- RAYFIELD TEST HUB - DEADLY DELIVERY
-- ====================================================================

-- Carregamento da biblioteca de interface Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Serviços nativos do Roblox
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Referências do Jogador Local
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Variáveis globais de controle das funções
local tpWalkSpeed = 5
local tpWalkEnabled = false
local tpConnection = nil
local espEnabled = false
local espConnection = nil
local godConnection = nil

-- Atualiza referências quando o jogador renasce (respawn)
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = newCharacter:WaitForChild("Humanoid")
    rootPart = newCharacter:WaitForChild("HumanoidRootPart")
end)

-- ====================================================================
-- FUNÇÕES DE LÓGICA E AUTOMAÇÃO
-- ====================================================================

-- Busca a estrutura do elevador/plataforma de fuga no workspace
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

-- Aplica caixa delimitadora e rótulo de distância no monstro
local function applyESP(model)
    if model:FindFirstChild("MonsterESP") then return end
    if model.Name:lower():match("package") or model.Name:lower():match("letter") or model.Name:lower():match("egg") then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "MonsterESP"
    box.Size = model:GetExtentsSize() + Vector3.new(0.5, 0.5, 0.5)
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Adornee = model:FindFirstChildOfClass("BasePart") or model
    box.Transparency = 0.4
    box.Parent = model

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "MonsterTag"
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.AlwaysOnTop = true
    billboard.ExtentsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = model

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "MONSTRO!"
    label.TextColor3 = Color3.fromRGB(255, 65, 65)
    label.TextSize = 12
    label.Font = Enum.Font.SourceSansBold
    label.Parent = billboard

    task.spawn(function()
        while model.Parent and rootPart and espEnabled do
            local part = model:FindFirstChildOfClass("BasePart")
            if part then
                local dist = math.floor((rootPart.Position - part.Position).Magnitude)
                label.Text = "MONSTRO [" .. dist .. "m]"
            end
            task.wait(0.2)
        end
    end)
end

-- Varre o mapa e ativa o monitoramento de novos monstros
local function startMonsterESP()
    if espConnection then espConnection:Disconnect() end

    local function checkAndApply(v)
        if not espEnabled then return end
        if v:IsA("Model") and v ~= character and not Players:GetPlayerFromCharacter(v) then
            local hum = v:FindFirstChildOfClass("Humanoid")
            if hum or v.Name:lower():match("monster") or v.Name:lower():match("bot") or v.Name:lower():match("killer") or v.Name:lower():match("crocodile") then
                applyESP(v)
            end
        end
    end

    for _, v in pairs(workspace:GetDescendants()) do checkAndApply(v) end
    espConnection = workspace.DescendantAdded:Connect(function(v) task.wait(0.5) checkAndApply(v) end)
end

-- Remove todos os elementos visuais de ESP quando desativado
local function stopMonsterESP()
    if espConnection then
        espConnection:Disconnect()
        espConnection = nil
    end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:FindFirstChild("MonsterESP") then v.MonsterESP:Destroy() end
        if v:FindFirstChild("MonsterTag") then v.MonsterTag:Destroy() end
    end
end

-- Executa a movimentação acelerada no Heartbeat
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
-- CRIAÇÃO DA ESTRUTURA DA INTERFACE (RAYFIELD)
-- ====================================================================

local Window = Rayfield:CreateWindow({
   Name = "Hub de Testes - Deadly Delivery",
   LoadingTitle = "Carregando Módulos de Teste...",
   LoadingSubtitle = "Rayfield UI",
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- --------------------------------------------------------------------
-- GRUPO 1: ALTERAÇÕES DO JOGADOR
-- --------------------------------------------------------------------
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
      else
         if tpConnection then tpConnection:Disconnect() tpConnection = nil end
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
   Name = "Modo Deus (Hardcore / Invicibilidade)",
   CurrentValue = false,
   Flag = "GodModeToggle",
   Callback = function(Value)
      if Value then
         godConnection = RunService.Heartbeat:Connect(function()
            pcall(function()
               if character then
                  -- Congela atributos de vida personalizados em 100
                  if character:SetAttribute("Health", 100) then character:SetAttribute("Health", 100) end
                  if player:SetAttribute("Health", 100) then player:SetAttribute("Health", 100) end
                  if character:FindFirstChild("Health") and character.Health:IsA("NumberValue") then
                     character.Health.Value = 100
                  end

                  -- Desativa toque/colisão física para evitar dano de monstros
                  for _, part in pairs(character:GetChildren()) do
                     if part:IsA("BasePart") then
                        part.CanTouch = false
                     end
                  end
               end
            end)
         end)
      else
         if godConnection then
            godConnection:Disconnect()
            godConnection = nil
         end
      end
   end,
})

-- --------------------------------------------------------------------
-- GRUPO 2: MONSTROS E INIMIGOS
-- --------------------------------------------------------------------
local MonsterTab = Window:CreateTab("Monstros", 4483362458)

MonsterTab:CreateSection("Detecção e Visão (ESP)")

MonsterTab:CreateToggle({
   Name = "ESP de Monstros (Caixa Vermelha & Distância)",
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

-- --------------------------------------------------------------------
-- GRUPO 3: TELEPORTE E OBJETIVOS / LOOT
-- --------------------------------------------------------------------
local TeleportTab = Window:CreateTab("Teleporte / Loot", 4483362458)

TeleportTab:CreateSection("Localização e Fuga")

TeleportTab:CreateButton({
   Name = "Teleportar para o Elevador / Plataforma",
   Callback = function()
      if rootPart then
         local realLift = getAbsoluteElevator()
         if realLift then
            rootPart.CFrame = realLift.CFrame + Vector3.new(0, 3, 0)
            Rayfield:Notify({
               Title = "Sucesso!",
               Content = "Teleportado para o elevador com sucesso.",
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
      end
   end,
})
