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
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions Call Update on this to refresh Mission Listing
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowerList=OrderHallMissionFrame.FollowerList -- Contains follower list (visible in both follower and mission mode)
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local OHFMapTab=OrderHallMissionFrame.MapTab -- Contains quest map
local OHFCompleteDialog=OrderHallMissionFrameMissions.CompleteDialog
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
local emptyTable={}
local holdEvents
local releaseEvents
local events={stacklevel=0,frames={}} --#events
--@debug@
local viragdone
local debug={}
function addon:GetDebug()
	return debug
end
function addon:PushDebug(missionID,text,...)
	if true then return end
	if not viragdone and ViragDevTool_AddData then
		ViragDevTool_AddData(debug,"OHC Debug")
		viragdone=true
	end
	if text==nil then
		wipe(debug[missionID])
		return
	end
	debug[missionID]._ctr=debug[missionID]._ctr or 0
	debug[missionID]._ctr=debug[missionID]._ctr+1
	local stack=debugstack(2,1,0)	
	local addon,file, line = stack:match("([%w_]*)[/\\]?([%w_]*%.[Ll][Uu][Aa]):(%d-):")	
	local key=format("%03d %s:%d",debug[missionID]._ctr,file,line)
	debug[missionID][key]=text
	if select('#',...)>0 then
		debug[missionID][key .. '_data']={...}
	end
end
--@end-debug@
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
--@debug@
	reason=strjoin(' ',tostringall(reason,...))
--@end-debug@
	return false,reason
end	 

function partyManager:SatisfyCondition(candidate,key,table)
	local missionID=self.missionID
--@debug@
	addon:PushDebug(missionID,"SatisfyCondition",type(key),key,candidate[key])
--@end-debug@

	if type(candidate) ~= "table" then return self:Fail("NOTABLE") end
	local followerID=candidate[key]
	self.lastChecked=followerID
	if not followerID then return self:Fail("No follower id for party slot",key) end
	if addon:GetBoolean("SPARE") and candidate.cost > candidate.baseCost then return self:Fail("SPARE",addon:GetBoolean("SPARE"),candidate.cost , candidate.baseCost) end
	if addon:GetBoolean("MAKEITVERYQUICK") and not candidate.timeIsImproved then return self:Fail("VERYQUICK") end
	if addon:GetBoolean("MAKEITQUICK") and candidate.hasMissionTimeNegativeEffect then return self:Fail("QUICK") end
	if addon:GetBoolean("BONUS") and candidate.hasBonusLootNegativeEffect then return self:Fail("BONUS") end
	if addon:GetBoolean("SAVETROOPS") and candidate.hasKillTroopsEffect then if addon:GetFollowerData(followerID,'durability',0) > 1 then self:Fail("KILLTROOPS") end end 	
	local ready=addon:GetFollowerData(followerID,"busyUntil")
	if not ready then return self:Fail("No ready data") end
	local status=G.GetFollowerStatus(followerID)
	if status then 
		if addon:GetBoolean("USEALLY") and status==GARRISON_FOLLOWER_COMBAT_ALLY then
			return true
		end
		return self:Fail("BUSY",status,'G.GetFollowerStatus("' ..followerID..'")')
	end 
	return true,'OK'
end
function partyManager:IterateIndex()
	--self:GenerateIndex()
	return ipairs(self.candidatesIndex)
end
local function GetSelectedParty(self,dbg)
	local missionID=self.missionID
	local lastkey
	local bestkey
	local xpkey
	local absolutebestkey
	local busybestkey
	local xpperc=0
	local xpgainers=0
	local maxChamps=addon:GetNumber("MAXCHAMP")
--@debug@
		addon:PushDebug(missionID,"GetSelectedParty " .. addon:GetMissionData(missionID,"name","none"),self.candidates)
--@end-debug@				

	for i,key in ipairs(self.candidatesIndex) do
		local candidate=self.candidates[key]
