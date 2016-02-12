--[[TO DO:--
compare
better filtering, STARTED
reset & exit button
target tracking
--]]
local _, iEET = ...
iEET.data = {}
iEET.font = 'Interface\\AddOns\\iEncounterEventTracker\\Accidental Presidency.ttf'
iEET.fontsize = 12
iEET.spacing = 2
iEET.justifyH = 'LEFT'
iEET.backdrop = {
	bgFile = 'Interface\\Buttons\\WHITE8x8', 
	edgeFile = 'Interface\\Buttons\\WHITE8x8', 
	edgeSize = 1, 
	insets = {
		left = -1,
		right = -1,
		top = -1,
		bottom = -1,
	}
}	
iEET.version = 1.300
local colors = {}
local eventsToTrack = {
	['SPELL_CAST_START'] = 'SC_START',
	['SPELL_CAST_SUCCESS'] = 'SC_SUCCESS',
	['SPELL_AURA_APPLIED'] = '+SAURA',
	['SPELL_AURA_REMOVED'] = '-SAURA',
	['SPELL_AURA_APPLIED_DOSE'] = '+SA_DOSE',
	['SPELL_AURA_REMOVED_DOSE'] = '-SA_DOSE',
	['SPELL_AURA_REFRESH'] = 'SAURA_R',
	['SPELL_CAST_FAILED'] = 'SC_FAILED',
	['SPELL_CREATE'] = 'SPELL_CREATE',
	['SPELL_SUMMON'] = 'SPELL_SUMMON',
	['SPELL_HEAL'] = 'SPELL_HEAL',
	
	['SPELL_PERIODIC_CAST_START'] = 'SPC_START',
	['SPELL_PERIODIC_CAST_SUCCESS'] = 'SPC_SUCCESS',
	['SPELL_PERIODIC_AURA_APPLIED'] = '+SPAURA',
	['SPELL_PERIODIC_AURA_REMOVED'] = '-SPAURA',
	['SPELL_PERIODIC_AURA_APPLIED_DOSE'] = '+SPA_DOSE',
	['SPELL_PERIODIC_AURA_REMOVED_DOSE'] = '-SPA_DOSE',
	['SPELL_PERIODIC_AURA_REFRESH'] = 'SPAURA_R',
	['SPELL_PERIODIC_CAST_FAILED'] = 'SPC_FAILED',
	['SPELL_PERIODIC_CREATE'] = 'SP_CREATE',
	['SPELL_PERIODIC_SUMMON'] = 'SP_SUMMON',
	['SPELL_PERIODIC_HEAL'] = 'SP_HEAL',
};
local monsterEvents = {
	['MONSTER_SAY'] = true,
	['MONSTER_EMOTE'] = true,
	['MONSTER_YELL'] = true,
};

local addon = CreateFrame("Frame")
addon:SetScript("OnEvent", function(self, event, ...)
	self[event](self, ...)
end)
addon:RegisterEvent('ENCOUNTER_START')
addon:RegisterEvent('ENCOUNTER_END')
addon:RegisterEvent('ADDON_LOADED')
local function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
	
    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
function iEET:LoadDefaults()
	iEETConfig.tracking = {
		['USC_SUCCEEDED'] = true,
		['SC_START'] = true,
		['SC_SUCCESS'] = true,
		['+SAURA'] = true,
		['-SAURA'] = true,
		['+SA_DOSE'] = true,
		['-SA_DOSE'] = true,
		['SAURA_R'] = true,
		['SC_FAILED'] = true,
		['SPELL_CREATE'] = true,
		['SPELL_SUMMON'] = true,
		['SPELL_HEAL'] = true,
		['SPC_START'] = true,
		['SPC_SUCCESS'] = true,
		['+SPAURA'] = true,
		['-SPAURA'] = true,
		['+SPA_DOSE'] = true,
		['-SPA_DOSE'] = true,
		['SPAURA_R'] = true,
		['SPC_FAILED'] = true,
		['SP_CREATE'] = true,
		['SP_SUMMON'] = true,
		['SP_HEAL'] = true,
		['MONSTER_SAY'] = true,
		['MONSTER_EMOTE'] = true,
		['MONSTER_YELL'] = true,
	}
	iEETConfig.version = iEET.version
	iEETConfig.autoSave = false
	iEETConfig.autoDiscard = 30
	iEETConfig.filtering = {} -- NEW, TESTING
	print('iEET: loaded default settings.')
end
function addon:ADDON_LOADED(addonName)
	if addonName == 'iEncounterEventTracker' then
		iEETConfig = iEETConfig or {}
		if not iEETConfig.version or not iEETConfig.tracking or iEETConfig.version < iEET.version then
			iEET:LoadDefaults()
		else
			iEETConfig.version = iEET.version
		end
		addon:UnregisterEvent('ADDON_LOADED')
	end
end
function addon:ENCOUNTER_START(encounterID, encounterName)
	iEET.data = nil
	iEET.data = {}
	iEET.encounterInfoData = { --TODO
		['start'] = GetTime(),
		['encounterName'] = encounterName,
		['pullTime'] = date('%y.%m.%d %H:%M'), -- y.m.d instead of d.m.y for easier sorting
		['fightTime'] = '00:00',
		['difficulty']= 0,
		['raidSize'] = 0,
		['kill'] = 0,
	}
	iEET.encounterInfo = date('%d.%m.%y %H:%M') .. ' ' .. encounterName
	table.insert(iEET.data, {['event'] = 'ENCOUNTER_START', ['timestamp'] = GetTime(), ['casterName'] = encounterName, ['targetName'] = encounterID})
	addon:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	addon:RegisterEvent('CHAT_MSG_MONSTER_SAY')
	addon:RegisterEvent('CHAT_MSG_MONSTER_EMOTE')
	addon:RegisterEvent('CHAT_MSG_MONSTER_YELL')
	addon:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
end
function addon:ENCOUNTER_END(EncounterID, encounterName, difficultyID, raidSize, kill)
	table.insert(iEET.data, {['event'] = 'ENCOUNTER_END', ['timestamp'] = GetTime() ,['casterName'] = kill == 1 and 'Victory!' or 'Wipe'})
	addon:UnregisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
	addon:UnregisterEvent('CHAT_MSG_MONSTER_SAY')
	addon:UnregisterEvent('CHAT_MSG_MONSTER_EMOTE')
	addon:UnregisterEvent('CHAT_MSG_MONSTER_YELL')
	addon:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	iEET.encounterInfoData.fightTime = iEET.encounterInfoData.start and date('%M:%S', (GetTime() - iEET.encounterInfoData.start)) or '00:00' -- if we are missing start time for some reason
	iEET.encounterInfoData.difficulty = difficultyID
	iEET.encounterInfoData.kill = kill
	iEET.encounterInfoData.raidSize = raidSize
	if iEETConfig.autoSave then
		iEET:ExportData(true)
	end
end
function addon:UNIT_SPELLCAST_SUCCEEDED(unitID, spellName,_,_,spellID)
	local sourceGUID = UnitGUID(unitID)
	local unitType, _, serverID, instanceID, zoneID, npcID, spawnID
	if sourceGUID then -- fix for arena id's
		unitType, _, serverID, instanceID, zoneID, npcID, spawnID = strsplit("-", sourceGUID)
	end
	if (unitType == 'Creature') or (unitType == 'Vehicle') or (spellID and iEET.approvedSpells[spellID]) or not sourceGUID then
		local sourceName = UnitName(unitID)
		local chp = UnitHealth(unitID)
		local maxhp = UnitHealthMax(unitID)
		local php = nil
		if chp and maxhp then
			php = math.floor(chp/maxhp*1000+0.5)/10
		end
		if not iEET.npcIgnoreList[tonumber(npcID)] then
			if not iEET.ignoredSpells[spellID] then
				table.insert(iEET.data, {
					['event'] = 'USC_SUCCEEDED',
					['timestamp'] = GetTime(),
					['sourceGUID'] = sourceGUID or 'NONE',
					['casterName'] = sourceName or 'NONE',
					['targetName'] = unitID or nil,
					['spellName'] = spellName or nil,
					['spellID'] = spellID or nil,
					['hp'] = php or nil,
				});
			end
		end
	end	
