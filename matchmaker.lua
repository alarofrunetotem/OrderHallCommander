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
--local new=function() return {} end 
--local del=function(t) wipe(t) end
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
local LE_FOLLOWER_TYPE_GARRISON_7_0=LE_FOLLOWER_TYPE_GARRISON_7_0
local LE_GARRISON_TYPE_7_0=LE_GARRISON_TYPE_7_0
local GARRISON_FOLLOWER_COMBAT_ALLY=GARRISON_FOLLOWER_COMBAT_ALLY
local GARRISON_FOLLOWER_ON_MISSION=GARRISON_FOLLOWER_ON_MISSION
local GARRISON_FOLLOWER_INACTIVE=GARRISON_FOLLOWER_INACTIVE





-- End Template - DO NOT MODIFY ANYTHING BEFORE THIS LINE
--*BEGIN
local debugprofilestop=debugprofilestop
local timings={
	match={},
	select={},
	acquire={},
}
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
	if not missionID then return end
	if not viragdone and ViragDevTool_AddData then
		ViragDevTool_AddData(debug,"OHC Debug")
		viragdone=true
	end
	missionID=self:GetMissionData(missionID,"name",missionID)
	if text==nil then
		if debug[missionID] then
			del(debug[missionID])
		end
		debug[missionID]=new()
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
--@debug@
	reason=strjoin(' ',tostringall(reason,...))
	self.failed[addon:GetFollowerName(self.lastChecked)]=reason
	if addon.showFailure then
		print(self.lastChecked,addon:GetFollowerName(self.lastChecked),reason)
	end
	addon:PushDebug(self.missionID,reason)
--@end-debug@
	self.lastreason=reason
	return false,reason
end

function partyManager:SatisfyCondition(candidate,key)
	local missionID=self.missionID
	if type(candidate) ~= "table" then return self:Fail("NOTABLE") end
	local followerID=candidate[key]
	local reserved=addon:IsReserved(followerID)
	if reserved and reserved ~= missionID then return self:Fail("RESERVED",G.GetFollowerName(followerID)) end
	self.lastChecked=followerID
	if not followerID then return self:Fail("No follower id for party slot",key) end
	if addon:GetBoolean("SPARE") and candidate.cost > candidate.baseCost then return self:Fail("SPARE",addon:GetBoolean("SPARE"),candidate.cost , candidate.baseCost) end
	if addon:GetBoolean("MAKEITVERYQUICK") and not candidate.timeIsImproved then return self:Fail("VERYQUICK") end
	if addon:GetBoolean("MAKEITQUICK") and candidate.hasMissionTimeNegativeEffect then return self:Fail("QUICK") end
	if addon:GetBoolean("BONUS") and candidate.hasBonusLootNegativeEffect then return self:Fail("BONUS") end
	if addon:GetBoolean("SAVETROOPS") and candidate.hasKillTroopsEffect and addon:GetFollowerData(followerID,'durability',0) > 1 then return self:Fail("KILLTROOPS") end
	if addon:GetBoolean("NOTROOPS") 	and addon:GetFollowerData(followerID,"isTroop") then return self:Fail("NOTROOPS") end
	local ready=addon:GetFollowerData(followerID,"busyUntil")
	if not ready then return self:Fail("No ready data") end
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
local function GetSelectedParty(self,dbg)
	local missionID=self.missionID
	local lastkey
	local bestkey
	local mandatorykey
	local xpkey
	local absolutebestkey
	local busybestkey
	local xpperc=0
	local xpgainers=0
	local maxChamps=addon:GetNumber("MAXCHAMP")
	local maximizeXP=addon:GetBoolean("MAXIMIZEXP")
	local baseChance=addon:GetNumber("BASECHANCE")
	local bonusChance=100 + (self.elite and 0 or addon:GetNumber("BONUSCHANCE"))
	local capChance=self.elite and 100 or 200
	local mandatoryFollowers=new()
	local mandatoryTotal=0
	--@debug@
	if missionID == 1055 then print("Starting match",addon:GetMissionData(missionID,'name')) end
	--@end-debug@
	for f,m in pairs(addon:IsReserved()) do
		if m==missionID then
			mandatoryFollowers[f]=1
			mandatoryTotal=mandatoryTotal + 1
