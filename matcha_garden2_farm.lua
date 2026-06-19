if _G.MatchaCleanup then pcall(_G.MatchaCleanup) end
local ScriptActive = true

local pcall    = pcall
local pairs    = pairs
local ipairs   = ipairs
local tostring = tostring
local task     = task
local Vector2  = Vector2
local Vector3  = Vector3
local Color3   = Color3
local Drawing  = Drawing

local players   = game:GetService("Players")
local workspace = game:GetService("Workspace")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local player    = players.LocalPlayer

-- Fix #4: Viewport size detection — runtime scan with 1920x1080 fallback
-- ViewportSize read may be nil in Matcha; fallback guarantees a usable value
local function getViewport()
  local ok, vp = pcall(function() return workspace.CurrentCamera.ViewportSize end)
  if ok and vp and type(vp) ~= "nil" and vp.X and vp.X > 100 then
    return math.floor(vp.X), math.floor(vp.Y)
  end
  return 1920, 1080  -- safe fallback
end



-- Auto-restart support - find script source
local RSRC
local RPA = {"matcha_garden2_farm.lua","C:\\Users\\Administrator\\Desktop\\PROYECTOMATCHA\\matcha_garden2_farm.lua","C:/Users/Administrator/Desktop/PROYECTOMATCHA/matcha_garden2_farm.lua"}
for _, p in ipairs(RPA) do local ok, s = pcall(readfile, p); if ok and s and #s > 100 then RSRC = s; break end end
if not RSRC then print("[Farm] WARNING: auto-restart unavailable") end

local hCyc = 0; local MCYC = 999999

local function safeNotify(msg, title, dur)
  pcall(function() notify(tostring(msg), tostring(title or "Farm"), dur or 3) end)
end

local function getHRP()
  local char = player.Character
  if not char then return nil end
  return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart")
end

local drawObjs = {}
local function D(typ, props)
  local obj = Drawing.new(typ)
  for k, v in pairs(props) do obj[k] = v end
  table.insert(drawObjs, obj)
  return obj
end

-- UI colors
local C0 = Color3.fromRGB
local C_A = C0(0, 212, 170); local C_BG = C0(14, 14, 22); local C_TP = C0(24, 24, 38)
local C_TX = C0(225, 225, 235); local C_DM = C0(100, 100, 115); local C_TO = C0(55, 55, 72)
local C_AC = C0(255, 186, 76); local C_SN = C0(110, 110, 126); local C_SP = C0(30, 30, 48)

local function lerpColor(a, b, t)
  return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function haptic()
  pcall(function()
    local UIS = game:GetService("UserInputService")
    UIS.HapticFeedback = Enum.HapticFeedbackType.HighFrequencyVibration
    task.delay(0.05, function()
      pcall(function() UIS.HapticFeedback = Enum.HapticFeedbackType.End end)
    end)
  end)
end

local uiPos = Vector2.new(150, 120)
local RH = 30; local TH = 46; local AH = 2; local SH = 1; local STH = 14; local MAXS = 6; local SLH = 24
local uiS = Vector2.new(390, TH + AH + MAXS * RH + SLH + 6 + SH + 8 + STH + 6)
local drg, dOff, lastM1, hov, anm = false, Vector2.new(0, 0), false, 0, {}

local SHD = D("Square", {Size = Vector2.new(uiS.X + 8, uiS.Y + 8), Color = C0(0,0,0), Transparency = 0.4, Filled = true, Visible = true})
local BG  = D("Square", {Size = uiS, Color = C_BG, Filled = true, Visible = true})
local TB  = D("Square", {Size = Vector2.new(uiS.X, TH), Color = C_TP, Filled = true, Visible = true})
local AL  = D("Square", {Size = Vector2.new(uiS.X, AH), Color = C_A, Filled = true, Visible = true})
local TT  = D("Text",   {Text = "FARM HUB v2", Size = 14, Color = C_A, Outline = true, Visible = true, Font = Drawing.Fonts.System})
local TAB_F  = D("Text", {Text = "FARM",  Size = 15, Color = C_A,  Outline = true, Visible = true, Font = Drawing.Fonts.System})
local TAB_P  = D("Text", {Text = "PETS",  Size = 15, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})
local TAB_S  = D("Text", {Text = "SEEDS", Size = 15, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})
local TAB_ST = D("Text", {Text = "STEAL", Size = 15, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})
local TAB_G  = D("Text", {Text = "GEARS", Size = 15, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})
-- Active-tab underline bars: 3px highlight at bottom of header (C_A=active, C_SP=inactive)
local TAB_F_UL  = D("Square", {Size = Vector2.new(56, 3), Color = C_A,  Filled = true, Visible = true})
local TAB_P_UL  = D("Square", {Size = Vector2.new(56, 3), Color = C_SP, Filled = true, Visible = true})
local TAB_S_UL  = D("Square", {Size = Vector2.new(56, 3), Color = C_SP, Filled = true, Visible = true})
local TAB_ST_UL = D("Square", {Size = Vector2.new(56, 3), Color = C_SP, Filled = true, Visible = true})
local TAB_G_UL  = D("Square", {Size = Vector2.new(56, 3), Color = C_SP, Filled = true, Visible = true})
local SCR_U = D("Triangle", {Thickness = 1, Color = C_A, Filled = true, Visible = false})
local SCR_D = D("Triangle", {Thickness = 1, Color = C_A, Filled = true, Visible = false})
local SCR_B = D("Square", {Size = Vector2.new(3, 30), Color = C_A, Filled = true, Visible = false, Transparency = 0.6})
local CLR = D("Text", {Text = "CLEAR ALL", Size = 11, Color = C_SN, Outline = true, Visible = false, Font = Drawing.Fonts.System})

local SL, SC, SF = {}, {}, {}
for i = 1, MAXS do
  SL[i] = D("Text",   {Text = "", Size = 13, Color = C_TX, Outline = true, Visible = false, Font = Drawing.Fonts.System})
  SC[i] = D("Circle", {Radius = 12, Thickness = 2, Color = C_TO, Filled = false, Visible = false})
  SF[i] = D("Circle", {Radius = 9,  Color = C_A, Filled = true, Visible = false})
  anm[i] = 0
end
local SEP = D("Square", {Size = Vector2.new(uiS.X - 24, SH), Color = C_SP, Filled = true, Visible = true})
local STX = D("Text", {Text = "", Size = 11, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})

-- Sell threshold slider
local SLR_BG  = D("Square", {Size = Vector2.new(160, 6), Color = C_SP, Filled = true, Visible = false})
local SLR_FG  = D("Square", {Size = Vector2.new(80, 6), Color = C_A, Filled = true, Visible = false})
local SLR_TX  = D("Text", {Text = "", Size = 11, Color = C_DM, Outline = true, Visible = false, Font = Drawing.Fonts.System})
local SLR_VL  = D("Text", {Text = "", Size = 11, Color = C_A, Outline = true, Visible = false, Font = Drawing.Fonts.System})

local F = {}
local function feat(key, label, kind, hotkey)
  local f = {key=key, label=label, kind=kind, value=false, hotkey=hotkey}
  table.insert(F, f)
  return f
end

feat("AutoHarvest", "AUTO HARVEST [1]", "toggle", 0x31)
feat("AutoLoot",    "AUTO LOOT [2]",    "toggle", 0x32)
feat("AutoGold",    "AUTO GOLD",        "toggle")
feat("AutoSell",    "AUTO SELL [3]",    "toggle", 0x33)
feat("AntiSteal",   "ANTI STEAL",       "toggle")
feat("SaveConfig",  "SAVE CONFIG",      "action")
feat("LoadConfig",  "LOAD CONFIG",      "action")
feat("ForceBuy",    "BUY",              "action")

-- Sell threshold slider (1-99)
local sellThreshold = 80
local SLIDER_SL, SLIDER_BG, SLIDER_FG, SLIDER_TXT
local dragSlider = false
local slEdit = false
local slText = ""
local slLastKeys = {}

local function fVal(key)
  for _, f in ipairs(F) do if f.key == key then return f.value end end
  return false
end

-- Fix #2: Programmatic toggle setter used by sell-once logic
local function setToggle(key, val)
  for _, f in ipairs(F) do if f.key == key then f.value = val; return end end
end

-- Pets
local activeTab = "farm"
local ALL_PETS = {"Frog","Bunny","Owl","Deer","Robin","Bee","Monkey","GoldenDragonfly","Unicorn","Raccoon","IceSerpent","BlackDragon","Golden Dragonfly","Ice Serpent","Black Dragon"}
local petSpawned = {}; local petSelected = {}; local petBlacklist = {}; local petScroll = 0
local ptRun = false; local ptTh = nil; local ptCount = 0; local autoPet = false
local petBuying = false
local function petCount() local c=0; for _,v in pairs(petSelected) do if v == true then c=c+1 end end return c end

-- Seeds
local ALL_SEEDS = {}  -- populated by scanSeeds() after GUI scan — no hardcoded values
local _savedSeedCfg = {}  -- raw seed selections from config, applied after first scan
local seedSelected = {}; local seedScroll = 0
local seedScanned = false; local autoBuy = false
-- Gears
local autoGear = false
local agRun = false
local agTh = nil
local function seedCount() local c=0; for _,v in pairs(seedSelected) do if v == true then c=c+1 end end return c end

-- AutoSteal
local stealTargets = {}    -- player names scanned from game.Players
local stealSelected = {}   -- {[name]=true/false} which players to target
local stealLimit   = 20    -- max fruits per rotation (slider 1-48)
local stealScroll  = 0     -- UI list scroll offset
local stRun        = false -- steal loop running flag
local stTh         = nil   -- steal thread handle
local autoSteal    = false -- master steal toggle
local stolenCount  = 0     -- total fruits stolen this session (declared here so stealFromPlayer can close over it)
local function stealSelCount() local c=0; for _,v in pairs(stealSelected) do if v == true then c=c+1 end end return c end

-- Config save/load
local CONFIG_PATH = "matcha_garden_config.json"

