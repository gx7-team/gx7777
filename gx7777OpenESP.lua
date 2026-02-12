getgenv().ESPLoaded = getgenv().ESPLoaded or false

if getgenv().ESPLoaded then
    warn("ESP já está carregado! Não execute novamente.")
    return
end
getgenv().ESPLoaded = true

-- Limpeza anterior
pcall(function()
    local coreGui = game:GetService("CoreGui")
    for _, child in ipairs(coreGui:GetChildren()) do
        if child:IsA("ScreenGui") and (child.Name:find("ESP") or child.Name:find("Panel")) then
            child:Destroy()
        end
    end
end)

if getgenv().ESPObjs then
    for _, o in pairs(getgenv().ESPObjs) do
        for _, v in pairs(o) do
            if type(v) == "table" then
                for _, l in pairs(v) do pcall(function() l:Remove() end) end
            else
                pcall(function() v:Remove() end)
            end
        end
    end
end

if getgenv().ESPConnection then
    getgenv().ESPConnection:Disconnect()
    getgenv().ESPConnection = nil
end

task.wait(0.3)

local Plrs = game:GetService("Players")
local RS = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Cam = workspace.CurrentCamera
local LP = Plrs.LocalPlayer
local HttpService = game:GetService("HttpService")

local DrawingNew = Drawing.new
local InstanceNew = Instance.new

local C = {
    on = true,
    dist = 2500,
    box = true,
    name = true,
    hp = true,
    distance = true,
    skel = true,
    head = true,
    team = false,
    tcolor = true,
    thick = 1,
    menuLocked = false
}

local configFile = "esp_config.json"
local loadedConfig = nil
if isfile(configFile) then
    pcall(function()
        loadedConfig = HttpService:JSONDecode(readfile(configFile))
        for k, v in pairs(loadedConfig) do
            if C[k] ~= nil then
                C[k] = v
            end
        end
    end)
end

local O = {}
getgenv().ESPObjs = O

local r15 = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"UpperTorso","RightUpperArm"},
    {"LowerTorso","LeftUpperLeg"},
    {"LowerTorso","RightUpperLeg"}
}
local r6 = {
    {"Head","Torso"},
    {"Torso","Left Arm"},
    {"Torso","Right Arm"},
    {"Torso","Left Leg"},
    {"Torso","Right Leg"}
}

local vector2New = Vector2.new
local vector3New = Vector3.new
local color3New = Color3.new
local mathFloor = math.floor
local mathAbs = math.abs
local mathClamp = math.clamp
local mathSqrt = math.sqrt
local worldToViewport = workspace.CurrentCamera.WorldToViewportPoint

local function saveConfig(f)
    local config = {}
    for k, v in pairs(C) do
        config[k] = v
    end
    config.positionXScale = f.Position.X.Scale
    config.positionXOffset = f.Position.X.Offset
    config.positionYScale = f.Position.Y.Scale
    config.positionYOffset = f.Position.Y.Offset
    pcall(function()
        writefile(configFile, HttpService:JSONEncode(config))
    end)
end

local function deleteAll()
    for p, o in pairs(O) do
        for _, v in pairs(o.l or {}) do pcall(function() v:Remove() end) end
        for _, v in pairs(o.s or {}) do pcall(function() v:Remove() end) end
        if o.h then pcall(function() o.h:Remove() end) end
        if o.t then pcall(function() o.t:Remove() end) end
    end
    O = {}
    getgenv().ESPObjs = nil
    getgenv().ESPLoaded = nil

    pcall(function()
        local coreGui = game:GetService("CoreGui")
        for _, child in ipairs(coreGui:GetChildren()) do
            if child:IsA("ScreenGui") and (child.Name:find("ESP") or child.Name:find("Panel")) then
                child:Destroy()
            end
        end
    end)

    if getgenv().ESPConnection then
        getgenv().ESPConnection:Disconnect()
        getgenv().ESPConnection = nil
    end
    print("ESP deletado completamente. Pode executar de novo.")
end