--@debug@
			if missionID == 1055 then print(addon:GetFollowerName(f)) end 
--@end-debug@			
		end
	end
--@debug@
	addon:PushDebug(missionID,"GetSelectedParty " .. addon:GetMissionData(missionID,"name","none"),self.candidates)
--@end-debug@
	for i,key in ipairs(self.candidatesIndex) do
		local candidate=self.candidates[key]
		local chance=candidate.perc
		self.candidates[key].ready=false
--@debug@
		addon:PushDebug(missionID,chance,{key=key,Candidate=candidate,base=baseChance,bonus=bonusChance,cap=capChance})
--@end-debug@
		if candidate and candidate.champions <=maxChamps  then
			if not absolutebestkey then absolutebestkey=key end
			local reason=''
			if type(self.numFollowers) ~= "number" then
				self.numFollowers=addon:GetMissionData(self,"numfollowers",3)
			end
			local got=true
			local mandatoryfound=0		
			--@debug@
			if missionID == 1055 then print(
				chance,
				addon:GetFollowerName(candidate[1]),
				addon:GetFollowerName(candidate[2]),
				addon:GetFollowerName(candidate[3])
				)	
			end
			--@end-debug@
			for j=1,#candidate do
				mandatoryfound=mandatoryfound+(mandatoryFollowers[candidate[j]] or 0)
				local rc,reason = self:SatisfyCondition(candidate,j)
				got=got and rc
				if not got then
					--@debug@
					if missionID == 1055 then print(
						"Refused due to",
						addon:GetFollowerName(candidate[j],self.lastreason)
						)	
					end
					break
				end
			end
			if got and mandatoryfound < mandatoryTotal then
			--@debug@
				if missionID == 1055 then
					print("Used mandatory",mandatoryfound,'<',"Requested mandatory",mandatoryTotal," in party",#candidate)
				end
			--@end-debug@
				self:Fail("Locked follower presents, none in this party")
				if #candidate>0 then got=false end
			end
			if got then
				self.candidates[key].ready=true
				if mandatoryfound >= mandatoryTotal then
					if not mandatorykey then 
						if missionID == 1055 then
							print("GOT as mandatory")
						end
						mandatorykey=key 
					end
				end
	--@debug@
				addon:PushDebug(missionID,"Considering " .. i .. " : " .. chance .. ' ' .. key .. format(" Cap=%d Bonus=%d base=%d",capChance,bonusChance,baseChance))
	--@end-debug@
				if not bestkey then
					if chance == capChance then --exactly 100 or 200, we take this one				 
	--@debug@
						addon:PushDebug(missionID,"Assigned " .. key)
	--@end-debug@
						bestkey=key
					elseif chance < capChance then --under cap
						if chance >= bonusChance then -- beats bonusChance, we take this one
	--@debug@
							addon:PushDebug(missionID,"Assigned " .. key)
	--@end-debug@
							bestkey=key
						else
							capChance=100 -- We failed achieving bonus, so no we cap at 100
							if chance >=baseChance and chance <=capChance then
	--@debug@
								addon:PushDebug(missionID,"Assigned " .. key)
	--@end-debug@
								bestkey=key
							elseif chance<baseChance then
								for k=i-1,1,-1 do
									local prevkey=self.candidatesIndex[k]
	--@debug@
									addon:PushDebug(missionID,"Backing " .. k .. " : " .. key)
	--@end-debug@
									if self.candidates[prevkey].ready and self.candidates[prevkey].perc >= baseChance then
										bestkey=prevkey
	--@debug@
										addon:PushDebug(missionID,"Assigned prev " ..prevkey)
	--@end-debug@
										break
									end
								end							
								if not bestkey then 
									bestkey=key 
	--@debug@
									addon:PushDebug(missionID,"Assigned " .. key)
	--@end-debug@
									bestkey=key
								end
							end						
						end
					else
	--@debug@
						addon:PushDebug(missionID,"Ignored " .. chance)
	--@end-debug@
					end    
				end
				if maximizeXP then
					if chance >= baseChance and candidate.xpGainers >xpgainers then
						xpkey=key
						xpperc=chance
						xpgainers=candidate.xpGainers
					end
				--else
				--	candidate.order=i
				--	candidate.key=key
				--	return candidate,key
				end
				if chance <= capChance then
					lastkey=key
				end
				if bestkey then break end
			end
--@debug@
		else
			if dbg then addon:Print("Too many champions:",candidate.champions) end
--@end-debug@
		end

	end -- for i,key in ipairs(self.candidatesIndex) do
	--@debug@
	addon:PushDebug(missionID,
		format("%s - Best: %s, Xp: %s, Absolute: %s, Last:%s",addon.lastChange,tostringall(bestkey,xpkey,absolutebestkey,lastkey))
	)
	--@end-debug@
	del(mandatoryFollowers,false)
	self.xpkey=xpkey
	self.bestkey=bestkey
	self.mandatorykey=mandatorykey
	self.absolutebestkey=absolutebestkey
	if xpkey then
		return self.candidates[xpkey],xpkey
	elseif bestkey then
		return self.candidates[bestkey],bestkey
	elseif mandatorykey then
		return self.candidates[mandatorykey],mandatorykey
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
	local start=debugprofilestop()
	--@debug@
	addon:PushDebug(missionID)
	--@end-debug@
	if addon:GetMissionData(missionID,"inProgress") then
		return emptyTable,"progress"
	end
	if type(key)=="string" and self.candidates[key] then
		return self.candidates[key],key
	end
	local candidate,key=GetSelectedParty(self)
	self.bestChance=candidate.perc or 0
	self.bestTimeseconds=candidate.timeseconds or 0
	candidate.totalXP=(self.baseXP or 0) + (self.rewardXP or 0)+(candidate.bonusXP or 0)*(candidate.xpGainers or 0)
	self.totalXP=candidate.totalXP
	timings.select[missionID]=start-debugprofilestop()
	return candidate,key
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
	if not missionEffects then missionEffects={} end
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
--@debug@
	addon:PushDebug(missionID,"Build",addon:GetFollowerName(select(1,...)),addon:GetFollowerName(select(2,...)),addon:GetFollowerName(select(3,...)))
--@end-debug@
	local followers=new()
	if select('#',...)>0 then
		for i=1,numFollowers or 3 do
			local followerID=select(i,...)
			if followerID then
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
	end
	local missionEffects=self:GetEffects()
	missionEffects.xpGainers=0
	missionEffects.champions=0
	local troopcost=0
	for i=1,#followers do
		local followerID=followers[i]
		local isTroop=addon:GetFollowerData(followerID,"isTroop")
		if not  isTroop then
			local qlevel=addon:GetFollowerData(followerID,'qLevel',0)
			missionEffects.champions=missionEffects.champions+1
			if qlevel < addon:MAXQLEVEL() then
				missionEffects.xpGainers=missionEffects.xpGainers+1
			end
		else
			troopcost=troopcost + addon:GetFollowerData(followerID,"maxDurability") + addon:GetFollowerData(followerID,"quality")
		end
		missionEffects[i]=followerID
	--@debug@
		missionEffects['f'..i]=addon:GetFollowerName(followerID)
	--@end-debug@
	end
	self.unique=self.unique+1
	local index=format("%04d:%1d:%1d:%1d:%1d:%1d:%2d",
		1000-missionEffects.perc,
		#followers,
		troopcost,
		missionEffects.improvements,
		missionEffects.champions,
		3-missionEffects.xpGainers,
		self.unique)
	missionEffects.chance=index
	self.candidates[index]=setmetatable(missionEffects,CandidateMeta)
	self:Remove(followers)

end

function partyManager:Match()
	local missionID=self.missionID
	if not missionID then print("Missing missionID",self) return false end
	local name=addon:GetMissionData(missionID,'name')
	if not name then print("Missing name",self)return false end
	self.name=name
	self.failed=self.failed or {}
	wipe(self.failed)
	local start=debugprofilestop()
	local champs=addon:GetPermutations()
	local troops=addon:GetAllTroops()
	wipe(self.candidates)
	local totChamps=#champs
--@debug@
	addon:PushDebug(missionID,"Match started for mission " .. name,champs,troops)
--@end-debug@
	self.unique=0
	local _,baseXP,_,_,_,_,exhausting,enemies=G.GetMissionInfo(missionID)
	self.numFollowers=addon:GetMissionData(missionID,"numFollowers",0)
	self.exhausting=exhausting
	self.missionClass,self.missionValue,self.missionSort=addon:Reward2Class(missionID)
	self.elite=addon:GetMissionData(missionID,'elite') or false
	self.baseXP=baseXP or 0
	self.rewardXP=(self.missionClass=="FollowerXP" and self.missionValue) or 0
	self.totalXP=self.baseXP+self.rewardXP
	local async=coroutine.running()
	if not async then holdEvents() end
	local n=self.numFollowers or 3
	for i=1,n do
		for x,tuple in pairs(champs[i]) do
			if async then holdEvents() end
			local f1,f2,f3=strsplit(',',tuple)
			f1=empty(f1) and nil or f1
			f2=empty(f2) and nil or f2
			f3=empty(f3) and nil or f3
			if i < n then
				if n-i==2 then -- room for 2 troops
					for k=1,#troops  do
						for j=2,#troops do
							self:Build(f1,troops[k],troops[j])
						end
					end
				end
				if n-i>0 then -- room for 1 troops, 
					if n==2 then
						for k=1,#troops  do
							self:Build(f1,troops[k])
						end
					else
						for k=1,#troops  do
							self:Build(f1,f2,troops[k])
						end
					end
				end
			else
				self:Build(f1,f2,f3) -- Full Champions group
				self:Build(f1,f2) -- Full Champions group
				self:Build(f1) -- Full Champions group
			end
		end
		if async then
			releaseEvents()
			coroutine.yield()
		end
	end
	self:Build()
	self:GenerateIndex()
	timings.match[missionID]=debugprofilestop()-start
--@debug@
	print("MATCH START for",name)
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
	addon:AddRange("MAXCHAMP",2,1,3,L["Max champions"],L["Use at most this many champions"],1)
	addon:AddRange("BASECHANCE",100,10,100,L["Base Chance"],L["Minimum acceptable chance for missions"],10)
	addon:AddRange("BONUSCHANCE",100,10,100,L["Bonus Chance"],L["Minimum acceptable bonus chance for missions. If cant reach it, tries to achieve just a 100% chance. Ignored for elite missions"],10)
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
	local start=debugprofilestop()
	if not missionParties[missionID] then
		missionParties[missionID]=partiesPool:Acquire()
		missionParties[missionID].missionID=missionID
	end
	timings.acquire[missionID]=start-debugprofilestop()
	return missionParties[missionID]
end
function addon:GetAllMissionParties()
	return missionParties
end
function addon:RefillParties()
	local i=0
	for _,mission in ipairs(OHFMissions.availableMissions) do
		self:GetMissionParties(mission.missionID):Match()
		i=_
	end
	return i
end
function module:ProfileStats()
	addon:LoadProfileData(partyManager,"Matchmaker")
end
function addon:Timings()
	local AceGUI=LibStub("AceGUI-3.0",true)
	if not AceGUI then error("Missing AceGUI") return end
	local dbgFrame=AceGUI:Create("Window")
	dbgFrame:SetTitle("Timings")
	dbgFrame:SetPoint("RIGHT",-100,0)
	dbgFrame:SetWidth(240)
	dbgFrame:SetHeight(400)
	dbgFrame:SetLayout("List")
	local match,acquire,select=0,0,0
	for k,v in pairs(timings) do
		local Text=AceGUI:Create("Label")
		Text:SetColor(1,1,0)
		Text:SetFullWidth(true)
		local a,m,s=tonumber(v.match) or 0,tonumber(v.acquire) or 0,tonumber(v.select) or 0
		Text:SetText(format("%5d M:%f A:%f S:%f",k,a,m,s))
		acquire=acquire + a
		match=match+m
		select=select+s
		dbgFrame:AddChild(Text)
		dbgFrame[k]=Text
	end
	local Text=AceGUI:Create("Label")
	Text:SetColor(1,1,0)
	Text:SetFullWidth(true)
	Text:SetFormattedText("%20s M:%f A:%f S:%f","Total",v.match,v.acquire,v.select)
	dbgFrame:AddChild(Text)
	dbgFrame[i]=Text
	dbgFrame:DoLayout()
end
--@debug@
function addon:SetDebug(id)
	debugMission=id
end
--@end-debug@
