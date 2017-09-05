local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file, must be 1
--@debug@
print('Loaded',__FILE__)
--@end-debug@
local function pp(...) print(GetTime(),"|cff009900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE module
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0","AceSerializer-3.0","AceConsole-3.0"
--*MINOR 35
-- Auto Generated
local me,ns=...
if ns.die then return end
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
local new=addon:Wrap("NewTable")
local del=addon:Wrap("DelTable")
local kpairs=addon:Wrap("Kpairs")
local empty=addon:Wrap("Empty")

local todefault=addon:Wrap("todefault")

local tonumber=tonumber
local type=type
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
local OHFCompleteDialog=OrderHallMissionFrameMissions.CompleteDialog
local OHFMissionScroll=OrderHallMissionFrameMissionsListScrollFrame
local OHFMissionScrollChild=OrderHallMissionFrameMissionsListScrollFrameScrollChild
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local garrisonType=LE_GARRISON_TYPE_7_0
local FAKE_FOLLOWERID="0x0000000000000000"
local MAX_LEVEL=110

local ShowTT=OrderHallCommanderMixin.ShowTT
local HideTT=OrderHallCommanderMixin.HideTT

local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")

if LibDebug then LibDebug() dprint=print end
local safeG=addon.safeG

--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
local LE_FOLLOWER_TYPE_GARRISON_7_0=LE_FOLLOWER_TYPE_GARRISON_7_0
local LE_GARRISON_TYPE_7_0=LE_GARRISON_TYPE_7_0
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE
local ViragDevTool_AddData=_G.ViragDevTool_AddData
if not ViragDevTool_AddData then ViragDevTool_AddData=function() end end
local KEY_BUTTON1 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:228:283\124t" -- left mouse button
local KEY_BUTTON2 = "\124TInterface\\TutorialFrame\\UI-Tutorial-Frame:12:12:0:0:512:512:10:65:330:385\124t" -- right mouse button
local CTRL_KEY_TEXT,SHIFT_KEY_TEXT=CTRL_KEY_TEXT,SHIFT_KEY_TEXT


-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN
addon.lastChange=GetTime()
local matchtimer={time=0,count=0}
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
local assert,ipairs,pairs,wipe,GetFramesRegisteredForEvent=assert,ipairs,pairs,wipe,GetFramesRegisteredForEvent
local select,tinsert,format,pcall,setmetatable,coroutine=select,tinsert,format,pcall,setmetatable,coroutine
local tostringall=tostringall
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local emptyTable=setmetatable({},{__newindex=function() end})
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
local busyCache={}
function addon:BusyFor(candidate)
	if not candidate then wipe(busyCache) return end
	local busyUntil=0
	for _,followerID in candidate:IterateFollowers() do
		if not busyCache[followerID] then
			busyCache[followerID]=G.GetFollowerMissionTimeLeftSeconds(followerID) or 0
		end
		if busyCache[followerID]>busyUntil then
			busyUntil=busyCache[followerID]
		end
	end
	return busyUntil
end
function addon:CanKillTroops(candidate)
	for _,followerID in candidate:IterateFollowers() do
		if self:GetFollowerData(followerID,'durability',0)>1 then
			return true
		end
	end
	return false
end

-- Party management
local partyManager={} --#PartyManager
local missionParties={}
local partiesPool=CreateObjectPool(
	function(self) return setmetatable({},{__index=partyManager}) end,
	function(self,obj)
		local c=obj.candidates
		local ci=obj.candidatesIndex
		if ci then wipe(ci) else ci ={} end
		if c then wipe(c) else c={} end
		wipe(obj)
		obj.candidates=c
		obj.candidatesIndex=ci
	end

)

--	addon:RegisterForMenu("mission","SAVETROOPS","SPARE","MAKEITQUICK","MAXIMIZEXP")
function partyManager:Fail(reason,...)
	self.lastreason=reason
	return false,reason
end

function partyManager:SatisfyCondition(candidate,index)
	local missionID=self.missionID
	if type(candidate) ~= "table" then return self:Fail("NOTABLE") end
	local followerID=candidate[index]
	if not followerID then return self:Fail("No follower id for party slot",index) end

	local follower=addon:GetFollowerData(followerID)
	if follower.IsTroop then
		if addon:GetBoolean("NOTROOPS") 	then return self:Fail("NOTROOPS") end
		local durability
		if addon:GetBoolean("SAVETROOPS") and candidate.hasKillTroopsEffect then durability =1 end
		followerID=addon:GetTroop(missionID,followerID,durability,addon:GetBoolean('IGNOREBUSY'))
		if followerID then candidate[index]=followerID return true,'OK' else return false,"NOAVAILABLETROOPS" end
	else
		local reserved=addon:IsReserved(followerID)
		if reserved and reserved ~= missionID then return self:Fail("RESERVED",G.GetFollowerName(followerID)) end
		self.lastChecked=followerID
	end
	local status=G.GetFollowerStatus(followerID)
	if status then
		if addon:GetBoolean("USEALLY") and status==GARRISON_FOLLOWER_COMBAT_ALLY then
			return true
		end
		if not addon:GetBoolean('IGNOREBUSY') and status==GARRISON_FOLLOWER_ON_MISSION then
			return true
		end
		if not addon:GetBoolean('IGNOREINACTIVE') and status==GARRISON_FOLLOWER_INACTIVE then
			return true
		end
		return self:Fail("BUSY",status,G.GetFollowerName(followerID))
	end
	return true,'OK'
end
function partyManager:IterateIndex()
	--self:GenerateIndex()
	return ipairs(self.candidatesIndex)
end
local function describe(...)
	local s=''
	for i=1,select('#',...) do
		local f=addon:GetFollowerData(select(i,...))
		if f then
			if f.IsTroop then
				s=s .. tostring(f.followerID)
			else
				s=s .. tostring(f.name and f.name or f.followerID)
			end
			s=s .. ' '
		end
	end
	return s
end
function partyManager:CheckCaps(index)
	local candidate=self.candidates[self.candidatesIndex[index]]
	local chance=candidate.perc
	if chance <= self.capChance then -- Cap requisite satisfied
		if chance >= self.bonusChance then -- beats bonusChance, we take this one
			return candidate.key
		else
			self.capChance=100 -- We failed achieving bonus, so now we cap at 100
			if chance >=self.baseChance and chance <=self.capChance then
				return candidate.key
			elseif chance<self.baseChance then
				-- we are too low, so we need to go back in the chain and find someting better than baseChance even if over cap
				for k=index-1,1,-1 do
					local candidate=self.candidates[self.candidatesIndex[k]]
					if candidate and candidate.good and candidate.perc >= self.baseChance then
						return candidate.key
					end
				end
				return candidate.key							
			end
		end    
	end
end
function partyManager:CheckParty(candidate)
	candidate.good=false
	local key,chance=candidate.key,candidate.perc
	local missionID=candidate.missionID
	if not self.elite and chance < self.minChance then return end
	if type(self.numFollowers) ~= "number" then
		self.numFollowers=addon:GetMissionData(self,"numfollowers",3)
	end
	if addon:GetBoolean("SPARE") and candidate.cost > candidate.baseCost then return self:Fail("SPARE",addon:GetBoolean("SPARE"),candidate.cost , candidate.baseCost) end
	if addon:GetBoolean("MAKEITVERYQUICK") and not candidate.timeImproved then return self:Fail("VERYQUICK") end
	if addon:GetBoolean("MAKEITQUICK") and candidate.hasMissionTimeNegativeEffect then return self:Fail("QUICK") end
	if addon:GetBoolean("BONUS") and candidate.hasBonusLootNegativeEffect then return self:Fail("BONUS") end			
	local mandatoryfound=0
	for j=1,#candidate do
		local oldfollower=candidate[j]
		local rc,reason = self:SatisfyCondition(candidate,j)
		if not rc then self.lastreason=reason return end
	end
	for _,mandatory in ipairs(self.mandatoryFollowers) do
		if not tContains(candidate,mandatory) then
			self.lastreason="Missing mandatory follower"
			return
		end
	end
	self.candidates[key].good=true -- This party is good, we now check caps
	return key
end

function partyManager:GetSelectedParty(key)
	-- When we receive a key we MUST return the selected party, no question asked
	if type(key)=="string" and self.candidates[key] then
		return self.candidates[key],key
	end
	local missionID=self.missionID
	local xpgainers=0
	self.maximizeXP=addon:GetBoolean("MAXIMIZEXP")
	self.minChance=addon:GetNumber("MINCHANCE")
	self.baseChance=addon:GetNumber("BASECHANCE")
	self.bonusChance=100 + (self.elite and 0 or addon:GetNumber("BONUSCHANCE"))
	self.capChance=self.elite and 100 or 200
	self.maxXp=0
	self.bestkey,self.xpkey,self.absolutebestkey,self.lastkey=nil,nil,nil,nil
	self.mandatoryFollowers=new()
	self.lastreason='GOOD'
	for f,m in pairs(addon:IsReserved()) do
		if m==missionID then
			tinsert(self.mandatoryFollowers,f)
		end
	end
	for i=1,#self.candidatesIndex do
		local candidate=self.candidates[self.candidatesIndex[i]]
		if candidate then
			local key = candidate.key 
			if self:CheckParty(candidate) then
				if self.maximizeXP and candidate.totalXP >self.maxXp then 
					self.maxXp=candidate.totalXP
					self.xpkey=key 
				end
				if candidate.champions > addon:GetNumber("MAXCHAMP") then 
					self.lastreason=format("TOOMANYCHAMPIONS %d over %d",candidate.champions,addon:GetNumber("MAXCHAMP"))
				else
					if not self.absolutebestkey then self.absolutebestkey=key end
					if not self.bestkey then self.bestkey=self:CheckCaps(i) end
					self.lastkey=key
				end
			end
			if self.bestkey and not self.maximizeXP then break end
			if candidate.perc < self.minChance then break end
		end
	end -- for i,key in ipairs(self.candidatesIndex) do
	del(self.mandatoryFollowers,false)
	self.mandatoryFollowers=nil
	local selected
	if self.xpkey then
		selected = self.candidates[self.xpkey]
	elseif self.bestkey then
		selected = self.candidates[self.bestkey]
	elseif not addon:GetBoolean("IGNOREBUSY") and self.absolutebestkey then
		selected = self.candidates[self.absolutebestkey]
	elseif self.lastkey then
		--if self.candidates[lastkey].busyUntil <= GetTime() then
			selected = self.candidates[self.lastkey] -- should not return busy followers
		--end
	else
		selected = setmetatable(self:GetEffects(),CandidateMeta)
	end
	self.bestChance=selected.perc or 0
	self.bestTimeseconds=selected.timeseconds or 0
	self.previouskey=selected.key
	return selected,selected.key
end
function partyManager:Remove(...)
	local tbl=...
	if type(tbl)=="table" then
		for _,id in ipairs(tbl) do
			if type(id)=="table" then id=id.followerID end
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,id)
		end
	else
		for i=1,select('#',...) do
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,(select(i,...)))
		end
	end
