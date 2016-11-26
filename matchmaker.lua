local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local function pp(...) print(__FILE__:sub(-15),...) end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceSerializer-3.0","AceConsole-3.0"
--*MINOR 35
-- Generated on 20/11/2016 11:08:08
local me,ns=...
local addon=ns --#Addon (to keep eclipse happy)
ns=nil
local module=addon:NewSubModule('Matchmaker',"AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceSerializer-3.0","AceConsole-3.0")  --#Module
function addon:GetMatchmakerModule() return module end
-- Template
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon.NewTable
local del=addon.DelTable
local kpairs=addon:GetKpairs()
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
--*if-non-addon*
local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT
--*end-if-non-addon*
local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
--*if-non-addon*
if LibDebug then LibDebug() dprint=print end
local safeG=addon.safeG
--*end-if-non-addon*
--[===[*if-addon*
-- Addon Build, we need to create globals the easy way
local function encapsulate()
if LibDebug then LibDebug() dprint=print end
end
encapsulate()
local pcall=pcall
local function parse(default,rc,...)
	if rc then return default else return ... end
end
	
addon.safeG=setmetatable({},{
	__index=function(table,key)
		rawset(table,key,
			function(default,...)
				return parse(default,pcall(G[key],...))
			end
		) 
		return table[key]
	end
})

--*end-if-addon*[===]
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]

-- End Template
--*BEGIN 
local lethalMechanicEffectID = 437;
local cursedMechanicEffectID = 471;
local slowingMechanicEffectID = 428;
local disorientingMechanicEffectID = 472;
local debugMission=0
local function parse(default,rc,...)
	if rc then 
		return ... 
	else
	--@debug@
		error(message,2) 
	--@end-debug@
		return default
	end
end
	
local meta={
__index = function(t,key)
	return function(...) return parse(nil,pcall(C_Garrison[key],...)) end end
}
--upvalues
local MAX_LEVEL=110
local assert,ipairs,pairs,wipe,GetFramesRegisteredForEvent=assert,ipairs,pairs,wipe,GetFramesRegisteredForEvent
local select,tinsert,format,pcall,setmetatable,coroutine=select,tinsert,format,pcall,setmetatable,coroutine
local tostringall=tostringall
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local emptyTable={}
local holdEvents
local releaseEvents
local events={stacklevel=0,frames={}} --#events
function events.hold() --#eventsholdEvents
	if events.stacklevel==0 then
		events.frames={GetFramesRegisteredForEvent('GARRISON_FOLLOWER_LIST_UPDATE')}
		for i=1,#events.frames do
			events.frames[i]:UnregisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
	end
	events.stacklevel=events.stacklevel+1
end
function events.release()
	events.stacklevel=events.stacklevel-1
	assert(events.stacklevel>=0)
	if (events.stacklevel==0) then
		for i=1,#events.frames do
			events.frames[i]:RegisterEvent("GARRISON_FOLLOWER_LIST_UPDATE")
		end
		events.frames=nil
	end
end
holdEvents=events.hold
releaseEvents=events.release
local maxtime=3600*24*7
-- Candidate management
local CandidateManager={perc=0,chance=0} --#CandidateManager
local CandidateMeta={__index=CandidateManager}
local emptyCandidate=setmetatable({},CandidateMeta)
local inProgressCandidate=setmetatable({},CandidateMeta)
function CandidateManager:IterateFollowers()
	return ipairs(self)
end
function CandidateManager:Follower(index)
	return self[index]
end
-- Party management
local partyManager={} --#PartyManager
local function newParty()
	return setmetatable(new(),
		{__index=partyManager,
		__call=function(table)  end
		})
end
local parties={}
local function IsLower(cur,base)
	if not cur then
		return 99
	else 
		return cur < base
	end
end
local function IsHigher(cur,base)
	if not cur then
		return 0
	else 
		return cur > base
	end
end

--	addon:RegisterForMenu("mission","SAVETROOPS","SPARE","MAKEITQUICK","MAXIMIZEXP")
	 
function partyManager:Fail(...)
--@debug@
	pp("Failed",self.missionID,...)
--@end-debug@
	return false
end	 
function partyManager:FillRealFollowers(candidate)
	for i=1,3 do
		if i > self.numFollowers then return end
		local followerID,classSpec=strsplit(',',candidate['f'..i])
		local troops=self.troops
		if classSpec~=0 then
			local better=(candidate.hasKillTroopsEffect and IsLower or IsHigher)
			local base=better()
			local found
			for i,troop in pairs(troops) do
				local ignore=false
				if troop.status and troop.status=="GARRISON_FOLLOWER_ON_MISSION" and  troop.classSpec==classSpec  then
					if i>1 and troop.followerID==candidate[i-1] then
						ignore=true
					end
					if i>2 and troop.followerID==candidate[i-2] then
						ignore=true
					end
						if better(troop.durability,base) then
							found=i
							base=troop.durability
						end
				end
			end
			if not found then
				return self:Fail("NOTROOPS") 
			end
			followerID=troops[found].followerID
			-- SAVETROOPS doesnt allow to have unintended casualties
			if addon:GetBoolean("SAVETROOPS") and candidate.hasKillTroopsEffect and addon:GetFollowerData(followerID,'durability') > 1 then 
				return self:Fail("SAVETROOPS") 
			end
		end
		candidate[i]=followerID
	end		
end
function partyManager:SatisfyCondition(candidate,key,table)
	local followerID,classSpec=strsplit(',',candidate[key])
	if addon:GetBoolean("SPARE") and candidate.cost > candidate.baseCost then return self:Fail("SPARE") end
	if addon:GetBoolean("MAKEITVERYQUICK") and not candidate.timeIsImproved then return self:Fail("VERYQUICK") end
	if addon:GetBoolean("MAKEITQUICK") and candidate.hasMissionTimeNegativeEffect then return self:Fail("QUICK") end
	classSpec=addon:tonumber(classSpec,0)
	local troops=self.troops
	if classSpec~=0 then
		local better=(candidate.hasKillTroopsEffect and IsLower or IsHigher)
		local base=better()
		local found
		for i,troop in pairs(troops) do
			if not troop.status and troop.classSpec==classSpec  then
				if not table or not tContains(table,troop.followerID) then
					if better(troop.durability,base) then
						found=i
						base=troop.durability
					end
				end
			end
		end
		if not found then
			return self:Fail("NOTROOPS") 
		end
		followerID=troops[found].followerID
		-- SAVETROOPS doesnt allow to have unintended casualties
		if addon:GetBoolean("SAVETROOPS") and candidate.hasKillTroopsEffect and addon:GetFollowerData(followerID,'durability') > 1 then 
			return self:Fail("SAVETROOPS") 
		end
	end
	if G.GetFollowerStatus(followerID) then
		return self:Fail("BUSY", G.GetFollowerStatus(followerID),G.GetFollowerName(followerID))
	else
		candidate[addon:tonumber(key:sub(2))]=followerID
		return true 
	end
end
function partyManager:GetSelectedParty(mission)
	if type(mission)=="table" and mission.inProgress then
		if not self.candidates or not self.candidates.progress then
			local candidate=self:GetEffects()
			local followers=mission.followers
			if followers then
				for i =1,#followers do
					candidate[i]=followers[i]
				end
			end	
			self.candidates.progress=setmetatable(candidate,CandidateMeta)		
		end 
		return self.candidates.progress	
	end
	if type(mission)=="string" and self.candidates[mission] then
		return self.candidates[mission]
	end
	if not self.ready then
		self:Match()
		self.ready=true
	end
	wipe(self.troops)
	addon:GetAllTroops(self.troops)
	local lastkey
	for i,key in ipairs(self.candidatesIndex) do
		local candidate=self.candidates[key]
		lastkey=key
		if self:SatisfyCondition(candidate,'f1') and
			self:SatisfyCondition(candidate,'f2') and
			self:SatisfyCondition(candidate,'f3') then
			candidate.order=i
			candidate.key=key
			return candidate
		end
	end
	if lastkey and #self.candidates[lastkey] >= self.numFollowers then 
		return self.candidates[lastkey] -- should not return busy followers
	end
	return emptyCandidate
end
function partyManager:Remove(...)
	local tbl=...
	if type(tbl)=="table" then
		for _,id in ipairs(tbl) do
			if type(id)=="table" then id=id.followerID end
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,id)
			if not rc then	print("Remove failed",message,self.missionID,...) end
		end
	else
		for i=1,select('#',...) do
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,(select(i,...)))
			if not rc then	print("Remove failed",message,self.missionID,...) end
		end
	end	