--@debug@
		addon:PushDebug(missionID,{key=key,Candidate=candidate})
--@end-debug@				
		if candidate and candidate.champions <=maxChamps  then
			if not absolutebestkey then absolutebestkey=key end
			lastkey=key
			local got=true
			local reason=''
			if type(self.numFollowers) ~= "number" then
				self.numFollowers=addon:GetMissionData(self,"numfollowers",3)				
			end
			for i=1,self.numFollowers do
				local rc,reason = self:SatisfyCondition(candidate,i)
				got=got and rc
				if not got then
--@debug@
					addon:PushDebug(missionID,"Rejected",candidate[i],reason)
--@end-debug@				
					break 
				end
			end
			if got then
--@debug@
				addon:PushDebug(missionID,"Accepted",candidate[i])
--@end-debug@				
				if not bestkey then bestkey=key end
				if addon:GetBoolean("MAXIMIZEXP") then
					if candidate.perc >= 100 and candidate.xpGainers >xpgainers then
						xpkey=key
						xpperc=candidate.perc
						xpgainers=candidate.xpGainers
					end
				else
					candidate.order=i
					candidate.key=key
					return candidate,key
				end
			end
--@debug@
		else
			if dbg then addon:Print("Too many champions:",candidate.champions) end
--@end-debug@			
		end
		
	end
	--@debug@
	if dbg then addon:Print(
		format("Best: %s, Xp: %s, Absolute: %s, Last:%s",tostringall(bestkey,xpkey,absolutebestkey,lastkey))
		)
	end
	print("XPKey,Bestkey,Lastkey",self.missionID,xpkey,bestkey,lastkey)
	--@end-debug@
	if xpkey then 
		return self.candidates[xpkey],xpkey
	end
	if bestkey then 
		return self.candidates[bestkey],bestkey
	end
	if not addon:GetBoolean("IGNOREBUSY") and absolutebestkey then 
		return self.candidates[absolutebestkey],absolutebestkey
	end
	if lastkey then 
		--if self.candidates[lastkey].busyUntil <= GetTime() then
			return self.candidates[lastkey],lastkey -- should not return busy followers
		--end
	end
	return setmetatable(self:GetEffects(),CandidateMeta)
end
function partyManager:GetSelectedParty(key)
	local missionID=self.missionID
	--@debug@
	if debug[missionID] then
		wipe(debug[missionID])
	else
		debug[missionID]={}
	end
	--@end-debug@
	if addon:GetMissionData(missionID,"inProgress") then
		return emptyTable,"progress"
	end
	if type(key)=="string" and self.candidates[key] then
		return self.candidates[key],key
	end
	self:Match() -- Caching and optimization to be added in match
	local candidate=GetSelectedParty(self)
	self.bestChance=candidate.perc or 0
	self.bestTimeseconds=candidate.timeseconds or 0
	self.totalXP=(self.baseXP+self.rewardXP+(candidate.bonusXP or 0))*(candidate.xpGainers or 0)
	return candidate
end
function partyManager:Remove(...)
	local tbl=...
	if type(tbl)=="table" then
		for _,id in ipairs(tbl) do
			if type(id)=="table" then id=id.followerID end
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,id)
--@debug@
			if not rc then	
				print("Remove failed",message,self.missionID,...) 
			end
--@end-debug@
		end
	else
		for i=1,select('#',...) do
			local rc,message=pcall(G.RemoveFollowerFromMission,self.missionID,(select(i,...)))
--@debug@
			if not rc then	
				print("Remove failed",message,self.missionID,...) 
			end
