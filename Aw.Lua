--// =========================================================
--// GENERATED FULL FIX BY GPT - AUTO MAP CLEAN SPEED PATCH record udah bener gak bug
--// File ini dibuat dari script yang kamu upload.
--// Fokus fix: SAVE tetap hapus kedut, tapi speed normal map/coil dikunci otomatis.
--// =========================================================

--// =========================================================
--// ONIUM Recorder / BittWise Recorder
--// Delta + Xeno Mobile Friendly
--// FULL BITWISE SUPPORT + RAW MOMENTUM + ANTI KEDUT + SAFE ROLLBACK + CP MARKER
--// PATCH: AUTO MAP CLEAN + ANTI KEDUT + NORMAL SPEED LOCK
--// PATCH 2026-05-28: TRAMPOLINE JUMP LAUNCH ONLY FIX - pas terjun tetap, lompat trampoline lebih natural
--// =========================================================

--// Anti duplicate
local ENV = _G
pcall(function()
    if getgenv then
        ENV = getgenv()
    end
end)

if ENV.__ONIUM_RECORDER_CLEANUP then
    pcall(ENV.__ONIUM_RECORDER_CLEANUP)
end

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// Config
local FOLDER_NAME = "ONIUM_RECORDER"
local CUSTOM_LOGO_ASSET = "rbxassetid://130280202431400"
local USE_NATURAL_MAP_JUMP = true
local USE_MAP_WALKSPEED_ON_PLAYBACK = true
local USE_MAP_HIPHEIGHT_ON_PLAYBACK = true
local SAMPLE_INTERVAL = 0.004 -- RAW recorder: sample rapat, times tetap waktu asli


--// =========================================================
--// WEB UPLOAD + MERGE FAST PATCH 2026-05-17
--// Fokus patch ini hanya upload web + merge/save agar lebih ringan.
--// Cleaner anti blink / anti speed spike lama TIDAK dimatikan.
--// =========================================================
local AUTO_UPLOAD_API_URL = "https://kingstrom.my.id/gunung_api.php"
local AUTO_UPLOAD_API_URLS = {
    "https://kingstrom.my.id/gunung_api.php",
    "https://www.kingstrom.my.id/gunung_api.php",
    "https://kingstrom.my.id/public/gunung_api.php",
    "https://kingstrom.my.id/api/gunung_api.php",
    "https://kingstrom.my.id/backup/gunung_api.php"
}
local AUTO_UPLOAD_TOKEN = "ONIUM_UPLOAD_B2EF2EFA48AD790B36503EB6B159544F"
local AUTO_UPLOAD_DESCRIPTION = "Full Route"
local AUTO_UPLOAD_CHUNK_MIN_BYTES = 850000
local AUTO_UPLOAD_CHUNK_SIZE = 260000
local AUTO_UPLOAD_CHUNK_PROGRESS_EVERY = 5

-- Save besar ditulis bertahap agar merge tidak macet karena payload JSON raksasa.
local SAVE_STREAM_USE_APPEND = true
local SAVE_STREAM_BATCH_FRAMES = 650
local SAVE_STREAM_YIELD_FRAMES = 650

-- Merge tetap memakai final clean lama supaya bug blink/speed tidak balik,
-- tapi prosesnya dicicil dan titik merge dimatikan sementara agar PC tidak freeze.
local MERGE_FAST_YIELD_EVERY_FRAMES = 450
local MERGE_FAST_NOTIFY_EVERY_CP = 2
local MERGE_FAST_DISABLE_DOTS_DURING_PROCESS = true

-- Portal/teleport guard: untuk cut/seam jauh, reset state supaya tidak nyangkut/ngayang.
local PORTAL_CUT_RESET_ENABLED = true
local PORTAL_CUT_WAIT_FRAMES = 3
local PORTAL_CUT_DISTANCE = 18

--// =========================================================
--// AUTO MAP CLEAN SPEED FIX 2026-05-09
--// SAVE tetap menghapus kedut seperti versi lama, tetapi speed lari normal
--// dikunci otomatis mengikuti map/coil yang sedang dipakai.
--// Contoh: kalau map speed normal 51, frame belok/mundur yang turun jadi 30
--// akan dinaikkan kembali ke 51 tanpa hardcode angka 51.
--// =========================================================
local EXPORT_RAW_EXACT_MODE = true
local RAW_EXACT_KEEP_WALKSPEED = true
local RAW_EXACT_SAVE_WITHOUT_HEAVY_CLEANER = false
local RAW_EXACT_DISABLE_PREVIEW_SPEED_MULTIPLIER = true
local RAW_EXACT_MIN_DT = 0.001

local AUTO_MAP_CLEAN_SPEED_MODE = true
local AUTO_MAP_LOCK_RUN_SPEED = true
local AUTO_MAP_SPEED_MIN_SAMPLES = 6
local AUTO_MAP_SPEED_DROP_TOLERANCE = 0.94
local AUTO_MAP_SPEED_SPIKE_CAP_MULT = 1.10
local AUTO_MAP_SPEED_MIN_MOVEDIR = 0.045
local AUTO_MAP_SPEED_USE_TIMING_FIX = true
local AUTO_MAP_SPEED_MIN_DT = 0.0065
local AUTO_MAP_SPEED_MAX_DT = 0.140

--// PATCH LIGHT RECORD:
--// Record tetap akurat, tapi tidak lagi kerja berat setiap heartbeat.
--// 1) UI overlay di-update berkala, bukan 2x tiap frame.
--// 2) Ground raycast/cache tidak dipanggil setiap frame.
--// 3) Frame record dibatasi agar HP/Delta/Xeno tidak berat saat REC.
local RECORD_LIGHT_MODE = true
local RECORD_MIN_SAMPLE_DT = 0.0085      -- kira-kira max 117 fps; 60 fps tetap aman
local RECORD_AIR_SAMPLE_DT = 0.0065      -- saat jump/freefall boleh lebih rapat
local RECORD_UI_UPDATE_INTERVAL = 0.10
local RECORD_GROUND_CACHE_INTERVAL = 0.055
local RECORD_TOOL_CACHE_INTERVAL = 0.15

--// =========================================================
--// SMART RECORD (Anti Hold Jump Bug)
--// Mode default: DISABLED untuk rekam RAW semua frame jump
--// =========================================================
local SMART_RECORD_ENABLED = false    -- false = RAW Record (semua frame), true = Smart Record (debounce)
local SMART_JUMP_DEBOUNCE_TIME = 0.35 -- detik antara jump event agar tidak dobel saat hold

--// PLAYBACK STATE GUARD: cegah paksa Freefall saat climbing/obstacle
local PLAYBACK_STATE_GUARD = true
local PLAYBACK_CLIMB_PRIORITY = true
--// VELOCITY STRICT: jangan biarkan velocity playback lebih besar dari rekaman
local PLAYBACK_VELOCITY_STRICT = true