end
function partyManager:GetEffects()
	local timestring,timeseconds,timeImproved,chance,buffs,missionEffects,xpBonus,materials,gold=G.GetPartyMissionInfo(self.missionID)
	missionEffects.timestring=timestring
	missionEffects.timeseconds=timeseconds
	missionEffects.perc=chance
	missionEffects.timeImproved=timeImproved
	missionEffects.xpBonus=xpBonus
	missionEffects.materials=materials
	missionEffects.gold=gold
	missionEffects.perc=chance
	chance=chance*10 + 5
	if timeImproved then chance=chance +1 end  
	if missionEffects.hasMissionTimeNegativeEffect then chance=chance-1 end
	missionEffects.baseCost,missionEffects.cost=G.GetMissionCost(self.missionID)
	if missionEffects.baseCost < missionEffects.cost then
		chance=chance-2
	elseif missionEffects.baseCost > missionEffects.cost then
		chance=chance+1
	end
	missionEffects.chance=chance
	return missionEffects

end
function partyManager:Build(...)
	local followers=new()
	if select('#',...)>0 then
		for i=1,self.numFollowers or 3 do
			local follower=select(i,...)
			if not follower then return self:Remove(followers) end
			local followerID=follower.followerID
			local rc,res = pcall(G.AddFollowerToMission,self.missionID,followerID)
			if not rc or not res then
				self:Remove(followers)
				del(followers)
				return
			end
			tinsert(followers,follower) 
		end 
	end
	local missionEffects=self:GetEffects()
	missionEffects.f1=format("%s,%s",tostringall(followers[1].followerID,followers[1].isTroop and followers[1].classSpec or "0"))
	missionEffects.f2=format("%s,%s",tostringall(followers[2].followerID,followers[2].isTroop and followers[2].classSpec or "0"))
	missionEffects.f3=format("%s,%s",tostringall(followers[3].followerID,followers[3].isTroop and followers[3].classSpec or "0"))
