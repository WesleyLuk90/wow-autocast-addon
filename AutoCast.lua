local AutoCastFrame = CreateFrame("Frame", "AutoCastFrame", UIParent)
AutoCastFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
AutoCastFrame:SetWidth(200)
AutoCastFrame:SetHeight(200)
AutoCastFrame:SetFrameStrata("TOOLTIP")

local Texture = AutoCastFrame:CreateTexture("AutoCastFrameTexture", "OVERLAY")

MyValues = {
	571000 + 565,
	0,
	414000 + 804
}

Texture:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
Texture:SetWidth(1)
Texture:SetHeight(1)

local function SetColor(r, g, b)
	Texture:SetTexture(r / 255, g / 255, b / 255)
end

SetColor(0, 0, 0)

function Debug(text)
	if false then
		print(text)
	end
end

local index = 0
local function GetIndex()
	i = index
	index = (index + 1) % 10
	return i
end

-- Control Functions
local function DoNothing()
	Debug("Do nothing")
	-- SetColor(0, 0, 0)
	MyValues[2] = 0
end

local function DoSkill(skillKey)
	MyValues[2] = skillKey
	SetColor(0, 0, skillKey)
end

-- Utility functions
-- 
function TargetHasDebuff(buff)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
		= UnitAura("target", buff, nil, "PLAYER|HARMFUL")
	return name ~= nil
end
function DebuffTimeRemaining(buff)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
		= UnitAura("target", buff, nil, "PLAYER|HARMFUL")
	return expirationTime - GetTime()
end
function GetPlayerCasting()
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, interrupt = UnitCastingInfo("player")
	return spell
end
function GetPlayerCastingRemaining()
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, interrupt = UnitCastingInfo("player")
	return endTime/1000 - GetTime()
end
function SelfHasBuff(buff)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
		= UnitAura("player", buff, nil, "PLAYER")
	return name ~= nil
end
function SelfBuffCount(buff)
	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
		= UnitAura("player", buff, nil, "PLAYER")
	return count
end

function IsSkillReady(skill)
	local start, duration, enabled = GetSpellCooldown(skill)
	return start == 0
end

function GetCooldown(skill)
	local start, duration, enabled = GetSpellCooldown(skill)
	if start == 0 then
		return 0
	end
	return start + duration - GetTime()
end

function GetSkillCastTime(skill)
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(skill)
	return castTime / 1000
end

function GetManaPercent()
	return UnitPower("player", SPELL_POWER_MANA) / UnitPowerMax ("player", SPELL_POWER_MANA)
end

function GetRunicPower()
	return UnitPower("player", SPELL_POWER_RUNIC)
end

function GetPlayerChannel()
	local name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
	return name
end

function GetPlayerChannelNextTick()
	local name, subText, text, texture, startTime, endTime, isTradeSkill, notInterruptible = UnitChannelInfo("player")
	startTime = startTime / 1000
	endTime = endTime / 1000
	local tick = (endTime - startTime) / 5
	local remaining = endTime - GetTime()
	local ticksLeft = math.floor(remaining / tick)
	return endTime - ticksLeft * tick
end

function GetTargetHPPercent()
	return UnitHealth("target") / UnitHealthMax("target")
end

function GetPlayerHPPercent()
	return UnitHealth("player") / UnitHealthMax("player")
end

local LastCast = nil
local EndTickTime = nil
AutocastIsRunning = true

SLASH_AUTOCAST1 = '/autocast'

function SlashCmdList.AUTOCAST(msg, editbox)
	AutocastIsRunning = not AutocastIsRunning
	if AutocastIsRunning then
		print ("Autocast is running")
	else
		print ("Autocast is not running")
	end
end

local UseCurseOfElements = false
SLASH_USEELEMENTS1 = '/USEELEMENTS'

function SlashCmdList.USEELEMENTS(msg, editbox)
	UseCurseOfElements = not UseCurseOfElements
	if UseCurseOfElements then
		print ("Using curse of elements")
	else
		print ("Not using curse of elements")
	end
end

local LevelingAutoCast = false
SLASH_DOLEVELING1 = '/doleveling'

function SlashCmdList.DOLEVELING(msg, editbox)
	LevelingAutoCast = not LevelingAutoCast
	if LevelingAutoCast then
		print ("Doing Leveling")
	else
		print ("Not Doing Leveling")
	end
end

local DELAY_ESTIMATE = 0.2;

