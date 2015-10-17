local addonName, addon = ...
addon._G = _G
setfenv(1, addon)

local spell = "Wrath"

local math = _G.math
--local print = _G.print
local print = function(...) end

local handlerFrame = _G.CreateFrame("Frame")
local texture

local update
do
  local rotation = 0
  local alpha = 0
  local deltaAlpha = 1.5

  update = function(self, elapsed)
    local start, duration = _G.GetSpellCooldown(spell)

    if not start or not duration then
      return
    end

    if start == 0 or duration == 0 then -- GCD inactive.
      if alpha ~= 0 then
        alpha = math.max(0, alpha - deltaAlpha * elapsed)
        texture:SetAlpha(alpha)
      elseif rotation ~= 0 then
        rotation = 0
        texture:SetRotation(rotation)
      end
      if math.abs(rotation) >= 2 * math.pi * (15 / 16) then
        rotation = 0
        texture:SetRotation(rotation)
      end
    else
      rotation = -2 * math.pi * (--[[_G.GetTime() < start and 0 or --]]_G.GetTime() - start) / duration
      alpha = math.min(1, alpha + deltaAlpha * elapsed)
      texture:SetRotation(rotation)
      texture:SetAlpha(alpha)
    end
  end
end

handlerFrame:SetScript("OnUpdate", update)

--[=[
local epsilon = 0.01
local maxAlpha = 1
local animationGroup, initialRotation, rotation, fadeIn, fadeOut

local cachedStart, cachedDuration = 0, 0
local cachedAlpha, cachedRadians = 0, 0

local function updateAnimations()
  local start, duration = _G.GetSpellCooldown(spell)

  if not start or not duration then
    return false
  end

  if (start == 0 or duration == 0) and (cachedStart ~= 0 or cachedDuration ~= 0) then -- GCD inactive.
    cachedStart, cachedDuration = 0, 0
    if rotation:IsPlaying() then
      if rotation:GetProgress() >= 0.99 then
        -- ...
      else
        cachedRadians = initialRotation:GetRadians() + rotation:GetRadians() * rotation:GetProgress()
        cachedAlpha = texture:GetAlpha()
        animationGroup:Stop() -- Hide the GCD indicator instantly.
        initialAlpha:SetChange(cachedAlpha)
        fadeIn:SetChange(0)
        fadeIn:SetDuration(0)
        fadeOut:SetChange(-cachedAlpha)
        initialRotation:SetRadians(cachedRadians)
        --_G.print(cachedRadians)
        rotation:SetRadians(0)
        rotation:SetDuration(0)
        animationGroup:Play()
      end
      return true
    end
    return false
  elseif math.abs(start - cachedStart) <= epsilon and math.abs(duration - cachedDuration) <= epsilon then
    return false -- Nothing changed much.
  end

  -- The GCD indicator needs a new set of animations.

  cachedAlpha = texture:GetAlpha()

  -- This shouldn't happen.
  --if cachedAlpha > maxAlpha then cachedAlpha = maxAlpha end

  if animationGroup:IsPlaying() then
    --[[
    if animationGroup:GetProgress() >= 0.95 then
      return false
    end
    ]]
    animationGroup:Stop()
  end

  cachedStart = start
  cachedDuration = duration

  local elapsed = --[[_G.GetTime() < start and 0 or --]]_G.GetTime() - start
  local remaining = duration - elapsed

  _G.assert(texture:GetAlpha() == 0)

  initialAlpha:SetChange(cachedAlpha)
  fadeIn:SetChange(maxAlpha - cachedAlpha)
  fadeIn:SetDuration(0.5)
  fadeOut:SetChange(-maxAlpha)
  --texture:SetRotation(-2 * math.pi * elapsed / duration)
  initialRotation:SetRadians(-2 * math.pi * elapsed / duration)
  rotation:SetRadians(-2 * math.pi * remaining / duration)
  rotation:SetDuration(remaining)
  animationGroup:Play()

  return true
end

handlerFrame:SetScript("OnUpdate", function(self, elapsed)
  local updated = updateAnimations()
end)
--]=]

handlerFrame:SetScript("OnEvent", function(self, event, ...)
  return self[event](self, ...)
end)

--[[
function handlerFrame:SPELL_UPDATE_COOLDOWN()
  updateAnimations()
end

handlerFrame.SPELL_UPDATE_USABLE = handlerFrame.SPELL_UPDATE_COOLDOWN
--]]

function handlerFrame:ADDON_LOADED(...)
  _G.assert(_G.Minimap)

  texture = _G.Minimap:CreateTexture()
  texture:SetTexture([[Interface\AddOns\]] .. addonName .. [[\gcd_indicator]])
  texture:SetPoint("CENTER", 0, 0)
  texture:SetHeight(2.02 * _G.Minimap:GetHeight() * math.sqrt(2))
  texture:SetWidth(2.02 * _G.Minimap:GetWidth() * math.sqrt(2))
  texture:SetAlpha(0)

  --[=[
  animationGroup = texture:CreateAnimationGroup()
  animationGroup:SetIgnoreFramerateThrottle(true)
  animationGroup:SetLooping("NONE")

  initialRotation = animationGroup:CreateAnimation("Rotation")
  initialRotation:SetSmoothing("NONE")
  initialRotation:SetOrder(1)
  initialRotation:SetDuration(0)

  rotation = animationGroup:CreateAnimation("Rotation")
  rotation:SetSmoothing("NONE")
  rotation:SetOrder(2)

  initialAlpha = animationGroup:CreateAnimation("Alpha")
  initialAlpha:SetSmoothing("NONE")
  initialAlpha:SetOrder(1)
  initialAlpha:SetDuration(0)

  fadeIn = animationGroup:CreateAnimation("Alpha")
  fadeIn:SetSmoothing("NONE")
  fadeIn:SetOrder(2)
  fadeIn:SetChange(maxAlpha)
  fadeIn:SetDuration(0.5)

  fadeOut = animationGroup:CreateAnimation("Alpha")
  fadeOut:SetSmoothing("NONE")
  fadeOut:SetOrder(3)
  fadeOut:SetChange(-maxAlpha)
  fadeOut:SetDuration(0.5)
  fadeOut:SetScript("OnPlay", function(self, requested)
    fadeOut:SetChange(-texture:GetAlpha())
  end)
  --[[
  fadeOut:SetScript("OnStop", function(self, requested)
    initialAlpha:SetChange(texture:GetAlpha())
    fadeIn:SetChange(maxAlpha - texture:GetAlpha())
  end)
  --]]
  --]=]

  -- Neither of these events is sufficiently fast or reliable.
  --self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
  --self:RegisterEvent("SPELL_UPDATE_USABLE")

  self:UnregisterEvent("ADDON_LOADED")
  self.ADDON_LOADED = nil
end

handlerFrame:RegisterEvent("ADDON_LOADED")

-- vim: tw=120 sts=2 sw=2 et