end
function partyManager:GetEffects()
	local timestring,timeseconds,timeImproved,chance,buffs,missionEffects,xpBonus,materials,gold=G.GetPartyMissionInfo(self.missionID)
	if not missionEffects then missionEffects={} end
	missionEffects.timestring=timestring
	missionEffects.timeseconds=timeseconds
	missionEffects.perc=chance or 0
	missionEffects.timeImproved=timeImproved
	missionEffects.xpBonus=xpBonus
	missionEffects.materials=materials
	missionEffects.gold=gold

	local improvements=5
	if timeImproved then improvements=improvements -1 end
	if missionEffects.hasMissionTimeNegativeEffect then improvements=improvements+1 end
	missionEffects.baseCost,missionEffects.cost=G.GetMissionCost(self.missionID)
	if missionEffects.baseCost and missionEffects.cost then
		if missionEffects.baseCost < missionEffects.cost then
			improvements=improvements+2
		elseif missionEffects.baseCost > missionEffects.cost then
			improvements=improvements-1
		end
	end
	if missionEffects.hasKillTroopsEffect then
		improvements=improvements+2
	end
	missionEffects.improvements=improvements
	return missionEffects

end
function partyManager:Build(...)
	local numFollowers=self.numFollowers
	local missionID=self.missionID
	local followers=new()
	local troopcost,xpGainers,champions=0,0,0
	if select('#',...)>0 then
		for i=1,numFollowers or 3 do
			local s=select(i,...)
			if s then
				local fType,followerID=strsplit('|',s)
				if followerID then
					local rc,res = pcall(G.AddFollowerToMission,missionID,followerID)
					if not rc or not res then
						self:Remove(followers)
						del(followers)
						return
					end
					tinsert(followers,followerID)
					if fType=="H" then -- Champion
						local qlevel=addon:GetFollowerData(followerID,'qLevel',0)
						champions=champions+1
						if qlevel < addon:MAXQLEVEL() then
							xpGainers=xpGainers+1
						end
					else
						troopcost=troopcost + addon:GetFollowerData(followerID,"maxDurability") + addon:GetFollowerData(followerID,"quality")
					end
				end
			end
		end
	end
	local missionEffects=self:GetEffects()
	missionEffects.xpGainers=xpGainers
	missionEffects.totalXP=(todefault(missionEffects.bonusXP,0) + todefault(self.baseXP,0))*(missionEffects.xpGainers or 0)	
	missionEffects.champions=champions
	if missionEffects.champions > 3 then print("Che cazzo succede",missionID,champions) end
	self.unique=self.unique+1
	for i=1,#followers do
		missionEffects[i]=followers[i]
	end
	local index=format("%04d:%1d:%1d:%1d:%1d:%1d:%2d",
		1000-missionEffects.perc,
		#followers,
		troopcost,
		missionEffects.improvements,
		missionEffects.champions,
		3-missionEffects.xpGainers,
		self.unique)
	missionEffects.key=index
	self.candidates[index]=setmetatable(missionEffects,CandidateMeta)
	self:Remove(followers)
	return index