local function new(p)
    if p == LP then return end
    pcall(function()
        local lines = {}
        for i = 1, 4 do
            local l = DrawingNew("Line")
            l.Visible = false
            l.Thickness = C.thick
            l.Color = color3New(1,1,1)
            l.Transparency = 1
            lines[i] = l
        end
        
        local skel = {}
        for i = 1, 6 do
            local l = DrawingNew("Line")
            l.Visible = false
            l.Thickness = C.thick
            l.Color = color3New(1,1,1)
            l.Transparency = 1
            skel[i] = l
        end
        
        local headCircle = DrawingNew("Circle")
        headCircle.Visible = false
        headCircle.Thickness = C.thick
        headCircle.NumSides = 8
        headCircle.Filled = false
        headCircle.Color = color3New(1,1,1)
        headCircle.Transparency = 1
        
        local txt = DrawingNew("Text")
        txt.Visible = false
        txt.Center = true
        txt.Outline = true
        txt.Font = 2
        txt.Size = 13
        txt.Color = color3New(1,1,1)
        
        O[p] = {l = lines, s = skel, h = headCircle, t = txt}
    end)
end

local function rem(p)
    if O[p] then
        pcall(function()
            for _, v in pairs(O[p].l or {}) do v:Remove() end
            for _, v in pairs(O[p].s or {}) do v:Remove() end
            if O[p].h then O[p].h:Remove() end
            if O[p].t then O[p].t:Remove() end
            O[p] = nil
        end)
    end
end

local function upd()
    pcall(function()
        if not C.on then
            for _, o in pairs(O) do
                for _, l in pairs(o.l or {}) do l.Visible = false end
                for _, l in pairs(o.s or {}) do l.Visible = false end
                if o.h then o.h.Visible = false end
                if o.t then o.t.Visible = false end
            end
            return
        end
        
        local lpChar = LP.Character
        if not lpChar then return end
        
        local lr = lpChar:FindFirstChild("HumanoidRootPart")
        if not (lr and Cam) then return end
        
        local lpTeam = LP.Team
        local camPos = Cam.CFrame.Position
        local viewportX = Cam.ViewportSize.X
        local viewportY = Cam.ViewportSize.Y
        local lrPos = lr.Position
        
        for p, o in pairs(O) do
            for _, l in pairs(o.l or {}) do l.Visible = false end
            for _, l in pairs(o.s or {}) do l.Visible = false end
            if o.h then o.h.Visible = false end
            if o.t then o.t.Visible = false end
            
            pcall(function()
                if not (p and p.Parent) then return end
                
                local c = p.Character
                if not c then return end
                
                local r = c:FindFirstChild("HumanoidRootPart")
                local h = c:FindFirstChildOfClass("Humanoid")
                
                if not (r and h and h.Health > 0) then return end
                
                local dx = lrPos.X - r.Position.X
                local dy = lrPos.Y - r.Position.Y
                local dz = lrPos.Z - r.Position.Z
                local distSq = dx*dx + dy*dy + dz*dz
                
                if distSq > C.dist * C.dist then return end
                
                if C.team and p.Team == lpTeam then return end
                
                local v, s = worldToViewport(Cam, r.Position)
                if not s then return end
                
                local hd = c:FindFirstChild("Head")
                if not (hd and hd:IsA("BasePart")) then return end
                
                local hp, hpVis = worldToViewport(Cam, hd.Position + vector3New(0, 0.5, 0))
                local lp, lpVis = worldToViewport(Cam, r.Position - vector3New(0, 3, 0))
                
                if not (hpVis and lpVis) then return end
                
                local hh = mathAbs(hp.Y - lp.Y)
                if hh < 2 then return end
                
                local w = hh * 0.5
                local col = C.tcolor and p.Team and p.Team.TeamColor.Color or color3New(1,1,1)
                
                local isClose = distSq < 1000000
                
                if C.box then
                    local x1, y1 = v.X - w*0.5, v.Y - hh*0.5
                    local x2, y2 = v.X + w*0.5, v.Y + hh*0.5
                    
                    if x1 > -500 and x2 < viewportX + 500 and y1 > -500 and y2 < viewportY + 500 then
                        o.l[1].From = vector2New(x1, y1)
                        o.l[1].To = vector2New(x2, y1)
                        o.l[1].Color = col
                        o.l[1].Visible = true
                        
                        o.l[2].From = vector2New(x2, y1)
                        o.l[2].To = vector2New(x2, y2)
                        o.l[2].Color = col
                        o.l[2].Visible = true
                        
                        o.l[3].From = vector2New(x2, y2)
                        o.l[3].To = vector2New(x1, y2)
                        o.l[3].Color = col
                        o.l[3].Visible = true
                        
                        o.l[4].From = vector2New(x1, y2)
                        o.l[4].To = vector2New(x1, y1)
                        o.l[4].Color = col
                        o.l[4].Visible = true
                    end
                end
                
                if C.head and isClose then
                    local headPos, headVis = worldToViewport(Cam, hd.Position)
                    if headVis and headPos.X > -500 and headPos.X < viewportX + 500 then
                        local headDist = (camPos - hd.Position).Magnitude
                        local radius = mathClamp((hd.Size.Y * 0.5) / headDist * 500, 2, 15)
                        o.h.Position = vector2New(headPos.X, headPos.Y)
                        o.h.Radius = radius
                        o.h.Color = col
                        o.h.Visible = true
                    end
                end
                
                if C.skel and isClose then
                    local conns = c:FindFirstChild("UpperTorso") and r15 or r6
                    
                    for i = 1, #conns do
                        local cn = conns[i]
                        local p1 = c:FindFirstChild(cn[1])
                        local p2 = c:FindFirstChild(cn[2])
                        
                        if p1 and p2 then
                            local pos1, vis1 = worldToViewport(Cam, p1.Position)
                            local pos2, vis2 = worldToViewport(Cam, p2.Position)
                            
                            if vis1 and vis2 then
                                o.s[i].From = vector2New(pos1.X, pos1.Y)
                                o.s[i].To = vector2New(pos2.X, pos2.Y)
                                o.s[i].Color = col
                                o.s[i].Visible = true
                            end
                        end
                    end
                end
                
                if C.name or C.hp or C.distance then
                    local str = C.name and p.Name or ""
                    if C.hp then
                        str = str .. (C.name and "\n" or "") .. mathFloor(h.Health) .. " HP"
                    end
                    if C.distance then
                        str = str .. ((C.name or C.hp) and "\n" or "") .. mathFloor(mathSqrt(distSq) * 0.28) .. "m"
                    end
                    
                    o.t.Text = str
                    o.t.Position = vector2New(v.X, v.Y - hh*0.5 - 16)
                    o.t.Color = col
                    o.t.Visible = true
                end
            end)
        end
    end)