--@end-debug@
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
	
	local improvements=5
	if timeImproved then improvements=improvements -1 end  
	if missionEffects.hasMissionTimeNegativeEffect then improvements=improvements+1 end
	missionEffects.baseCost,missionEffects.cost=G.GetMissionCost(self.missionID)
	if missionEffects.baseCost < missionEffects.cost then
		improvements=improvements+2
	elseif missionEffects.baseCost > missionEffects.cost then
		improvements=improvements-1
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
--@debug@
	addon:PushDebug(missionID,"Build",addon:GetFollowerName(select(1,...)),addon:GetFollowerName(select(2,...)),addon:GetFollowerName(select(3,...)))
--@end-debug@
	local followers=new()
	if select('#',...)>0 then
		for i=1,numFollowers or 3 do
			local followerID=select(i,...)
			if not followerID then return self:Remove(followers) end
			local rc,res = pcall(G.AddFollowerToMission,missionID,followerID)
			if not rc or not res then
--@debug@
				addon:PushDebug(missionID,"build failed " .. tostring(res),followers)
--@end-debug@

				self:Remove(followers)
				del(followers)
				return
			end
			tinsert(followers,followerID) 
		end 
	end
	local missionEffects=self:GetEffects()
	missionEffects.xpGainers=0
	missionEffects.champions=0
	for i=1,#followers do 
		local followerID=followers[i]
		local isTroop=addon:GetFollowerData(followerID,"isTroop")
		if not  isTroop then
			local qlevel=addon:GetFollowerData(followerID,'qLevel',0)
			missionEffects.champions=missionEffects.champions+1
			if qlevel < addon:MAXQLEVEL() then
				missionEffects.xpGainers=missionEffects.xpGainers+1
			end 
		end
		missionEffects[i]=followerID
	--@debug@
		missionEffects['f'..i]=addon:GetFollowerName(followerID)
	--@end-debug@
	end
	self.unique=self.unique+1	
	local index=format("%03d:%1d:%1d:%1d:%2d",900-missionEffects.perc,missionEffects.improvements,missionEffects.champions,3-missionEffects.xpGainers,self.unique)
	missionEffects.chance=index	
	self.candidates[index]=setmetatable(missionEffects,CandidateMeta)
	self:Remove(followers)

end	

function partyManager:Match()
	if self.ready and self.updated > addon.lastChange then return end
	local missionID=self.missionID
	if not missionID then print("Missing missionID",self) return false end
	local name=addon:GetMissionData(missionID,'name')
	if not name then print("Missing name",self)return false end
	local champs=addon:GetPermutations()
	local troops=new()
	addon:GetAllTroops(troops)
	wipe(self.candidates)
	local totChamps=#champs
--@debug@
	addon:PushDebug(missionID,"Match started for mission " .. name,champs,troops)
--@end-debug@
	self.unique=0
	local _,baseXP,_,_,_,_,exhausting,enemies=G.GetMissionInfo(missionID)
	self.numFollowers=addon:GetMissionData(missionID,"numFollowers",0)
	self.exhausting=exhausting
	self.missionSort=addon:Reward2Class(missionID)
	self.missionClass="MissionClass"
	self.missionValue=-1
	self.baseXP=baseXP or 0
	self.rewardXP=(self.missionClass=="FollowerXP" and self.missionValue) or 0
	self.totalXP=self.baseXP+self.rewardXP
	local async=coroutine.running()
	if not async then holdEvents() end
	local n=self.numFollowers or 3
	for i=1,n do
--@debug@
		addon:PushDebug(missionID,format("Outer loop %d",i),champs[i])
--@end-debug@
		for x,tuple in pairs(champs[i]) do
--@debug@
			addon:PushDebug(missionID,format("Inner loop %d",x,tuple))
--@end-debug@
			if async then holdEvents() end
			local f1,f2,f3=strsplit(',',tuple)
--@debug@
			addon:PushDebug(missionID,format("Checking tuple [%d][%d] %s",i,x,tuple),f1,addon:GetFollowerName(f1),f2,addon:GetFollowerName(f2),f3,addon:GetFollowerName(f3))
