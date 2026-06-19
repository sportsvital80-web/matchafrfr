if _G.FishCatchCleanup then pcall(_G.FishCatchCleanup) end
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
local player    = players.LocalPlayer
local UIS       = game:GetService("UserInputService")

local drawObjs = {}
local function D(typ, props)
  local obj = Drawing.new(typ)
  for k, v in pairs(props) do obj[k] = v end
  table.insert(drawObjs, obj)
  return obj
end

local C0 = Color3.fromRGB
local C_A  = C0(0, 212, 170)
local C_BG = C0(14, 14, 22)
local C_TP = C0(24, 24, 38)
local C_TX = C0(225, 225, 235)
local C_DM = C0(100, 100, 115)
local C_TO = C0(55, 55, 72)
local C_AC = C0(255, 186, 76)
local C_SP = C0(30, 30, 48)

local function lerpColor(a, b, t)
  return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function haptic()
  pcall(function()
    UIS.HapticFeedback = Enum.HapticFeedbackType.HighFrequencyVibration
    task.delay(0.05, function() pcall(function() UIS.HapticFeedback = Enum.HapticFeedbackType.End end) end)
  end)
end

local MAXS = 2
local uiPos = Vector2.new(150, 120)
local RH = 30; local TH = 34; local AH = 2
local uiS = Vector2.new(390, TH + AH + RH * MAXS + 6 + 8 + 14 + 6)
local drg, dOff, lastM1, hov = false, Vector2.new(0, 0), false, 0

local SHD = D("Square", {Size = Vector2.new(uiS.X + 8, uiS.Y + 8), Color = C0(0,0,0), Transparency = 0.4, Filled = true, Visible = true})
local BG  = D("Square", {Size = uiS, Color = C_BG, Filled = true, Visible = true})
local TB  = D("Square", {Size = Vector2.new(uiS.X, TH), Color = C_TP, Filled = true, Visible = true})
local AL  = D("Square", {Size = Vector2.new(uiS.X, AH), Color = C_A, Filled = true, Visible = true})
local TT  = D("Text",   {Text = "FISH AUTO CATCH", Size = 14, Color = C_A, Outline = true, Visible = true, Font = Drawing.Fonts.System})

local SL, SC, SF, anm = {}, {}, {}, {}

for i = 1, MAXS do
  SL[i] = D("Text",   {Text = "", Size = 13, Color = C_TX, Outline = true, Visible = false, Font = Drawing.Fonts.System})
  SC[i] = D("Circle", {Radius = 9, Thickness = 2, Color = C_TO, Filled = false, Visible = false})
  SF[i] = D("Circle", {Radius = 6, Color = C_A, Filled = true, Visible = false})
  anm[i] = 0
end
local SEP = D("Square", {Size = Vector2.new(uiS.X - 24, 1), Color = C_SP, Filled = true, Visible = true})
local STX = D("Text", {Text = "", Size = 11, Color = C_DM, Outline = true, Visible = true, Font = Drawing.Fonts.System})

local F = {}
local function feat(key, label, kind)
  local f = {key = key, label = label, kind = kind, value = false}
  table.insert(F, f)
  return f
end

feat("AutoFish", "AUTO FISH [1]", "toggle")
feat("AutoSell", "AUTO SELL [2]", "toggle")

local function safeNotify(msg, title, dur)
  pcall(function() notify(tostring(msg), tostring(title or "Fish"), dur or 3) end)
end

-- Cached GUI elements
local cachedTL      = nil
local cachedPerfect = nil

local function findFishingGUI()
  cachedTL = nil; cachedPerfect = nil
  local gui = player:FindFirstChild("PlayerGui")
  if not gui then return end
  local fgt = gui:FindFirstChild("FishGameTemplate")
  if not fgt then return end
  local main = fgt:FindFirstChild("Main")
  if not main then return end
  local tf = main:FindFirstChild("TargetFrame")
  if not tf then return end
  local tl = tf:FindFirstChild("TargetLine")
  if tl then cachedTL = tl end
  local tgt = tf:FindFirstChild("Target")
  if tgt then
    local perf = tgt:FindFirstChild("Perfect")
    if perf then cachedPerfect = perf end
  end
end

local function isWidgetValid(obj)
  if not obj then return false end
  local ok, parent = pcall(function() return obj.Parent end)
  if not ok or not parent then return false end
  local ok2, isDescendant = pcall(function() return obj:IsDescendantOf(player:FindFirstChild("PlayerGui")) end)
  if not ok2 or not isDescendant then return false end
  local gui = player:FindFirstChild("PlayerGui")
  local fgt = gui and gui:FindFirstChild("FishGameTemplate")
  if not fgt then return false end
  local ok3, enabled = pcall(function() return fgt.Enabled end)
  local ok4, visible = pcall(function() return fgt.Visible end)
  if ok3 and not enabled then return false end
  if ok4 and not visible then return false end
  return true
end

local function getLineY()
  if not isWidgetValid(cachedTL) then findFishingGUI() end
  if not cachedTL then return nil end
  local ok, p = pcall(function() return cachedTL.AbsolutePosition.Y end)
  if not ok then cachedTL = nil; findFishingGUI(); return nil end
  return p