end

-- UI
local minimized = false
local function ui()
    local sg = InstanceNew("ScreenGui")
    sg.Name = "ESP_Panel_" .. math.random(10000, 999999)
    sg.ResetOnSpawn = false
    
    local f = InstanceNew("Frame")
    f.Size = UDim2.new(0, 200, 0, 320)
    f.Position = UDim2.new(0.02, 0, 0.35, 0)
    f.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
    f.BorderSizePixel = 0
    f.Active = true
    f.Draggable = true
    f.Parent = sg
    
    if loadedConfig then
        f.Position = UDim2.new(
            loadedConfig.positionXScale or 0.02,
            loadedConfig.positionXOffset or 0,
            loadedConfig.positionYScale or 0.35,
            loadedConfig.positionYOffset or 0
        )
    end
    
    InstanceNew("UICorner", f).CornerRadius = UDim.new(0, 6)
    
    local t = InstanceNew("TextLabel")
    t.Size = UDim2.new(1, -90, 0, 25)
    t.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    t.BorderSizePixel = 0
    t.Text = "ESP Ultra Fast"
    t.TextColor3 = Color3.new(1,1,1)
    t.TextSize = 14
    t.Font = Enum.Font.GothamBold
    t.Parent = f
    
    InstanceNew("UICorner", t).CornerRadius = UDim.new(0, 6)
    
    local lock = InstanceNew("TextButton")
    lock.Size = UDim2.new(0, 25, 0, 25)
    lock.Position = UDim2.new(1, -87, 0, 0)
    lock.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    lock.BorderSizePixel = 0
    lock.Text = "🔓"
    lock.TextColor3 = Color3.new(1,1,1)
    lock.TextSize = 14
    lock.Font = Enum.Font.GothamBold
    lock.Parent = f
    
    InstanceNew("UICorner", lock).CornerRadius = UDim.new(0, 5)
    
    local min = InstanceNew("TextButton")
    min.Size = UDim2.new(0, 25, 0, 25)
    min.Position = UDim2.new(1, -57, 0, 0)
    min.BackgroundColor3 = Color3.fromRGB(0, 120, 180)
    min.BorderSizePixel = 0
    min.Text = "_"
    min.TextColor3 = Color3.new(1,1,1)
    min.TextSize = 16
    min.Font = Enum.Font.GothamBold
    min.Parent = f
    
    InstanceNew("UICorner", min).CornerRadius = UDim.new(0, 5)
    
    local m = InstanceNew("TextButton")
    m.Size = UDim2.new(0, 25, 0, 25)
    m.Position = UDim2.new(1, -27, 0, 0)
    m.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    m.BorderSizePixel = 0
    m.Text = "X"
    m.TextColor3 = Color3.new(1,1,1)
    m.TextSize = 16
    m.Font = Enum.Font.GothamBold
    m.Parent = f
    
    InstanceNew("UICorner", m).CornerRadius = UDim.new(0, 5)
    
    local c = InstanceNew("Frame")
    c.Size = UDim2.new(1, -14, 1, -32)
    c.Position = UDim2.new(0, 7, 0, 28)
    c.BackgroundTransparency = 1
    c.BorderSizePixel = 0
    c.Parent = f
    
    local l = InstanceNew("UIListLayout")
    l.Padding = UDim.new(0, 5)
    l.Parent = c
    
    lock.MouseButton1Click:Connect(function()
        C.menuLocked = not C.menuLocked
        f.Draggable = not C.menuLocked
        lock.BackgroundColor3 = C.menuLocked and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(255, 165, 0)
        lock.Text = C.menuLocked and "🔒" or "🔓"
    end)
    
    min.MouseButton1Click:Connect(function()
        minimized = not minimized
        c.Visible = not minimized
        f.Size = minimized and UDim2.new(0, 200, 0, 25) or UDim2.new(0, 200, 0, 320)
        min.Text = minimized and "+" or "_"
    end)
    
    m.MouseButton1Click:Connect(function()
        saveConfig(f)
        deleteAll()
    end)
    
    sg.Parent = game:GetService("CoreGui")
    return c, f