end
function addon:CHAT_MSG_MONSTER_EMOTE(msg, sourceName)
	table.insert(iEET.data, {
		['event'] = 'MONSTER_EMOTE',
		['timestamp'] = GetTime(),
		['spellID'] = msg,
		['casterName'] = sourceName,
		['sourceGUID'] = sourceName,
	});
end
function addon:CHAT_MSG_MONSTER_SAY(msg, sourceName)
	table.insert(iEET.data, {
		['event'] = 'MONSTER_SAY',
		['timestamp'] = GetTime(),
		['spellID'] = msg,
		['casterName'] = sourceName,
		['sourceGUID'] = sourceName,
	});
end
function addon:CHAT_MSG_MONSTER_YELL(msg, sourceName)
	table.insert(iEET.data, {
		['event'] = 'MONSTER_YELL',
		['timestamp'] = GetTime(),
		['spellID'] = msg,
		['casterName'] = sourceName,
		['sourceGUID'] = sourceName,
	});
end
function addon:COMBAT_LOG_EVENT_UNFILTERED(timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceRaidFlags,destGUID,destName,destFlags,destRaidFlags,...)
	if eventsToTrack[event] then
		local spellID, spellName = ...
		local unitType, _, serverID, instanceID, zoneID, npcID, spawnID
		if sourceGUID then -- fix for arena id's
			unitType, _, serverID, instanceID, zoneID, npcID, spawnID = strsplit("-", sourceGUID)
		end
		if (unitType == 'Creature') or (unitType == 'Vehicle') or (spellID and iEET.approvedSpells[spellID]) or not sourceGUID or hideCaster then
			if spellID and not iEET.ignoredSpells[spellID] then
				if not iEET.npcIgnoreList[tonumber(npcID)] then
					table.insert(iEET.data, {
						['event'] = eventsToTrack[event],
						['timestamp'] = GetTime(),
						['sourceGUID'] = sourceGUID or 'NONE',
						['casterName'] = sourceName or 'NONE',
						['targetName'] = destName or nil,
						['spellName'] = spellName or 'NONE',
						['spellID'] = spellID or 'NONE',
					});
				end
			end
		end
	end
end
function addon:UNIT_TARGET(unitID)
	
end
function iEET:getColor(event, sourceGUID, spellID)
	if sourceGUID then
		if colors[sourceGUID] and colors[sourceGUID][event] and colors[sourceGUID][event][spellID] then
			return {colors[sourceGUID][event][spellID].r,colors[sourceGUID][event][spellID].g,colors[sourceGUID][event][spellID].b}
		end
		-- https://www.w3.org/WAI/ER/WD-AERT/#color-contrast
		local t, i = {}, 0
		repeat
			t = {
				['r'] = math.random(),
				['g'] = math.random(),
				['b'] = math.random(),
				};
				i = i + 1
		until (((t.r * 255 * 299) + (t.g * 255 * 587) + (t.b * 255 * 114)) / 1000 > 125 or i >= 10)
		if colors[sourceGUID] then
			if colors[sourceGUID][event] then
				if not colors[sourceGUID][event][spellID] then
					colors[sourceGUID][event][spellID] = t
				end
			else
				colors[sourceGUID][event] = {[spellID] = t}
			end
		else
			colors[sourceGUID] = {[event] = {[spellID] = t}}
		end
		return {colors[sourceGUID][event][spellID].r,colors[sourceGUID][event][spellID].g,colors[sourceGUID][event][spellID].b}
	elseif event == 'ENCOUNTER_START' then
		return {0,1,0}
	elseif event == 'ENCOUNTER_END' then
		return {1,0,0}
	else
		return {0,0,0}
	end
end
function iEET:ScrollContent(delta)
	if delta == -1 then
		for i = 1, 8 do
			--local f = _G['iEET_content' .. i]
			
			if IsShiftKeyDown() then
				iEET['content' .. i]:PageDown()
			else
				iEET['content' .. i]:ScrollDown()
			end
		end
	else
		for i = 1, 8 do
			if IsShiftKeyDown() then
				iEET['content' .. i]:PageUp()
			else
				iEET['content' .. i]:ScrollUp()
			end				
		end
	end
end
function iEET:ScrollDetails(delta)
	if delta == -1 then
		for i = 1, 7 do
			if i == 4 then
			else
				if IsShiftKeyDown() then
					iEET['detailContent' .. i]:PageDown()
				else
					iEET['detailContent' .. i]:ScrollDown()
				end
			end
		end
	else
		for i = 1, 7 do
			if i == 4 then
			else
				if IsShiftKeyDown() then
					iEET['detailContent' .. i]:PageUp()
				else
					iEET['detailContent' .. i]:ScrollUp()
				end	
			end
		end
	end
