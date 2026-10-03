-- MaulzzPRESET — AutoWalk
-- LocalScript: StarterPlayer > StarterPlayerScripts
-- Recording tersimpan di sesi. Export menghasilkan data Lua untuk ditempel
-- ke EmbeddedMaps agar dapat dipakai semua pengguna script yang sama.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local APP = "MaulzzPRESET — AutoWalk"

local CFG = {
    RecordInterval = 0.08,
    WaypointDistance = 1.5,
    ReachDistance = 2.5,
    DefaultSpeed = 18,
    AdaptiveSpeed = 24,
    Acceleration = 3.5,
    ObstacleDistance = 4,
}

-- Masukkan hasil Export Recording di sini untuk map permanen.
local EmbeddedMaps = {
    -- ["Jalur Gunung"] = {
    --     {x=0,y=5,z=0,rx=0,ry=0,rz=0},
    --     {x=0,y=5,z=10,rx=0,ry=0,rz=0},
    -- },
}

local char, hum, root
local recording = {}
local recordingName = "MyRoute"
local recordingOn, playing = false, false
local direction = 1
local index = 1
local loop = false
local speedMode = "Acceleration Dominant"
local showLine = false
local locked = false -- selalu OFF saat launch
local streamer = false
local recConn, playConn, lineFolder

local function bind(c)
    char = c
    hum = c:WaitForChild("Humanoid", 10)
    root = c:WaitForChild("HumanoidRootPart", 10)
end
bind(Player.Character or Player.CharacterAdded:Wait())
Player.CharacterAdded:Connect(bind)

local function rootPart()
    if not root or not root.Parent then
        bind(Player.Character or Player.CharacterAdded:Wait())
    end
    return root
end

local function pack(cf)
    local rx, ry, rz = cf:ToOrientation()
    return {
        x=math.round(cf.X*100)/100, y=math.round(cf.Y*100)/100,
        z=math.round(cf.Z*100)/100,
        rx=math.round(math.deg(rx)*10)/10,
        ry=math.round(math.deg(ry)*10)/10,
        rz=math.round(math.deg(rz)*10)/10,
    }
end

local function pos(p)
    return Vector3.new(p.x or 0, p.y or 0, p.z or 0)
end

local function clearLine()
    if lineFolder then lineFolder:Destroy(); lineFolder=nil end
end

local function drawLine()
    clearLine()
    if not showLine or #recording < 2 then return end
    lineFolder=Instance.new("Folder")
    lineFolder.Name="MaulzzPRESET_Route"
    lineFolder.Parent=workspace

    for i=1,#recording-1 do
        local a,b=pos(recording[i]),pos(recording[i+1])
        local d=b-a
        if d.Magnitude>0.05 then
            local p=Instance.new("Part")
            p.Anchored=true
            p.CanCollide=false
            p.CanTouch=false
            p.CanQuery=false
            p.Material=Enum.Material.Neon
            p.Transparency=.25
            p.Size=Vector3.new(.1,.1,d.Magnitude)
            p.CFrame=CFrame.lookAt((a+b)/2,b)
            p.Parent=lineFolder
        end
    end
end

local function stopRecording()
    recordingOn=false
    if recConn then recConn:Disconnect(); recConn=nil end
end

local function startRecording()
    if playing then return end
    stopRecording()
    recording={}
    recordingOn=true
    local last
    local t=0

    recConn=RunService.Heartbeat:Connect(function(dt)
        t+=dt
        if not recordingOn or t<CFG.RecordInterval then return end
        t=0
        local r=rootPart()
        if not r then return end
        if not last or (r.Position-last).Magnitude>=CFG.WaypointDistance then
            table.insert(recording,pack(r.CFrame))
            last=r.Position
        end
    end)
end