end

local function getPerfectY()
  if not isWidgetValid(cachedPerfect) then findFishingGUI() end
  if not cachedPerfect then return nil end
  local ok, p = pcall(function() return cachedPerfect.AbsolutePosition.Y end)
  if not ok then cachedPerfect = nil; findFishingGUI(); return nil end
  return p
end

local function isFishingActive()
  local ly = getLineY()
  local py = getPerfectY()
  return ly and py and ly > 0 and py > 0
end

-- Fish catch loop
local fishRunning = false
local ready = true
local wasActive = false
local wasSelling = false
local prevLy = nil
local staleFrames = 0
local STALE_THRESHOLD = 15

local function fishLoop()
  while ScriptActive and F[1].value do
    if sellingNow then
      wasSelling = true
      task.wait(0.5)
    elseif wasSelling then
      wasSelling = false
      wasActive = false
      cachedTL = nil; cachedPerfect = nil
      prevLy = nil; staleFrames = 0; ready = true
      task.wait(0.3)
    end
    pcall(function()
      local active = isFishingActive()
      if active and not wasActive then
        cachedTL = nil; cachedPerfect = nil
        prevLy = nil; staleFrames = 0
        ready = true
      end
      wasActive = active

      if active then
        local ly = getLineY()
        local py = getPerfectY()

        if ly and py then
          if prevLy ~= nil and math.abs(ly - prevLy) < 0.5 then
            staleFrames = staleFrames + 1
          else
            staleFrames = 0
          end
          prevLy = ly

          if staleFrames < STALE_THRESHOLD then
            if ly >= py and ly <= py + 6 and ready then
              pcall(function() mouse1press() end)
              task.wait(0.03)
              pcall(function() mouse1release() end)
              haptic()
              ready = false
            elseif math.abs(py - ly) > 15 then
              ready = true
            end
          end
        end
      else
        prevLy = nil; staleFrames = 0
      end
    end)
    task.wait()
  end
  fishRunning = false
end

-- Auto Sell
local sellRunning = false
local sellingNow = false

local function findPlayerModel()
  local iceHoles = workspace:FindFirstChild("IceHoles")
  if not iceHoles then return nil end
  local pname = player.Name
  for _, child in pairs(iceHoles:GetChildren()) do
    local m = child:FindFirstChild(pname)
    if m then return m end
  end
  return nil
end

local function getSellHandle()
  local m = findPlayerModel()
  if not m then return nil end
  local co = m:FindFirstChild("CanvasObjects")
  if not co then return nil end
  local cc = co:FindFirstChild("Coldman Cooler")
  if not cc then return nil end
  local h = cc:FindFirstChild("Handle")
  if h and h:IsA("BasePart") then return h end
  return nil
end

local function findPlayerCenterPart()
  local m = findPlayerModel()
  if not m then return nil end
  local cp = m:FindFirstChild("CenterPart")
  if cp and cp:IsA("BasePart") then return cp end
  return nil
end

local function getAmountLabel()
  local m = findPlayerModel()
  if not m then return nil end
  local co = m:FindFirstChild("CanvasObjects")
  if not co then return nil end
  local cc = co:FindFirstChild("Coldman Cooler")
  if not cc then return nil end
  local main = cc:FindFirstChild("Main")
  if not main then return nil end
  local da = main:FindFirstChild("DisplayAttachment")
  if not da then return nil end
  local disp = da:FindFirstChild("Display")
  if not disp then return nil end
  local frame = disp:FindFirstChild("Frame")
  if not frame then return nil end
  return frame:FindFirstChild("AmountLabel")
end

local function getCarPet()
  local fm = workspace:FindFirstChild("FishMarket")
  if not fm then return nil end
  local fr = fm:FindFirstChild("FloorRug")
  if not fr then return nil end
  local cp = fr:FindFirstChild("Carpet")
  if cp and cp:IsA("BasePart") then return cp end
  return nil
end

local function tpTo(part, yOff)
  local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if hrp and part then
    hrp.CFrame = CFrame.new(part.Position.X, part.Position.Y + (yOff or 2), part.Position.Z)
    task.wait(0.2)
  end
end

local function pressE()
  keypress(0x45)
  task.wait(0.05)
  keyrelease(0x45)
end

local function sellFlow()
  local handle = getSellHandle()
  if not handle then return false end
  local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
  if not hrp then return false end

  print("[SELL] TP to Coldman Cooler Handle")
  tpTo(handle, 3)
  task.wait(0.1)
  print("[SELL] Pressing E to pick up")
  pressE()
  task.wait(0.3)

  local ok, cc = pcall(function() return handle.CanCollide end)
  if ok and not cc then
    print("[SELL] Picked up — TP to Carpet")
    local carPet = getCarPet()
    if carPet then
      tpTo(carPet, 2)
      task.wait(1)
    end
    print("[SELL] TP back to CenterPart — pressing E")
    local cp = findPlayerCenterPart()
    if cp then
      tpTo(cp, 2)
      task.wait(0.15)
      pressE()
    end
    return true
  else
    print("[SELL] Not picked up — CanCollide=true, retrying")
    return false
  end