end

-- 
function partyManager:Match()
	local missionID=self.missionID
	if not missionID then print("Missing missionID",self) return false end
	local mission=addon:GetMissionData(missionID)
	if not mission then print("Missing mission ",missionID,self)return false end
	self.name=mission.name
	wipe(self.candidates)
	self.unique=0
	local _,baseXP,_,_,_,_,exhausting,enemies=G.GetMissionInfo(missionID)
	self.numFollowers=mission.numFollowers or 0
	self.exhausting=exhausting
	self.elite=mission.elite
	self.baseXP=baseXP or 0
	self.rewardXP=(mission.class=="FollowerXP" and mission.value) or 0
	self.totalXP=self.baseXP+self.rewardXP
	local n=self.numFollowers or 3
	for _,tuple in pairs(addon:GetFullPermutations()) do
		local total,totalChamps,totalTroops,f1,f2,f3=strsplit(',',tuple)
		if tonumber(total) > n then break end
		self:Build(f1,f2,f3)
	end
	self:Build()
	self:GenerateIndex()
	return true
end
function partyManager:GenerateIndex()
	wipe(self.candidatesIndex)
	for k,_ in pairs(self.candidates) do
		tinsert(self.candidatesIndex,k)
	end
	table.sort(self.candidatesIndex)