local function Update()
	if not AutocastIsRunning then
		DoSkill(0)
		return
	end
	localizedClass, englishClass = UnitClass("player")
	if localizedClass == "Warlock" then
		if LevelingAutoCast then
			WarlockLeveling()
			return
		end
		if GetActiveTalentGroup(false, false) == 1 then
			WarlockAffRotation()
		elseif GetActiveTalentGroup(false, false) == 2 then
			-- WarlockDestroRotation()
			WarlockDemoRotation()
		end
	end
	if localizedClass == "Death Knight" then
		if GetActiveTalentGroup(false, false) == 1 then
			DKFrostRotation()
		end
		if GetActiveTalentGroup(false, false) == 2 then
			DKTankRotation()
		end
	end
end

local KEY_1 = 1
local KEY_2 = 2
local KEY_3 = 3
local KEY_4 = 4
local KEY_Q = 5
local KEY_E = 6
local KEY_F = 7
local KEY_R = 8
local KEY_V = 9
local KEY_5 = 10
local KEY_6 = 11
local KEY_Z = 12
local KEY_X = 13
local KEY_C = 14
function WarlockLeveling()
	local CORRUPTION = KEY_4
	local LIFETAP = KEY_Q

	if UnitName("target") == nil then
		DoSkill(0)
		return
	end

	if UnitName("targettarget") == nil then
		DoSkill(0)
		return
	end

	if UnitIsDead("targettarget") then
		DoSkill(0)
		return
	end

	if GetManaPercent() < 0.25 and IsSkillReady("Life Tap") then
		DoSkill(LIFETAP)
		return
	end

	local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId
		= UnitAura("targettarget", "Corruption", nil, "PLAYER|HARMFUL")

	if UnitIsTapped("targettarget") and IsSkillReady("Corruption") and not name then
		DoSkill(CORRUPTION)
		return
	end

	DoSkill(0);
end
function WarlockAffRotation()

	local CORRUPTION_KEY = KEY_4
	local COA_KEY = KEY_3
	local UA_KEY = KEY_2
	local HAUNT_KEY = KEY_1
	local LT_KEY = KEY_Q
	local SB_KEY = KEY_E
	local DRAIN_SOUL_KEY = KEY_F

	if UnitName("target") == nil then
		DoSkill(0)
		return
	end
	if GetPlayerCasting() ~= nil then
		if GetPlayerCastingRemaining() > DELAY_ESTIMATE then
			DoSkill(0)
			LastCast = GetPlayerCasting()
			return
		end
	end
	if GetPlayerChannel() == "Drain Soul" then
		if EndTickTime == nil then
			EndTickTime = GetPlayerChannelNextTick()
			-- print("Next Tick" .. EndTickTime)
		end
		-- print(EndTickTime - GetTime() .. " seconds remaining")
		-- If we have not reached the new tick
		if EndTickTime > GetTime() then
			DoSkill(0)
			return
		end
	end
	if not TargetHasDebuff("Haunt") and GetCooldown("Haunt") < DELAY_ESTIMATE then
		DoSkill(HAUNT_KEY)
		return
	end
	if IsSkillReady("Haunt") then
		DoSkill(HAUNT_KEY)
		return
	end

	if TargetHasDebuff("Corruption") then
		if DebuffTimeRemaining("Corruption") < GetSkillCastTime("Corruption") then
			DoSkill(DRAIN_SOUL_KEY)
			return
		end

		if DebuffTimeRemaining("Corruption") < 3 then
			DoSkill(CORRUPTION_KEY)
			return
		end
	end

	if not TargetHasDebuff("Corruption") and GetCooldown("Corruption") < DELAY_ESTIMATE then
		DoSkill(CORRUPTION_KEY)
		return
	end
	if LastCast ~= "Unstable Affliction" and GetCooldown("Unstable Affliction") < DELAY_ESTIMATE then
		if not TargetHasDebuff("Unstable Affliction") then
			DoSkill(UA_KEY)
			return
		end
		if DebuffTimeRemaining("Unstable Affliction") < GetSkillCastTime("Unstable Affliction") then
			DoSkill(UA_KEY)
			return
		end
	end
	if not TargetHasDebuff("Curse of Agony") and
		not TargetHasDebuff("Curse of the Elements") then
		DoSkill(COA_KEY)
		return
	end
	if not SelfHasBuff("Life Tap") or GetManaPercent() < 0.25 then
		DoSkill(LT_KEY)
		return
	end
	if GetTargetHPPercent() > 0.25
		-- and	false
		then
		DoSkill(SB_KEY)
	else
		if not GetPlayerChannel() then
			DoSkill(DRAIN_SOUL_KEY)
		end
		EndTickTime = nil
	end