end

local function sellLoop()
  while ScriptActive and F[2].value do
    pcall(function()
      local al = getAmountLabel()
      if not al then task.wait(2); return end

      local ok, text = pcall(function() return al.Text end)
      if not ok or not text then task.wait(2); return end

      local cur, max = text:match("(%d+)/(%d+)")
      if not cur or not max then task.wait(2); return end

      cur = tonumber(cur); max = tonumber(max)
      print("[SELL] Cooler: " .. cur .. "/" .. max)

      if cur >= max then
        print("[SELL] Cooler full — starting sell flow")
        sellingNow = true
        local sold = false
        local attempts = 0
        while not sold and attempts < 10 and ScriptActive and F[2].value do
          sold = sellFlow()
          attempts = attempts + 1
          if not sold then task.wait(1.5) end
        end
        sellingNow = false
        if sold then print("[SELL] Sell complete — monitoring resumed") end
      end
    end)
    task.wait(2)
  end
  sellRunning = false; sellingNow = false
end

local function Render()
  local x0, y0 = uiPos.X, uiPos.Y
  SHD.Position = Vector2.new(x0 - 4, y0 - 4)
  BG.Position  = Vector2.new(x0, y0)
  TB.Position  = Vector2.new(x0, y0)
  AL.Position  = Vector2.new(x0, y0 + TH)
  TT.Position  = Vector2.new(x0 + uiS.X - TT.Text:len() * 7 - 10, y0 + 9)

  local yy0 = y0 + TH + AH + 3
  for s = 1, MAXS do
    local f = F[s]
    if not f then
      SL[s].Visible = false; SC[s].Visible = false; SF[s].Visible = false
    else
      local yy = yy0 + (s - 1) * RH
      local lc = f.value and C_A or C_TX
      local txt = "   " .. f.label
      SL[s].Text = txt; SL[s].Position = Vector2.new(x0 + 16, yy)
      SL[s].Color = (hov == s) and C_TX or lc
      SL[s].Visible = true
      SC[s].Position = Vector2.new(x0 + uiS.X - 28, yy + 8)
      SC[s].Color = f.value and C_A or C_TO; SC[s].Visible = true
      SF[s].Position = Vector2.new(x0 + uiS.X - 28, yy + 8)
      if f.value then anm[s] = math.min(1, anm[s] + 0.08) else anm[s] = math.max(0, anm[s] - 0.08) end
      if anm[s] > 0.01 then
        SF[s].Visible = true; SF[s].Radius = 1 + anm[s] * 5
        SF[s].Color = lerpColor(C_A, C_TO, 1 - anm[s])
      else SF[s].Visible = false end
    end
  end

  SEP.Position = Vector2.new(x0 + 12, y0 + uiS.Y - 24)
  STX.Text = (isFishingActive() and "FISHING" or "HIDDEN") .. " | FISH:" .. (F[1].value and "ON" or "OFF") .. " SELL:" .. (F[2].value and "ON" or "OFF")
  STX.Position = Vector2.new(x0 + 14, y0 + uiS.Y - 18)
end

task.spawn(function()
  while ScriptActive do
    task.wait(0.016)
    local mx, my = 0, 0
    pcall(function() local m = player:GetMouse(); mx = m.X; my = m.Y end)
    local m1 = false
    pcall(function() m1 = ismouse1pressed() end)
    local yy0 = uiPos.Y + TH + AH + 3
    hov = 0

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
              safeNotify(f.label .. ": " .. (f.value and "ON" or "OFF"), "Toggle", 2)
              if f.key == "AutoFish" then
                if f.value and not fishRunning then
                  findFishingGUI()
                  fishRunning = true
                  task.spawn(fishLoop)
                end
              elseif f.key == "AutoSell" then
                if f.value and not sellRunning then
                  sellRunning = true
                  task.spawn(sellLoop)
                end
              end
            end
        end
      end
      if mx >= uiPos.X and mx <= uiPos.X + uiS.X and my >= uiPos.Y and my <= uiPos.Y + TH then
        drg = true; dOff = Vector2.new(mx - uiPos.X, my - uiPos.Y)
      end
    end

    pcall(function()
      if iskeypressed(0x31) and F[1].value then
        F[1].value = false; haptic()
        safeNotify("AUTO FISH OFF", "Hotkey", 2)
        task.wait(0.3)
      end
    end)
    pcall(function()
      if iskeypressed(0x32) and F[2].value then
        F[2].value = false; haptic()
        safeNotify("AUTO SELL OFF", "Hotkey", 2)
        task.wait(0.3)
      end
    end)

    if drg then
      if m1 then uiPos = Vector2.new(mx - dOff.X, my - dOff.Y) else drg = false end
    end
    lastM1 = m1
    pcall(Render)
  end
end)

_G.FishCatchCleanup = function()
  ScriptActive = false
  for _, obj in ipairs(drawObjs) do pcall(function() obj:Remove() end) end
  print("[FishCatch] Cleanup done")
end

print("ready")