end
function iEET:ShouldShow(eventData) -- NEW, TESTING
	--[[
	iEET.filtering = {
		timeBasedFiltering = {
			[1] = {
				from = { (or nil)
					timestamp/event/spellid/etc = X
				} ,
				to = { (or nil)
					timestamp/event/spellid/etc = X
				},
				ok = true/false
			}
			...
		},
		req = {
			[1] = {
				event/spellid/etc = X,
				event/spellid/etc = X,
				...
			} ,
		},
		requireAll = true/false, --require all from/to combos
		anyData = X,
		showTime = true -- show time from nearest 'from' event instead of ENCOUNTER_START
		
	}
	
	
	]]
	local timeOK = true
	if #iEET.filtering.timeBasedFiltering > 0 then
		for i = 1, #iEET.filtering.req do -- loop trough every from/to combo
			if iEET.filtering.timeBasedFiltering[i].from then
				if iEET.filtering.timeBasedFiltering[i].from.timestamp and iEET.filtering.timeBasedFiltering[i].from.timestamp >= eventData.timestamp then
					iEET.filtering.timeBasedFiltering[i].from.ok = true
				elseif iEET.filtering.timeBasedFiltering[i].to.timestamp and iEET.filtering.timeBasedFiltering[i].to.timestamp > eventData.timestamp then
					iEET.filtering.timeBasedFiltering[i].from.ok = false
				else
					for k,v in pairs(eventData) do
						if iEET.filtering.timeBasedFiltering[i].from[k] and string.find(string.lower(v), iEET.filtering.timeBasedFiltering[i].from[k]) then
							iEET.filtering.timeBasedFiltering[i].from.ok = true
						elseif iEET.filtering.timeBasedFiltering[i].to[k] and string.find(string.lower(v), iEET.filtering.timeBasedFiltering[i].to[k]) then
							iEET.filtering.timeBasedFiltering[i].from.ok = false
						end
					end
				end
			end
		end
		local found = 0
		for i = 1, #iEET.filtering.timeBasedFiltering do
			if iEET.filtering.timeBasedFiltering[i].ok then
				found = found + 1
			end
		end
		if (iEET.filtering.requireAll and found == #iEET.filtering.timeBasedFiltering) or (found > 0 and not iEET.filtering.requireAll) then
			timeOK = true
		else
			timeOK = false
		end
	end
	if timeOK then
		if #iEET.filtering.req > 0 then
			for k,v in pairs(eventData) do -- loop trough current event
				for requiredData, requiredValue in pairs(iEET.filtering.req) do -- try to find right values
					if (requiredData and string.find(string.lower(v), requiredData)) or string.find(string.lower(v), iEET.filtering.anyData) then
						return true -- found right value
					end
				end
			end
			return false -- found nothing
		end
		return true -- nothing to find
	end
end
function iEET:addSpellDetails(hyperlink, linkData)
	--local linkType, spellID = strsplit(':', linkData)
	--spellID = tonumber(spellID)
	--1-7, 4 tyhja
	--local linkType, eventToFind, spellIDToFind, spellNametoFind = strsplit(':',linkData)
	local linkType, eventToFind, spellIDToFind, spellNametoFind = strsplit(':',linkData)
	if linkType == 'iEETcustomspell' then
		spellIDToFind = tonumber(spellIDToFind)
	end
	local starttime = 0
	local intervalls = {}
	local counts = {}
	for i = 1, 7 do
		if i == 4 then
		else
			iEET['detailContent' .. i]:Clear()
		end
	end
	--for k,v in ipairs(testDB) do
	for k,v in ipairs(iEET.data) do
		if v.event == 'ENCOUNTER_START' then starttime = v.timestamp end
		if linkType == 'iEETcustomspell' or linkType == 'iEETcustomyell' then
			local found = false
			if v.spellID then
				if v.spellID == spellIDToFind and v.event == eventToFind then 
					found = true 
				end
			end
			if found then
				local intervall = false
				local timestamp = v.timestamp-starttime or nil 
				local casterName = v.casterName or nil 
				local targetName = v.targetName or nil
				local spellID = v.spellID or nil
				local event = v.event or nil
				local count = nil
				local sourceGUID = v.sourceGUID or nil
				--local spellID = v.spellID
				if sourceGUID then
					if intervalls[sourceGUID] then
						if intervalls[sourceGUID][event] then
							if intervalls[sourceGUID][event][spellID] then
								intervall = timestamp - intervalls[sourceGUID][event][spellID]
								intervalls[sourceGUID][event][spellID] = timestamp
							else
								intervalls[sourceGUID][event][spellID] = timestamp
							end
						else
							intervalls[sourceGUID][event] = {
									[spellID] = timestamp,
							};
						end
					else
						intervalls[sourceGUID] = {
							[event] = {
								[spellID] = timestamp,
							};
						};
					end
					if counts[sourceGUID] then
						if counts[sourceGUID][event] then
							if counts[sourceGUID][event][spellID] then
								counts[sourceGUID][event][spellID] = counts[sourceGUID][event][spellID] + 1
								count = counts[sourceGUID][event][spellID]
							else
								counts[sourceGUID][event][spellID] = 1
								count = 1
							end
						else
							counts[sourceGUID][event] = {
								[spellID] = 1,
							}
						end
					else
						counts[sourceGUID] = {
							[event] = {
								[spellID] = 1,
							};
						};
						count = 1
					end
				end		
				iEET.detailContent1:AddMessage(string.format("%.1f",timestamp), unpack(iEET:getColor(event, sourceGUID, spellID)))
				if intervall then
					iEET.detailContent2:AddMessage(string.format("%.1f",intervall), unpack(iEET:getColor(event, sourceGUID, spellID)))
				else
					iEET.detailContent2:AddMessage(' ')
				end
				if event then
					if string.len(event) > 24 then
						event = string.sub(event, 1, 24)
					end
					iEET.detailContent3:AddMessage(event, unpack(iEET:getColor(event, sourceGUID, spellID)))
				else
					iEET.detailContent3:AddMessage(' ')
				end
				if casterName then
					if string.len(casterName) > 20 then
						casterName = string.sub(casterName, 1, 20)
					end
					iEET.detailContent5:AddMessage(casterName, unpack(iEET:getColor(event, sourceGUID, spellID)))
				else
					iEET.detailContent5:AddMessage(' ')
				end
				if targetName then
					if string.len(targetName) > 18 then
						targetName = string.sub(targetName, 1, 18)
					end
					iEET.detailContent6:AddMessage(targetName, unpack(iEET:getColor(event, sourceGUID, spellID)))
				else
					iEET.detailContent6:AddMessage(' ')
				end
				if count then
					iEET.detailContent7:AddMessage(count, unpack(iEET:getColor(event, sourceGUID, spellID)))
				else
					iEET.detailContent7:AddMessage(' ')
				end
			end
		end
	end
	iEETDetailInfo:SetText(hyperlink)
end
function iEET:addToContent(timestamp,event,casterName,targetName,spellName,spellID,intervall,count,sourceGUID, hp)
	iEET.content1:AddMessage(string.format("%.1f",timestamp),unpack(iEET:getColor(event, sourceGUID, spellID)))
	if intervall then
		iEET.content2:AddMessage(string.format("%.1f",intervall), unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content2:AddMessage(' ')
	end
	
	iEET.content3:AddMessage(event, unpack(iEET:getColor(event, sourceGUID, spellID)))
	if monsterEvents[event] then
		local msg = spellID
		if event == 'MONSTER_EMOTE' then --trying to fix monster emotes
			--"|TInterface\\Icons\\spell_fel_elementaldevastation.blp:20|tVerestriona's |cFFFF0000|Hspell:182008|h[Latent Energy]|h|r reacts violently as they step into the |cFFFF0000|Hspell:179582|h[Rumbling Fissure]|h|r!}|D|"
			--TODO: Better solution
			msg = string.gsub(spellID, "|T.+|t", "") -- Textures
			msg = string.gsub(msg, "spell:%d-", "") -- Spells
			msg = string.gsub(msg, "|h", "") -- Spells
			msg = string.gsub(msg, "|H", "") -- Spells
			msg = string.gsub(msg, "|c........", "") -- Colors
			msg = string.gsub(msg, "|r", "") -- Colors 
		end	
		iEET.content4:AddMessage('\124HiEETcustomyell:' .. event .. ':' .. msg .. '\124hMessage\124h', unpack(iEET:getColor(event, sourceGUID, spellID)))
	elseif spellID then
		local spellnametoShow = ''
		if string.len(spellName) > 20 then
			spellnametoShow = string.sub(spellName, 1, 20)
		else
			spellnametoShow = spellName
		end
		local unitType, _, serverID, instanceID, zoneID, npcID, spawnID
		if sourceGUID then
			unitType, _, serverID, instanceID, zoneID, npcID, spawnID = strsplit("-", sourceGUID)
		else
			npcID = 'NONE'
		end
		iEET.content4:AddMessage('\124HiEETcustomspell:' .. event .. ':' .. spellID .. ':' .. spellName .. ':' .. (npcID and npcID or 'NONE').. '!' .. (spawnID and spawnID or '') ..'\124h' .. spellnametoShow .. '\124h', unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content4:AddMessage(' ')
	end
	if casterName then
		if string.len(casterName) > 16 then
			casterName = string.sub(casterName, 1, 16)
		end
		iEET.content5:AddMessage(casterName, unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content5:AddMessage(' ')
	end
	if targetName then
		if string.len(targetName) > 16 then
			targetName = string.sub(targetName, 1, 16)
		end
		iEET.content6:AddMessage(targetName, unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content6:AddMessage(' ')
	end
	if count then
		iEET.content7:AddMessage(count, unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content7:AddMessage(' ')
	end
	if hp then
		iEET.content8:AddMessage(hp, unpack(iEET:getColor(event, sourceGUID, spellID)))
	else
		iEET.content8:AddMessage(' ')
	end
	
end
function iEET:addToEncounterAbilities(spellID, spellName)
	if spellID and tonumber(spellID) and spellName then
		iEET.encounterAbilitiesContent:AddMessage('\124Hspell:' .. tonumber(spellID) .. '\124h[' .. spellName .. ']\124h\124r')
	end
end
function iEET:addMessages(msg)
	local starttime = 0
	local intervalls = {}
	local counts = {}
	colors = {}
	for i=1, 8 do
		iEET['content' .. i]:Clear()
	end
	iEET.encounterAbilitiesContent:Clear()
	local from, to = false, false
	local encounterSpells = {}
	--time-filtering---------
	if msg then
		if string.match(msg, '^from:(%d-) to:(%d+)') then
			from, to = string.match(msg, '^from:(%d-) to:(%d+)')
			from = tonumber(from)
			to = tonumber(to)
		elseif string.match(msg, '^from:(%d+)') then
			from = string.match(msg, '^from:(%d+)')
			from = tonumber(from)
		elseif string.match(msg, '^to:(%d+)') then
			to = string.match(msg, '^to:(%d+)')
			to = tonumber(to)
		end
	end
	--end-of-time-filtering--
	for k,v in ipairs(iEET.data) do
		if v.event == 'ENCOUNTER_START' then starttime = v.timestamp end
		if v.spellID and not encounterSpells[v.spellID] then
			encounterSpells[v.spellID] = v.spellName
			iEET:addToEncounterAbilities(v.spellID, v.spellName)
		end	
		if msg then
			local found = false
			--if ShouldShow(v) then -- NEW, TESTING
			if not from and not to then
				for k,v in pairs(v) do
					if string.find(string.lower(v), string.lower(msg)) then found = true end
				end
			end
			if found or from or to then
				if v.event == 'ENCOUNTER_START' then starttime = v.timestamp end
				local intervall = nil
				local timestamp = v.timestamp-starttime or nil
				--time-filtering---------
				if from and timestamp and timestamp < from or to and timestamp and timestamp > to then else
				--end-of-time-filtering--
					local casterName = v.casterName or nil
					local targetName = v.targetName or nil
					local spellName = v.spellName or nil
					local spellID = v.spellID or nil
					local event = v.event
					local count = nil
					local sourceGUID = v.sourceGUID or nil
					local hp = v.hp or nil
					
					--if casterName then
					if sourceGUID then
						if intervalls[sourceGUID] then
							if intervalls[sourceGUID][event] then
								if intervalls[sourceGUID][event][spellID] then
									intervall = timestamp - intervalls[sourceGUID][event][spellID]
									intervalls[sourceGUID][event][spellID] = timestamp
								else
									intervalls[sourceGUID][event][spellID] = timestamp
								end
							else
								intervalls[sourceGUID][event] = {
										[spellID] = timestamp,
								};
							end
						else
							intervalls[sourceGUID] = {
								[event] = {
									[spellID] = timestamp,
								};
							};
						end
						if counts[sourceGUID] then
							if counts[sourceGUID][event] then
								if counts[sourceGUID][event][spellID] then
									counts[sourceGUID][event][spellID] = counts[sourceGUID][event][spellID] + 1
									count = counts[sourceGUID][event][spellID]
								else
									counts[sourceGUID][event][spellID] = 1
									count = 1
								end
							else
								counts[sourceGUID][event] = {
									[spellID] = 1,
								}
							end
						else
							counts[sourceGUID] = {
								[event] = {
									[spellID] = 1,
								};
							};
							count = 1
						end
					end
					if iEETConfig.tracking[event] or event == 'ENCOUNTER_START' or event == 'ENCOUNTER_END' then
										
						iEET:addToContent(timestamp,event,casterName,targetName,spellName,spellID, intervall,count, sourceGUID,hp)
					end
				end
			end
		else
			if v.event == 'ENCOUNTER_START' then starttime = v.timestamp end
			local intervall = false
			local timestamp = v.timestamp-starttime or nil
			local casterName = v.casterName or nil
			local targetName = v.targetName or nil
			local spellName = v.spellName or nil
			local spellID = v.spellID or nil
			local event = v.event
			local count = nil
			local sourceGUID = v.sourceGUID or nil
			local hp = v.hp or nil
			
			if sourceGUID then
				if intervalls[sourceGUID] then
					if intervalls[sourceGUID][event] then
						if intervalls[sourceGUID][event][spellID] then
							intervall = timestamp - intervalls[sourceGUID][event][spellID]
							intervalls[sourceGUID][event][spellID] = timestamp
						else
							intervalls[sourceGUID][event][spellID] = timestamp
						end
					else
						intervalls[sourceGUID][event] = {
								[spellID] = timestamp,
						};
					end
				else
					intervalls[sourceGUID] = {
						[event] = {
							[spellID] = timestamp,
						};
					};
				end
				if counts[sourceGUID] then
					if counts[sourceGUID][event] then
						if counts[sourceGUID][event][spellID] then
							counts[sourceGUID][event][spellID] = counts[sourceGUID][event][spellID] + 1
							count = counts[sourceGUID][event][spellID]
						else
							counts[sourceGUID][event][spellID] = 1
							count = 1
						end
					else
						counts[sourceGUID][event] = {
							[spellID] = 1,
						}
					end
				else
					counts[sourceGUID] = {
						[event] = {
							[spellID] = 1,
						};
					};
					count = 1
				end
			end
			if iEETConfig.tracking[event] or event == 'ENCOUNTER_START' or event == 'ENCOUNTER_END' then
				iEET:addToContent(timestamp,event,casterName,targetName,spellName,spellID, intervall,count, sourceGUID,hp)
			end
		end
	end
	
end
iEET.eventlistMenu = {}
function iEET:updateEventlistMenu()
	iEET.eventlistMenu = nil
	iEET.eventlistMenu = {}
	for k,_ in pairs(iEETConfig.tracking) do
		table.insert(iEET.eventlistMenu, { 
			text = k, 
			isNotRadio = true,
			checked = iEETConfig.tracking[k],
			--checked = false,
			keepShownOnClick = true,
			func = function() 
				if iEETConfig.tracking[k] then
					iEETConfig.tracking[k] = false
				else
					iEETConfig.tracking[k] = true
				end
			end,
		})
	end
	table.insert(iEET.eventlistMenu, { text = 'Save', notCheckable = true, func = function () CloseDropDownMenus(); iEET:updateEventlistMenu(); iEET:addMessages() end})
end
iEET.eventlistMenuFrame = CreateFrame("Frame", "iEETEventListMenu", UIParent, "UIDropDownMenuTemplate")

iEET.encounterListMenu = {}
function iEET:updateEncounterListMenu()
	iEET.encounterListMenu = nil
	iEET.encounterListMenu = {}
	local encountersTempTable = {}
	for k,_ in pairs(iEET_Data) do -- Get encounters
		local temp = {}
		for eK,eV in string.gmatch(k, '{(.-)=(.-)}') do
			if eK == 'difficulty' or eK == 'raidSize' or eK == 'start' or eK == 'kill' then
				if tonumber(eV) then
					eV = tonumber(eV)
				end
			end
			temp[eK] = eV
		end
		temp.dataKey = k
		if not encountersTempTable[temp.encounterName] then
			encountersTempTable[temp.encounterName] = {}
		end
		if not encountersTempTable[temp.encounterName][temp.difficulty] then
			encountersTempTable[temp.encounterName][temp.difficulty] = {}
		end
		table.insert(encountersTempTable[temp.encounterName][temp.difficulty], temp)
	end -- Sorted by encounter -> Sort by ids inside
	-- temp{} -> encounter{} -> difficulty{} -> fight{}
	
	
	for encounterName,_ in spairs(encountersTempTable) do -- Get alphabetically sorted encounters
		--Looping bosses
		--print(encounterName) -- Debug
		local t = {text = encounterName, hasArrow = true, notCheckable = true, menuList = {}}
		local t2 = {}
		for difficultyID,_ in spairs(encountersTempTable[encounterName]) do
			-- Looping difficulties
			--print('difficultyID', difficultyID) -- Debug
			t2 = {text = GetDifficultyInfo(difficultyID), hasArrow = true, notCheckable = true, menuList = {}}
			--for k,v in pairs(encountersTempTable[encounterName][difficultyID]) do
			for k,v in spairs(encountersTempTable[encounterName][difficultyID], function(t,a,b) return t[b].pullTime < t[a].pullTime end) do
				local fightEntry = {
					text = (v.kill == 1 and '+' or '-') .. v.fightTime .. ' (' .. v.pullTime .. ')',
					notCheckable = true,
					hasArrow = true,
					checked = false,
					keepShownOnClick = false,
					func = function() 
						iEET:ImportData(v.dataKey)
						iEET:Toggle(true) -- not really needed
						CloseDropDownMenus()
					end,
					menuList = {{ -- delete menu
						text = 'Delete', 
						notCheckable = true, 
						func = function() 
							iEET_Data[v.dataKey] = nil
							iEET:updateEncounterListMenu()
						end,
					},}, 
				}
				table.insert(t2.menuList, fightEntry)
			end
			table.insert(t.menuList, t2)
		end
		table.insert(iEET.encounterListMenu, t)
	end
	table.insert(iEET.encounterListMenu, { text = 'Exit', notCheckable = true, func = function () CloseDropDownMenus() end})
end
iEET.encounterListMenuFrame = CreateFrame("Frame", "iEETEncounterListMenu", UIParent, "UIDropDownMenuTemplate")

function iEET:CreateMainFrame()
	iEET.frame = CreateFrame("Frame", "iEETFrame", UIParent)
	iEET.frame:SetSize(554,800)
	iEET.frame:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
	iEET.frame:SetScript("OnMouseDown", function(self,button)
		iEET.frame:ClearAllPoints()
		iEET.frame:StartMoving()
	end)
	iEET.frame:SetScript('OnMouseUp', function(self, button)
		iEET.frame:StopMovingOrSizing()
	end)
	iEET.frame:SetScript('OnShow', function() iEET:addMessages() end)
	iEET.frame:Show()
	iEET.frame:SetFrameStrata('HIGH')
	iEET.frame:SetFrameLevel(1)
	iEET.top = CreateFrame('FRAME', nil, iEET.frame)
	iEET.top:SetSize(554, 25)
	iEET.top:SetPoint('BOTTOMRIGHT', iEET.frame, 'TOPRIGHT', 0, -1)
	iEET.top:SetBackdrop(iEET.backdrop);
	iEET.top:SetBackdropColor(0.1,0.1,0.1,0.9)
	iEET.top:SetBackdropBorderColor(0,0,0,1)
	iEET.top:SetScript('OnMouseDown', function(self,button)
		iEET.frame:ClearAllPoints()
		iEET.frame:StartMoving()
	end)
	iEET.top:SetScript('OnMouseUp', function(self, button)
		iEET.frame:StopMovingOrSizing()
	end)
	
	iEET.top:EnableMouse(true)
	iEET.top:Show()
	iEET.top:SetFrameStrata('HIGH')
	iEET.top:SetFrameLevel(1)
	iEET.detailtop = CreateFrame('FRAME', nil, iEET.frame)
	iEET.detailtop:SetSize(405, 25)
	iEET.detailtop:SetPoint('RIGHT', iEET.top, 'LEFT', 1, 0)
	iEET.detailtop:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8", 
		edgeFile = "Interface\\Buttons\\WHITE8x8", 
		edgeSize = 1, 
		insets = {
			left = -1,
			right = -1,
			top = -1,
			bottom = -1,
		},
	});
	iEET.detailtop:SetBackdropColor(0.1,0.1,0.1,0.9)
	iEET.detailtop:SetBackdropBorderColor(0,0,0,1)
	iEET.detailtop:Show()
	iEET.detailtop:SetScript("OnMouseDown", function(self,button)
		iEET.frame:ClearAllPoints()
		iEET.frame:StartMoving()
	end)
	iEET.detailtop:SetScript('OnMouseUp', function(self, button)
		iEET.frame:StopMovingOrSizing()
	end)
	iEET.detailtop:SetFrameStrata('HIGH')
	iEET.detailtop:SetFrameLevel(1)
	iEET.detailtop:EnableMouse(true)
	
	iEET.encounterAbilities = CreateFrame('FRAME', nil, iEET.frame)
	iEET.encounterAbilities:SetSize(200, 25)
	iEET.encounterAbilities:SetPoint('LEFT', iEET.top, 'RIGHT', -1, 0)
	iEET.encounterAbilities:SetBackdrop({
		bgFile = "Interface\\Buttons\\WHITE8x8", 
		edgeFile = "Interface\\Buttons\\WHITE8x8", 
		edgeSize = 1, 
		insets = {
			left = -1,
			right = -1,
			top = -1,
			bottom = -1,
		},
	});
	iEET.encounterAbilities:SetBackdropColor(0.1,0.1,0.1,0.9)
	iEET.encounterAbilities:SetBackdropBorderColor(0,0,0,1)
	iEET.encounterAbilities:Show()
	iEET.encounterAbilities:SetScript("OnMouseDown", function(self,button)
		iEET.frame:ClearAllPoints()
		iEET.frame:StartMoving()
	end)
	iEET.encounterAbilities:SetScript('OnMouseUp', function(self, button)
		iEET.frame:StopMovingOrSizing()
	end)
	iEET.encounterAbilities:SetFrameStrata('HIGH')
	iEET.encounterAbilities:SetFrameLevel(1)
	iEET.encounterAbilities:EnableMouse(true)
	-----EXCEL STYLE test -----
	local lastframe = false
	local slices = {
		[1] = 36,
		[2] = 36,
		[3] = 110,
		[4] = 121,
		[5] = 110,
		[6] = 87,
		[7] = 31,
		[8] = 30,
	};
	for i=1, 8 do ---bigcontent
		---anhorframe
		iEET['contentAnchor' .. i] = CreateFrame('FRAME', nil , iEET.frame)
		iEET['contentAnchor' .. i]:SetSize(slices[i], 834)
		if not lastframe then
			iEET['contentAnchor' .. i]:SetPoint('TOPLEFT', iEET.frame, 'TOPLEFT', 0, 0)
			lastframe = 'contentAnchor' .. i 
		else
			iEET['contentAnchor' .. i]:SetPoint('LEFT', iEET[lastframe], 'RIGHT', -1,0)
			lastframe = 'contentAnchor' .. i 
		end
		iEET['contentAnchor' .. i]:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8", 
			edgeFile = "Interface\\Buttons\\WHITE8x8", 
			edgeSize = 1, 
			insets = {
				left = -1,
				right = -1,
				top = -1,
				bottom = -1,
			},
		});
		iEET['contentAnchor' .. i]:SetBackdropColor(0.1,0.1,0.1,0.9)
		iEET['contentAnchor' .. i]:SetBackdropBorderColor(0,0,0,1)
		---
		
		iEET['content' .. i] = CreateFrame('ScrollingMessageFrame', nil, iEET['contentAnchor' .. i])
		iEET['content' .. i]:SetSize(slices[i]-8,828)
		iEET['content' .. i]:SetPoint('CENTER', iEET['contentAnchor' .. i], 'CENTER', 0, 0)
		iEET['content' .. i]:SetFont(iEET.font, iEET.fontsize)
		iEET['content' .. i]:SetFading(false)
		iEET['content' .. i]:SetInsertMode("BOTTOM")
		iEET['content' .. i]:SetJustifyH(iEET.justifyH)
		iEET['content' .. i]:SetMaxLines(5000)
		iEET['content' .. i]:SetSpacing(iEET.spacing)
		iEET['content' .. i]:EnableMouseWheel(true)
		iEET['content' .. i]:SetHyperlinksEnabled(true)
		iEET['content' .. i]:SetIndentedWordWrap(false)
		iEET['content' .. i]:SetScript("OnMouseWheel", function(self, delta)
			iEET:ScrollContent(delta)
		end)
		iEET['content' .. i]:SetScript("OnHyperlinkEnter", function(self, linkData, link)
			GameTooltip:SetOwner(iEET.frame, "ANCHOR_TOPRIGHT", 0-iEET.frame:GetWidth(), 0-iEET.frame:GetHeight())
			GameTooltip:ClearLines()
			local linkType = strsplit(':', linkData)
			if linkType == 'iEETcustomyell' then
				local _, event, spellID, spellName = strsplit(':',linkData)
				GameTooltip:SetText(spellID)
				--iEET_content4:AddMessage('\124HiEETcustomspell:' .. event .. ':' .. spellID .. ':' .. spellname ..'\124h' .. spellName .. '\124h', unpack(getColor(event, sourceGUID, spellID)))
			elseif linkType == 'iEETcustomspell' then
				local _, event, spellID, spellName, npcID = strsplit(':',linkData)
				--print(event, spellID, spellName)
				local hyperlink = '\124Hspell:' .. tonumber(spellID)
				GameTooltip:SetHyperlink('spell:' .. tonumber(spellID))
				GameTooltip:AddLine('spellID:' .. spellID)
				GameTooltip:AddLine('npcID:' .. npcID)
			else
				GameTooltip:SetHyperlink(link)		
			end
			GameTooltip:Show()
		end)
		iEET['content' .. i]:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
			if IsShiftKeyDown() and IsInRaid() then
				local linkType = strsplit(':', linkData)
				if linkType == 'iEETcustomyell' then
					local _, event, spellID, spellName = strsplit(':',linkData)
					SendChatMessage(spellID, 'RAID')
				elseif linkType == 'iEETcustomspell' then
					local _, event, spellID, spellName, npcID = strsplit(':',linkData)
					SendChatMessage(GetSpellLink(tonumber(spellID)), 'RAID')
				end
			else
				iEET:addSpellDetails(link, linkData)
			end
		end)
		iEET['content' .. i]:SetFrameStrata('HIGH')
		iEET['content' .. i]:SetFrameLevel(2)
		iEET['content' .. i]:EnableMouse(true)
		--smf:SetFrameStrata('HIGH')
	end
	lastframe = false
	for i=7, 1, -1 do ---detail content
		---anhorframe
		if i == 4 then 
		else
		iEET['detailAnchor' .. i] = CreateFrame('FRAME', nil, iEET.frame)
		iEET['detailAnchor' .. i]:SetSize(slices[i], 400)
		if not lastframe then
			iEET['detailAnchor' .. i]:SetPoint('TOPRIGHT', iEET.frame, 'TOPLEFT', 1, 0)
			lastframe = 'detailAnchor' .. i 
		else
			iEET['detailAnchor' .. i]:SetPoint('RIGHT', iEET[lastframe], 'LEFT', 1,0)
			lastframe = 'detailAnchor' .. i
		end
		iEET['detailAnchor' .. i]:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8", 
			edgeFile = "Interface\\Buttons\\WHITE8x8", 
			edgeSize = 1, 
			insets = {
				left = -1,
				right = -1,
				top = -1,
				bottom = -1,
			},
		});
		iEET['detailAnchor' .. i]:SetBackdropColor(0.1,0.1,0.1,0.9)
		iEET['detailAnchor' .. i]:SetBackdropBorderColor(0,0,0,1)
		---
		iEET['detailContent' .. i] = CreateFrame('ScrollingMessageFrame', nil, iEET['detailAnchor' .. i])
		iEET['detailContent' .. i]:SetSize(slices[i]-8,392)
		iEET['detailContent' .. i]:SetPoint('CENTER', iEET['detailAnchor' .. i], 'CENTER', 0, 0)
		iEET['detailContent' .. i]:SetFont(iEET.font, iEET.fontsize)
		iEET['detailContent' .. i]:SetFading(false)
		iEET['detailContent' .. i]:SetInsertMode("BOTTOM")
		iEET['detailContent' .. i]:SetJustifyH(iEET.justifyH)
		iEET['detailContent' .. i]:SetMaxLines(5000)
		iEET['detailContent' .. i]:SetSpacing(iEET.spacing)
		iEET['detailContent' .. i]:EnableMouseWheel(true)
		iEET['detailContent' .. i]:SetHyperlinksEnabled(true)
		iEET['detailContent' .. i]:SetScript("OnMouseWheel", function(self, delta)
			iEET:ScrollDetails(delta)
		end)
		iEET['detailContent' .. i]:SetScript("OnHyperlinkEnter", function(self, linkData, link)
			GameTooltip:SetOwner(iEET.frame, "ANCHOR_TOPRIGHT", 0-iEET.frame:GetWidth(), 0-iEET.frame:GetHeight())
			GameTooltip:ClearLines()		
			GameTooltip:SetHyperlink(link)		
			GameTooltip:Show()
		end)
		iEET['detailContent' .. i]:EnableMouse(true)
		iEET['detailContent' .. i]:SetFrameStrata('HIGH')
		iEET['detailContent' .. i]:SetFrameLevel(2)
		--smf:SetFrameStrata('HIGH')
	end
	end
	--SPELL LISTING--
	do
		iEET.encounterAbilitiesAnchor = CreateFrame('FRAME', nil, iEET.frame)
		iEET.encounterAbilitiesAnchor:SetSize(200, 400)
		iEET.encounterAbilitiesAnchor:SetPoint('TOPLEFT', iEET.frame, 'TOPRIGHT', -1, 0)
		iEET.encounterAbilitiesAnchor:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8", 
			edgeFile = "Interface\\Buttons\\WHITE8x8", 
			edgeSize = 1, 
			insets = {
				left = -1,
				right = -1,
				top = -1,
				bottom = -1,
			},
		});
		iEET.encounterAbilitiesAnchor:SetBackdropColor(0.1,0.1,0.1,0.9)
		iEET.encounterAbilitiesAnchor:SetBackdropBorderColor(0,0,0,1)
		---
		iEET.encounterAbilitiesContent = CreateFrame('ScrollingMessageFrame', nil, iEET.encounterAbilitiesAnchor)
		iEET.encounterAbilitiesContent:SetSize(192,392)
		iEET.encounterAbilitiesContent:SetPoint('CENTER', iEET.encounterAbilitiesAnchor, 'CENTER', 0, 0)
		iEET.encounterAbilitiesContent:SetFont(iEET.font, iEET.fontsize)
		iEET.encounterAbilitiesContent:SetFading(false)
		iEET.encounterAbilitiesContent:SetInsertMode("BOTTOM")
		iEET.encounterAbilitiesContent:SetJustifyH(iEET.justifyH)
		iEET.encounterAbilitiesContent:SetMaxLines(200)
		iEET.encounterAbilitiesContent:SetSpacing(iEET.spacing)
		iEET.encounterAbilitiesContent:EnableMouseWheel(true)
		iEET.encounterAbilitiesContent:SetHyperlinksEnabled(true)
		iEET.encounterAbilitiesContent:SetScript("OnMouseWheel", function(self, delta)
			if delta == -1 then
				if IsShiftKeyDown() then
					iEET.encounterAbilitiesContent:PageDown()
				else
					iEET.encounterAbilitiesContent:ScrollDown()
				end
			else
				if IsShiftKeyDown() then
					iEET.encounterAbilitiesContent:PageUp()
				else
					iEET.encounterAbilitiesContent:ScrollUp()
				end				
			end
		end)
		iEET.encounterAbilitiesContent:SetScript("OnHyperlinkEnter", function(self, linkData, link)
			GameTooltip:SetOwner(iEET.frame, "ANCHOR_TOPRIGHT", 0-iEET.frame:GetWidth(), 0-iEET.frame:GetHeight())
			GameTooltip:ClearLines()		
			GameTooltip:SetHyperlink(link)		
			GameTooltip:Show()
		end)
		iEET.encounterAbilitiesContent:SetScript("OnHyperlinkClick", function(self, linkData, link, button)
			local spellID = tonumber(string.match(linkData, 'spell:(%d+)'))
			if spellID then
				iEET:addMessages(spellID)
			end
		end)
		iEET.encounterAbilitiesContent:EnableMouse(true)
		iEET.encounterAbilitiesContent:SetFrameStrata('HIGH')
		iEET.encounterAbilitiesContent:SetFrameLevel(2)
	end
	--]]
	---- END OF EXCEL STYLE TEST ---
	iEET.detailInfo = iEET.frame:CreateFontString('iEETDetailInfo')
	iEET.detailInfo:SetFont(iEET.font, iEET.fontsize, "OUTLINE")
	iEET.detailInfo:SetPoint("CENTER", iEET.detailtop, 'CENTER', 0,0)
	iEET.detailInfo:SetText("Details")
	iEET.detailInfo:Show()
	iEET.encounterAbilitiesText = iEET.frame:CreateFontString('iEETEncounterAbilitiesInfo')
	iEET.encounterAbilitiesText:SetFont(iEET.font, iEET.fontsize, "OUTLINE")
	iEET.encounterAbilitiesText:SetPoint("CENTER", iEET.encounterAbilities, 'CENTER', 0,0)
	iEET.encounterAbilitiesText:SetText("Encounter spells")
	iEET.encounterAbilitiesText:Show()
	iEET.frame:EnableMouse(true)
	iEET.frame:SetMovable(true)
	local scale = (0.63999998569489/iEET.frame:GetEffectiveScale())
	iEET.frame:SetScale(scale)
	--iEET.editbox = CreateFrame('EditBox', 'iEETEditBox', iEET.frame,'SearchBoxTemplate')
	iEET.editbox = CreateFrame('EditBox', 'iEETEditBox', iEET.frame)
	--local editbox = CreateFrame('EditBox', 'iEETEditBox', f, 'InputBoxTemplate')
	iEET.editbox:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8x8", 
			edgeFile = "Interface\\Buttons\\WHITE8x8", 
			edgeSize = 1, 
			insets = {
				left = -1,
				right = -1,
				top = -1,
				bottom = -1,
			},
		});
	iEET.editbox:SetBackdropColor(0.1,0.1,0.1,0.2)
	iEET.editbox:SetBackdropBorderColor(0,0,0,1)
	iEET.editbox:SetScript('OnEnterPressed', function()
		iEET.editbox:ClearFocus()
		if iEET.editbox:GetText() ~= 'Search' then
			iEET:addMessages(iEET.editbox:GetText())
		else
			iEET:addMessages()
		end
	end)
	iEET.editbox:SetAutoFocus(false)
	iEET.editbox:SetWidth(300)
	iEET.editbox:SetHeight(21)
	iEET.editbox:SetTextInsets(2, 2, 1, 0)
	iEET.editbox:SetPoint('RIGHT', iEET.top, 'RIGHT', -25,0)
	iEET.editbox:SetFrameStrata('HIGH')
	iEET.editbox:SetFrameLevel(3)
	iEET.editbox:Show()
	iEET.editbox:SetFont(iEET.font, iEET.fontsize+2, 'OUTLINE')
	----Event list:
	iEET.eventlist = CreateFrame('BUTTON', 'iEETEventListMenuButton', iEET.frame, "UIPanelInfoButton")
	--f.eventlist:SetFont(font, fontsize, 'OUTLINE')
	iEET.eventlist:SetSize(20, 20)
	iEET.eventlist.texture:SetVertexColor(0.5,0.5,0.5,1)
	iEET.eventlist:SetPoint("LEFT", iEET.top, 'LEFT', 4,-2)
	--f.eventlist:SetText('Events')
	iEET.eventlist:Show()
	iEET.eventlist:RegisterForClicks('AnyUp')
	iEET.eventlist:SetScript('OnClick',function()
		EasyMenu(iEET.eventlistMenu, iEET.eventlistMenuFrame, "cursor", 0 , 0, "MENU");
	end)
	iEET:updateEventlistMenu()
	----end of event list
	----Encounter list button:
	iEET.encounterListButton = CreateFrame('BUTTON', 'iEETEncounterListMenuButton', iEET.frame, "UIPanelInfoButton")
	iEET.encounterListButton:SetSize(20, 20)
	iEET.encounterListButton.texture:SetVertexColor(1,0.25,0.25,1)
	iEET.encounterListButton:SetPoint('LEFT', iEET.eventlist, 'RIGHT', 3,0)
	iEET.encounterListButton:Show()
	iEET.encounterListButton:RegisterForClicks('AnyUp')
	iEET.encounterListButton:SetScript('OnClick',function()
		EasyMenu(iEET.encounterListMenu, iEET.encounterListMenuFrame, "cursor", 0 , 0, "MENU");
	end)
	iEET:updateEncounterListMenu()
	----end of encounter list button
	iEET:addMessages()
	