--@end-debug@
			f1=empty(f1) and nil or f1
			f2=empty(f2) and nil or f2
			f3=empty(f3) and nil or f3
			if i < n then
				if n-i==2 then -- needs 2 troops
					for k=1,#troops  do
						for j=2,#troops do
--@debug@
							addon:PushDebug(missionID,format("k=%d j=%d",k,j))
--@end-debug@
							self:Build(f1,troops[k].followerID,troops[j].followerID)
						end
					end
				elseif n-i==1 then
					if n==2 then
						for k=1,#troops  do
--@debug@
							addon:PushDebug(missionID,format("k=%d",k))
--@end-debug@
							self:Build(f1,troops[k].followerID)
						end
					else
						for k=1,#troops  do
--@debug@
							addon:PushDebug(missionID,format("k=%d",k))
--@end-debug@
							self:Build(f1,f2,troops[k].followerID)
						end
					end
				end
			else
				self:Build(f1,f2,f3) -- Full Champions group
			end
		end
		if async then
			releaseEvents()
			coroutine.yield()
		end
	end
	self:Build()
	self:GenerateIndex()
--@debug@
	addon:PushDebug(missionID,"Parties built",self.candidates,self.candidatesIndex)
--@end-debug@

	if not async then releaseEvents() end
	self.ready=true
	self.updated=GetTime()
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
	--addon:AddBoolean("MAXIMIZEMISSIONS",false,L["Maximize filled missions"],L["Attempts to use less champions for missions, in order to fill more missions"])
	addon:AddRange("MAXCHAMP",2,1,3,L["Max champions"],L["Use at most this many champions"])
	addon:AddBoolean("USEALLY",false,L["Use combat ally"],L["Combat ally is proposed for missions so you can consider unassigning him"])
	addon:AddBoolean("IGNOREBUSY",false,L["Ignore busy followers"],L["When no free followers are available shows empty follower"])
	addon:AddBoolean("IGNOREINACTIVE",true,L["Ignore inactive followers"],L["If not checked, inactive followers are used as last chance"])
	addon:RegisterForMenu("mission","SAVETROOPS","BONUS","SPARE","MAKEITQUICK","MAKEITVERYQUICK","MAXIMIZEXP",'MAXCHAMP','USEALLY','IGNOREBUSY','IGNOREINACTIVE')
	self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_UPGRADED","Refresh")
	self:RegisterEvent("GARRISON_FOLLOWER_ADDED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_STARTED","Refresh")
	self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","Refresh")	
	self:RegisterEvent("FOLLOWER_LIST_UPDATE","Refresh")	
end
function module:Refresh(event)
	self:ResetParties()
	addon:GetMissionlistModule():SortMissions()
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
	return self:GetMissionParties(missionID):GetSelectedParty(key)
end
function addon:ResetParties()
	return module:ResetParties()
end
--@debug@
function addon:TestParty(missionID)
	local parties=self:GetMissionParties(missionID)
	self:Print("Debug for ", missionID,G.GetMissionName(missionID))
	local choosen,choosenkey=parties:GetSelectedParty()
	self:Print(choosenkey)
	DevTools_Dump(choosen)
	
	
end
--@end-debug@

function addon:GetMissionParties(missionID)
	if not missionParties[missionID] then
		missionParties[missionID]=partiesPool:Acquire()
		missionParties[missionID].missionID=missionID
	end
--@debug@
	local n=0
	for _,_ in pairs(missionParties) do
		n=n+1
	end
	OHCDebug:Set("NumParties",n)
--@end-debug@	
	return missionParties[missionID]
end
function addon:GetAllMissionParties()
	return missionParties
end
function addon:ReFillParties()
	for missionID,_ in pairs(addon:GetMissionData()) do
		self:GetMissionParties(missionID):Match()
	end
end
function module:ProfileStats()
	addon:LoadProfileData(partyManager,"Matchmaker")
end
--@debug@
function addon:SetDebug(id)
	debugMission=id
end
--@end-debug@
