local PLUGIN = PLUGIN
PLUGIN.schema = "HL2 RP"
PLUGIN.name = "voiceLines"
PLUGIN.author = "4illNation"
PLUGIN.description = "Adds voice lines during convoiceLinesual situations."

-- [Requirements]
-- extrahl2rpvoices.lua:https://github.com/4illnation/lua
-- hl2_ep1_male01_voices: https://steamcommunity.com/sharedfiles/filedetails/?id=3164508401

-- Version: VERSION 2.1

-- To change the timer or the voice type for the voices, go down where the sendVoiceLine function is called and change the 4th argument.
-- sendVoiceLine(ply, 'ic', voiceLines, x)

-- [NPC Classes]
local entityTable = {
    combines = {'npc_combine_s', 'npc_metropolice'},
    citizens = {'npc_citizen'},
    headcrabs = {'npc_headcrab', 'npc_headcrab_fast', 'npc_headcrab_black'},
    zombies = {'npc_fastzombie', 'npc_fastzombie_torso', 'npc_zombie_torso', 'npc_zombie', 'npc_poisonzombie', 'npc_zombine'},
    grenades = {'npc_grenade_frag'}
}

-- [VOICES]
local playerVoices = {
    citizenVoices = {
        {'got one', 'got one2'}, -- [1]  NPC / Player Kill
        {'shit', 'shit2', 'help', "i'm hurt"}, -- [2]  PlayerHurt
        {'help6'}, -- [3]  Unused.
        {'Grenade out!'}, -- [4]  Grenade Send
        {'incoming'}, -- [5]  Grenade receive
        {'shit2', 'shit'}, -- [6]  Fall
        {'help', 'no', "i'm hurt"}, -- [7]  PlayerHurt
        {'oh no', 'no2'}, -- [8]  This index is broken. Don't use it
        {'reload', 'reload2'}, -- [9]  Reload
        {'headcrabs', 'headcrabs2'}, -- [10] Headcrabs
        {'zombies', 'zombies2'}, -- [11] Zombies
        {'combine'}, -- [12] Combine Detection
        
        -- Female Only
        {'help', 'no', "i'm hurt"}, -- [12] PlayerHurt
        {'oh no', 'no2'},-- This index is broken. Don't use it
        {'oh no', 'no2'} -- [14] Fall
    },

    combineVoices = {
        {'final verdict', 'one down'}, -- [1] NPC / Player Kill
        {'10-78', 'needs help'}, -- [2] PlayerHurt 
        {'11-99'}, -- [3] Unused
        {'ripcordripcord', 'flaredown'}, -- [4] Grenade Send
        {'grenade', 'bouncerbouncer'}, -- [5] Grenade receive
        {'shit'}, -- [6] Fall
        {'back me up'}, -- [7] Reload
        {'necrotics', 'outbreak'} -- [8] Headcrabs & Zombies
    }
}

local function isNoClipping(ply)
    if not IsValid(ply) then return end
    return ply:GetMoveType() == MOVETYPE_NOCLIP
end

local function isCitizen(ply)
    if not IsValid(ply) then return end
    return ply:Team() == FACTION_CITIZEN
end

local function isEntityClass(getClass, entityTable)
    for _, entity in pairs(entityTable) do
        if getClass == entity then 
            return true
        end
    end
    return false
end

local function invalidWeapons(ply)
    local invalidWeaponTypes = {'npc_grenade_frag', 'weapon_grenade', 'weapon_rpg', 'ix_hands'}
    local activeWeapon = ply:GetActiveWeapon()
    if IsValid(activeWeapon) then
        for _, weaponType in ipairs(invalidWeaponTypes) do
            if activeWeapon:GetClass() == weaponType then
                return true
            end
        end
    end
    return false
end

local plyIsFalling
local reloadFrame = {}
local playerTimers = {}
local newIndex = {}
local lastIndex = {}
local grenade_CurrentDetection = {}
local grenade_PreviousDetection = {}
local headcrab_CurrentDetection = {}
local headcrab_PreviousDetection = {}
local zombie_CurrentDetection = {}
local zombie_PreviousDetection = {}
local combine_CurrentDetection = {}
local combine_PreviousDetection = {}