end
function iEET:Toggle(show)
	if not InCombatLockdown() then
		if not iEET.frame then
			iEET:CreateMainFrame()
		elseif iEET.frame:IsShown() and not show then
			iEET.frame:Hide()
		else
			iEET.frame:Show()		
			iEET:updateEncounterListMenu()
		end
	elseif iEET.frame and not show then
		iEET.frame:Hide()
	end
end
function iEET:toggleCopyFrame(forceShow)
	if not iEET.frame then iEET:CreateMainFrame() end
	if not iEET.copyFrame and not InCombatLockdown() then
		iEET.copyFrame = CreateFrame('EditBox', 'iEETCopyFrame', UIParent)
		iEET.copyFrame:SetBackdrop({
				bgFile = "Interface\\Buttons\\WHITE8x8", 
				edgeFile = "Interface\\Buttons\\WHITE8x8", 
				edgeSize = 1, 
				insets = {
					left = -1,
					right = -1,
					top = -1,
					bottom = -1,
				},
			});
		iEET.copyFrame:SetBackdropColor(0.1,0.1,0.1,0.2)
		iEET.copyFrame:SetBackdropBorderColor(0.5,0,0,1)
		iEET.copyFrame:SetScript('OnEnterPressed', function()
			iEET.copyFrame:ClearFocus()
			iEET.copyFrame:SetText('')
			iEET.copyFrame:Hide()
		end)
		iEET.copyFrame:SetAutoFocus(true)
		iEET.copyFrame:SetWidth(400)
		iEET.copyFrame:SetHeight(21)
		iEET.copyFrame:SetTextInsets(2, 2, 1, 0)
		--iEET.copyFrame:SetMultiLine(true)
		iEET.copyFrame:SetPoint('CENTER', UIParent, 'CENTER', 0,0)
		iEET.copyFrame:SetFrameStrata('DIALOG')
		iEET.copyFrame:Show()
		iEET.copyFrame:SetFont(iEET.font, iEET.fontsize+2, 'OUTLINE')
	else
		if iEET.copyFrame:IsShown() and not forceShow then
			iEET.copyFrame:Hide()
		elseif not InCombatLockdown() then
			iEET.copyFrame:Show()
		end
	end