end
function module:OnInitialized()
	addon:AddLabel(L["Missions"],L["Configuration for mission party builder"])
	addon:AddBoolean("SAVETROOPS",false,L["Dont kill Troops"],L["Always counter kill troops (ignored if we can only use troops with just 1 durability left)"])
	addon:AddBoolean("BONUS",true,L["Keep extra bonus"],L["Always counter no bonus loot threat"])
	addon:AddBoolean("SPARE",false,L["Keep cost low"],L["Always counter increased resource cost"])
	addon:AddBoolean("MAKEITQUICK",true,L["Keep time short"],L["Always counter increased time"])
	addon:AddBoolean("MAKEITVERYQUICK",false,L["Keep time VERY short"],L["Only accept missions with time improved"])
	addon:AddBoolean("MAXIMIZEXP",false,L["Maximize xp gain"],L["Favours leveling follower for xp missions"])
	addon:AddRange("MAXCHAMP",2,1,3,L["Max champions"],L["Use at most this many champions"],1)
	addon:AddRange("MINCHANCE",5,5,100,L["Absolute Minimum Chance"],L["Dont bother filling missions under this success chance. (Can speed up the whole selection)."],5)
	addon:AddRange("BONUSCHANCE",5,5,100,L["Bonus Chance"],L["If bonus chance is lower than this, then we try to not overcap the mission."],5)
	addon:AddRange("BASECHANCE",5,5,100,L["Base Chance"],L["When we cant achieve the requested bonus chance, we try to reach at least this one"],5)
	addon:AddBoolean("NOTROOPS",false,L["Don't use troops"],L["Only use champions even if troops are available"])
	addon:AddBoolean("USEALLY",false,L["Use combat ally"],L["Combat ally is proposed for missions so you can consider unassigning him"])
	addon:AddBoolean("IGNOREBUSY",false,L["Ignore busy followers"],L["When no free followers are available shows empty follower"])
	addon:AddBoolean("IGNOREINACTIVE",true,L["Ignore inactive followers"],L["If not checked, inactive followers are used as last chance"])
	addon:RegisterForMenu("mission",
		"SAVETROOPS",
		"BONUS",
		"SPARE",
		"MAKEITQUICK",
		"MAKEITVERYQUICK",
		"MAXIMIZEXP",
		'MAXCHAMP',
		'MINCHANCE',
		'BASECHANCE',
		'BONUSCHANCE',
		'NOTROOPS',
		'USEALLY',
		'IGNOREBUSY',
		'IGNOREINACTIVE')