end

local function tog(p, txt, def, cb)
    local f = InstanceNew("Frame")
    f.Size = UDim2.new(1, 0, 0, 24)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    f.BorderSizePixel = 0
    f.Parent = p
    
    InstanceNew("UICorner", f).CornerRadius = UDim.new(0, 4)
    
    local l = InstanceNew("TextLabel")
    l.Size = UDim2.new(1, -45, 1, 0)
    l.Position = UDim2.new(0, 6, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = txt
    l.TextColor3 = Color3.new(1,1,1)
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local b = InstanceNew("TextButton")
    b.Size = UDim2.new(0, 40, 0, 16)
    b.Position = UDim2.new(1, -44, 0.5, -8)
    b.BackgroundColor3 = def and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    b.BorderSizePixel = 0
    b.Text = def and "ON" or "OFF"
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    
    InstanceNew("UICorner", b).CornerRadius = UDim.new(0, 3)
    
    local s = def
    b.MouseButton1Click:Connect(function()
        s = not s
        b.BackgroundColor3 = s and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        b.Text = s and "ON" or "OFF"
        cb(s)
    end)
end

local function sld(p, txt, min, max, def, cb)
    local f = InstanceNew("Frame")
    f.Size = UDim2.new(1, 0, 0, 32)
    f.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    f.BorderSizePixel = 0
    f.Parent = p
    
    InstanceNew("UICorner", f).CornerRadius = UDim.new(0, 4)
    
    local l = InstanceNew("TextLabel")
    l.Size = UDim2.new(1, -12, 0, 16)
    l.Position = UDim2.new(0, 6, 0, 3)
    l.BackgroundTransparency = 1
    l.Text = txt .. ": " .. def
    l.TextColor3 = Color3.new(1,1,1)
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local bg = InstanceNew("Frame")
    bg.Size = UDim2.new(1, -12, 0, 4)
    bg.Position = UDim2.new(0, 6, 1, -8)
    bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    bg.BorderSizePixel = 0
    bg.Parent = f
    
    InstanceNew("UICorner", bg).CornerRadius = UDim.new(1, 0)
    
    local fl = InstanceNew("Frame")
    fl.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
    fl.BackgroundColor3 = Color3.fromRGB(0, 130, 255)
    fl.BorderSizePixel = 0
    fl.Parent = bg
    
    InstanceNew("UICorner", fl).CornerRadius = UDim.new(1, 0)
    
    local d = false
    bg.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = true end
    end)
    bg.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then d = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if d and i.UserInputType == Enum.UserInputType.MouseMovement then
            local pos = mathClamp((i.Position.X - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
            fl.Size = UDim2.new(pos, 0, 1, 0)
            local val = mathFloor(min + (max - min) * pos)
            l.Text = txt .. ": " .. val
            cb(val)
        end
    end)
end

-- Init UI e toggles
local content, panelFrame = ui()

tog(content, "Enabled", C.on, function(v) C.on = v end)
tog(content, "Box", C.box, function(v) C.box = v end)
tog(content, "Skeleton", C.skel, function(v) C.skel = v end)
tog(content, "Head Circle", C.head, function(v) C.head = v end)
tog(content, "Name", C.name, function(v) C.name = v end)
tog(content, "Health", C.hp, function(v) C.hp = v end)
tog(content, "Distance", C.distance, function(v) C.distance = v end)
tog(content, "Team Check", C.team, function(v) C.team = v end)
tog(content, "Team Colors", C.tcolor, function(v) C.tcolor = v end)
sld(content, "Max Distance", 500, 5000, C.dist, function(v) C.dist = v end)
sld(content, "Thickness", 1, 3, C.thick, function(v)
    C.thick = v
    for _, o in pairs(O) do
        for _, l in pairs(o.l or {}) do l.Thickness = v end
        for _, l in pairs(o.s or {}) do l.Thickness = v end
        if o.h then o.h.Thickness = v end
    end
end)

-- Botão para salvar configuração
local saveBtnFrame = InstanceNew("Frame")
saveBtnFrame.Size = UDim2.new(1, 0, 0, 24)
saveBtnFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
saveBtnFrame.BorderSizePixel = 0
saveBtnFrame.Parent = content

InstanceNew("UICorner", saveBtnFrame).CornerRadius = UDim.new(0, 4)

local saveBtn = InstanceNew("TextButton")
saveBtn.Size = UDim2.new(1, -12, 1, 0)
saveBtn.Position = UDim2.new(0, 6, 0, 0)
saveBtn.BackgroundTransparency = 1
saveBtn.Text = "Save Config"
saveBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
saveBtn.TextSize = 11
saveBtn.Font = Enum.Font.GothamBold
saveBtn.TextXAlignment = Enum.TextXAlignment.Left
saveBtn.Parent = saveBtnFrame

saveBtn.MouseButton1Click:Connect(function()
    saveConfig(panelFrame)
    print("Configurações salvas em " .. configFile)
end)

-- Players
for _, p in pairs(Plrs:GetPlayers()) do
    task.delay(math.random(1, 80)/1000, function() if p and p.Parent then new(p) end end)
end

Plrs.PlayerAdded:Connect(function(p)
    task.delay(math.random(20, 120)/1000, function() if p and p.Parent then new(p) end end)
end)

Plrs.PlayerRemoving:Connect(rem)

getgenv().ESPConnection = RS.RenderStepped:Connect(upd)

LP.CharacterAdded:Connect(function()
    task.delay(1, function()
        for p in pairs(O) do
            rem(p)
            new(p)
        end
    end)
end)

print("ESP carregado! Panel deve aparecer com toggles. Pressione X para fechar, RightShift para deletar.")