--// =========================================================
--// PLAYBACK ENGINE FIXES v3.0
--// BUG 1: Jump debounce terlalu agresif (0.18s) - tap jump delay
--// BUG 2: Jump sound dobel - tidak ada debounce per event
--// BUG 3: Footstep debounce terlalu tinggi
--// BUG 4: Speed tidak sync dengan coil yang aktif
--// BUG 5: Timing pakai akumulasi tick() bukan os.clock() absolut
--// =========================================================
local JUMP_COYOTE_DEBOUNCE_TIME = 0.035
local JUMP_VELOCITY_DISABLE_DURATION = 0.035
local JUMP_SOUND_DEBOUNCE_TIME = 0.30
local lastJumpSoundTime = 0
local FOOTSTEP_DEBOUNCE_DIST = 1.2
local PLAYBACK_DYNAMIC_SPEED_SYNC = true

--// =========================================================
--// PLAYBACK ENGINE FIXES v3.0 - COMPREHENSIVE
--// BUG 1 FIX: Jump stutter - jangan pakai hum.Jump=true (triggers built-in physics)
--// BUG 2 FIX: Double jump sound - debounce jump event per timestamp
--// BUG 3 FIX: Footstep/Surface effect - record material + replay footstep events
--// BUG 4 FIX: Speed coil sync - monitor WalkSpeed real-time
--// BUG 5 FIX: Timing - os.clock() absolut master clock tanpa drift
--// =========================================================
local PLAYBACK_JUMP_EVENT_DEBOUNCE = 0.25   -- detik antara jump event baru
local lastPlaybackJumpEventTime = -999       -- timestamp jump event terakhir
local lastPlaybackJumpFrameIdx = -1          -- frame index jump terakhir
local PLAYBACK_FOOTSTEP_ENABLED = true       -- aktifkan footstep replay
local PLAYBACK_FOOTSTEP_MIN_DT = 0.18       -- minimal dt antara footstep
local lastPlaybackFootstepTime = -999
local lastPlaybackFootstepMaterial = ""
local lastPlaybackFootstepPosition = nil
local PLAYBACK_SPEED_SYNC_THRESHOLD = 1.0   -- threshold perubahan WalkSpeed
local lastPlaybackMonitoredWs = -1
local PLAYBACK_JUMP_VELOCITY_APPLY_ORDER = "velocity_first" -- velocity dulu, baru state
local PLAYBACK_FOOTSTEP_MATERIALS = {
    Grass = {soundId = "rbxassetid://9125402735", particleColor = Color3.fromRGB(86, 120, 42)},
    Wood = {soundId = "rbxassetid://9125400964", particleColor = Color3.fromRGB(139, 90, 43)},
    Concrete = {soundId = "rbxassetid://9125401756", particleColor = Color3.fromRGB(128, 128, 128)},
    Metal = {soundId = "rbxassetid://9125402389", particleColor = Color3.fromRGB(180, 180, 200)},
    Sand = {soundId = "rbxassetid://9125403138", particleColor = Color3.fromRGB(220, 200, 140)},
    Mud = {soundId = "rbxassetid://9125403542", particleColor = Color3.fromRGB(90, 65, 35)},
    Stone = {soundId = "rbxassetid://9125401756", particleColor = Color3.fromRGB(160, 160, 160)},
    Default = {soundId = "rbxassetid://9125401756", particleColor = Color3.fromRGB(150, 150, 150)},
}
local PLAYBACK_FOOTSTEP_SOUNDS_CACHE = {}

--// Map nama material Roblox ke key PLAYBACK_FOOTSTEP_MATERIALS di atas.
--// Dipakai bersama record (makeFrame) dan playback (raycast/footstep) supaya
--// material yang tersimpan di frame selalu cocok dengan tabel efek.
--// Sengaja global (tanpa `local`): top-level chunk file ini sudah punya banyak
--// local, dan Lua/Luau membatasi jumlah local aktif per fungsi/chunk.
PLAYBACK_FOOTSTEP_MATERIAL_MAP = {
    Grass = "Grass", LeafyGrass = "Grass",
    Wood = "Wood", WoodPlanks = "Wood",
    Concrete = "Concrete", Slate = "Concrete", Granite = "Concrete",
    Marble = "Concrete", Brick = "Concrete", Pavement = "Concrete",
    Cobblestone = "Stone", Rock = "Stone", Limestone = "Stone",
    Basalt = "Stone", CrackedLava = "Stone", Pebble = "Stone",
    Metal = "Metal", DiamondPlate = "Metal", CorrodedMetal = "Metal",
    Sand = "Sand", Sandstone = "Sand",
    Mud = "Mud", Ground = "Default", Snow = "Default",
}

function mapFootstepMaterialName(materialName)
    local name = tostring(materialName or "")
    if name == "" then
        return "Default"
    end

    -- Terima juga format "Enum.Material.Grass" hasil tostring(Enum.Material.X)
    name = name:match("([^%.]+)$") or name

    if PLAYBACK_FOOTSTEP_MATERIALS[name] then
        return name
    end

    return PLAYBACK_FOOTSTEP_MATERIAL_MAP[name] or "Default"
end

--// =========================================================
--// BUG 3 FIX: Footstep/Surface Effect Replay System
--// Selama playback, deteksi material bawah kaki dan mainkan
--// sound + particle sesuai material yang terekam.
--// =========================================================
function playFootstepEffect(hrp, materialName)
    if not PLAYBACK_FOOTSTEP_ENABLED or not hrp then return end
    if not materialName or materialName == "" then materialName = "Default" end

    local now = os.clock()
    if (now - lastPlaybackFootstepTime) < PLAYBACK_FOOTSTEP_MIN_DT then return end
    if materialName == lastPlaybackFootstepMaterial and (now - lastPlaybackFootstepTime) < (PLAYBACK_FOOTSTEP_MIN_DT * 2) then return end

    lastPlaybackFootstepTime = now
    lastPlaybackFootstepMaterial = materialName

    local matData = PLAYBACK_FOOTSTEP_MATERIALS[materialName] or PLAYBACK_FOOTSTEP_MATERIALS.Default
    if not matData then return end

    --// Sound
    pcall(function()
        local soundId = matData.soundId
        if not soundId then return end
        if not PLAYBACK_FOOTSTEP_SOUNDS_CACHE[soundId] then
            local s = Instance.new("Sound")
            s.Name = "PB_Footstep"
            s.SoundId = soundId
            s.Volume = 0.35
            s.PlaybackSpeed = 0.9 + math.random() * 0.2
            s.Parent = hrp
            PLAYBACK_FOOTSTEP_SOUNDS_CACHE[soundId] = s
        end
        local snd = PLAYBACK_FOOTSTEP_SOUNDS_CACHE[soundId]
        snd.PlaybackSpeed = 0.85 + math.random() * 0.3
        snd:Play()
    end)

    --// Particle
    pcall(function()
        local color = matData.particleColor
        if not color then return end
        local p = Instance.new("ParticleEmitter")
        p.Color = ColorSequence.new(color)
        p.Size = NumberSequence.new(0.3, 0)
        p.Lifetime = NumberRange.new(0.2, 0.5)
        p.Speed = NumberRange.new(1, 3)
        p.SpreadAngle = Vector2.new(30, 30)
        p.Rate = 0
        p.Parent = hrp
        p:Emit(3)
        game:GetService("Debris"):AddItem(p, 0.6)
    end)