end


function WarlockDemoRotation()
	local LIFETAP = KEY_Q
	local CORRUPTION = KEY_1
	local IMMOLATE = KEY_2
	local SHADOWBOLT = KEY_E
	local INCINERATE = KEY_R
	local SOULFIRE = KEY_3
	local CURSEOFDOOM = KEY_5
	local CURSEOFELEMENTS = KEY_4
	local CURSEOFAGONY = KEY_6

	if UnitName("target") == nil then
		DoSkill(0)
		return
	end

	if GetPlayerCasting() ~= nil then
		if GetPlayerCastingRemaining() > DELAY_ESTIMATE then
			DoSkill(0)
			LastCast = GetPlayerCasting()
			return
		end
	end

	if not SelfHasBuff("Life Tap") then
		DoSkill(LIFETAP)
		return
	end

	if not TargetHasDebuff("Curse of Agony") and
		not TargetHasDebuff("Curse of the Elements") and
		not TargetHasDebuff("Curse of Doom") then
		if UseCurseOfElements then
			DoSkill(CURSEOFELEMENTS)
			return
		else
			if UnitHealth("target") > 2000000 and GetCooldown("Curse of Doom") < DELAY_ESTIMATE then
				DoSkill(CURSEOFDOOM)
			else
				DoSkill(CURSEOFAGONY)
			end
			return
		end
	end

	if not TargetHasDebuff("Corruption") then
		DoSkill(CORRUPTION)
		return
	end

	if not TargetHasDebuff("Immolate") and LastCast ~= "Immolate" then
		DoSkill(IMMOLATE)
		return
	end

	if GetManaPercent() < 0.25 then
		DoSkill(LIFETAP)
		return
	end

	if SelfHasBuff("Molten Core") then
		if SelfBuffCount("Molten Core") > 1 then
			DoSkill(INCINERATE)
			return
		end
		if SelfBuffCount("Molten Core") == 1 and
			GetPlayerCasting() ~= "Incinerate" then

			DoSkill(INCINERATE)
			return
		end
	end

	-- Filler skills follow

	if not TargetHasDebuff("Shadow Mastery") then
		DoSkill(SHADOWBOLT)
		-- print("No shadow mastery")
		return
	end

	if SelfHasBuff("Decimation") then
		DoSkill(SOULFIRE)
		return
	end

	DoSkill(SHADOWBOLT)
end


function WarlockDestroRotation()
	local IMMOLATE = 1
	local CONFLAGRATE = 2
	local CHAOS_BOLT = 3
	local CURSE = 4
	local LIFETAP = 5
	local INCINERATE = 6

	if UnitName("target") == nil then
		DoSkill(0)
		return
	end
	if GetPlayerCasting() ~= nil then
		if GetPlayerCastingRemaining() > DELAY_ESTIMATE then
			DoSkill(0)
			LastCast = GetPlayerCasting()
			return
		end
	end

	if not TargetHasDebuff("Curse of Doom") and
		not TargetHasDebuff("Curse of the Elements")
	then
		DoSkill(CURSE)
		return
	end

	if not TargetHasDebuff("Immolate") and
		GetCooldown("Immolate") < DELAY_ESTIMATE and
		LastCast ~= "Immolate"
	then
		DoSkill(IMMOLATE)
		return
	end

	if GetCooldown("Chaos Bolt") < DELAY_ESTIMATE	then
		DoSkill(CHAOS_BOLT)
		return
	end

	if GetCooldown("Conflagrate") < DELAY_ESTIMATE	then
		DoSkill(CONFLAGRATE)
		return
	end

	if not SelfHasBuff("Life Tap") or GetManaPercent() < 0.25 then
		DoSkill(LIFETAP)
		return
	end

	if GetCooldown("Incinerate") < DELAY_ESTIMATE	then
		DoSkill(INCINERATE)
		return
	end

	DoSkill(0)
end