local function saveConfig()
  local cfg = {
    sellThreshold = sellThreshold,
    toggles = {},
    seeds = {},
    pets = {},
  }
  for _, f in ipairs(F) do cfg.toggles[f.key] = f.value end
  for _, nm in ipairs(ALL_SEEDS) do
    cfg.seeds[nm] = (seedSelected[nm] == true)
  end
  for _, nm in ipairs(ALL_PETS) do
    cfg.pets[nm] = (petSelected[nm] == true)
  end
  cfg.stealLimit = stealLimit
  cfg.stealSel = {}
  for _, nm in ipairs(stealTargets) do cfg.stealSel[nm] = (stealSelected[nm] == true) end
  local ok, json = pcall(function() return HttpService:JSONEncode(cfg) end)
  if ok and json then
    pcall(function() writefile(CONFIG_PATH, json) end)
    safeNotify("Config saved!", "Config", 2)
    print("[Config] Saved to " .. CONFIG_PATH)
  else
    safeNotify("Config save failed!", "Config", 2)
  end
end

local function loadConfig()
  local ok, content = pcall(function() return readfile(CONFIG_PATH) end)
  if not ok or not content then return end
  local ok2, cfg = pcall(function() return HttpService:JSONDecode(content) end)
  if not ok2 or not cfg then return end
  if cfg.sellThreshold then sellThreshold = cfg.sellThreshold end
  if cfg.toggles then
    for _, f in ipairs(F) do
      if cfg.toggles[f.key] ~= nil then f.value = cfg.toggles[f.key] end
    end
  end
  if cfg.seeds then
    _savedSeedCfg = cfg.seeds  -- store raw config; applied to seedSelected after scanSeeds runs
    for _, nm in ipairs(ALL_SEEDS) do seedSelected[nm] = (cfg.seeds[nm] == true) end
  end
  if cfg.pets then for _, nm in ipairs(ALL_PETS) do petSelected[nm] = (cfg.pets[nm] == true) end end
  if cfg.stealLimit then stealLimit = math.max(1, math.min(48, math.floor(cfg.stealLimit))) end
  if cfg.stealSel then for nm, v in pairs(cfg.stealSel) do stealSelected[nm] = (v == true) end end
  safeNotify("Config loaded!", "Config", 2)
  print("[Config] Loaded | sell=" .. sellThreshold .. " seeds=" .. seedCount() .. " pets=" .. petCount())
end
loadConfig()

-- Farm logic
local VK_E = 0x45
local gardens = workspace:FindFirstChild("Gardens")


local cachedGridFrame = nil
local function countItems()
  local t0 = tick()
  if not cachedGridFrame or not cachedGridFrame.Parent then
    pcall(function()
      local bg = player.PlayerGui:FindFirstChild("BackpackGui")
      local bp = bg and bg:FindFirstChild("Backpack")
      local inv = bp and bp:FindFirstChild("Inventory")
      local sf = inv and inv:FindFirstChild("ScrollingFrame")
      cachedGridFrame = sf and sf:FindFirstChild("UIGridFrame")
    end)
  end
  if not cachedGridFrame then return 0 end
  local n = 0
  local ok, children = pcall(function() return cachedGridFrame:GetChildren() end)
  if ok and children then
    for _, c in ipairs(children) do
      if c:IsA("Frame") then n = n + 1 end
    end
  end
  local dt = tick() - t0
  if dt > 0.02 then print("[DBG] countItems took " .. string.format("%.3f", dt) .. "s") end
  return math.max(0, n - 10)
end

local function findPlot()
  if not gardens then return nil end
  for _, p in ipairs(gardens:GetChildren()) do
    local plants = p:FindFirstChild("Plants")
    if plants then
      local foundPlayerFruit = false
      for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")
        if fruits then
          for _, fruit in ipairs(fruits:GetChildren()) do
            local hp = fruit:FindFirstChild("HarvestPart")
            if (hp and hp:FindFirstChild("HarvestPrompt")) or fruit:FindFirstChild("HarvestPrompt") then
              foundPlayerFruit = true
              break
            end
          end
        end
        if foundPlayerFruit then break end
      end
      if foundPlayerFruit then return p end
    end
  end

  for _, p in ipairs(gardens:GetChildren()) do
    if tostring(p:GetAttribute("Owner")) == player.Name then
      return p
    end
  end
  return nil
end

local function getPlotAnchor(plot)
  if not plot then return nil end
  local ref = plot:FindFirstChild("PlotSizeReference")
  if ref then
    local ok, refCF = pcall(function() return ref.CFrame end)
    if ok and refCF then return refCF * CFrame.new(0, -3, 0) end
  end
  local sp = plot:FindFirstChild("SpawnPoint")
  if sp then
    local ok, spCF = pcall(function() return sp.CFrame end)
    if ok and spCF then return spCF * CFrame.new(0, 3, 0) end
  end
  return nil
end

local function smoothFlight(hrp, targetPos, stepDist)
  stepDist = stepDist or 3
  local ok, startPos = pcall(function() return hrp.Position end)
  if not ok then return end
  local dist = (targetPos - startPos).Magnitude
  if dist <= stepDist then
    pcall(function() hrp.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z) end)
    return
  end
  local steps = math.max(1, math.floor(dist / stepDist))
  for i = 1, steps do
    if not ScriptActive then break end
    local p = startPos:Lerp(targetPos, i / steps)
    pcall(function() hrp.CFrame = CFrame.new(p.X, p.Y, p.Z) end)
    task.wait(0.03)
  end
  pcall(function() hrp.CFrame = CFrame.new(targetPos.X, targetPos.Y, targetPos.Z) end)
end

local function tpToAnchor(plot)
  local cf = getPlotAnchor(plot)
  if not cf then print("[Farm] WARNING: tpToAnchor failed — no SpawnPoint or PlotSizeReference"); return end
  local h = getHRP()
  if not h then return end
  smoothFlight(h, cf.Position)
  -- aggressive persistence for 0.5s after landing
  local deadline = tick() + 0.5
  while tick() < deadline do
    local h = getHRP()
    if h then pcall(function() h.CFrame = cf end) end
    task.wait(0.02)
  end
end

local harvestCache     = {}
local harvestBlacklist = {} -- fruits that failed 2 stuck TPs; cleared on harvest toggle off
local function scanHarvest(plot)
  harvestCache = {}
  local plants = plot and plot:FindFirstChild("Plants")
  if not plants then return end
  for _, plant in ipairs(plants:GetChildren()) do
    local fruits = plant:FindFirstChild("Fruits")
    if fruits then
      for _, fruit in ipairs(fruits:GetChildren()) do
        local hp = fruit:FindFirstChild("HarvestPart")
        if hp and hp:IsA("BasePart") then table.insert(harvestCache, hp) end
      end
    end
  end
end


-- Forces the camera to look at a world-space target from eyePos.
-- CameraType.Scriptable prevents the engine from overriding cam.CFrame each frame.
-- Called every 0.05s loop tick so the camera stays locked on the fruit.
local function camLookAt(eyePos, targetPos)
  local cam = workspace.CurrentCamera
  pcall(function()
    cam.CameraType = Enum.CameraType.Scriptable
    cam.CFrame = CFrame.lookAt(eyePos, targetPos)
  end)
end

-- Restores camera to player control after harvest/steal loop ends.
local function camRestore()
  pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

-- Calculates the screen pixel (sx, sy) to aim the camera at worldPos.
-- Returns nil,nil on failure — caller must check before calling mousemoveabs.
local function worldToMousePos(worldPos)
  if not worldPos then return nil, nil end
  local cam = workspace.CurrentCamera
  if not cam then return nil, nil end
  local ok, sx, sy = pcall(function()
    local cf  = cam.CFrame
    local vs  = cam.ViewportSize
    local cvw, cvh = vs.X, vs.Y
    local dir = worldPos - cf.Position
    local fwd   = math.max(dir:Dot(cf.LookVector), 0.1)
    local scale = (cvh * 0.5) / math.tan(math.rad(cam.FieldOfView / 2))
    return
      math.clamp(cvw * 0.5 + dir:Dot(cf.RightVector) / fwd * scale, 0, cvw),
      math.clamp(cvh * 0.5 - dir:Dot(cf.UpVector)    / fwd * scale, 0, cvh)
  end)
  if ok and sx then return sx, sy end
  return nil, nil
end

-- ── AutoSteal helpers ────────────────────────────────────────────────────────
-- Checks if a Vector3 pos is inside the 3D bounds of a BasePart
local function isInsidePart(pos, part)
  local ok1, cf = pcall(function() return part.CFrame end)
  local ok2, sz = pcall(function() return part.Size end)
  if not (ok1 and ok2 and cf and sz) then return false end
  -- PointToObjectSpace converts world pos → local space without CFrame:inverse()
  local p = cf:PointToObjectSpace(pos); local h = sz / 2
  return math.abs(p.X) <= h.X and math.abs(p.Y) <= h.Y and math.abs(p.Z) <= h.Z
end