end

function detectPlaybackFootstepMaterial(hrp)
    if not hrp then return "Default" end
    local char = LocalPlayer.Character
    local params = RaycastParams.new()
    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
        params.FilterDescendantsInstances = char and { char } or {}
        params.IgnoreWater = true
    end)
    local ok, result = pcall(function()
        return workspace:Raycast(hrp.Position, Vector3.new(0, -5, 0), params)
    end)
    if ok and result and result.Instance then
        local mat = "Default"
        pcall(function()
            mat = tostring(result.Material and result.Material.Name or "Default")
        end)
        return mapFootstepMaterialName(mat)
    end
    return "Default"
end

--// BUG 4 FIX: Speed Coil Monitor - real-time WalkSpeed sync
function monitorPlaybackSpeedCoil(hum, recordedBaseSpeed, myToken)
    if not hum or not PLAYBACK_DYNAMIC_SPEED_SYNC then return end
    if myToken ~= playToken then return end

    local currentWs = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    if lastPlaybackMonitoredWs < 0 then
        lastPlaybackMonitoredWs = currentWs
        return
    end

    local wsDiff = math.abs(currentWs - lastPlaybackMonitoredWs)
    if wsDiff > PLAYBACK_SPEED_SYNC_THRESHOLD then
        -- WalkSpeed berubah (coil equip/unequip) → sinkronisasi
        lastPlaybackMonitoredWs = currentWs
    end
end

--// BUG 3 FIX: Footstep trigger berdasarkan gerakan kaki
function triggerPlaybackFootstepIfMoving(hum, hrp, fr, prevFr)
    if not PLAYBACK_FOOTSTEP_ENABLED or not hum or not hrp then return end
    if not fr then return end

    local st = tostring(fr.states or "")
    -- Hanya trigger footstep saat Running/Landed (di tanah)
    if st ~= "Running" and st ~= "Landed" then return end

    local city = tableToVec(fr.city)
    local hSpeed = Vector3.new(city.X, 0, city.Z).Magnitude
    if hSpeed < 3 then return end  -- terlalu pelan, jangan bunyi

    -- Trigger berdasarkan perpindahan kaki, bukan setiap frame Running.
    -- Ini penting saat mendarat di trampoline: state Running dapat bertahan
    -- beberapa frame dan tidak boleh menghasilkan suara loncat/footstep spam.
    local nowPos = hrp.Position
    local wasAir = prevFr and (
        prevFr.jump == true
        or prevFr.trampolineAir == true
        or isAirState(prevFr.states or prevFr.state)
    )
    local strideDistance = lastPlaybackFootstepPosition
        and (nowPos - lastPlaybackFootstepPosition).Magnitude
        or math.huge
    if not wasAir and lastPlaybackFootstepPosition and strideDistance < (FOOTSTEP_DEBOUNCE_DIST or 1.2) then
        return
    end
    lastPlaybackFootstepPosition = nowPos

    -- Deteksi material dari frame data atau raycast
    local matName = "Default"
    if fr.floorMaterial and fr.floorMaterial ~= "" and fr.floorMaterial ~= "Default" then
        matName = fr.floorMaterial
    else
        matName = detectPlaybackFootstepMaterial(hrp)
    end

    playFootstepEffect(hrp, matName)
end

--// PATCH RECORD STUTTER / BLING FIX:
--// Kalau HP/PC patah-patah saat record, biasanya ada gap waktu besar antar frame.
--// Gap itu bikin hasil save/play seperti blink/bling. Patch ini menyisipkan frame
--// bridge ringan di live record + saat save, jadi rute tetap halus walau device sempat macet.
local RECORD_STUTTER_GAP_DT = 0.075
local RECORD_STUTTER_MAX_STEP = 1.35
local RECORD_STUTTER_MAX_BRIDGE_DISTANCE = 45
local RECORD_STUTTER_INSERT_MAX = 35
local RECORD_STUTTER_AIR_INSERT_MAX = 28
local RECORD_STUTTER_MIN_DT = 0.0065
local RECORD_STUTTER_SAVE_FIX = true

--// PATCH BUG JUMP SETELAH SAVE -> RECORD LAGI:
--// Tap tombol UI di HP kadang ikut kebaca Jump/Freefall setelah save.
--// Start record sekarang punya jump guard lebih panjang dan frame air palsu awal diabaikan.
local RECORD_START_JUMP_SUPPRESS_SECONDS = 0.65
local RECORD_START_AIR_IGNORE_SECONDS = 0.45

--// Playback speed mode dibuat sama seperti ONIUM Race:
--// angka speed = stud/s, bukan multiplier x.
local MIN_PLAYBACK_SPEED = 8
local MAX_PLAYBACK_SPEED = 500000
local DEFAULT_PLAYBACK_SPEED = 16

--// FORMAT JSON KHUSUS BITWISE
--// Samakan dengan JSON normal kedua.
local BITWISE_JSON_WALKSPEED = 45
local BITWISE_CLIMB_Y_SPEED = 31.5
local BITWISE_AIR_Y_SPEED = 50.7
local BITWISE_AIR_MIN_HSPEED = 45
local BITWISE_JSON_HIPHEIGHT = 5.331189155578613

--// Filter record agar avatar diam tidak masuk JSON
local MIN_RECORD_DISTANCE = 0.09
local MIN_VERTICAL_DISTANCE = 0.6
local MIN_MOVE_DIRECTION = 0.02
local MIN_HORIZONTAL_VELOCITY = 0.15

--// Filter merge agar idle frame dibuang
local CLEAN_DISTANCE_THRESHOLD = 0.07
local CLEAN_VERTICAL_THRESHOLD = 0.10

--// Smooth playback / merge anti-blink
local MAX_PLAYBACK_WAIT = 0.18
local PLAYBACK_MIN_DURATION = 0.004
local PLAYBACK_STEP_DISTANCE = 0.85
local PLAYBACK_MIN_STEP_DISTANCE = 0.04
local PLAYBACK_HOLD_FINAL_TIME = 0

--// FIX PLAY AFTER FINISH:
--// Kalau avatar masih berdiri di posisi FINISH lalu PLAY lagi, langsung balik ke START.
--// Kalau avatar sudah jauh dari FINISH, smart resume tetap mulai dari titik path terdekat.
local PLAY_AGAIN_FINISH_RESET_DISTANCE = 18
local PLAY_AGAIN_FINISH_TIME_WINDOW = 0.12

--// FIX LOOP SPEED:
--// Pengaman agar mode loop/toggle loop dari versi UI lain tidak membuat velocity dobel/kenceng.
local LOOP_SPEED_SAFE_CAP_MULTIPLIER = 1.12

--// Speed sync limiter:
--// Export JSON akan retime berdasarkan jarak / speed set, supaya saat di-load di ONIUM Race
--// speedometer tidak tembus jauh di atas angka yang kamu set.
local SPEED_TIMING_MIN_DT = 0.006
local SPEED_TIMING_MAX_DT = 0.18
local SPEED_HARD_CAP_MULTIPLIER = 1.03