function DKFrostRotation()
	local ICY_TOUCH = 1
	local PLAGUE_STRIKE = 2
	local FROST_STRIKE = 3
	local OBLITERATE = 5
	local BLOOD_STRIKE = 6
	local HOWLING_BLAST = 8
	local HOW = 9

	if SelfHasBuff("Killing Machine") and 
		GetRunicPower() >= 32 and 
		GetCooldown("Frost Strike") < DELAY_ESTIMATE 
	then
		DoSkill(FROST_STRIKE)
		return
	end

	if not TargetHasDebuff("Frost Fever") and 
		GetCooldown("Icy Touch") < DELAY_ESTIMATE
	then
		DoSkill(ICY_TOUCH)
		return
	end

	if not TargetHasDebuff("Blood Plague") and 
		GetCooldown("Plague Strike") < DELAY_ESTIMATE
	then
		DoSkill(PLAGUE_STRIKE)
		return
	end

	if GetCooldown("Obliterate") < DELAY_ESTIMATE then
		DoSkill(OBLITERATE)
		return
	end

	if GetCooldown("Blood Strike") < DELAY_ESTIMATE then
		DoSkill(BLOOD_STRIKE)
		return
	end

	if SelfHasBuff("Freezing Fog") and 
		GetCooldown("Howling Blast") < DELAY_ESTIMATE
	then
		DoSkill(HOWLING_BLAST)
		return
	end

	if GetRunicPower() >= 64 and 
		GetCooldown("Frost Strike") < DELAY_ESTIMATE
	then
		DoSkill(BLOOD_STRIKE)
		return
	end

	if GetCooldown("Horn of Winter") < DELAY_ESTIMATE then
		DoSkill(HOW)
		return
	end

	DoSkill(0)
end

local function countEffectiveBloodRunes()
	local runes = 0
	for i=1,6 do
		if GetRuneCooldown(1) == 0 then -- Rune is ready
			if GetRuneType(i) == 1 or GetRuneType(i) == 4 then
				runes = runes + 1
			end
		end
	end
	return runes
end

local function timeTillNextBloodRune()
	local minimum = 10
	for i=1,6 do
		local start, duration, ready = GetRuneCooldown(1)
		if start > 0 then -- Rune is on cd
			if GetRuneType(i) == 1 or GetRuneType(i) == 4 then
				local timeLeft = start + duration - GetTime()
				if timeLeft < minimum then
					minimum = timeLeft
				end
			end
		end
	end
	return minimum
end

function DKTankRotation()
	local ICY_TOUCH = KEY_1
	local PLAGUE_STRIKE = KEY_2
	local HEART_STRIKE = KEY_3
	local DEATH_STRIKE = KEY_E
	local RUNE_STRIKE = KEY_4
	local HOW = KEY_F
	local PESTILENCE = KEY_C

	local blood1, blood1d = GetRuneCooldown(1)
	local blood2, blood2d = GetRuneCooldown(2)

	if blood1 > 0 then
		blood1 = blood1 + blood1d - GetTime()
	end
	if blood2 > 0 then
		blood2 = blood2 + blood2d - GetTime()
	end

	if UnitName("target") == nil then
		DoSkill(0)
		return
	end

	if not TargetHasDebuff("Frost Fever") and 
		GetCooldown("Icy Touch") < DELAY_ESTIMATE
	then
		DoSkill(ICY_TOUCH)
		return
	end

	if not TargetHasDebuff("Blood Plague") and 
		GetCooldown("Plague Strike") < DELAY_ESTIMATE
	then
		DoSkill(PLAGUE_STRIKE)
		return
	end

	if GetPlayerHPPercent() < 0.9 and GetCooldown("Death Strike") < DELAY_ESTIMATE then
		DoSkill(DEATH_STRIKE)
		return
	end

	local shouldUsePestilence = TargetHasDebuff("Frost Fever") and TargetHasDebuff("Blood Plague")

	if shouldUsePestilence then 
		if DebuffTimeRemaining("Frost Fever") < 3 or DebuffTimeRemaining("Blood Plague") < 3 then
			if GetCooldown("Pestilence") < DELAY_ESTIMATE then
				DoSkill(PESTILENCE)
				return
			end
		end
	end

	if GetPlayerHPPercent() > 0.9 and GetCooldown("Icy Touch") < DELAY_ESTIMATE then
		DoSkill(ICY_TOUCH)
		return
	end

	if GetCooldown("Heart Strike") < DELAY_ESTIMATE then
		DoSkill(HEART_STRIKE)
		return
	end

	if GetCooldown("Death Strike") < DELAY_ESTIMATE then
		DoSkill(DEATH_STRIKE)
		return
	end

	if GetCooldown("Horn of Winter") < DELAY_ESTIMATE then
		DoSkill(HOW)
		return
	end

	if GetRunicPower() >= 60 then
		DoSkill(RUNE_STRIKE)
		return
	end

	DoSkill(0)

end

AutoCastFrame:SetScript("OnUpdate", Update)