end
function iEET:copyCurrent()
	
	--iEET['content' .. i]GetCurrentLine()
	local totalData = ''
	for line = 1, iEET.content1:GetNumMessages() do
		local lineData = ''
		for i = 1, 8 do 
			lineData = lineData .. iEET['content' .. i]:GetMessageInfo(line) .. '\t'
		end
		totalData = totalData .. '\r' .. string.gsub(lineData, '+', '') --+SAURA etc messes excel so remove +, should be enough for excel
	end
	iEET:toggleCopyFrame(true)
	iEET.copyFrame:SetText(totalData)
end
--[[ OLD
function iEET:ExportData(auto)
	if auto and InCombatLockdown() then
		C_Timer.After(3, 
		function() 
			iEET:ExportData(true)
		end)
		return
	end
	local str = '|E|' .. (iEET.encounterInfo and iEET.encounterInfo or 'Unknown') .. '|E|'
	for k,v in ipairs(iEET.data) do
		local t = ''
		for a,b in pairs(v) do
			t = t .. '{' .. a .. '=' .. b .. '}'
		end
		str = str .. '|D|' .. t .. '|D|'
		
	end
	if not iEET_Data then
		iEET_Data = {}
	end
	table.insert(iEET_Data, str)
	print((iEET.encounterInfo and iEET.encounterInfo or 'Unknown').." exported."..(auto and '(autosave)' or ''))
	--iEET.InputBox:SetText(str)
	--iEET.InputBox:Show()
end
--]]
function iEET:ExportData(auto) -- NEW, TESTING
	if auto then
		local m,s = string.match(iEET.encounterInfoData.fightTime, '(%d):(%d)')
		--print(iEET.encounterInfoData.fightTime)
		if m*60+s < iEETConfig.autoDiscard then
			print('discarded', m*60+s)
			return
		end
		if InCombatLockdown() then
			C_Timer.After(3, function() 
				iEET:ExportData(true)
			end)
			return
		end
	end
	--local encounterString = '|E|' .. (iEET.encounterInfo and iEET.encounterInfo or 'Unknown') .. '|E|'
	local encounterString = ''
	for k,v in pairs(iEET.encounterInfoData) do
		encounterString = encounterString .. '{' .. k .. '=' .. v .. '}'
	end
	local dataString = ''
	for k,v in ipairs(iEET.data) do
		local t = ''
		for a,b in pairs(v) do
			t = t .. '{' .. a .. '=' .. b .. '}'
		end
		dataString = dataString .. '|D|' .. t .. '|D|'
		
	end
	if not iEET_Data then
		iEET_Data = {}
	end
	--table.insert(iEET_Data, str)
	iEET_Data[encounterString] = dataString
	print((iEET.encounterInfoData.encounterName and iEET.encounterInfoData.encounterName or 'Unknown').." exported."..(auto and ' (autosave)' or ''))
	--iEET.InputBox:SetText(str)
	--iEET.InputBox:Show()