--// Jangan tarik karakter untuk jarak jauh.
--// Kalau jarak antar frame/antar file terlalu jauh, playback akan cut/teleport sekali, bukan ditarik bolak-balik.
local PLAYBACK_MAX_SMOOTH_DISTANCE = 10
local BRIDGE_STEP_DISTANCE = 0.85
local MERGE_SKIP_JOIN_DISTANCE = 0.35
local MERGE_MAX_BRIDGE_DISTANCE = 10
local MAX_BRIDGE_FRAMES = 80

--// Ground / object detector untuk rollback ke object terakhir yang diinjak
local GROUND_RAY_DISTANCE = 9
local ROLLBACK_OBJECT_HARD_LIMIT = 800

--// Rollback
local ROLLBACK_SECONDS = 2.5
local ROLLBACK_MAX_FRAMES = math.max(5, math.floor(ROLLBACK_SECONDS / SAMPLE_INTERVAL))

--// UI Vars
local ScreenGui
local MainFrame
local MiniLogo
local RecordOverlay
local ToastLabel

local searchBox
local saveNameBox
local uploadNameBox
local speedBox
local listFrame
local listLayout
local timerLabel
local overlayStatusLabel
local frameCountLabel
local cpMarkerToggleBtn

--// Data State
local checkpoints = {}
local nextOrder = 1

--// TITIK PETUNJUK SAMBUNGAN CP
local seamDotFolder = nil
local MERGE_DOT_ENABLED = true
local MERGE_DOT_COUNT = 12
local MERGE_DOT_SIZE = 0.46
local MERGE_DOT_HEIGHT = 0.35

--// TANDA PER CP + SAMBUNGAN MERGE
--// Default OFF supaya saat SAVE tidak freeze/render berat.
local CP_MARKER_ENABLED = false
local CP_MARKER_SELECTED_NAME = nil -- nil = semua CP, string = hanya 1 checkpoint
local CP_MARKER_CULLER_TOKEN = 0
local CP_MARKER_DOT_COUNT = 6
local CP_MARKER_SIZE = 0.42
local CP_MARKER_HEIGHT = 1.25
local CP_MARKER_MAX_PER_CP = 8
--// Marker CP jangan ganggu layar: hanya kelihatan kalau dekat.
CP_MARKER_LABEL_MAX_DISTANCE = 45
CP_MARKER_VISIBLE_DISTANCE = 70
CP_MARKER_CULL_INTERVAL = 0.35

local recordFrames = {}
local temporaryRecord = {}

local isRecording = false
local isRollbacking = false
local rollbackCancel = false
local rollbackToken = 0
local isPlaying = false
local playToken = 0
local isMerging = false

--// FIX ROLLBACK FREEFALL:
--// Setelah rollback, ada window waktu di mana frame Freefall/FallingDown palsu
--// akibat physics bounce tidak boleh direkam. Variable ini di-set oleh rollback.
local ignoreAirFramesUntil = 0

--// Speed sync seperti ONIUM Race
--// currentPlaybackSpeed = speed yang kamu set dari speedometer / manual.
--// syncBaseSpeed = speed dasar yang akan ditulis ke JSON sebagai ws.
--// ONIUM Race menghitung: speedMultiplier = currentPlaybackSpeed / recordedBaseSpeed.
--// Jadi kalau di ONIUM Race kamu Set Speed dari speedometer dengan angka yang sama,
--// replay akan jalan normal/sinkron.
local currentPlaybackSpeed = DEFAULT_PLAYBACK_SPEED
local syncBaseSpeed = DEFAULT_PLAYBACK_SPEED

local recordConnection = nil
local allConnections = {}

--// Record cursor position supaya setelah rollback record lanjut smooth
local lastRecordSavedPos = nil
local recordStartClock = 0

--// FIX COIL SPEED:
--// Jangan biarkan rollback / stop record menurunkan speed coil.
--// Kita simpan speed humanoid sebelum record dan speed tertinggi saat tool/coil dipakai.
local preRecordWalkSpeed = nil
local lastKnownToolWalkSpeed = nil
local lastKnownEquippedTool = ""

--// FIX MAP SPEED AFTER PREVIEW/PLAY STOP:
--// Setiap map bisa punya WalkSpeed berbeda.
--// Jadi speed asli map disimpan SEBELUM preview/playback, lalu dipakai lagi saat stop/finish.
--// Jangan memakai currentPlaybackSpeed/syncBaseSpeed sebagai speed normal map.
local prePlaybackMapWalkSpeed = nil
local prePlaybackHadTool = false

function hasEquippedToolSafe(char)
    char = char or LocalPlayer.Character
    if not char then
        return false
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            lastKnownEquippedTool = obj.Name
            return true
        end
    end

    return false
end

function captureMapSpeedBeforePlayback()
    local char, hum = getCharacter()
    if not hum then
        return
    end

    --// Ambil speed asli sebelum playback mengubah Humanoid.WalkSpeed.
    prePlaybackMapWalkSpeed = tonumber(hum.WalkSpeed) or DEFAULT_PLAYBACK_SPEED
    prePlaybackHadTool = hasEquippedToolSafe(char)
end

--// Forward
local refreshList
local playCheckpoint
local stopPlayback
local startRecording
local stopRecording
local rollbackRecording
local saveTemporaryRecord
local importLoad
local deleteAllCheckpoints
local mergeCheckpoints

--// =========================================================
--// Utility
--// =========================================================

function addConnection(c)
    if c then
        table.insert(allConnections, c)
    end
    return c
end

function cleanup()
    pcall(function()
        if recordConnection then
            recordConnection:Disconnect()
            recordConnection = nil
        end
    end)

    for _, c in ipairs(allConnections) do
        pcall(function()
            c:Disconnect()
        end)
    end

    playToken = playToken + 1
    isPlaying = false
    isRecording = false
    isRollbacking = false

    --// Hapus titik sambungan kalau script diexecute ulang / diclose
    pcall(function()
        if seamDotFolder then
            seamDotFolder:Destroy()
            seamDotFolder = nil
        end

        local old = workspace:FindFirstChild("ONIUM_MERGE_DOTS")
        if old then
            old:Destroy()
        end

        local oldCp = workspace:FindFirstChild("ONIUM_CP_MARKERS")
        if oldCp then
            oldCp:Destroy()
        end
    end)

    pcall(function()
        if ScreenGui then
            ScreenGui:Destroy()
        end
    end)
end

ENV.__ONIUM_RECORDER_CLEANUP = cleanup

function roundNumber(n, dec)
    dec = dec or 3
    local mult = 10 ^ dec
    n = tonumber(n) or 0
    if n ~= n then n = 0 end -- NaN
    if n == math.huge or n == -math.huge then n = 0 end
    local r = math.floor(n * mult + 0.5) / mult
    if r ~= r then return 0 end -- NaN safety
    return r
end