local function customTimerHandler(ply, timerDuration, voiceLines)
    if not playerTimers[ply] then
        playerTimers[ply] = { lastVoiceIndex = nil }
    end

    if not playerTimers[ply][voiceLines] or CurTime() - playerTimers[ply][voiceLines] >= timerDuration then
        playerTimers[ply][voiceLines] = CurTime()
        return true
    end
    return false
end

local function sendVoiceLine(ply, channel, voiceLines, timerDuration)
    if customTimerHandler(ply, timerDuration, voiceLines) then
        local lastIndex = playerTimers[ply].lastVoiceIndex

        repeat
            newIndex = math.random(#voiceLines)
        until newIndex ~= lastIndex

        playerTimers[ply].lastVoiceIndex = newIndex
        ix.chat.Send(ply, channel, voiceLines[newIndex])
    end
end

function PLUGIN:OnNPCKilled(npc, attacker)
	if not attacker:IsPlayer() then return end
    
    local voiceLines
	if attacker:IsCombine() then
		voiceLines = playerVoices.combineVoices[1]
	elseif isCitizen(attacker) then
		voiceLines = playerVoices.citizenVoices[1]
	end
    if voiceLines then
	    sendVoiceLine(attacker, 'y', voiceLines, 0)
    end
end

function PLUGIN:PlayerHurt(victim, attacker)
    if attacker:IsWorld() then return end
    if invalidWeapons(attacker) then return end
    
    local voiceLines
    if victim:IsCombine() then
        voiceLines = playerVoices.combineVoices[2]
    elseif isCitizen(victim) and victim:IsFemale() then
        voiceLines = playerVoices.citizenVoices[7]
    elseif isCitizen(victim) and not victim:IsFemale() then
        voiceLines = playerVoices.citizenVoices[2]
    end
    if voiceLines then
        sendVoiceLine(victim, 'y', voiceLines, 3)
    end
end

function PLUGIN:PlayerDeath(victim, inflictor, attacker)
    if isNoClipping(attacker) then return end
    if attacker:IsNPC() then return end
    if attacker:IsWorld() then return end
    if isCitizen(attacker) and isCitizen(victim) then return end
    
    local voiceLines
    if attacker:IsCombine() then
        voiceLines = playerVoices.combineVoices[1]
    elseif isCitizen(attacker) and victim:IsCombine() then
        voiceLines = playerVoices.citizenVoices[1]
    end
    if voiceLines then
        sendVoiceLine(ply, 'y', voiceLines, 0)
    end
end

local function weaponReload(ply, currentWeapon)
    if isNoClipping(ply) or ply:IsBot() then return end
    local voiceLines
    local ammoType = currentWeapon:GetPrimaryAmmoType()
    local maxAmmo = currentWeapon:GetMaxClip1()
    local ammoCount = currentWeapon:Clip1()
    local reserveCount = ply:GetAmmoCount(ammoType)
    if not IsValid(currentWeapon) then return end

    if IsValid(ply) and IsValid(currentWeapon) then
        if not reloadFrame[ply] then
            if ammoCount == 0 and reserveCount == 0 then return end
            if ply:IsCombine() and ammoCount == 0 and reserveCount > 0 then 
                voiceLines = playerVoices.combineVoices[7]
                sendVoiceLine(ply, 'y', voiceLines, 5)
            elseif isCitizen(ply) and ammoCount == 0 and reserveCount > 0 then
                voiceLines = playerVoices.citizenVoices[9]
                sendVoiceLine(ply, 'y', voiceLines, 5)
            end
            reloadFrame[ply] = true            
        end
    end

    if reloadFrame[ply] then
        reloadFrame[ply] = false
    end
end

function playerFallVelocity(ply)
    local velocity = ply:GetVelocity().z
    if velocity < 0 then
        local playerVelocity = math.abs(velocity)
        return playerVelocity
    else
        return 0
    end
end

local function playerFall(ply)
    if isNoClipping(ply) then return end
    
    local voiceLines
    local playerVelocity = playerFallVelocity(ply)
    if playerVelocity >= 550 and not plyIsFalling then
        plyIsFalling = true
        -- Female voices disabled here due to a bug.
        if isCitizen(ply) and ply:IsFemale() then
            voiceLines = playerVoices.citizenVoices[14]
        elseif ply:IsCombine() then
            voiceLines = playerVoices.combineVoices[6]
        elseif isCitizen(ply) then
            voiceLines = playerVoices.citizenVoices[6]
        end
        plyIsFalling = nil
        sendVoiceLine(ply, 'y', voiceLines, 5)
    end
end

local function detectPlayer(entityTable, detectionRadius, playerVoices, detectionType)
    for _, ent in pairs(ents.GetAll()) do
        local entPos = ent:GetPos()
        local entSphere = ents.FindInSphere(entPos, detectionRadius)
        local currentEntity = ent
        if #entSphere > 0 then
            for _, ply in ipairs(player.GetAll()) do
                local alreadyDetected = detectionType[currentEntity] and detectionType[currentEntity][ply]
                if not alreadyDetected then
                    for _, entsInRange in pairs(entSphere) do
                        if entsInRange:IsPlayer() and entsInRange == ply then
                            if isNoClipping(ply) then return end
                            detectionType[currentEntity] = detectionType[currentEntity] or {}
                            detectionType[currentEntity][ply] = true
                            local voiceLines
                            if isEntityClass(currentEntity:GetClass(), entityTable.grenades) then
                                local owner = currentEntity:GetOwner()
                                if owner == ply then
                                    if ply:IsCombine() then
                                        voiceLines = playerVoices.combineVoices[4]
                                    elseif isCitizen(ply) then
                                        voiceLines = playerVoices.citizenVoices[4]
                                    end
                                elseif owner ~= ply then
                                    if ply:IsCombine() then
                                        voiceLines = playerVoices.combineVoices[5]
                                    elseif isCitizen(ply) then
                                        voiceLines = playerVoices.citizenVoices[5]
                                    end
                                end
                            elseif isEntityClass(currentEntity:GetClass(), entityTable.headcrabs) then
                                if ply:IsCombine() then
                                    voiceLines = playerVoices.combineVoices[8]
                                elseif isCitizen(ply) then
                                    voiceLines = playerVoices.citizenVoices[10]
                                end
                            elseif isEntityClass(currentEntity:GetClass(), entityTable.zombies) then
                                if ply:IsCombine() then
                                    voiceLines = playerVoices.combineVoices[8]
                                elseif isCitizen(ply) then
                                    voiceLines = playerVoices.citizenVoices[11]
                                end
                            end
                            if voiceLines then
                                sendVoiceLine(ply, 'y', voiceLines, 1)
                            end
                            break
                        end
                    end
                end
            end
        end
    end
end

function PLUGIN:PlayerTick(ply)
    ply = ply or LocalPlayer()

    if CLIENT then return end

    local grenadeRadius = 100
    local headcrabRadius = 200
    local zombieRadius = 300

    for _, v in pairs(ents.GetAll()) do
        if isEntityClass(v:GetClass(), entityTable.grenades) then
            detectPlayer(entityTable, grenadeRadius, playerVoices, grenade_CurrentDetection)
        elseif isEntityClass(v:GetClass(), entityTable.headcrabs) then
            detectPlayer(entityTable, headcrabRadius, playerVoices, headcrab_CurrentDetection)
        elseif isEntityClass(v:GetClass(), entityTable.zombies) then
            detectPlayer(entityTable, zombieRadius, playerVoices, zombie_CurrentDetection)
        end
    end
    weaponReload(ply, ply:GetActiveWeapon())
    invalidWeapons(ply)
    playerFall(ply)
end