end
--[[ OLD
function iEET:ImportData(msg)
	iEET.data = {}
	iEET.encounterInfo = string.match(msg, '^|E|(.-)|E|')
	for v in string.gmatch(msg, 'D|(.-)|D') do
		local t = {}
		for dataKey,dataValue in string.gmatch(v, '{(.-)=(.-)}') do
			if dataKey == 'spellID' or dataKey == 'timestamp' then
				if tonumber(dataValue) then
					dataValue = tonumber(dataValue)
				end
			end
			t[dataKey] = dataValue
		end
		table.insert(iEET.data, t)
	end
	iEET:addMessages()
	print('iEET: Imported ' .. iEET.encounterInfo .. '.')
end
--]]
function iEET:ImportData(dataKey) -- NEW, TESTING
	iEET.data = {}
	iEET.encounterInfoData = {}
	for eK,eV in string.gmatch(dataKey, '{(.-)=(.-)}') do
		if eK == 'difficulty' or eK == 'raidSize' or eK == 'start' or eK == 'kill' then
			if tonumber(eV) then
				eV = tonumber(eV)
			end
		end
		iEET.encounterInfoData[eK] = eV
	end
	for v in string.gmatch(iEET_Data[dataKey], 'D|(.-)|D') do
		local tempTable = {}
		for dK,dV in string.gmatch(v, '{(.-)=(.-)}') do
			if dK == 'spellID' or dK == 'timestamp' then
				if tonumber(dV) then
					dV = tonumber(dV)
				end
			end
			tempTable[dK] = dV
		end
		table.insert(iEET.data, tempTable)
	end
	iEET:addMessages()
	local s = 
	print(string.format('iEET: Imported %s on %s (%s), %sman (%s), Time: %s.',iEET.encounterInfoData.encounterName,GetDifficultyInfo(iEET.encounterInfoData.difficulty),iEET.encounterInfoData.fightTime, iEET.encounterInfoData.raidSize, (iEET.encounterInfoData.kill == 1 and 'kill' or 'wipe'), iEET.encounterInfoData.pullTime))