end
function module:Events()
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_UPGRADED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Refresh")
	self:RegisterEvent("FOLLOWER_LIST_UPDATE","Refresh")
end
function module:Refresh(event)
	self:ResetParties()
	addon.lastChange=GetTime()
	return addon:RefreshMissions()
end
function module:ResetParties()
	partiesPool:ReleaseAll()
	wipe(missionParties)
end
function addon:HoldEvents()
	return holdEvents()
end
function addon:ReleaseEvents()
	return releaseEvents()
end
function addon:GetSelectedParty(missionID,key)
	if addon:GetMissionData(missionID,"inProgress") then return emptyTable,"progress" end
	return self:GetMissionParties(missionID):GetSelectedParty(key)
end
function addon:ResetParties()
	return module:ResetParties()
end
--@debug@
local cache={}
function addon:TestParty(missionID)
	local parties=self:GetMissionParties(missionID)
	wipe(cache)
	tinsert(cache,addon:GetMissionData(missionID,'name',missionID))
	local title=G.GetMissionName(missionID)
	self:Print("Debug for ", title)
	local choosen,choosenkey=parties:GetSelectedParty()
	self:Print(choosenkey)
	if ViragDevTool_AddData then
		ViragDevTool_AddData({_title=title,_key=choosenkey,data=parties.candidates},"Mission debug " .. title)
		GetSelectedParty(parties,true)
	end
end
--@end-debug@

function addon:GetMissionParties(missionID)
	if not missionParties[missionID] then
		missionParties[missionID]=partiesPool:Acquire()
		missionParties[missionID].missionID=missionID
	end
	return missionParties[missionID]
end
function addon:GetAllMissionParties()
	return missionParties
end
function addon:RefillParties()
	local i=0
	holdEvents()
	for _,mission in ipairs(OHFMissions.availableMissions) do
		self:GetMissionParties(mission.missionID):Match()
		i=_
	end
	releaseEvents()
	return i
end
function module:ProfileStats()
	addon:LoadProfileData(partyManager,"Matchmaker")
end