local function exportRecording()
    if #recording==0 then return end
    local name=recordingName:gsub("[^%w_%-]","_")
    local out={'["'..name..'"] = {'}
    for _,p in ipairs(recording) do
        out[#out+1]=string.format(
            "    {x=%.2f,y=%.2f,z=%.2f,rx=%.1f,ry=%.1f,rz=%.1f},",
            p.x,p.y,p.z,p.rx or 0,p.ry or 0,p.rz or 0)
    end
    out[#out+1]="},"
    local s=table.concat(out,"\n")
    if typeof(setclipboard)=="function" then pcall(setclipboard,s) end
    return s
end

local function loadMap(name)
    local map=EmbeddedMaps[name]
    if not map then return false end
    recording={}
    for i,p in ipairs(map) do
        recording[i]={x=p.x,y=p.y,z=p.z,rx=p.rx or 0,ry=p.ry or 0,rz=p.rz or 0}
    end
    drawLine()
    return true
end

local function obstacle()
    local r=rootPart()
    if not r then return false end
    local rp=RaycastParams.new()
    rp.FilterType=Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances={char,lineFolder}
    local hit=workspace:Raycast(r.Position+Vector3.new(0,1.5,0),
        r.CFrame.LookVector*CFG.ObstacleDistance,rp)
    if not hit or not hit.Instance or not hit.Instance.CanCollide then return false end
    return hit.Normal.Y<=.65
end

local function stopPlayback()
    playing=false
    if playConn then playConn:Disconnect(); playConn=nil end
    if hum then hum:Move(Vector3.zero,false) end
end

local function speed()
    return speedMode=="Advanced Adaptive" and CFG.AdaptiveSpeed or CFG.DefaultSpeed
end

local function startPlayback()
    if playing or #recording<2 then return end
    local r=rootPart()
    if not r or not hum then return end

    playing=true
    index=math.clamp(index,1,#recording)

    playConn=RunService.Heartbeat:Connect(function()
        if not playing then return end
        r=rootPart()
        if not r or not hum or hum.Health<=0 then stopPlayback(); return end

        local target=recording[index]
        if not target then
            if loop then
                index=(direction==1) and 1 or #recording
                target=recording[index]
            else
                stopPlayback(); return
            end
        end

        -- Jangan menghentikan route saat airborne; biarkan jump/parabola selesai.
        if hum.FloorMaterial~=Enum.Material.Air and obstacle() then
            stopPlayback()
            return
        end

        local delta=pos(target)-r.Position
        if delta.Magnitude<=CFG.ReachDistance then
            index+=direction
            if index<1 or index>#recording then
                if loop then
                    index=(direction==1) and 1 or #recording
                else
                    stopPlayback(); return
                end
            end
            delta=pos(recording[index])-r.Position
        end

        if delta.Magnitude>.05 then
            local targetSpeed=speed()
            if speedMode=="Acceleration Dominant" then
                local diff=targetSpeed-hum.WalkSpeed
                local step=CFG.Acceleration*.05
                if math.abs(diff)<=step then hum.WalkSpeed=targetSpeed
                else hum.WalkSpeed+=math.sign(diff)*step end
            else
                hum.WalkSpeed=targetSpeed
            end
            hum:Move(delta.Unit,false)
        end
    end)
end

-- GUI
local gui=Instance.new("ScreenGui")
gui.Name="MaulzzPRESET_AutoWalk"
gui.ResetOnSpawn=false
gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
gui.Parent=Player:WaitForChild("PlayerGui")

local main=Instance.new("Frame")
main.Size=UDim2.fromOffset(390,510)
main.Position=UDim2.new(.5,-195,.5,-255)
main.BackgroundColor3=Color3.fromRGB(14,10,22)
main.BorderSizePixel=0
main.Parent=gui
Instance.new("UICorner",main).CornerRadius=UDim.new(0,14)
local ms=Instance.new("UIStroke",main)
ms.Color=Color3.fromRGB(150,80,255); ms.Thickness=1.5

local header=Instance.new("Frame",main)
header.Size=UDim2.new(1,0,0,64); header.BackgroundTransparency=1

local title=Instance.new("TextLabel",header)
title.BackgroundTransparency=1; title.Position=UDim2.fromOffset(18,8)
title.Size=UDim2.new(1,-70,0,27); title.Font=Enum.Font.GothamBold
title.TextSize=18; title.TextXAlignment=Enum.TextXAlignment.Left
title.TextColor3=Color3.fromRGB(235,220,255); title.Text=APP

local sub=Instance.new("TextLabel",header)
sub.BackgroundTransparency=1; sub.Position=UDim2.fromOffset(18,35)
sub.Size=UDim2.new(1,-70,0,18); sub.Font=Enum.Font.Gotham
sub.TextSize=11; sub.TextXAlignment=Enum.TextXAlignment.Left
sub.TextColor3=Color3.fromRGB(170,150,195)
sub.Text="Recording • Playback • Route"

local mini=Instance.new("TextButton",header)
mini.Size=UDim2.fromOffset(38,32); mini.Position=UDim2.new(1,-48,0,15)
mini.BackgroundColor3=Color3.fromRGB(38,28,52); mini.Text="—"
mini.TextColor3=Color3.fromRGB(230,210,255); mini.Font=Enum.Font.GothamBold
mini.TextSize=18
Instance.new("UICorner",mini).CornerRadius=UDim.new(0,9)

local scroll=Instance.new("ScrollingFrame",main)
scroll.Position=UDim2.fromOffset(12,68); scroll.Size=UDim2.new(1,-24,1,-80)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
scroll.ScrollBarThickness=4; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
local list=Instance.new("UIListLayout",scroll); list.Padding=UDim.new(0,8)
local pad=Instance.new("UIPadding",scroll); pad.PaddingBottom=UDim.new(0,14)

local function section(t)
    local l=Instance.new("TextLabel",scroll)
    l.Size=UDim2.new(1,-4,0,24); l.BackgroundTransparency=1
    l.Font=Enum.Font.GothamBold; l.TextSize=13
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Color3.fromRGB(190,150,255); l.Text=t
end

local function label(t)
    local l=Instance.new("TextLabel",scroll)
    l.Size=UDim2.new(1,-4,0,30); l.BackgroundTransparency=1
    l.Font=Enum.Font.Gotham; l.TextSize=11; l.TextWrapped=true
    l.TextXAlignment=Enum.TextXAlignment.Left
    l.TextColor3=Color3.fromRGB(160,150,175); l.Text=t
    return l
end

local function button(t,fn)
    local b=Instance.new("TextButton",scroll)
    b.Size=UDim2.new(1,-4,0,38); b.BackgroundColor3=Color3.fromRGB(28,21,39)
    b.BorderSizePixel=0; b.Font=Enum.Font.GothamMedium; b.TextSize=13
    b.TextColor3=Color3.fromRGB(235,230,245); b.Text=t
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
    local s=Instance.new("UIStroke",b); s.Color=Color3.fromRGB(62,44,84)
    b.MouseButton1Click:Connect(fn)
    return b
end

section("RECORDING")
local recLabel=label("Status: Idle • 0 waypoint")
button("🔴 Start Recording",function()
    startRecording()
    recLabel.Text="Status: Recording..."
end)
button("⏹ Stop Recording",function()
    stopRecording()
    recLabel.Text="Status: Idle • "..#recording.." waypoint"
    drawLine()
end)
button("💾 Save Recording",function()
    stopRecording()
    recLabel.Text="Saved in session • "..#recording.." waypoint"
    drawLine()
end)
button("📤 Export Recording",function()
    local s=exportRecording()
    recLabel.Text=s and "Export siap. Jika didukung, sudah dicopy ke clipboard." or "Tidak ada recording."
end)

section("MAPS")
local mapLabel=label("Map aktif: None")
button("📂 Load Map",function()
    local names={}
    for n in pairs(EmbeddedMaps) do names[#names+1]=n end
    table.sort(names)
    if #names==0 then
        mapLabel.Text="EmbeddedMaps kosong. Tempel hasil Export ke tabel EmbeddedMaps."
        return
    end
    if loadMap(names[1]) then
        mapLabel.Text="Map aktif: "..names[1].." • "..#recording.." waypoint"
    end
end)

section("PLAYBACK")
local playButton
playButton=button("▶ Jalan",function()
    if playing then
        stopPlayback()
        playButton.Text="▶ Jalan"
    else
        startPlayback()
        playButton.Text=playing and "⏹ Stop" or "▶ Jalan"
    end
end)
button("◀ Mundur",function()
    direction=-1; index=#recording
    recLabel.Text="Arah: Mundur"
end)
button("▶ Maju",function()
    direction=1; index=1
    recLabel.Text="Arah: Maju"
end)
button("🔁 Loop: OFF",function(b)
    -- callback tidak menerima b; tombol diubah dari closure berikut
end)

-- Ubah tombol loop secara langsung agar tidak perlu state GUI terpisah.
local loopButton=scroll:GetChildren()[#scroll:GetChildren()]
if loopButton and loopButton:IsA("TextButton") then
    loopButton.MouseButton1Click:Connect(function()
        loop=not loop
        loopButton.Text="🔁 Loop: "..(loop and "ON" or "OFF")
    end)
end

section("SPEED MODE")
local speedButton
speedButton=button("⚡ Acceleration Dominant",function()
    if speedMode=="Acceleration Dominant" then
        speedMode="Advanced Adaptive"
        speedButton.Text="🧠 Advanced Adaptive"
    else
        speedMode="Acceleration Dominant"
        speedButton.Text="⚡ Acceleration Dominant"
    end
end)

section("VISUAL / SYSTEM")
local lineButton
lineButton=button("👁 Show Line Jalur: OFF",function()
    showLine=not showLine
    lineButton.Text="👁 Show Line Jalur: "..(showLine and "ON" or "OFF")
    drawLine()
end)

local lockButton
lockButton=button("🔓 Floating UI Lock: OFF",function()
    locked=not locked
    lockButton.Text=locked and "🔒 Floating UI Lock: ON" or "🔓 Floating UI Lock: OFF"
end)

local streamerButton
streamerButton=button("🎥 Streamer Mode: OFF",function()
    streamer=not streamer
    streamerButton.Text="🎥 Streamer Mode: "..(streamer and "ON" or "OFF")
end)

label("Obstacle berubah → playback berhenti. Saat airborne, obstacle check ditahan agar jump dapat menyelesaikan parabola.")

-- Drag: mulai selalu unlocked
local dragging=false
local dragStart,startPos
header.InputBegan:Connect(function(i)
    if locked then return end
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
        dragging=true; dragStart=i.Position; startPos=main.Position
        i.Changed:Connect(function()
            if i.UserInputState==Enum.UserInputState.End then dragging=false end
        end)
    end
end)
UIS.InputChanged:Connect(function(i)
    if not dragging or locked then return end
    if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
        local d=i.Position-dragStart
        main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
    end
end)

-- Floating mini button
local float=Instance.new("TextButton",gui)
float.Size=UDim2.fromOffset(54,54); float.Position=UDim2.new(0,18,.5,-27)
float.BackgroundColor3=Color3.fromRGB(25,17,35); float.Text="AW"
float.TextColor3=Color3.fromRGB(220,190,255); float.Font=Enum.Font.GothamBold
float.TextSize=15; float.Visible=false
Instance.new("UICorner",float).CornerRadius=UDim.new(1,0)
local fs=Instance.new("UIStroke",float); fs.Color=Color3.fromRGB(150,80,255); fs.Thickness=2

mini.MouseButton1Click:Connect(function()
    main.Visible=false; float.Visible=true
end)
float.MouseButton1Click:Connect(function()
    main.Visible=true; float.Visible=false
end)

-- PC Streamer shortcut: RightShift
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.RightShift then
        streamer=not streamer
        main.Visible=not streamer
        float.Visible=streamer
    end
end)

-- Mobile recovery: tap 3x top-left
local taps,lastTap=0,0
UIS.InputBegan:Connect(function(i,gp)
    if gp or i.UserInputType~=Enum.UserInputType.Touch then return end
    if i.Position.X<=90 and i.Position.Y<=90 then
        local now=os.clock()
        if now-lastTap>1.2 then taps=0 end
        taps+=1; lastTap=now
        if taps>=3 then
            taps=0; streamer=false; main.Visible=true; float.Visible=false
        end
    end
end)

print("["..APP.."] Loaded")