end
SLASH_IEET1 = "/ieet"
SlashCmdList["IEET"] = function(msg)
	if string.match(msg, 'copy') then
		iEET:copyCurrent()
	elseif string.match(msg, 'import') then
		if iEET_Data then
			iEET:Toggle(true)
			local id = string.gsub(msg, 'import ', '')
			if iEET_Data[id] then
				iEET:ImportData(id)
			else
				print('iEET: key [' .. id .. '] not found')
			end
		else
			print('iEET: No data to import.')
		end
	elseif string.match(msg, 'clear') then
		iEET_Data = nil
		iEET_Data = {}
		print('iEET_Data wiped.')
	elseif string.match(msg, 'autosave') then
		if iEETConfig.autoSave then
			iEETConfig.autoSave = false
			print('iEET: Automatic saving after ENCOUNTER_END off.')
		else
			iEETConfig.autoSave = true
			print('iEET: Automatic saving after ENCOUNTER_END on.')
		end
	elseif string.match(msg, 'autodiscard') then
		local timer = string.match(msg, 'autodiscard (%d+)')
		if timer then
			print('iEET: Auto discard timer changed from ' .. iEETConfig.autoDiscard .. ' to ' .. timer .. '.')
			iEETConfig.autoDiscard = tonumber(timer)
		else
			print('iEET: Invalid number')
		end
	elseif string.match(msg, 'help') then
		print('iEET: /ieet autosave to toggle autosaving\r/ieet autodiscard X to change auto discard timer\r/ieet clear to delete every fight entry')
	else
		iEET:Toggle()
	end
end
BINDING_HEADER_IEET = 'iEncounterEventTracker'
BINDING_NAME_IEET_TOGGLE = 'Toggle window'
BINDING_NAME_IEET_EXPORT = 'Export Data'
BINDING_NAME_IEET_COPY = 'Copy currently shown fight to spreadsheet'
function IEET_TOGGLE(window)
	if window == 'frame' then
		iEET:Toggle()
	elseif window == 'copy' and not InCombatLockdown() then
		iEET:copyCurrent()
	elseif window == 'export' and not InCombatLockdown() then
		iEET:ExportData()
	end
end

function iEET_Debug(v)
	return iEET[v]
end
--42700871ifpnhfr
--Tracking ID: 000078