--@debug@
	missionEffects.f1=missionEffects.f1..','..addon:GetFollowerData(followers[1].followerID,'name')
	missionEffects.f2=missionEffects.f2..','..addon:GetFollowerData(followers[2].followerID,'name')
	missionEffects.f3=missionEffects.f3..','..addon:GetFollowerData(followers[3].followerID,'name')
--@end-debug@	
	if G.AreMissionFollowerRequirementsMet(self.missionID) then
		self.candidates[format("%04d",10000-missionEffects.chance)]=setmetatable(missionEffects,CandidateMeta)
	end
	self:Remove(followers)

end	
function partyManager:Match()
--@debug@
	OHCDebug:Bump("Parties")
--@end-debug@
	local champs=new()
	wipe(self.candidates)
	addon:GetAllChampions(champs)
	local totChamps=#champs
	local mission=addon:GetMissionData(self.missionID)
	self.numFollowers=mission.numFollowers
	local t=addon:GetTroopTypes()
	local t1_1,t1_2=addon:GetTroop(t[1],2)
	local t2_1,t2_2=addon:GetTroop(t[2],2)
	local async=coroutine.running()
	if not async then holdEvents() end
	for i,champ in ipairs(champs) do
		if async then holdEvents() end
		for n=i+1,totChamps do
			local f1,f2,f3=champ,champs[n],champs[n+1]
			if f2 and f3 then
				self:Build(f1,f2,f3) -- Full Champions group
			end
			if f2 then
				if t1_1 then self:Build(f1,f2,t1_1) end
				if t2_1 then self:Build(f1,f2,t2_1) end
			end
		end
		if t1_1 and t2_1 then
			self:Build(champ,t1_1,t2_1)
		end
		if t1_1 and t1_2 then
			self:Build(champ,t1_1,t1_2)
		end
		if t2_1 and t2_2 then
			self:Build(champ,t2_1,t2_2)
		end
		if async then
			releaseEvents()
			coroutine.yield()
		end
	end
	if not async then releaseEvents() end
	if not self.candidatesIndex then self.candidatesIndex=new() end
	for k,_ in pairs(self.candidates) do
		tinsert(self.candidatesIndex,k)
	end	
	table.sort(self.candidatesIndex)
	del(champs)
	return self
end
function module:OnInitialized()
	addon:AddBoolean("SAVETROOPS",false,L["Dont kill Troops"],L["Always counter kill troops (ignored if we can only use troops with just 1 durability left)"])
	addon:AddBoolean("SPARE",false,L["Keep cost low"],L["Always counter increased resource cost"])
	addon:AddBoolean("MAKEITQUICK",true,L["Keep time short"],L["Always counter increased time"])
	addon:AddBoolean("MAKEITVERYQUICK",false,L["Keep time VERY short"],L["Only accept missions with time improved"])
	addon:AddBoolean("MAXIMIZEXP",false,L["Maximize xp gain"],L["Favours leveling follower for xp missions"])
	addon:AddSlider("WAIT",0,0,120,L["Wait time"],L["Minutes you are willing to wait for a better party"])
	addon:RegisterForMenu("mission","SAVETROOPS","SPARE","MAKEITQUICK","MAKEITVERYQUICK","MAXIMIZEXP","WAIT")
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_UPGRADED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Refresh")	
	self:RegisterEvent("FOLLOWER_LIST_UPDATE","Refresh")	
end
function module:Refresh()
	return addon:RefreshMissions()
end
function module:ResetParties()
	for _,party in pairs(parties) do
		party.ready=false
	end
end
--Public interface
function addon:ApplySAVETROOPS(value)
	return addon:RefreshMissions()
end
function addon:ApplySPARE(value)
	return addon:RefreshMissions()
end
function addon:ApplyMAKEITQUICK(value)
	return addon:RefreshMissions()
end
function addon:ApplyMAKEITVERYQUICK(value)
	return addon:RefreshMissions()
end
function addon:ApplyMAXIMIZEXP(value)
	return addon:RefreshMissions()
end
function addon:HoldEvents()
	return holdEvents()
end
function addon:ReleaseEvents()
	return releaseEvents()
end
function addon:GetParties(missionID)
	if not parties[missionID] then
		parties[missionID]=newParty()
		parties[missionID].missionID=missionID
		parties[missionID].troops=new()
		parties[missionID].candidates=new()
	end
	return parties[missionID]
end
function addon:GetAllParties()
	return parties
end
function addon:ReFillParties()
	for missionID,_ in pairs(addon:GetMissionData()) do
		self:GetParties(missionID):Match()
	end
end
--@debug@
function addon:SetDebug(id)
	debugMission=id
end
--@end-debug@