function parseSpeedValue(raw, fallback)
    raw = tostring(raw or fallback or DEFAULT_PLAYBACK_SPEED)
    raw = raw:gsub(",", ".")
    raw = raw:gsub("[^%d%.%-]", "")

    local spd = tonumber(raw) or tonumber(fallback) or DEFAULT_PLAYBACK_SPEED
    spd = math.clamp(spd, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)

    return roundNumber(spd, 1)
end

function setSyncBaseSpeed(value, updateBox)
    local spd = parseSpeedValue(value, syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED)

    currentPlaybackSpeed = spd
    syncBaseSpeed = spd

    if updateBox and speedBox then
        speedBox.Text = tostring(spd)
    end

    return spd
end

function readSpeedBoxToSync()
    if speedBox then
        return setSyncBaseSpeed(speedBox.Text, false)
    end

    return setSyncBaseSpeed(syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED, false)
end

function getExportSyncSpeed()
    return parseSpeedValue(syncBaseSpeed or currentPlaybackSpeed or DEFAULT_PLAYBACK_SPEED, DEFAULT_PLAYBACK_SPEED)
end

function trimText(s)
    s = tostring(s or "")
    s = s:gsub("^%s+", "")
    s = s:gsub("%s+$", "")
    return s
end

function cleanFileName(s)
    s = trimText(s)
    s = s:gsub("[^%w_%-]", "_")
    if s == "" then
        s = "checkpoint"
    end
    return s
end

function vecToTable(v)
    -- RAW precision: jangan bulatkan 4 digit, karena city/position contoh JSON punya detail banyak.
    return {
        x = roundNumber(v.X, 9),
        y = roundNumber(v.Y, 9),
        z = roundNumber(v.Z, 9)
    }
end

function tableToVec(t)
    if type(t) ~= "table" then
        return Vector3.new(0, 0, 0)
    end

    return Vector3.new(
        tonumber(t.x) or 0,
        tonumber(t.y) or 0,
        tonumber(t.z) or 0
    )
end

--// =========================================================
--// PATCH 2026-05-28: TRAMPOLINE RAW TIMING ONLY FIX
--// Fokus: trampoline/lompat tinggi jangan terasa slow lalu kenceng saat hasil record diplay.
--// Patch ini hanya melindungi frame udara dengan velocity Y besar.
--// Lari biasa, gundukan, merge, upload, UI, dan fitur lain tidak diubah.
--// =========================================================
local TRAMPOLINE_RAW_TIMING_FIX = true
local TRAMPOLINE_HIGH_Y_SPEED = 58       -- di atas jump normal; aman dari gundukan/tanah tidak rata
local TRAMPOLINE_FALL_Y_SPEED = 58       -- jatuh cepat setelah trampoline ikut dilindungi
local TRAMPOLINE_RAW_MIN_DT = 0.004
local TRAMPOLINE_RAW_MAX_DT = 0.090      -- cukup besar untuk natural, tapi tetap buang freeze panjang
local TRAMPOLINE_MARK_NEIGHBOR_FRAMES = 3

--// =========================================================
--// PATCH FIX TANJAKAN / SLOPE GROUND STATE
--// Saat lari di tanjakan, Humanoid kadang sesaat lapor Freefall/FallingDown
--// padahal kaki masih menapak permukaan. Patch ini: kalau FloorMaterial masih
--// menyentuh ground (bukan Air) dan velocity Y masih dalam batas wajar tanjakan,
--// state dipertahankan Running. Freefall/FallingDown HANYA dipaksa kalau benar-benar
--// lepas dari ground. Threshold dibuat agar lompat asli (vel.Y besar) tetap kebaca.
local SLOPE_KEEP_RUNNING_FIX = true
local SLOPE_KEEP_RUNNING_MAX_RISE_Y = 22   -- naik tanjakan: di bawah ini & masih napak = Running
local SLOPE_KEEP_RUNNING_MAX_FALL_Y = 22   -- turun tanjakan: di atas -ini & masih napak = Running

function isGroundedNowSafe(hum, hrp)
    -- Cek murah: FloorMaterial bukan Air berarti Humanoid sedang menapak.
    local grounded = false
    pcall(function()
        if hum and hum.FloorMaterial ~= nil and hum.FloorMaterial ~= Enum.Material.Air then
            grounded = true
        end
    end)

    if grounded then
        return true
    end

    -- Fallback ringan: raycast pendek ke bawah (untuk executor yang FloorMaterial-nya tidak akurat).
    if hrp then
        local g = getGroundInfo(hrp)
        if type(g) == "table" and g.hitPosition then
            local hitY = tonumber(g.hitPosition.y)
            if hitY then
                -- jarak kaki ke ground kecil = masih napak.
                if (hrp.Position.Y - hitY) <= ((GROUND_RAY_DISTANCE or 9) * 0.6) then
                    return true
                end
            end
        end
    end

    return false
end

function trampolineFixState(fr)
    return tostring(fr and (fr.states or fr.state) or "")
end

function trampolineFixCity(fr)
    return tableToVec(fr and fr.city)
end

function trampolineFixRawTime(fr)
    return tonumber(fr and (fr.rawTimes or fr.rawTime or fr.originalTimes or fr.originalTime or fr.times or fr.t)) or 0
end

function trampolineFixIsAir(fr)
    local st = trampolineFixState(fr)
    return fr and (
        fr.jump == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
    )
end

function trampolineFixIsHighVertical(fr)
    if not TRAMPOLINE_RAW_TIMING_FIX or type(fr) ~= "table" then
        return false
    end

    if fr.trampolineJump == true or fr.trampolineAir == true then
        return true
    end

    local y = trampolineFixCity(fr).Y
    if y >= (TRAMPOLINE_HIGH_Y_SPEED or 58) then
        return true
    end
    if y <= -(TRAMPOLINE_FALL_Y_SPEED or 58) then
        return true
    end

    return false
end

function trampolineFixIsProtectedFrame(fr)
    if not TRAMPOLINE_RAW_TIMING_FIX or type(fr) ~= "table" then
        return false
    end

    if trampolineFixIsHighVertical(fr) then
        return true
    end

    -- Kalau sudah diberi marker dari area trampoline, ikut lindungi beberapa frame sekitar launch/fall.
    return fr.trampolineAir == true
end

function trampolineFixPair(a, b)
    if not TRAMPOLINE_RAW_TIMING_FIX then
        return false
    end

    return trampolineFixIsProtectedFrame(a)
        or trampolineFixIsProtectedFrame(b)
        or (trampolineFixIsAir(a) and trampolineFixIsAir(b)
            and (math.abs(trampolineFixCity(a).Y) >= (TRAMPOLINE_FALL_Y_SPEED or 58) * 0.72
                or math.abs(trampolineFixCity(b).Y) >= (TRAMPOLINE_FALL_Y_SPEED or 58) * 0.72))
end

function trampolineFixRawDt(a, b, fallback)
    local raw = trampolineFixRawTime(b) - trampolineFixRawTime(a)
    if raw <= 0 then
        raw = tonumber(fallback) or (SAMPLE_INTERVAL or 0.004)
    end

    -- Freeze HP yang ekstrem tetap dipotong, tapi timing trampoline normal tidak dipadatkan lagi.
    return math.clamp(
        raw,
        TRAMPOLINE_RAW_MIN_DT or 0.004,
        TRAMPOLINE_RAW_MAX_DT or 0.090
    )