local function scanStealTargets()
  stealTargets = {}
  local ok, players = pcall(function() return game.Players:GetPlayers() end)
  if not ok or not players then return end
  for _, p in ipairs(players) do
    if p.Name ~= player.Name then table.insert(stealTargets, p.Name) end
  end
  table.sort(stealTargets, function(a, b) return a:lower() < b:lower() end)
  stealScroll = 0
  print("[Steal] Found " .. #stealTargets .. " targets")
end

-- Steals up to stealLimit fruits from target's plot.
-- Same TP + camera.lookAt + anti-gravity logic as doHarvest.
-- Aborts early if owner returns to GardenZonePart or phase leaves Night.
local function stealFromPlayer(target, targetPlot, zonePart)
  local hrp = getHRP(); if not hrp then return end
  local cache = {}
  local plants = targetPlot:FindFirstChild("Plants")
  if not plants then return end
  for _, plant in ipairs(plants:GetChildren()) do
    local fruits = plant:FindFirstChild("Fruits")
    if fruits then
      for _, fruit in ipairs(fruits:GetChildren()) do
        local hp = fruit:FindFirstChild("HarvestPart")
        if hp and hp:IsA("BasePart") then
          table.insert(cache, hp)
          if #cache >= stealLimit then break end
        end
      end
    end
    if #cache >= stealLimit then break end
  end
  if #cache == 0 then return end

  local stolen = 0; local first = true; local elevated = 0
  for _, hp in ipairs(cache) do
    if not stRun or stolen >= stealLimit then break end
    if tostring(workspace:GetAttribute("ActivePhase") or "") ~= "Night" then break end
    if zonePart then
      local tc = target.Character; local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
      if tHRP and isInsidePart(tHRP.Position, zonePart) then
        safeNotify(target.Name .. " returned — moving on", "AutoSteal", 3); break
      end
    end
    if hp and hp.Parent then
      local ok, cf = pcall(function() return hp.CFrame end)
      if ok and cf then
        local fruitPos = cf.Position
        local tpPos = (elevated > 0)
          and Vector3.new(fruitPos.X, fruitPos.Y + elevated, fruitPos.Z)
          or  Vector3.new(fruitPos.X, fruitPos.Y + 1, fruitPos.Z)
        local lookTarget = Vector3.new(fruitPos.X, fruitPos.Y, fruitPos.Z + 0.001)
        hrp.CFrame = CFrame.lookAt(tpPos, lookTarget)
        local msx, msy = worldToMousePos(fruitPos)
        if msx then pcall(function() mousemoveabs(msx, msy) end) end
        pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
        pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
        if first then
          for _ = 1, 12 do mousescroll(-120) end; task.wait(0.3)
          local msx2, msy2 = worldToMousePos(fruitPos)
          if msx2 then pcall(function() mousemoveabs(msx2, msy2) end) end
          task.wait(0.1); keypress(VK_E); first = false
        end
        local prevItems = countItems(); local waitStart = tick(); local stuckAt = tick()
        while hp and hp.Parent and hp:IsDescendantOf(workspace) do
          if not stRun or stolen >= stealLimit then break end
          if tick() - waitStart > 5 then break end
          if tostring(workspace:GetAttribute("ActivePhase") or "") ~= "Night" then break end
          if zonePart then
            local tc = target.Character; local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
            if tHRP and isInsidePart(tHRP.Position, zonePart) then break end
          end
          local now = countItems()
          if now > prevItems then stolen = stolen + (now - prevItems); prevItems = now; stuckAt = tick() end
          if tick() - stuckAt > 3 then
            pcall(function() keyrelease(VK_E) end); elevated = elevated + 5
            local pos = hrp.Position; tpPos = Vector3.new(pos.X, pos.Y + 5, pos.Z)
            hrp.CFrame = CFrame.lookAt(tpPos, lookTarget); task.wait(0.3)
            pcall(function() keypress(VK_E) end); task.wait(0.5); stuckAt = tick()
          end
          if (hrp.Position - tpPos).Magnitude > 1.5 then hrp.CFrame = CFrame.lookAt(tpPos, lookTarget) end
          pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
          pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
          task.wait(0.05)
        end
      end
    end
  end
  pcall(function() keyrelease(VK_E) end)
  stolenCount = stolenCount + stolen
  camRestore()
  local myPlot = findPlot()
  if myPlot then tpToAnchor(myPlot) end
  print("[Steal] Stole " .. stolen .. " from " .. target.Name)
  safeNotify("Stole " .. stolen .. " fruits from " .. target.Name, "AutoSteal", 3)
end

-- Rotates through selected targets each Night cycle.
-- If none selected, targets all known players.
-- Waits during Day and rescans players periodically.
local function autoStealLoop()
  safeNotify("AutoSteal started!", "AutoSteal", 3)
  local rotIdx = 1
  while stRun do
    local phase = tostring(workspace:GetAttribute("ActivePhase") or "")
    if phase == "Night" then
      local activeTargets = {}
      for _, nm in ipairs(stealTargets) do
        if stealSelected[nm] then table.insert(activeTargets, nm) end
      end
      if #activeTargets == 0 then
        for _, nm in ipairs(stealTargets) do table.insert(activeTargets, nm) end
      end
      if #activeTargets > 0 then
        if rotIdx > #activeTargets then rotIdx = 1 end
        local targetName = activeTargets[rotIdx]
        local target = game.Players:FindFirstChild(targetName)
        if target then
          local targetPlot = nil
          if gardens then
            for _, p in ipairs(gardens:GetChildren()) do
              if tostring(p:GetAttribute("Owner")) == targetName then targetPlot = p; break end
            end
          end
          if targetPlot then
            local visual = targetPlot:FindFirstChild("Visual")
            local zonePart = visual and visual:FindFirstChild("GardenZonePart")
            local tc = target.Character; local tHRP = tc and tc:FindFirstChild("HumanoidRootPart")
            local isAway = true
            if tHRP and zonePart then isAway = not isInsidePart(tHRP.Position, zonePart) end
            if isAway then stealFromPlayer(target, targetPlot, zonePart) end
          end
        end
        rotIdx = (rotIdx % #activeTargets) + 1
      end
      task.wait(0.5)  -- brief pause between targets in Night cycle
    else
      -- Not Night: only scan player plots every second, no scroll reset
      -- Keeps target list fresh so the moment Night starts we're ready
      local ok, players = pcall(function() return game.Players:GetPlayers() end)
      if ok and players then
        local fresh = {}
        for _, p in ipairs(players) do
          if p.Name ~= player.Name then table.insert(fresh, p.Name) end
        end
        table.sort(fresh, function(a, b) return a:lower() < b:lower() end)
        stealTargets = fresh  -- update list without touching stealScroll
      end
      task.wait(1)
    end
  end
  stRun = false; stTh = nil
  safeNotify("AutoSteal stopped!", "AutoSteal", 3)
end

local INV_MAX = 90
local sellFailCooldown = 0

local harvestTickActive = false
local function doHarvestTick(p)
  if harvestTickActive then return end
  harvestTickActive = true
  task.spawn(function()
    pcall(function()
      local plants = p and p:FindFirstChild("Plants")
      if not plants then return end
      local hrp = getHRP()
      if not hrp then return end
      local hx, hy, hz = hrp.Position.X, hrp.Position.Y, hrp.Position.Z

      local list = {}
      for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")
        if fruits then
          for _, fruit in ipairs(fruits:GetChildren()) do
            local hp = fruit:FindFirstChild("HarvestPart")
            if hp and hp:IsA("BasePart") and hp.Parent then
              table.insert(list, hp)
            end
          end
        end
      end

      table.sort(list, function(a, b)
        local aY = a.Position.Y
        local bY = b.Position.Y
        if aY < -100 and bY >= -100 then
          return false
        elseif aY >= -100 and bY < -100 then
          return true
        end
        return false
      end)

      local tpCount = 0
      for _, hp in ipairs(list) do
        if tpCount >= 48 then break end
        local angle = ((tpCount + 5) % 24) * (math.pi * 2 / 24)
        local px = hx + math.cos(angle) * 6
        local pz = hz + math.sin(angle) * 6
        pcall(function() hp.CFrame = CFrame.new(px, hy + 0.5, pz) end)
        tpCount = tpCount + 1
        if tpCount % 8 == 0 then task.wait() end
      end
    end)
    harvestTickActive = false
  end)
end
local lootCount = 0
local function doLoot()
  local di = workspace:FindFirstChild("DroppedItems")
  if not di then return end
  local hrp = getHRP()
  if not hrp then return end
  for _, item in ipairs(di:GetChildren()) do
    if not fVal("AutoLoot") then break end
    local anchor = item:FindFirstChild("PromptAnchor")
    if anchor and anchor:IsA("BasePart") then
      local ok, cf = pcall(function() return anchor.CFrame end)
      if ok and cf then
        hrp.CFrame = cf * CFrame.new(0, 1, 0)
        task.wait(0.1)
        keypress(VK_E)
        for _ = 1, 24 do
          if not fVal("AutoLoot") then break end
          task.wait(0.05)
        end
        keyrelease(VK_E)
        lootCount = lootCount + 1
      end
    end
  end
end

local goldCount = 0
local function collectGold()
  if not fVal("AutoGold") then return end
  local map = workspace:FindFirstChild("Map")
  if not map then return end
  local sp = map:FindFirstChild("SeedPackSpawnClient")
  if not sp then return end
  local mdl = sp:FindFirstChild("Model")
  if not mdl then return end
  local gold = mdl:FindFirstChild("Gold")
  if not gold then return end

  local hrp = getHRP()
  if not hrp then return end

  local part = gold:IsA("BasePart") and gold or nil
  if not part then
    for _, c in ipairs(gold:GetChildren()) do
      if c:IsA("BasePart") then part = c; break end
    end
  end
  if not part and gold:IsA("Model") then
    part = gold:FindFirstChild("PrimaryPart")
  end
  if not part then return end

  local goldStart = tick()
  local ePressed = false
  while gold and gold.Parent and gold:IsDescendantOf(workspace) do
    if tick() - goldStart > 5 then break end
    local ok, cf = pcall(function() return part.CFrame end)
    if ok and cf then
      hrp.CFrame = cf * CFrame.new(0, 1, 0)
      if not ePressed then
        for _ = 1, 4 do
          hrp.CFrame = cf * CFrame.new(0, 1, 0)
          pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
          pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
          task.wait(0.05)
        end
        keypress(VK_E); ePressed = true
      end
    end
    pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
    task.wait(0.05)
  end
  keyrelease(VK_E)
  goldCount = goldCount + 1
  print("[Gold] Collected #" .. goldCount)
end

local phase = "?" -- updated by getPhase(); stolenCount declared earlier so stealFromPlayer can access it
local function getPhase() local v = workspace:GetAttribute("ActivePhase"); if v then phase = tostring(v) end return phase end


local function scanSeeds(fr)
  if not fr then return end
  local found = {}
  for _, shopName in ipairs({"NormalShop", "ExclusiveShop"}) do
    local sh = fr:FindFirstChild(shopName)
    if sh then
      -- ipairs guarantees sequential order from GetChildren array
      for _, it in ipairs(sh:GetChildren()) do
        local skip = it.Name == "Sheckles_Shelf" or it.Name == "Robux_Shelf" or it.Name == "ItemTemplate"
        if not skip then
          local mf = it:FindFirstChild("Main_Frame")
          if mf and mf:FindFirstChild("TextButton") then
            table.insert(found, it.Name)
          end
        end
      end
    end
  end
  if #found == 0 then return end

  local seen = {}
  for _, nm in ipairs(ALL_SEEDS) do seen[nm] = true end
  for _, nm in ipairs(found) do
    if not seen[nm] then table.insert(ALL_SEEDS, nm) end
  end
  -- Keep UI order (no alphabetical sort)
  -- Reset scroll to top so list always starts at the beginning after each scan
  seedScroll = 0
  -- Restore saved config selections ONLY on first scan — clears after to prevent
  -- overriding user changes made in the UI between autoBuy cycles
  if next(_savedSeedCfg) ~= nil then
    for _, nm in ipairs(ALL_SEEDS) do
      if _savedSeedCfg[nm] ~= nil then
        seedSelected[nm] = (_savedSeedCfg[nm] == true)
      end
    end
    _savedSeedCfg = {}  -- clear: user UI changes are now authoritative
  end
  seedScanned = true
  print("[Seeds] Scanned " .. #ALL_SEEDS .. " seeds")
end
local function scanPets()
  local sp = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
  for _, nm in ipairs(ALL_PETS) do petSpawned[nm] = nil end
  if not sp then return end

  for _, inst in ipairs(sp:GetChildren()) do
    local n = inst.Name
    for _, nm in ipairs(ALL_PETS) do
      local p = nm:gsub("%s+", "")
      local q = nm:gsub("%s+", "_")
      if n:find("WildPet_" .. p .. "_") or n:find("WildPet_" .. q .. "_") or n:find(p) or n:find(q) then
        petSpawned[nm] = inst
        break
      end
    end
  end

  for _, inst in ipairs(sp:GetChildren()) do
    if inst.ClassName ~= "Model" then
      local n = inst.Name
      for _, nm in ipairs(ALL_PETS) do
        if n == nm or n == nm:gsub("%s+", "") then
          petSpawned[nm] = inst
          break
        end
      end
    end
  end
end
local function getPetPart(petInst)
  if petInst.ClassName ~= "Model" then return petInst end
  local pp = petInst.PrimaryPart; if pp then return pp end
  local pa = petInst:FindFirstChild("PromptAnchor"); if pa then return pa end
  for _, c in ipairs(petInst:GetChildren()) do
    if c.ClassName ~= "Model" then return c end
  end
  return nil
end
local function doPetBuy(name)
  local inst = petSpawned[name]
  if not inst then return end
  local hrp = getHRP(); if not hrp then return end
  for attempt = 1, 2 do
    if not inst or not inst.Parent or not inst:IsDescendantOf(workspace) then break end
    petBuying = true
    local part = getPetPart(inst)
    if part then
      local ok, cf = pcall(function() return part.CFrame end)
      if ok and cf then
        hrp.CFrame = cf * CFrame.new(0, 1, 0)
        for _ = 1, 4 do
          hrp.CFrame = cf * CFrame.new(0, 1, 0)
          pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
          pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
          task.wait(0.05)
        end
        keypress(VK_E)
        local buyStart = tick()
        while inst and inst.Parent and inst:IsDescendantOf(workspace) do
          if tick() - buyStart > 1.5 then break end
          local part2 = getPetPart(inst)
          if part2 then
            local ok2, cf2 = pcall(function() return part2.CFrame end)
            if ok2 and cf2 then hrp.CFrame = cf2 * CFrame.new(0, 1, 0) end
          end
          pcall(function() hrp.Velocity = Vector3.new(0, 0, 0) end)
          pcall(function() hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end)
          task.wait(0.05)
        end
      end
    end
    keyrelease(VK_E)
    petBuying = false
    local collected = not inst or not inst.Parent or not inst:IsDescendantOf(workspace)
    if collected then
      petSpawned[name] = nil
      ptCount = ptCount + 1; print("[PET] bought " .. name)
      return
    end
    print("[PET] attempt " .. attempt .. " failed for " .. name .. ", retrying...")
  end
  petSpawned[name] = nil
  petBlacklist[name] = true
  print("[PET] blacklisted " .. name .. " (2 attempts failed)")
end
local function petBuyLoop()
  safeNotify("AutoPet started!", "AutoPet", 3)
  while ptRun do
    scanPets()
    for _, nm in ipairs(ALL_PETS) do
      if not ptRun then break end
      if petSelected[nm] and petSpawned[nm] and not petBlacklist[nm] then doPetBuy(nm) end
    end
    task.wait(5)
  end
  ptRun = false; ptTh = nil
  safeNotify("AutoPet stopped!", "AutoPet", 3)
end

-- Auto Buy
local abRun = false
local abTh = nil
local asRun = false
local asTh = nil

local function num(t)
  if not t or type(t) ~= "string" then return 0 end
  local cleaned = t:gsub(",", "")
  local m = cleaned:match("(%d+%.?%d*)%s*[Mm]")
  if m then return math.floor(tonumber(m) * 1000000) end
  local k = cleaned:match("(%d+%.?%d*)%s*[Kk]")
  if k then return math.floor(tonumber(k) * 1000) end
  local b = cleaned:match("(%d+%.?%d*)%s*[Bb]")
  if b then return math.floor(tonumber(b) * 1000000000) end
  local n = cleaned:match("(%d+%.?%d*)")
  return n and tonumber(n) or 0
end

local function coins()
  local ok, t = pcall(function() return player.PlayerGui.HUD.Currencies.CoinsCounter.TextLabel.Text end)
  return ok and num(t) or 0
end

local function stk(mf)
  local ok, t = pcall(function() return mf.Stock_Text.Text end)
  return ok and num(t) or 0
end

local function prix(mf)
  local ok, t = pcall(function() return mf.Cost_Text.Text end)
  return ok and num(t) or 0
end

local function moveMouse(x, y)
  local cx, cy = 0, 0
  pcall(function() local m = player:GetMouse(); cx = m.X; cy = m.Y end)
  local dx, dy = x - cx, y - cy
  local dist = math.sqrt(dx * dx + dy * dy)
  local steps = math.max(3, math.min(12, math.floor(dist / 40)))
  for i = 1, steps do
    local t = i / steps
    mousemoveabs(cx + dx * t, cy + dy * t)
    task.wait(0.008)
  end
end

local function clk(o)
  if not o then return end
  local p, s = o.AbsolutePosition, o.AbsoluteSize
  moveMouse(p.X + s.X / 2, p.Y + s.Y / 2)
  task.wait(0.05); mouse1click(); task.wait(0.05)
end

local function shakeMouse(x, y, amplitude, cycles)
  amplitude = amplitude or 15
  cycles = cycles or 3
  for _ = 1, cycles do
    moveMouse(x - amplitude, y)
    task.wait(0.03)
    moveMouse(x + amplitude, y)
    task.wait(0.03)
  end
  moveMouse(x, y)
  task.wait(0.05)
end

local function rScrl(sh)
  if not sh then return end
  local p, s = sh.AbsolutePosition, sh.AbsoluteSize
  local cx = p.X + s.X / 2
  local cy = p.Y + s.Y / 2
  shakeMouse(cx, cy, 15, 3)
  local ok = pcall(function() sh.CanvasPosition = Vector2.new(0, 0) end)
  if not ok then
    mousemoveabs(cx, cy)
    task.wait(0.1)
    for _ = 1, 15 do mousescroll(10); task.wait(0.02) end
  end
end

local function scrlv(sh, it)
  pcall(function()
    local y = it.AbsolutePosition.Y - sh.AbsolutePosition.Y + sh.CanvasPosition.Y
    sh.CanvasPosition = Vector2.new(0, math.max(0, y))
  end)
  task.wait(0.1)
end

local function ferm(fr)
  if not fr then return end
  local ok, b = pcall(function() return fr.Header.ExitButton end)
  if ok and b then
    local p, s = b.AbsolutePosition, b.AbsoluteSize
    moveMouse(p.X + s.X / 2, p.Y + s.Y / 2 + 8)
    task.wait(0.05); mouse1click(); task.wait(0.05)
  end
end

local function attRst()
  local ok, v = pcall(function() return RS.StockValues.SeedShop.UnixNextRestock end)
  if not ok or not v then
    local t = 0; while t < 300 and abRun do task.wait(1); t = t + 1 end
    return
  end
  local nxt = v.Value
  local rst = nxt - os.time()
  if rst > 0 then
    safeNotify("Restock in " .. math.floor(rst / 60) .. "m " .. rst % 60 .. "s", "AutoBuy", 5)
    local t = 0; while t < rst + 2 and abRun do task.wait(1); t = t + 1 end
  end
  while v.Value == nxt and abRun do task.wait(0.5) end
  if abRun then safeNotify("Restock! Restarting...", "AutoBuy", 3); task.wait(2) end
end

local function achtt(fr)
  local tot = 0
  local anyInStock = false
  local selCount = seedCount()
  local visited = 0
  for _, nm in pairs({"NormalShop", "ExclusiveShop"}) do
    if not abRun then return tot end
    local sh = fr:FindFirstChild(nm)
    if sh then
      local ok, bb = pcall(function() return sh.Sheckles_Shelf.Main_Frame.Buttons.BuyButton end)
      if ok and bb then
        rScrl(sh); task.wait(0.2)
        for _, it in pairs(sh:GetChildren()) do
          if not abRun then ferm(fr); return tot end
          if visited >= selCount then break end
          if it.Name ~= "Sheckles_Shelf" and it.Name ~= "Robux_Shelf" and it.Name ~= "ItemTemplate" then
            local mf = it:FindFirstChild("Main_Frame")
            if mf then
              local sb = mf:FindFirstChild("TextButton")
              if sb then
                clk(sb); task.wait(0.5)
                if not abRun then ferm(fr); return tot end
                if seedSelected[it.Name] == true then
                  local inList = false
                  for _, sn in ipairs(ALL_SEEDS) do if sn == it.Name then inList = true; break end end
                  if inList then
                    local px, sk = prix(mf), stk(mf)
                    if sk > 0 then
                      anyInStock = true
                      if px > 0 then
                        if coins() < px then ferm(fr); safeNotify("Not enough coins! " .. tot .. " seeds bought.", "AutoBuy", 5); return tot end
                        for _ = 1, sk do
                          if not abRun then ferm(fr); return tot end
                          if coins() < px then ferm(fr); safeNotify("Not enough coins! " .. tot .. " seeds bought.", "AutoBuy", 5); return tot end
                          local bp, bs = bb.AbsolutePosition, bb.AbsoluteSize
                          moveMouse(bp.X + bs.X / 2, bp.Y + bs.Y / 2 + 10)
                          task.wait(0.05); mouse1click(); task.wait(0.15)
                          tot = tot + 1
                        end
                        task.wait(0.2)
                      end
                    end
                    visited = visited + 1
                  end
                end
              end
            end
          end
        end
      end
    end
    if visited >= selCount then break end
  end
  if not anyInStock and tot == 0 then
    ferm(fr); safeNotify("All selected seeds out of stock!", "AutoBuy", 3)
    return tot
  end
  ferm(fr); safeNotify("Cycle done! " .. tot .. " seeds bought.", "AutoBuy", 5)
  return tot
end

local function ouvr()
  local sam = workspace:FindFirstChild("NPCS") and workspace.NPCS:FindFirstChild("Sam")
  if not sam or not sam.PrimaryPart then return nil end
  local sp = sam.PrimaryPart.Position
  local hrp = getHRP()
  if not hrp then return nil end
  hrp.CFrame = CFrame.new(sp.X, sp.Y + 1, sp.Z + 3)
  local fr, att = nil, 0
  repeat
    if not abRun then return nil end
    att = att + 1
    keypress(VK_E); keyrelease(VK_E)
    task.wait(0.6)
    local sg = player.PlayerGui:FindFirstChild("SeedShop")
    if sg then fr = sg:FindFirstChild("Frame") end
    if not fr then
      hrp.CFrame = CFrame.new(sp.X, sp.Y + 1, sp.Z + 3)
    end
  until fr ~= nil or att >= 3
  task.wait(1)
  return fr
end

local function getGearsPart()
  local npcs = workspace:FindFirstChild("NPCS")
  if not npcs then return nil end
  local model = npcs:FindFirstChild("Model")
  if not model then return nil end
  local gears = model:FindFirstChild("Gears")
  if not gears then return nil end
  return gears:FindFirstChild("Part")
end

local function autoGearLoop()
  safeNotify("AutoGear started!", "AutoGear", 3)
  while agRun and autoGear do
    local hrp = getHRP()
    local gearsPart = getGearsPart()
    if hrp and gearsPart then
      local gearCF = CFrame.new(gearsPart.Position.X, gearsPart.Position.Y + 1, gearsPart.Position.Z)
      hrp.CFrame = gearCF
      task.wait(0.3)
      hrp.CFrame = gearCF
      task.wait(0.3)
      keypress(VK_E); task.wait(0.2); keyrelease(VK_E)
      task.wait(0.8)
      autoGear = false
      break
    end
    task.wait(1)
  end
  agRun = false
  agTh = nil
  safeNotify("AutoGear stopped!", "AutoGear", 3)
end

local function autoBuyLoop()
  safeNotify("AutoBuy started!", "AutoBuy", 3)
  while abRun do
    local fr = ouvr()
    if not abRun then break end
    if fr then
      scanSeeds(fr)
      achtt(fr)
      if not abRun then break end
      attRst()
    else
      task.wait(5)
    end
  end
  abRun = false
  abTh = nil
  safeNotify("AutoBuy stopped!", "AutoBuy", 3)
end

local function autoSellLoop()
  safeNotify("AutoSell started!", "AutoSell", 3)
  pcall(function()
    local myPlot = findPlot()
    local plants = myPlot and myPlot:FindFirstChild("Plants")
    if plants then
      for _, plant in ipairs(plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")
        if fruits then
          for _, fruit in ipairs(fruits:GetChildren()) do
            local hp = fruit:FindFirstChild("HarvestPart")
            if hp and hp:IsA("BasePart") and hp.Parent then
              local pos = hp.Position
              if pos.Y > -100 then
                hp.CFrame = CFrame.new(pos.X, -500, pos.Z)
              end
            end
          end
        end
      end
    end
  end)
  local sellTp = workspace:FindFirstChild("Teleports") and workspace.Teleports:FindFirstChild("Sell")
  if not sellTp then print("[Sell] ERROR: Teleports.Sell not found"); asRun = false; asTh = nil; return end

  local vw, vh = getViewport()
  print("[Sell] Viewport: " .. vw .. "x" .. vh .. " | Sell at " .. tostring(sellTp.Position))

  local hrp = getHRP()
  if not hrp then asRun = false; asTh = nil; return end

  -- Start persistence at sell position immediately (covers flight + interaction)
  local sellCF = CFrame.new(sellTp.Position.X, sellTp.Position.Y, sellTp.Position.Z)
  local persistStop = false
  task.spawn(function()
    while not persistStop do
      local h = getHRP()
      if h then pcall(function() h.CFrame = sellCF end) end
      task.wait(0.02)
    end
  end)

  -- Fly to sell
  smoothFlight(hrp, sellTp.Position)

  keypress(VK_E); task.wait(0.2); keyrelease(VK_E); task.wait(0.8)
  for _ = 1, 20 do mousescroll(120); task.wait(0.02) end; task.wait(0.3)
  moveMouse(vw * 0.500, vh * 0.685); task.wait(0.2)
  mousescroll(-2); task.wait(0.3)
  moveMouse(vw * 0.925, vh * 0.159); task.wait(0.05); mouse1click(); task.wait(0.3)
  moveMouse(vw * 0.500, vh * 0.491); task.wait(0.2)
  for _ = 1, 22 do mousescroll(-120); task.wait(0.02) end
  keypress(VK_E); task.wait(0.2); keyrelease(VK_E); task.wait(0.3)

  -- Stop sell persistence, fly back, then aggressively persist at garden
  persistStop = true
  local myPlot = findPlot()
  if myPlot then
    local anchorCF = getPlotAnchor(myPlot)
    if anchorCF then
      local h = getHRP()
      if h then smoothFlight(h, anchorCF.Position) end
      local gardenStop = false
      task.spawn(function()
        while not gardenStop do
          local h = getHRP()
          if h then pcall(function() h.CFrame = anchorCF end) end
          task.wait(0.02)
        end
      end)
      task.wait(0.5)
      gardenStop = true
    end
  end


  asRun = false; asTh = nil
  safeNotify("AutoSell stopped!", "AutoSell", 3)
end

-- Anti Steal: helper functions
local function resetCharAnchoring(hrp, anchored, platformStand)
  pcall(function()
    hrp.Anchored = anchored
    local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid.PlatformStand = platformStand end
  end)
end

local function getAntiStealData()
  if not fVal("AntiSteal") then return nil end
  local p = findPlot()
  if not p then return nil end
  local ref = p:FindFirstChild("PlotSizeReference")
  if not ref then return nil end
  local hrp = getHRP()
  if not hrp then return nil end
  local ok, refCF = pcall(function() return ref.CFrame end)
  if not (ok and refCF) then return nil end
  return hrp, refCF
end

local function startSellCycle(cam, harvesting)
  pcall(function() keyrelease(VK_E) end)
  -- Fix #6: cam.CameraType is nil in Matcha — removed dead write
  -- Fix #2: task.cancel does not exist in Matcha — use flag-based stop
  if abRun then abRun = false; abTh = nil end
  if not asRun then
    asRun = true; asTh = task.spawn(autoSellLoop)
    while asRun and fVal("AutoSell") do task.wait(0.5) end
    asRun = false
  end
  if harvesting and autoBuy then
    abRun = true; abTh = task.spawn(autoBuyLoop)
    while abRun and autoBuy do task.wait(0.5) end
  end
end

-- Anti Steal loop
task.spawn(function()
  while ScriptActive do
    local hrp, refCF = getAntiStealData()
    if hrp and refCF then
      local pos = hrp.Position
      local refPos = refCF.Position
      local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(refPos.X, 0, refPos.Z)).Magnitude

      if dist > 20 then
        pcall(function() hrp.CFrame = refCF * CFrame.new(0, -3, 0) end)
      end
      pcall(function() hrp.Velocity = Vector3.new(0, 0, 0); hrp.RotVelocity = Vector3.new(0, 0, 0) end)

      local isIdle = not fVal("AutoHarvest") and not fVal("AutoSell")
      if isIdle then
        resetCharAnchoring(hrp, true, true)
        pcall(function() hrp.CFrame = refCF * CFrame.new(0, -3, 0) end)
      else
        resetCharAnchoring(hrp, false, false)
      end
    end

    if not fVal("AntiSteal") then
      local hrp2 = getHRP()
      if hrp2 then resetCharAnchoring(hrp2, false, false) end
    end

    task.wait(0.1)
  end
end)
task.spawn(function()
  print("[Farm] Waiting 3s before starting...")
  task.wait(3)
  mouse1click()
  task.wait(0.3)

  local plot = findPlot()
  if not plot then print("[Farm] No plot found"); return end
  print("[Farm] Plot: " .. plot.Name)

  local prevHarvest = false
  local cam = workspace.CurrentCamera
  local persistTimer = 0

  local lastETap = tick()
  while ScriptActive do
    local harvesting = fVal("AutoHarvest")
    local selling = fVal("AutoSell")

    if harvesting then
      local t0 = tick()
      local items = countItems()
      local t1 = tick()
      local needsSell = selling and items >= sellThreshold

      -- Step 1 & 2: Go to plot and teleport fruits (only if not full and not at sell threshold)
      if items < INV_MAX and not needsSell then
        if not plot or not plot.Parent then
          plot = findPlot()
        end
        local p = plot
        local t2 = tick()
        if p then
          local cf = getPlotAnchor(p)
          if cf then
            local h = getHRP()
            if h then
              local dist = (h.Position - cf.Position).Magnitude
              if dist > 5 then
                pcall(function() h.CFrame = cf end)
              end
            end
          end
        end
        doHarvestTick(p)
        local t3 = tick()
        if t3 - t0 > 0.15 then print("[DBG] harvest block " .. string.format("%.3f", t3 - t0) .. "s (count=" .. string.format("%.3f", t1 - t0) .. " find=" .. string.format("%.3f", t2 - t1) .. " tick=" .. string.format("%.3f", t3 - t2) .. ")") end
      end

      -- Step 3: Always spam E when harvesting (faster rate -> ~0.10s cycle)
      local gap = tick() - lastETap
      if gap > 0.2 then print("[DBG] E gap " .. string.format("%.3f", gap) .. "s") end
      lastETap = tick()
      keypress(VK_E); task.wait(0.02); keyrelease(VK_E); task.wait(0.08)

      -- Step 4 & 5: Check inventory
      items = countItems()
      if items >= INV_MAX then
        if selling then
          startSellCycle(cam, harvesting)
        end
      elseif needsSell and not asRun and tick() >= sellFailCooldown then
        local beforeSell = items
        startSellCycle(cam, harvesting)
        items = countItems()
        if items < beforeSell then
          sellFailCooldown = tick() + 5
        else
          sellFailCooldown = tick() + 2
        end
      end

      hCyc = hCyc + 1

      if hCyc >= MCYC and RSRC then
        print("[Farm] Auto-restart after " .. hCyc .. " cycles")
        _G.MatchaCleanup()
        task.wait(1)
        local chunk = loadstring(RSRC)
        if chunk then task.spawn(chunk) end
        return
      end
    else
      task.wait(0.5)
    end

    if not petBuying then
      if not plot or not plot.Parent then plot = findPlot() end
      if plot then
        if prevHarvest and not harvesting then
          pcall(function() keyrelease(VK_E) end)
          harvestBlacklist = {}
          camRestore()
        end
        prevHarvest = harvesting

        if autoBuy and not abRun and not asRun then
          abRun = true
          abTh = task.spawn(autoBuyLoop)
        elseif not autoBuy and abRun then
          -- Fix #2: task.cancel is nil in Matcha — flag stop only
          abRun = false; abTh = nil
        end

        if autoPet and not ptRun then
          scanPets(); ptRun = true; ptTh = task.spawn(petBuyLoop)
        elseif not autoPet and ptRun then
          -- Fix #2: task.cancel is nil in Matcha — flag stop only
          ptRun = false; ptTh = nil
        end

        if fVal("AutoLoot") then doLoot() end
        if fVal("AutoGold") then collectGold() end
        getPhase()
      end
    end
  end
end)

local function forceBuyNow()
  local hrp = getHRP()
  if not hrp then safeNotify("No character", "Error", 2); return end
  local savedPos = hrp.CFrame
  local seeds = workspace:FindFirstChild("Teleports") and workspace.Teleports:FindFirstChild("Seeds")
  if not seeds or not seeds:IsA("BasePart") then safeNotify("Seeds teleport not found", "Error", 2); return end
  local ok, cf = pcall(function() return seeds.CFrame end)
  if not ok or not cf then safeNotify("Bad CFrame", "Error", 2); return end
  hrp.CFrame = cf
  for _ = 1, 5 do
    keypress(VK_E)
    task.wait(0.02)
    keyrelease(VK_E)
    task.wait(0.02)
  end
  hrp.CFrame = savedPos
  safeNotify("Buy menu opened", "BUY", 2)
end

local ActionMap = {
  ForceBuy = forceBuyNow,
  SaveConfig = saveConfig,
  LoadConfig = loadConfig,
}

local function renderToggle(s, x0, yy, text, on)
  SL[s].Text = text; SL[s].Position = Vector2.new(x0 + 16, yy)
  SL[s].Color = (hov == s) and (on and C_A or C_TX) or (on and C_A or C_DM)
  SL[s].Visible = true
  SC[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
  SC[s].Color = on and C_A or C_TO; SC[s].Visible = true
  SF[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
  if on then anm[s] = math.min(1, anm[s] + 0.08) else anm[s] = math.max(0, anm[s] - 0.08) end
  if anm[s] > 0.01 then
    SF[s].Visible = true; SF[s].Radius = 1 + anm[s] * 5
    SF[s].Color = lerpColor(C_A, C_TO, 1 - anm[s])
  else SF[s].Visible = false end
end

local function renderListItem(s, x0, yy, nm, sel, extra, prefix)
  SL[s].Text = (prefix or "  ") .. nm; SL[s].Position = Vector2.new(x0 + 16, yy)
  if hov == s then SL[s].Color = sel and C_A or C_TX
  elseif sel then SL[s].Color = extra and C_A or C_DM
  else SL[s].Color = extra and C_TX or C_DM end
  SL[s].Visible = true
  SC[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
  SC[s].Color = sel and C_A or C_TO; SC[s].Visible = true
  SF[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
  if sel then anm[s] = math.min(1, anm[s] + 0.08) else anm[s] = math.max(0, anm[s] - 0.08) end
  if anm[s] > 0.01 then
    SF[s].Visible = true; SF[s].Radius = 1 + anm[s] * 5
    SF[s].Color = lerpColor(C_A, C_TO, 1 - anm[s])
  else SF[s].Visible = false end
end

local function Render()
  local x0, y0 = uiPos.X, uiPos.Y
  SHD.Position = Vector2.new(x0 - 4, y0 - 4)
  BG.Position  = Vector2.new(x0, y0)
  TB.Position  = Vector2.new(x0, y0)
  AL.Position  = Vector2.new(x0, y0 + TH)
  TT.Text = (activeTab == "farm") and "FARM HUB v2" or (activeTab == "pets") and "PETS HUB v2" or (activeTab == "seeds") and "SEEDS HUB v2" or (activeTab == "steal") and "STEAL HUB v2" or "GEARS HUB v2"
  TT.Position  = Vector2.new(x0 + uiS.X - TT.Text:len() * 7 - 8, y0 + (TH - 14) / 2)

  -- 5 equal tab zones (56px each in first 280px), text vertically centered
  local tyy = y0 + (TH - 15) / 2
  TAB_F.Position  = Vector2.new(x0 + 14,  tyy)
  TAB_P.Position  = Vector2.new(x0 + 70,  tyy)
  TAB_S.Position  = Vector2.new(x0 + 123, tyy)
  TAB_ST.Position = Vector2.new(x0 + 179, tyy)
  TAB_G.Position  = Vector2.new(x0 + 235, tyy)
  TAB_F.Color  = (activeTab == "farm")  and C_A or C_DM
  TAB_P.Color  = (activeTab == "pets")  and C_A or C_DM
  TAB_S.Color  = (activeTab == "seeds") and C_A or C_DM
  TAB_ST.Color = (activeTab == "steal") and C_A or C_DM
  TAB_G.Color  = (activeTab == "gears") and C_A or C_DM
  -- Underline indicators at bottom of header
  TAB_F_UL.Position  = Vector2.new(x0 + 0,   y0 + TH - 3)
  TAB_P_UL.Position  = Vector2.new(x0 + 56,  y0 + TH - 3)
  TAB_S_UL.Position  = Vector2.new(x0 + 112, y0 + TH - 3)
  TAB_ST_UL.Position = Vector2.new(x0 + 168, y0 + TH - 3)
  TAB_G_UL.Position  = Vector2.new(x0 + 224, y0 + TH - 3)
  TAB_F_UL.Color  = (activeTab == "farm")  and C_A or C_SP
  TAB_P_UL.Color  = (activeTab == "pets")  and C_A or C_SP
  TAB_S_UL.Color  = (activeTab == "seeds") and C_A or C_SP
  TAB_ST_UL.Color = (activeTab == "steal") and C_A or C_SP
  TAB_G_UL.Color  = (activeTab == "gears") and C_A or C_SP

  local yy0 = y0 + TH + AH + 3
  if activeTab == "farm" then
    for s = 1, MAXS do
      local f = F[s]
      if not f then
        SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false
      else
      local yy = yy0 + (s - 1) * RH
      local ih = (hov == s)
      local lc = C_TX
      if f.kind == "action" then lc = C_AC elseif f.kind == "soon" then lc = C_SN elseif f.value then lc = C_A end
      local txt = "   " .. f.label
      if f.kind == "action" then txt = ">> " .. f.label end
      SL[s].Text = txt; SL[s].Position = Vector2.new(x0 + 16, yy)
      if ih then
        if f.kind == "action" then SL[s].Color = C0(255, 210, 120)
        elseif f.value then SL[s].Color = C_A
        else SL[s].Color = C_TX end
      else SL[s].Color = lc end
      SL[s].Visible = true
      if f.kind == "toggle" then
        SC[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
        SC[s].Color = f.value and C_A or C_TO; SC[s].Visible = true
        SF[s].Position = Vector2.new(x0 + uiS.X - 44, yy + 8)
        if f.value then anm[s] = math.min(1, anm[s] + 0.08) else anm[s] = math.max(0, anm[s] - 0.08) end
        if anm[s] > 0.01 then
          SF[s].Visible = true; SF[s].Radius = 1 + anm[s] * 5
          SF[s].Color = lerpColor(C_A, C_TO, 1 - anm[s])
        else SF[s].Visible = false end
      else SC[s].Visible = false; SF[s].Visible = false end
      end
    end
    SEP.Position = Vector2.new(x0 + 12, y0 + uiS.Y - STH - 10)
    local hrp = getHRP()
    local yS = hrp and tostring(math.floor(hrp.Position.Y)) or "?"
    local pi = (phase == "Night") and "~" or (phase == "Day") and "#" or "?"
    STX.Text = "Y " .. yS .. "  |  L " .. lootCount .. "  G " .. goldCount .. "  S " .. stolenCount .. "  B " .. (abRun and "ON" or "OFF") .. "  Se " .. (asRun and "ON" or "OFF") .. "  " .. pi
    STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - STH - 4)
    SCR_U.Visible = false; SCR_D.Visible = false; SCR_B.Visible = false; CLR.Visible = false
    -- Sell threshold slider
    local sly = yy0 + MAXS * RH + 4
    SLR_TX.Text = "Sell at:"
    SLR_TX.Position = Vector2.new(x0 + 16, sly)
    SLR_TX.Visible = true
    SLR_BG.Position = Vector2.new(x0 + 70, sly + 3)
    SLR_BG.Visible = true
    local slPct = (sellThreshold - 1) / 98
    local slW = math.floor(160 * slPct)
    if slW < 4 then slW = 4 end
    SLR_FG.Position = Vector2.new(x0 + 70, sly + 3)
    SLR_FG.Size = Vector2.new(slW, 6)
    SLR_FG.Visible = true
    if slEdit then
      SLR_VL.Text = slText .. ((tick() * 4 % 1) > 0.5 and "_" or "")
    else
      SLR_VL.Text = tostring(sellThreshold)
    end
    SLR_VL.Position = Vector2.new(x0 + 240, sly)
    SLR_VL.Visible = true
  elseif activeTab == "pets" then
    SLR_BG.Visible = false; SLR_FG.Visible = false; SLR_TX.Visible = false; SLR_VL.Visible = false
    for s = 1, MAXS do SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false end
    for s = 1, MAXS do
      local yy = yy0 + (s - 1) * RH
      if s == 1 then
        renderToggle(s, x0, yy, "   AUTO PET", autoPet)
      else
        local pi = petScroll + s - 1
        local nm = ALL_PETS[pi]
        if nm then renderListItem(s, x0, yy, nm, petSelected[nm] == true, petSpawned[nm] ~= nil, petBlacklist[nm] and "! " or "* ") end
      end
    end
    SEP.Position = Vector2.new(x0 + 12, y0 + uiS.Y - STH - 10)
    local spawnedCount = 0; for _, v in pairs(petSpawned) do if v then spawnedCount = spawnedCount + 1 end end
    local blCount = 0; for _, v in pairs(petBlacklist) do if v then blCount = blCount + 1 end end
    STX.Text = "Spawned: " .. spawnedCount .. "  Sel: " .. petCount() .. "  Bl: " .. blCount .. "  P " .. (ptRun and "ON" or "OFF")
    STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - STH - 4)
    CLR.Position = Vector2.new(x0 + uiS.X - 80, y0 + uiS.Y - STH - 3)
    CLR.Visible = petCount() > 0
    SCR_U.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + 22)
    SCR_U.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + 22)
    SCR_U.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + 6)
    SCR_U.Visible = petScroll > 0
    SCR_D.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + MAXS * RH - 6)
    SCR_D.Visible = petScroll + 4 < #ALL_PETS
    if #ALL_PETS > 4 then
      local barH = math.max(10, 140 * 4 / #ALL_PETS)
      local barY = y0 + TH + AH + 14 + (140 - barH) * (petScroll / math.max(1, #ALL_PETS - 4))
      SCR_B.Size = Vector2.new(5, barH)
      SCR_B.Position = Vector2.new(x0 + uiS.X - 5, barY)
      SCR_B.Visible = true
    else SCR_B.Visible = false end
  elseif activeTab == "seeds" then
    SLR_BG.Visible = false; SLR_FG.Visible = false; SLR_TX.Visible = false; SLR_VL.Visible = false
    for s = 1, MAXS do SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false end
    for s = 1, MAXS do
      local yy = yy0 + (s - 1) * RH
      if s == 1 then
        renderToggle(s, x0, yy, "   AUTO BUY", autoBuy)
      else
        local pi = seedScroll + s - 1
        local nm = ALL_SEEDS[pi]
        if nm then renderListItem(s, x0, yy, nm, seedSelected[nm] == true, false, "") end
      end
    end
    SEP.Position = Vector2.new(x0 + 12, y0 + uiS.Y - STH - 10)
    STX.Text = "Scanned: " .. #ALL_SEEDS .. "  Sel: " .. seedCount() .. "  B " .. (abRun and "ON" or "OFF")
    STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - STH - 4)
    CLR.Position = Vector2.new(x0 + uiS.X - 80, y0 + uiS.Y - STH - 3)
    CLR.Visible = #ALL_SEEDS > 0
    SCR_U.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + 22)
    SCR_U.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + 22)
    SCR_U.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + 6)
    SCR_U.Visible = seedScroll > 0
    SCR_D.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + MAXS * RH - 6)
    SCR_D.Visible = seedScroll + 4 < #ALL_SEEDS
    if #ALL_SEEDS > 4 then
      local barH = math.max(10, 140 * 4 / #ALL_SEEDS)
      local barY = y0 + TH + AH + 14 + (140 - barH) * (seedScroll / math.max(1, #ALL_SEEDS - 4))
      SCR_B.Size = Vector2.new(5, barH)
      SCR_B.Position = Vector2.new(x0 + uiS.X - 5, barY)
      SCR_B.Visible = true
    else SCR_B.Visible = false end
  elseif activeTab == "steal" then
    SLR_BG.Visible = false; SLR_FG.Visible = false; SLR_TX.Visible = false; SLR_VL.Visible = false
    for s = 1, MAXS do SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false end
    for s = 1, MAXS do
      local yy = yy0 + (s - 1) * RH
      if s == 1 then
        renderToggle(s, x0, yy, "   AUTO STEAL", autoSteal)
      else
        local pi = stealScroll + s - 1
        local nm = stealTargets[pi]
        if nm then renderListItem(s, x0, yy, nm, stealSelected[nm] == true, false, "") end
      end
    end
    SEP.Position = Vector2.new(x0 + 12, y0 + uiS.Y - STH - 10)
    STX.Text = "Players: " .. #stealTargets .. "  Sel: " .. stealSelCount() .. "  Stolen: " .. stolenCount
    STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - STH - 4)
    CLR.Position = Vector2.new(x0 + uiS.X - 80, y0 + uiS.Y - STH - 3)
    CLR.Visible = stealSelCount() > 0
    SCR_U.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + 22)
    SCR_U.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + 22)
    SCR_U.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + 6)
    SCR_U.Visible = stealScroll > 0
    SCR_D.PointA = Vector2.new(x0 + uiS.X - 3,  y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointB = Vector2.new(x0 + uiS.X - 27, y0 + TH + AH + MAXS * RH - 22)
    SCR_D.PointC = Vector2.new(x0 + uiS.X - 15, y0 + TH + AH + MAXS * RH - 6)
    SCR_D.Visible = stealScroll + 4 < #stealTargets
    if #stealTargets > 4 then
      local barH = math.max(10, 140 * 4 / #stealTargets)
      local barY = y0 + TH + AH + 14 + (140 - barH) * (stealScroll / math.max(1, #stealTargets - 4))
      SCR_B.Size = Vector2.new(5, barH)
      SCR_B.Position = Vector2.new(x0 + uiS.X - 5, barY)
      SCR_B.Visible = true
    else SCR_B.Visible = false end
    -- Steal limit slider (reuses SLR_* drawing objects, range 1-48)
    local sly = yy0 + MAXS * RH + 4
    SLR_TX.Text = "Max fruits:"; SLR_TX.Position = Vector2.new(x0 + 16, sly); SLR_TX.Visible = true
    SLR_BG.Position = Vector2.new(x0 + 100, sly + 3); SLR_BG.Visible = true
    local slPct = (stealLimit - 1) / 47
    local slW = math.max(4, math.floor(160 * slPct))
    SLR_FG.Position = Vector2.new(x0 + 100, sly + 3)
    SLR_FG.Size = Vector2.new(slW, 6); SLR_FG.Visible = true
    SLR_VL.Text = tostring(stealLimit); SLR_VL.Position = Vector2.new(x0 + 270, sly); SLR_VL.Visible = true
  elseif activeTab == "gears" then
    SLR_BG.Visible = false; SLR_FG.Visible = false; SLR_TX.Visible = false; SLR_VL.Visible = false
    for s = 1, MAXS do SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false end
    SEP.Visible = false
    STX.Text = "Gears — SOON"
    STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - STH - 4)
    CLR.Visible = false
    SCR_U.Visible = false; SCR_D.Visible = false; SCR_B.Visible = false
  end
end

task.spawn(function()
  print("[UI] Input loop ready")
  while ScriptActive do
    task.wait(0.016)
    local mx, my = 0, 0; pcall(function() local m = player:GetMouse(); mx = m.X; my = m.Y end)
    local m1 = false; pcall(function() m1 = ismouse1pressed() end)
    local yy0 = uiPos.Y + TH + AH + 3; hov = 0

    if activeTab == "farm" then
      for s = 1, MAXS do
        local yy = yy0 + (s - 1) * RH
        if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 8 and my >= yy - 4 and my <= yy + RH then hov = s; break end
      end
      if m1 and not lastM1 then
        for s = 1, MAXS do
          local f = F[s]; local yy = yy0 + (s - 1) * RH
          if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 8 and my >= yy - 4 and my <= yy + RH then
            if f.kind == "toggle" then
              f.value = not f.value; haptic()
              print("[UI] TOGGLED: " .. f.key .. " = " .. tostring(f.value))
              local lname = f.label:match("^(.-)%s*%[") or f.label
              safeNotify(lname .. ": " .. (f.value and "ON" or "OFF"), "Toggle", 2)
            elseif f.kind == "soon" then safeNotify("Coming soon!", "WIP", 2)
            elseif f.kind == "action" then
              print("[UI] ACTION: " .. f.key); haptic()
              local h = ActionMap[f.key]; if h then task.spawn(h) end
            end
          end
        end
      end
    elseif activeTab == "pets" then
      for s = 1, MAXS do
        local yy = yy0 + (s - 1) * RH
        if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 8 and my >= yy - 4 and my <= yy + RH then hov = s; break end
      end
      if m1 and not lastM1 then
        for s = 1, MAXS do
          local yy = yy0 + (s - 1) * RH
          if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 8 and my >= yy - 4 and my <= yy + RH then
            if s == 1 then
              autoPet = not autoPet; haptic()
              print("[UI] TOGGLED: AutoPet = " .. tostring(autoPet))
              safeNotify("AutoPet: " .. (autoPet and "ON" or "OFF"), "Toggle", 2)
              if autoPet and not ptRun then
                scanPets(); ptRun = true; ptTh = task.spawn(petBuyLoop)
              elseif not autoPet and ptRun then
                -- Fix #2: task.cancel is nil in Matcha — flag stop only
                ptRun = false; ptTh = nil
              end
            else
              local pi = petScroll + s - 1
              local nm = ALL_PETS[pi]
              if nm then
                if petSelected[nm] == true then petSelected[nm] = false else petSelected[nm] = true; petBlacklist[nm] = nil end; haptic()
                print("[UI] Pet " .. nm .. " = " .. tostring(petSelected[nm]))
              end
            end
          end
        end
        local cx = uiPos.X + uiS.X - 80; local cy = uiPos.Y + uiS.Y - STH - 3
        if mx >= cx and mx <= cx + 70 and my >= cy - 2 and my <= cy + 14 and m1 and not lastM1 then
          for _, k in pairs(ALL_PETS) do petSelected[k] = false; petBlacklist[k] = nil end; haptic()
          print("[UI] CLEAR ALL pets")
          safeNotify("All pets deselected", "Pets", 2)
        end
      end
    elseif activeTab == "seeds" then
      for s = 1, MAXS do
        local yy = yy0 + (s - 1) * RH
        if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 30 and my >= yy - 4 and my <= yy + RH then hov = s; break end
      end
      if m1 and not lastM1 then
        for s = 1, MAXS do
          local yy = yy0 + (s - 1) * RH
          if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 30 and my >= yy - 4 and my <= yy + RH then
            if s == 1 then
              autoBuy = not autoBuy; haptic()
              print("[UI] TOGGLED: AutoBuy = " .. tostring(autoBuy))
              safeNotify("AutoBuy: " .. (autoBuy and "ON" or "OFF"), "Toggle", 2)
            else
              local pi = seedScroll + s - 1
              local nm = ALL_SEEDS[pi]
              if nm then
                if seedSelected[nm] == true then seedSelected[nm] = false else seedSelected[nm] = true end; haptic()
                print("[UI] Seed " .. nm .. " = " .. tostring(seedSelected[nm]))
              end
            end
          end
        end
        local cx = uiPos.X + uiS.X - 80; local cy = uiPos.Y + uiS.Y - STH - 3
        if mx >= cx and mx <= cx + 70 and my >= cy - 2 and my <= cy + 14 and m1 and not lastM1 then
          for _, k in pairs(ALL_SEEDS) do seedSelected[k] = false end; haptic()
          print("[UI] CLEAR ALL seeds")
          safeNotify("All seeds deselected", "Seeds", 2)
        end
      end
    elseif activeTab == "steal" then
      for s = 1, MAXS do
        local yy = yy0 + (s - 1) * RH
        if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 30 and my >= yy - 4 and my <= yy + RH then hov = s; break end
      end
      if m1 and not lastM1 then
        for s = 1, MAXS do
          local yy = yy0 + (s - 1) * RH
          if mx >= uiPos.X + 8 and mx <= uiPos.X + uiS.X - 30 and my >= yy - 4 and my <= yy + RH then
            if s == 1 then
              autoSteal = not autoSteal; haptic()
              print("[UI] TOGGLED: AutoSteal = " .. tostring(autoSteal))
              safeNotify("AutoSteal: " .. (autoSteal and "ON" or "OFF"), "Toggle", 2)
              if autoSteal and not stRun then
                scanStealTargets(); stRun = true; stTh = task.spawn(autoStealLoop)
              elseif not autoSteal and stRun then
                stRun = false; stTh = nil
              end
            else
              local pi = stealScroll + s - 1
              local nm = stealTargets[pi]
              if nm then
                stealSelected[nm] = not (stealSelected[nm] == true); haptic()
                print("[UI] Steal target " .. nm .. " = " .. tostring(stealSelected[nm]))
              end
            end
          end
        end
        local cx = uiPos.X + uiS.X - 80; local cy = uiPos.Y + uiS.Y - STH - 3
        if mx >= cx and mx <= cx + 70 and my >= cy - 2 and my <= cy + 14 then
          for _, k in ipairs(stealTargets) do stealSelected[k] = false end; haptic()
          print("[UI] CLEAR ALL steal targets")
          safeNotify("All steal targets cleared", "Steal", 2)
        end
      end
    elseif activeTab == "gears" then
      -- SOON placeholder — no interaction
    end

    -- Sell threshold slider interaction (farm tab only)
    if activeTab == "farm" then
      local slx0 = uiPos.X + 70
      local sly0 = uiPos.Y + TH + AH + 3 + MAXS * RH + 4 + 3
      local slAreaX = mx >= slx0 and mx <= slx0 + 160
      local slAreaY = my >= sly0 - 4 and my <= sly0 + 10
      -- Click on number to type
      local nrx = uiPos.X + 240
      if m1 and not lastM1 and mx >= nrx and mx <= nrx + 30 and my >= sly0 - 4 and my <= sly0 + 14 then
        slEdit = true
        slText = ""
        haptic()
      elseif m1 and not lastM1 and slEdit then
        -- Click outside: confirm
        local val = tonumber(slText)
        if val and val >= 1 and val <= 99 then sellThreshold = val end
        slEdit = false; slText = ""
        haptic()
      end
      -- Slider drag
      if m1 and slAreaX and slAreaY and not slEdit then
        local pct = math.max(0, math.min(1, (mx - slx0) / 160))
        sellThreshold = math.max(1, math.min(99, math.floor(pct * 98 + 1 + 0.5)))
        haptic()
      end
    end

    -- Steal limit slider interaction (steal tab only)
    if activeTab == "steal" then
      local slx0 = uiPos.X + 100
      local sly0 = uiPos.Y + TH + AH + 3 + MAXS * RH + 4 + 3
      if m1 and mx >= slx0 and mx <= slx0 + 160 and my >= sly0 - 4 and my <= sly0 + 10 then
        local pct = math.max(0, math.min(1, (mx - slx0) / 160))
        stealLimit = math.max(1, math.min(48, math.floor(pct * 47 + 1 + 0.5)))
        haptic()
      end
    end

    -- tab switch click
    if m1 and not lastM1 then
      -- Tab zones: 4 x 70px in first 280px, full header height (TH) as click area
      -- Remaining 110px (x0+280 to x0+389) is title/drag area
      local tabY0 = uiPos.Y; local tabY1 = uiPos.Y + TH; local tabHit = false
      if mx >= uiPos.X+0   and mx <= uiPos.X+55  and my >= tabY0 and my <= tabY1 then activeTab = "farm";  tabHit = true; haptic() end
      if mx >= uiPos.X+56  and mx <= uiPos.X+111 and my >= tabY0 and my <= tabY1 then activeTab = "pets";  petScroll = 0; scanPets(); tabHit = true; haptic() end
      if mx >= uiPos.X+112 and mx <= uiPos.X+167 and my >= tabY0 and my <= tabY1 then activeTab = "seeds"; seedScroll = 0; tabHit = true; haptic() end
      if mx >= uiPos.X+168 and mx <= uiPos.X+223 and my >= tabY0 and my <= tabY1 then activeTab = "steal"; stealScroll = 0; scanStealTargets(); tabHit = true; haptic() end
      if mx >= uiPos.X+224 and mx <= uiPos.X+279 and my >= tabY0 and my <= tabY1 then activeTab = "gears"; tabHit = true; haptic() end

      if not tabHit and mx >= uiPos.X+280 and mx <= uiPos.X + uiS.X and my >= uiPos.Y and my <= uiPos.Y + TH then
        drg = true; dOff = Vector2.new(mx - uiPos.X, my - uiPos.Y)
      end
    end

    -- pet/seed scroll via arrow keys + mouse wheel
    -- Sell threshold number input
    if slEdit then
      local numberKeys = {
        [0x30] = "0", [0x31] = "1", [0x32] = "2", [0x33] = "3", [0x34] = "4",
        [0x35] = "5", [0x36] = "6", [0x37] = "7", [0x38] = "8", [0x39] = "9",
      }
      for vk, digit in pairs(numberKeys) do
        if iskeypressed(vk) and not slLastKeys[vk] then
          if #slText < 2 then slText = slText .. digit end
        end
      end
      if iskeypressed(0x08) and not slLastKeys[0x08] then
        slText = slText:sub(1, -2)
      end
      if iskeypressed(0x0D) and not slLastKeys[0x0D] then
        local val = tonumber(slText)
        if val and val >= 1 and val <= 99 then sellThreshold = val end
        slEdit = false; slText = ""
      end
      if iskeypressed(0x1B) and not slLastKeys[0x1B] then
        slEdit = false; slText = ""
      end
    end
    slLastKeys = {}
    for _, vk in ipairs({0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37,0x38,0x39,0x08,0x0D,0x1B}) do
      slLastKeys[vk] = iskeypressed(vk)
    end
    local inUI = mx >= uiPos.X and mx <= uiPos.X + uiS.X and my >= uiPos.Y and my <= uiPos.Y + uiS.Y
    pcall(function()
      if activeTab == "pets" and inUI then
        if iskeypressed(0x28) then
          if petScroll + 4 < #ALL_PETS then petScroll = petScroll + 1; task.wait(0.12) end
        elseif iskeypressed(0x26) then
          if petScroll > 0 then petScroll = petScroll - 1; task.wait(0.12) end
        end
      elseif activeTab == "seeds" and inUI then
        if iskeypressed(0x28) then
          if seedScroll + 4 < #ALL_SEEDS then seedScroll = seedScroll + 1; task.wait(0.12) end
        elseif iskeypressed(0x26) then
          if seedScroll > 0 then seedScroll = seedScroll - 1; task.wait(0.12) end
        end
      elseif activeTab == "steal" and inUI then
        if iskeypressed(0x28) then
          if stealScroll + 4 < #stealTargets then stealScroll = stealScroll + 1; task.wait(0.12) end
        elseif iskeypressed(0x26) then
          if stealScroll > 0 then stealScroll = stealScroll - 1; task.wait(0.12) end
        end
      end
    end)
    -- Fix #7: WheelForward/WheelBackward do not exist in Matcha — removed dead API
    -- Scroll handled by arrow keys (0x26/0x28) and arrow click detection below

    -- Arrow click detection
    if m1 and not lastM1 and inUI then
      local ax = uiPos.X + uiS.X - 30
      local aw = 30
      local upY = uiPos.Y + TH + AH + 4
      local dnY = uiPos.Y + TH + AH + MAXS * RH - 24
      if mx >= ax and mx <= ax + aw then
        if my >= upY and my <= upY + 22 then
          if activeTab == "pets" and petScroll > 0 then petScroll = petScroll - 1; haptic() end
          if activeTab == "seeds" and seedScroll > 0 then seedScroll = seedScroll - 1; haptic() end
          if activeTab == "steal" and stealScroll > 0 then stealScroll = stealScroll - 1; haptic() end
        end
        if my >= dnY and my <= dnY + 22 then
          if activeTab == "pets" and petScroll + 4 < #ALL_PETS then petScroll = petScroll + 1; haptic() end
          if activeTab == "seeds" and seedScroll + 4 < #ALL_SEEDS then seedScroll = seedScroll + 1; haptic() end
          if activeTab == "steal" and stealScroll + 4 < #stealTargets then stealScroll = stealScroll + 1; haptic() end
        end
      end
    end

    pcall(function()
      for _, f in ipairs(F) do
        if f.hotkey and iskeypressed(f.hotkey) and f.kind == "toggle" and f.value then
          f.value = false
          print("[UI] KEY OFF: " .. f.key)
          safeNotify(f.label:match("^(.-)%s*%[") .. " OFF", "Hotkey", 2)
          task.wait(0.3)
        end
      end

      if iskeypressed(0x35) then
        for _, f in ipairs(F) do
          if f.kind == "toggle" and f.value then
            f.value = false
            print("[UI] KEY ALL OFF: " .. f.key)
          end
        end
        autoBuy = false; autoSteal = false; autoGear = false
        safeNotify("ALL OFF (except AutoPet)", "Hotkey [5]", 2)
        task.wait(0.3)
      end
    end)

    if drg then
      if m1 then uiPos = Vector2.new(mx - dOff.X, my - dOff.Y) else drg = false end
    end
    lastM1 = m1; local rok, rerr = pcall(Render); if not rok then print("[UI] Render error:", tostring(rerr)) end
  end
end)

_G.MatchaCleanup = function()
  ScriptActive = false
  pcall(function() keyrelease(VK_E) end)
  -- Fix #2: task.cancel is nil in Matcha — loops exit via ScriptActive/abRun/asRun/ptRun flags
  abRun = false; abTh = nil
  asRun = false; asTh = nil
  ptRun = false; ptTh = nil
  stRun = false; stTh = nil; autoSteal = false
  agRun = false; agTh = nil; autoGear = false
  -- Fix #6: cam.CameraType is nil in Matcha — removed dead write
  for _, obj in ipairs(drawObjs) do pcall(function() obj:Remove() end) end
  print("[Farm] Cleanup done")
end

safeNotify("Farm loaded!", "Garden 2", 3)
print("ready")