end

function trampolineFixMarkFrames(frames)
    if not TRAMPOLINE_RAW_TIMING_FIX or type(frames) ~= "table" or #frames <= 0 then
        return frames
    end

    local out = deepCopy(frames)
    local span = tonumber(TRAMPOLINE_MARK_NEIGHBOR_FRAMES) or 3

    for i, fr in ipairs(out) do
        if trampolineFixIsHighVertical(fr) then
            local fromIndex = math.max(1, i - span)
            local toIndex = math.min(#out, i + span)
            for j = fromIndex, toIndex do
                if type(out[j]) == "table" and trampolineFixIsAir(out[j]) then
                    out[j].trampolineAir = true
                    if trampolineFixCity(out[j]).Y > 0 then
                        out[j].trampolineJump = true
                    end
                end
            end
        end
    end

    return out
end

function trampolineFixProtectTimes(frames)
    if not TRAMPOLINE_RAW_TIMING_FIX or type(frames) ~= "table" or #frames <= 1 then
        return frames
    end

    local src = trampolineFixMarkFrames(frames)
    local out = {}
    local t = 0

    for i, fr in ipairs(src) do
        local copy = deepCopy(fr)

        if i == 1 then
            t = 0
        else
            local prevSrc = src[i - 1]
            local oldDt = (tonumber(fr.times) or tonumber(fr.t) or 0) - (tonumber(prevSrc.times) or tonumber(prevSrc.t) or 0)

            if trampolineFixPair(prevSrc, fr) then
                t = t + trampolineFixRawDt(prevSrc, fr, oldDt)
            else
                if oldDt <= 0 then
                    oldDt = SAMPLE_INTERVAL or 0.004
                end
                t = t + oldDt
            end
        end

        copy.times = roundNumber(t, 9)
        copy.t = copy.times
        table.insert(out, copy)
    end

    return out
end



--// =========================================================
--// PATCH 2026-05-28: TRAMPOLINE UP-HAND ANIMATION ONLY FIX
--// Fokus: posisi/timing trampoline tetap dari patch raw timing,
--// tetapi animasi tangan saat naik tidak dipaksa Jumping terus-menerus.
--// Dalam 1 loncatan tinggi: Jump hanya di awal launch, sisanya Freefall/air.
--// Ini hanya aktif untuk vertical tinggi/trampoline; lari, gundukan, merge, UI tidak diubah.
--// =========================================================
local TRAMPOLINE_UP_HAND_ANIM_FIX = true
local TRAMPOLINE_ARM_MIN_HEIGHT = 10.0
local TRAMPOLINE_ARM_CHAIN_Y_SPEED = 12.0
local TRAMPOLINE_ARM_LAUNCH_TIME = 0.135
local TRAMPOLINE_ARM_CHAIN_MAX_GAP = 0.18

--// PATCH 2026-05-28: TRAMPOLINE SINGLE FALL PHASE FIX
--// Freefall tidak boleh dimulai berulang / terlalu cepat saat avatar masih naik.
--// Dalam 1 loncatan trampoline: Jumping stabil sampai benar-benar mulai turun,
--// lalu Freefall sekali sampai mendarat. Timing/posisi/speed tidak diubah.
local TRAMPOLINE_ARM_FALL_START_Y_SPEED = -2.0
local TRAMPOLINE_ARM_PEAK_DROP = 0.22

--// PATCH 2026-05-28: TRAMPOLINE JUMP LAUNCH ONLY FIX
--// Fall/terjun sudah enak, jadi jangan disentuh.
--// Yang diubah hanya fase LOMPAT/launch: Jumping jangan ditahan sampai puncak,
--// karena itu bisa membuat tangan trampoline terlihat tidak natural.
--// Setelah pulse jump awal selesai, state jadi air/Freefall kontinu sampai fase turun.
local TRAMPOLINE_ARM_JUMP_LAUNCH_HOLD_TIME = 0.115
local TRAMPOLINE_ARM_JUMP_MIN_HOLD_FRAMES = 3
local TRAMPOLINE_ARM_JUMP_MAX_HOLD_FRAMES = 8

function trampolineAnimTime(fr)
    return tonumber(fr and (fr.rawTimes or fr.rawTime or fr.originalTimes or fr.originalTime or fr.times or fr.t)) or 0
end

function trampolineAnimPosY(fr)
    local p = tableToVec(fr and fr.position)
    return p.Y
end

function trampolineAnimYVel(fr)
    return trampolineFixCity(fr).Y
end

function trampolineAnimIsAirLike(fr)
    if type(fr) ~= "table" then
        return false
    end
    local st = trampolineFixState(fr)
    local yv = trampolineAnimYVel(fr)
    return fr.jump == true
        or fr.trampolineAir == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
        or math.abs(yv) >= (TRAMPOLINE_ARM_CHAIN_Y_SPEED or 12)
end

function trampolineAnimIsHighFrame(fr)
    if type(fr) ~= "table" then
        return false
    end
    if trampolineFixIsHighVertical and trampolineFixIsHighVertical(fr) then
        return true
    end
    local yv = math.abs(trampolineAnimYVel(fr))
    return yv >= math.max(tonumber(TRAMPOLINE_HIGH_Y_SPEED) or 58, 58)
end

function trampolineAnimCanExtendChain(frA, frB)
    if type(frB) ~= "table" then
        return false
    end
    if not trampolineAnimIsAirLike(frB) then
        return false
    end
    if type(frA) == "table" then
        local gap = math.abs(trampolineAnimTime(frB) - trampolineAnimTime(frA))
        if gap > (TRAMPOLINE_ARM_CHAIN_MAX_GAP or 0.18) then
            return false
        end
    end
    return true
end

function trampolineAnimLockOneChain(out, startIndex, endIndex)
    if not TRAMPOLINE_UP_HAND_ANIM_FIX then
        return 0
    end
    if type(out) ~= "table" or not startIndex or not endIndex or endIndex < startIndex then
        return 0
    end

    local minY, maxY = math.huge, -math.huge
    local maxAbsVel = 0
    local launchIndex = nil

    for i = startIndex, endIndex do
        local fr = out[i]
        if type(fr) == "table" then
            local y = trampolineAnimPosY(fr)
            minY = math.min(minY, y)
            maxY = math.max(maxY, y)
            local yv = trampolineAnimYVel(fr)
            maxAbsVel = math.max(maxAbsVel, math.abs(yv))
            if not launchIndex and (yv >= ((TRAMPOLINE_HIGH_Y_SPEED or 58) * 0.45) or trampolineFixState(fr) == "Jumping" or fr.jump == true) then
                launchIndex = i
            end
        end
    end

    local height = maxY - minY
    local highEnough = height >= (TRAMPOLINE_ARM_MIN_HEIGHT or 10)
        or maxAbsVel >= math.max(tonumber(TRAMPOLINE_HIGH_Y_SPEED) or 58, 58)

    if not highEnough then
        return 0
    end

    launchIndex = launchIndex or startIndex

    -- Cari titik awal TURUN yang stabil.
    -- Bagian ini tetap sama seperti fix sebelumnya karena user bilang terjun sudah oke.
    local fallStartIndex = nil
    local peakY = trampolineAnimPosY(out[launchIndex])
    local peakIndex = launchIndex

    for i = launchIndex, endIndex do
        local fr = out[i]
        if type(fr) == "table" then
            local y = trampolineAnimPosY(fr)
            local yv = trampolineAnimYVel(fr)
            if y > peakY then
                peakY = y
                peakIndex = i
            end

            if i > launchIndex then
                local dropFromPeak = peakY - y
                if yv <= (TRAMPOLINE_ARM_FALL_START_Y_SPEED or -2.0)
                    or (i > peakIndex and dropFromPeak >= (TRAMPOLINE_ARM_PEAK_DROP or 0.22))
                then
                    fallStartIndex = i
                    break
                end
            end
        end
    end

    -- Kalau belum turun jelas, jangan paksa titik jatuh.
    fallStartIndex = fallStartIndex or (endIndex + 1)

    -- PATCH LOMPAT TRAMPOLINE SAJA:
    -- Jumping hanya dipakai di awal launch, tidak ditahan sampai puncak.
    -- Ini membuat tangan saat terpental trampoline lebih mirip normal main,
    -- sementara fase turun/freefall yang sudah enak tetap kontinu.
    local jumpEndIndex = launchIndex
    local launchTime = trampolineAnimTime(out[launchIndex])
    local minHold = math.max(1, tonumber(TRAMPOLINE_ARM_JUMP_MIN_HOLD_FRAMES) or 3)
    local maxHold = math.max(minHold, tonumber(TRAMPOLINE_ARM_JUMP_MAX_HOLD_FRAMES) or 8)
    local holdTime = tonumber(TRAMPOLINE_ARM_JUMP_LAUNCH_HOLD_TIME) or 0.115
    local holdCount = 0

    for i = launchIndex, math.min(endIndex, fallStartIndex - 1) do
        local fr = out[i]
        if type(fr) == "table" then
            holdCount = holdCount + 1
            local dtFromLaunch = trampolineAnimTime(fr) - launchTime
            if holdCount <= minHold or (dtFromLaunch <= holdTime and holdCount <= maxHold) then
                jumpEndIndex = i
            else
                break
            end
        end
    end

    if jumpEndIndex >= fallStartIndex then
        jumpEndIndex = math.max(launchIndex, fallStartIndex - 1)
    end

    local changed = 0
    local firstJumpDone = false

    for i = launchIndex, endIndex do
        local fr = out[i]
        if type(fr) == "table" then
            fr.trampolineAnimLocked = true
            fr.trampolineSingleFallPhase = true

            if i <= jumpEndIndex then
                -- Fase launch/lompat awal: cukup pendek supaya tangan tidak tertahan di pose jump.
                fr.states = "Jumping"
                fr.state = "Jumping"
                fr.rawState = "Jumping"
                fr.originalState = "Jumping"

                fr.jump = not firstJumpDone
                fr.rawJump = not firstJumpDone
                fr.originalJump = not firstJumpDone
                fr.trampolineAnimState = "Jumping"
                fr.trampolineAnimJump = not firstJumpDone
                fr.trampolineLaunchLocked = true
                firstJumpDone = true

            elseif i < fallStartIndex then
                -- PATCH FIX NAIK TRAMPOLINE / HABEG NAGA:
                -- Selama avatar MASIH NAIK (sebelum puncak/fallStartIndex), animasi tetap
                -- Jumping. Freefall TIDAK boleh muncul saat naik supaya tidak terbaca jatuh
                -- berulang. Jump impuls hanya di frame launch (firstJumpDone di atas),
                -- sisanya cukup state Jumping tanpa relaunch.
                -- Timing/posisi/city/speed tidak diubah.
                fr.states = "Jumping"
                fr.state = "Jumping"
                fr.rawState = "Jumping"
                fr.originalState = "Jumping"

                fr.jump = false
                fr.rawJump = false
                fr.originalJump = false
                fr.trampolineAnimState = "Jumping"
                fr.trampolineAnimJump = false
                fr.trampolineRiseAir = false

            else
                -- Fase turun: tetap dari fix sebelumnya, jangan diubah lagi.
                fr.states = "Freefall"
                fr.state = "Freefall"
                fr.rawState = "Freefall"
                fr.originalState = "Freefall"

                fr.jump = false
                fr.rawJump = false
                fr.originalJump = false
                fr.trampolineAnimState = "Freefall"
                fr.trampolineAnimJump = false
                fr.trampolineFallLocked = true
            end

            changed = changed + 1
        end
    end

    return changed
end

function trampolineAnimLockForExport(frames)
    if not TRAMPOLINE_UP_HAND_ANIM_FIX or type(frames) ~= "table" or #frames <= 1 then
        return frames, 0
    end

    local out = deepCopy(frames)
    local changed = 0
    local i = 1

    while i <= #out do
        local fr = out[i]
        if trampolineAnimIsHighFrame(fr) then
            local startIndex = i
            while startIndex > 1 and trampolineAnimCanExtendChain(out[startIndex], out[startIndex - 1]) do
                startIndex = startIndex - 1
            end

            local endIndex = i
            while endIndex < #out and trampolineAnimCanExtendChain(out[endIndex], out[endIndex + 1]) do
                endIndex = endIndex + 1
            end

            changed = changed + trampolineAnimLockOneChain(out, startIndex, endIndex)
            i = endIndex + 1
        else
            i = i + 1
        end
    end

    return out, changed
end

function horizontalDistance(a, b)
    return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function deepCopy(t)
    if type(t) ~= "table" then
        return t
    end

    local copy = {}
    for k, v in pairs(t) do
        copy[k] = deepCopy(v)
    end
    return copy
end

function getCharacter()
    local char = LocalPlayer.Character
    if not char then
        char = LocalPlayer.CharacterAdded:Wait()
    end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hum then
        hum = char:WaitForChild("Humanoid", 5)
    end

    if not hrp then
        hrp = char:WaitForChild("HumanoidRootPart", 5)
    end

    return char, hum, hrp
end

function restoreCharacterControl(speedOverride)
    local char, hum, hrp = getCharacter()

    --// PRIORITAS RESTORE SPEED:
    --// 1) speedOverride kalau memang dikirim manual.
    --// 2) speed asli map yang disimpan sebelum preview/playback.
    --// 3) speed sebelum record.
    --// 4) WalkSpeed sekarang / default.
    local targetSpeed = tonumber(speedOverride)
        or tonumber(prePlaybackMapWalkSpeed)
        or tonumber(preRecordWalkSpeed)
        or tonumber(hum and hum.WalkSpeed)
        or DEFAULT_PLAYBACK_SPEED

    local toolNow = hasEquippedToolSafe(char)

    --// Kalau sedang pakai coil/tool, jangan turunkan speed tool.
    --// Kalau tidak pakai tool, PAKSA balik ke speed map asli, bukan speed playback.
    if toolNow then
        if tonumber(hum and hum.WalkSpeed) then
            targetSpeed = math.max(targetSpeed, tonumber(hum.WalkSpeed))
        end

        if tonumber(lastKnownToolWalkSpeed) then
            targetSpeed = math.max(targetSpeed, tonumber(lastKnownToolWalkSpeed))
        end
    else
        targetSpeed = tonumber(speedOverride)
            or tonumber(prePlaybackMapWalkSpeed)
            or tonumber(preRecordWalkSpeed)
            or DEFAULT_PLAYBACK_SPEED
    end

    targetSpeed = math.clamp(targetSpeed, MIN_PLAYBACK_SPEED, MAX_PLAYBACK_SPEED)

    local function applyRestore()
        char, hum, hrp = getCharacter()
        local stillTool = hasEquippedToolSafe(char)

        if hum then
            pcall(function()
                hum.AutoRotate = true
                hum.PlatformStand = false
                hum.Sit = false

                if stillTool then
                    --// Tool/coil: hanya naikkan kalau speed turun.
                    if (tonumber(hum.WalkSpeed) or 0) < targetSpeed - 0.1 then
                        hum.WalkSpeed = targetSpeed
                    end
                else
                    --// Non-tool: kembalikan tepat ke speed map asli.
                    hum.WalkSpeed = targetSpeed
                end

                hum:Move(Vector3.new(0, 0, 0), true)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        if hrp then
            pcall(function()
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end

    applyRestore()

    --// Beberapa map/game script menulis WalkSpeed ulang 1-3 frame setelah stop.
    --// Restore diulang sebentar agar tidak nyangkut ke speed preview/playback.
    task.delay(0.05, applyRestore)
    task.delay(0.15, applyRestore)

    if toolNow then
        task.delay(0.35, applyRestore)
    end
end
function getEquippedToolName(char)
    char = char or LocalPlayer.Character
    if not char then
        return ""
    end

    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            return obj.Name
        end
    end

    return ""
end

function getHumanoidStateName(hum)
    local state = "Unknown"

    pcall(function()
        state = tostring(hum:GetState())
        state = state:gsub("Enum.HumanoidStateType.", "")
    end)

    return state
end

function isAirState(state)
    state = tostring(state or "")
    return state == "Jumping"
        or state == "Freefall"
        or state == "FallingDown"
        or state == "Climbing"
        or state == "Swimming"
end

function getSafeFullName(inst)
    local ok, result = pcall(function()
        return inst:GetFullName()
    end)

    if ok and result then
        return tostring(result)
    end

    return tostring(inst and inst.Name or "Unknown")
end

function normalizeGroundInfo(g)
    if type(g) ~= "table" then
        return nil
    end

    return {
        name = tostring(g.name or ""),
        class = tostring(g.class or ""),
        path = tostring(g.path or g.name or ""),
        position = {
            x = tonumber(g.position and g.position.x) or 0,
            y = tonumber(g.position and g.position.y) or 0,
            z = tonumber(g.position and g.position.z) or 0
        },
        hitPosition = {
            x = tonumber(g.hitPosition and g.hitPosition.x) or 0,
            y = tonumber(g.hitPosition and g.hitPosition.y) or 0,
            z = tonumber(g.hitPosition and g.hitPosition.z) or 0
        },
        normal = {
            x = tonumber(g.normal and g.normal.x) or 0,
            y = tonumber(g.normal and g.normal.y) or 1,
            z = tonumber(g.normal and g.normal.z) or 0
        },
        groundOffsetY = tonumber(g.groundOffsetY) or nil,
        material = tostring(g.material or "Default")
    }
end

function getGroundInfo(hrp)
    if not hrp then
        return nil
    end

    local char = LocalPlayer.Character
    local params = RaycastParams.new()

    pcall(function()
        params.FilterType = Enum.RaycastFilterType.Blacklist
    end)

    pcall(function()
        params.FilterDescendantsInstances = char and { char } or {}
    end)

    pcall(function()
        params.IgnoreWater = true
    end)

    local ok, result = pcall(function()
        return workspace:Raycast(
            hrp.Position,
            Vector3.new(0, -GROUND_RAY_DISTANCE, 0),
            params
        )
    end)

    if not ok or not result or not result.Instance then
        return nil
    end

    local inst = result.Instance
    local instPos = Vector3.new(0, 0, 0)

    pcall(function()
        instPos = inst.Position
    end)

    return {
        name = tostring(inst.Name),
        class = tostring(inst.ClassName),
        path = getSafeFullName(inst),
        position = vecToTable(instPos),
        hitPosition = vecToTable(result.Position),
        normal = vecToTable(result.Normal),
        material = tostring(result.Material and result.Material.Name or "Default"),
        groundOffsetY = tonumber(hrp.Position.Y - result.Position.Y) or 0
    }
end

function groundKeyFromFrame(fr)
    if type(fr) ~= "table" or type(fr.ground) ~= "table" then
        return nil
    end

    local key = tostring(fr.ground.path or fr.ground.name or "")
    if key == "" then
        return nil
    end

    return key
end

--// =========================================================
--// ROLLBACK TARGET: BALIK KE POSISI SEBELUM LOMPAT
--// Cari frame terakhir yang masih grounded sebelum Jumping/Freefall
--// =========================================================

--// =========================================================
--// ROLLBACK TARGET: BALIK KE POSISI SEBELUM LOMPAT
--// Contoh: dari tangga A lompat ke tangga B gagal/jatuh,
--// pencet ROLL -> balik ke posisi terakhir sebelum kaki lepas dari tangga A.
--// =========================================================

local ROLLBACK_BEFORE_JUMP_BACKSTEP = 2 -- mundur 2 frame biar benar-benar sebelum lompat

function getFrameYVelocity(fr)
    if type(fr) ~= "table" then
        return 0
    end

    local city = tableToVec(fr.city)
    return city.Y or 0
end

function isRollbackAirFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    local st = tostring(fr.states or fr.state or "")
    local yVel = getFrameYVelocity(fr)
    local hasGround = groundKeyFromFrame(fr) ~= nil

    --// State udara jelas
    if fr.jump == true
        or st == "Jumping"
        or st == "Freefall"
        or st == "FallingDown"
    then
        return true
    end

    --// Kalau tidak ada ground dan velocity Y bergerak, anggap udara
    if not hasGround and math.abs(yVel) > 1.5 then
        return true
    end

    return false
end

function isRollbackGroundFrame(fr)
    if type(fr) ~= "table" then
        return false
    end

    if isRollbackAirFrame(fr) then
        return false
    end

    local st = tostring(fr.states or fr.state or "")

    --// Jangan pilih climbing/swimming sebagai titik sebelum lompat biasa
    if st == "Climbing" or st == "Swimming" then
        return false
    end

    if groundKeyFromFrame(fr) ~= nil then
        return true
    end

    if st == "Running" or st == "Landed" then
        return true
    end

    retur... (318 KB left)
