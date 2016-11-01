local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file
local me,addon=...
--8<--------------------------------------------------------
local G=C_Garrison
local _
local AceGUI=LibStub("AceGUI-3.0")
local C=addon:GetColorTable()
local L=addon:GetLocale()
local new=addon.NewTable
local del=addon.Deltable
local OHF=OrderHallMissionFrame
local OHFMissionTab=OrderHallMissionFrame.MissionTab --Container for mission list and single mission
local OHFMissions=OrderHallMissionFrame.MissionTab.MissionList -- same as OrderHallMissionFrameMissions 
local OHFFollowerTab=OrderHallMissionFrame.FollowerTab -- Contains model view
local OHFFollowers=OrderHallMissionFrameFollowers -- Contains scroll list
local OHFMissionPage=OrderHallMissionFrame.MissionTab.MissionPage -- Contains mission description and party setup 
local dprint
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
local function encapsulate() 
	if LibDebug then LibDebug() dprint=print end
end
--@end-debug@
--[===[@non-debug@
dprint=function() end
ddump=function() end
local print=function() end
--@end-non-debug@]===]
--8<-------------------------------------------------------
local module=addon:NewSubModule(module,"AceHook-3.0","AceEvent-3.0","AceTimer-3.0") --# module
local CompleteButton=OHFMissions.CompleteDialog.BorderFrame.ViewButton
local followerType=LE_FOLLOWER_TYPE_GARRISON_7_0
local pairs=pairs
local format=format
local strsplit=strsplit
--@debug@
if LibDebug then LibDebug() end
--@end-debug@
---------------------------------------------------------------------------
function module:OnInitialized()
	local ref=OHFMissions.CompleteDialog.BorderFrame.ViewButton
	local bt = CreateFrame('BUTTON',nil, ref, 'UIPanelButtonTemplate')
	bt:SetText(L["HallComander Quick Mission Completion"])
	bt:SetWidth(bt:GetTextWidth()+10)
	bt:SetPoint("CENTER",0,-50)
	addon:ActivateButton(bt,"MissionComplete",L["Complete all missions without confirmation"])
end

function module:GenerateMissionCompleteList(title,anchor)
	local w=AceGUI:Create("OHCMissionList")
--@debug@
	title=format("%s %s %s",title,w.frame:GetName(),GetTime()*1000)
--@end-debug@
	w:SetTitle(title)
	w:SetCallback("OnClose",function(widget) widget:Release() return module:MissionsCleanup() end)
	--report:SetPoint("TOPLEFT",GMFMissions.CompleteDialog.BorderFrame)
	--report:SetPoint("BOTTOMRIGHT",GMFMissions.CompleteDialog.BorderFrame)
	w:ClearAllPoints()
	w:SetPoint("TOP",anchor)
	w:SetPoint("BOTTOM",anchor)
	w:SetWidth(500)
	w:SetParent(anchor)
	w.frame:SetFrameStrata("HIGH")
	return w
end
--@debug@
function addon:ShowRewards()
	module:GenerateMissionCompleteList("Test",UIParent)
end
--@end-debug@
local cappedCurrencies={
	GARRISON_CURRENCY,
	GARRISON_SHIP_OIL_CURRENCY
}

local missions={}
local states={}
local rewards={
	items={},
	followerQLevel=setmetatable({},{__index=function() return 0 end}),
	followerXP=setmetatable({},{__index=function() return 0 end}),
	currencies=setmetatable({},{__index=function(t,k) rawset(t,k,{icon="",qt=0}) return t[k] end}),
	bonuses={}
}
local scroller
local report
local timer
local function stopTimer()
	if (timer) then
		module:CancelTimer(timer)
		timer=nil
	end
end
local function startTimer(delay,event,...)
	delay=delay or 0.2
	event=event or "LOOP"
	stopTimer()
	timer=module:ScheduleRepeatingTimer("MissionAutoComplete",delay,event,...)
	--@debug@
	print("Timer rearmed for",event,delay)
	--@end-debug@
end
function module:MissionsCleanup()
	local f=OHF
	self:Events(false)
	stopTimer()
	f.MissionTab.MissionList.CompleteDialog:Hide()
	f.MissionComplete:Hide()
	f.MissionCompleteBackground:Hide()
	f.MissionComplete.currentIndex = nil
	f.MissionTab:Show()
	-- Re-enable "view" button
	CompleteButton:SetEnabled(true)
	f:UpdateMissions()
	f:CheckCompleteMissions()
end
--[[
Eventi correlati al completamento missione
GARRISON_MISSION_COMPLETE_RESPONSE,missionID,true,true
GARRISON_FOLLOWER_DURABILITY_CHANGED,4(followertype?),followerID,0
GARRISON_FOLLOWER_XP_CHANGED,4(followertype?)followerID,240,42,104,1
GARRISON_MISSION_BONUS_ROLL_COMPLETE,missionID,true (standard loot)
GARRISON_MISSION_LIST_UPDATE,4(followwertype)
GARRISON_MISSION_BONUS_ROLL_LOOT,139611(itemid) (bonus loot)
--]]
function module:Events(on)
	if (on) then
		self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_LOOT","MissionAutoComplete")
		self:RegisterEvent("GARRISON_MISSION_BONUS_ROLL_COMPLETE","MissionAutoComplete")
		self:RegisterEvent("GARRISON_MISSION_COMPLETE_RESPONSE","MissionAutoComplete")
		self:RegisterEvent("GARRISON_FOLLOWER_XP_CHANGED","MissionAutoComplete")
		self:RegisterEvent("GARRISON_FOLLOWER_REMOVED","MissionAutoComplete")
		self:RegisterEvent("GARRISON_FOLLOWER_DURABILITY_CHANGED","MissionAutoComplete")		
	else
		self:UnregisterAllEvents()
	end
end
function module:CloseReport()
	if report then pcall(report.Close,report) report=nil end
	print(pcall(OHF.CloseMissionComplete(OHF)))
end
function module:MissionComplete(this,button,skiprescheck)
	missions=G.GetCompleteMissions(followerType)
	if (missions and #missions > 0) then
		this:SetEnabled(false)
		OHFMissions.CompleteDialog.BorderFrame.ViewButton:SetEnabled(false) -- Disabling standard Blizzard Completion
		wipe(rewards.followerQLevel)
		wipe(rewards.followerXP)
		wipe(rewards.currencies)
		wipe(rewards.items)
		local message=C("WARNING",'red')
		local wasted={}
		for i=1,#missions do
			for k,v in pairs(missions[i].followers) do
				rewards.followerBase[v]=addon:GetChampionData(followerType,v,qLevel)
			end
			for k,v in pairs(missions[i].rewards) do
				if v.itemID then GetItemInfo(v.itemID) end -- tickling server
				if v.currencyID and tContains(cappedCurrencies,v.currencyID) then
					wasted[v.currencyID]=(wasted[v.currencyID] or 0) + v.quantity
				end
			end
			local m=missions[i]
--totalTimeString, totalTimeSeconds, isMissionTimeImproved, successChance, partyBuffs, isEnvMechanicCountered, xpBonus, materialMultiplier, goldMultiplier = C_Garrison.GetPartyMissionInfo(MISSION_PAGE_FRAME.missionInfo.missionID);

			_,_,m.isMissionTimeImproved,m.successChance,_,_,m.xpBonus,m.resourceMultiplier,m.goldMultiplier=G.GetPartyMissionInfo(m.missionID)
		end
		local stop
		for id,qt in pairs(wasted) do
			local name,current,_,_,_,cap=GetCurrencyInfo(id)
			--@debug@
			print(name,current,qt,cap)
			--@end-debug@
			current=current+qt
			if current+qt > cap then
				message=message.."\n"..format(L["Capped %1$s. Spend at least %2$d of them"],name,current+qt-cap)
				stop =true
			end
		end
		if stop and not skiprescheck then
			self:Popup(message.."\n" ..format(L["If you %s, you will loose them\nClick on %s to abort"],ACCEPT,CANCEL),0,
				function()
					StaticPopup_Hide("LIBINIT_POPUP")
					module:MissionComplete(this,button,true)
				end,
				function()
					StaticPopup_Hide("LIBINIT_POPUP")
					this:SetEnabled(true)
					CompleteButton:SetEnabled(true)
					OHF:Hide()
					addon.quick=false

				end
			)
			return
		end
		report=self:GenerateMissionCompleteList("Missions' results",OHF)
		report:SetUserData('missions',missions)
		report:SetUserData('current',1)
		self:Events(true)
		self:MissionAutoComplete("INIT")
		this:SetEnabled(true)
	end
end
function module:GetMission(missionID)
	if not report then
		return
	end
	local missions=report:GetUserData('missions')
	if missions then
		for i=1,#missions do
			if missions[i].missionID==missionID then
				return missions[i]
			end
		end
	end
end
--[[
GARRISON_MISSION_COMPLETE_RESPONSE,missionID,canComplete,success,bool(?),table(?)
GARRISON_FOLLOWER_DURABILITY_CHANGED,followerType,followerID,number(Durability left?)
GARRISON_FOLLOWER_XP_CHANGED,followerType,followerID,gainedxp,oldxp,oldlevel,oldquality (gained is 0 for maxed)
GARRISON_MISSION_BONUS_ROLL_COMPLETE,missionID,bool(Success?)
If succeeded then
GARRISON_MISSION_BONUS_ROLL_LOOT,itemId
GARRISON_MISSION_LIST_UPDATE,missionType
GARRISON_FOLLOWER_XP_CHANGED,followerType,followerID,gainedxp,oldxp,oldlevel,oldquality (gained is 0 for maxed)
If troops lost:
GARRISON_FOLLOWER_REMOVED,followerType
GARRISON_FOLLOWER_LIST_UPDATE,followerType
--]]
function module:MissionAutoComplete(event,...)
-- C_Garrison.MarkMissionComplete Mark mission as complete and prepare it for bonus roll, da chiamare solo in caso di successo
-- C_Garrison.MissionBonusRoll
--@debug@
	print("evt",event,...)
--@end-debug@
	if event=="LOOT" then
		return self:MissionsPrintResults()
	end
	local current=report:GetUserData('current')
	local currentMission=report:GetUserData('missions')[current]
	local missionID=currentMission and currentMission.missionID or 0
	-- GARRISON_FOLLOWER_XP_CHANGED: followerType,followerID, xpGained, oldXp, oldLevel, oldQuality
	if (event=="GARRISON_FOLLOWER_XP_CHANGED") then
		local followerType,followerID, xpGained, oldXp, oldLevel, oldQuality=...
		if addon:tonumber(xpGained,0) then
			rewards.followerXP[followerID]=rewards.followerXP[followerID]+addon:tonumber(xpGained,0)
		end
		return
	-- GARRISON_MISSION_BONUS_ROLL_LOOT: itemID
	elseif (event=="GARRISON_MISSION_BONUS_ROLL_LOOT") then
		local itemID=...
		if (missionID) then
			rewards.items[format("%d:%s",missionID,itemID)]=1
		else
			rewards.items[format("%d:%s",0,itemID)]=1
		end
		return
	-- GARRISON_FOLLOWER_DURABILITY_CHANGED,followerType,followerID,number(Durability left?)
	elseif event=="GARRISON_FOLLOWER_DURABILITY_CHANGED" then
		local followerType,followerID,durabilityLeft=...		
	-- GARRISON_FOLLOWER_REMOVED
	elseif (event=="GARRISON_FOLLOWER_REMOVED") then
		-- gestire la distruzione di un follower... senza il follower
	-- GARRISON_MISSION_COMPLETE_RESPONSE,missionID,canComplete,success,unknown_bool,unknown_table
	elseif (event=="GARRISON_MISSION_COMPLETE_RESPONSE") then
		local missionID,canComplete,success,unknown_bool,unknown_table	
		if currentMission.completed then
			canComplete=true
			success=true
		end
		if (not canComplete) then
			-- We need to call server again
			currentMission.state=0
		elseif (success) then -- success, we need to roll
			currentMission.state=1
		else -- failure, just print results
			currentMission.state=2
		end
		startTimer(0.1)
		return
	-- GARRISON_MISSION_BONUS_ROLL_COMPLETE: missionID, requestCompleted; happens after calling C_Garrison.MissionBonusRoll
	elseif (event=="GARRISON_MISSION_BONUS_ROLL_COMPLETE") then
		local missionID, requestCompleted =...
		if (not requestCompleted) then
			-- We need to call server again
			currentMission.state=1
		else
			currentMission.state=3
		end
		startTimer(0.1)
		return
	else -- event == LOOP or INIT
		if (currentMission) then
			local step=currentMission.state or -1
			if (step<1) then
				step=0
				currentMission.state=0
				currentMission.goldMultiplier=currentMission.goldMultiplier or 1
				currentMission.xp=select(2,G.GetMissionInfo(currentMission.missionID))
				report:AddMissionButton(currentMission,addon:GetParty(currentMission.missionID),currentMission.successChance,"report")
			end
			if (step==0) then
				--@debug@
				print("Fired mission complete for",currentMission.missionID)
				--@end-debug@
				print(G.MarkMissionComplete(currentMission.missionID))
				startTimer(2)
			elseif (step==1) then
				--@debug@
				print("Fired bonus roll complete for",currentMission.missionID)
				--@end-debug@
				print(G.MissionBonusRoll(currentMission.missionID))
				startTimer(2)
			elseif (step>=2) then
				self:GetMissionResults(step==3,currentMission)
				--addon:RefreshFollowerStatus()
				--shipyard:RefreshFollowerStatus()
				local current=report:GetUserData('current')
				report:SetUserData('current',current+1)
				startTimer()
				return
			end
			currentMission.state=step
		else
			report:AddButton(L["Building Final report"])
			startTimer(1,"LOOT")
		end
	end
end
function module:GetMissionResults(success,currentMission)
	stopTimer()
	if (success) then
		report:AddMissionResult(currentMission.missionID,true)
		PlaySound("UI_Garrison_Mission_Complete_Mission_Success")
	else
		report:AddMissionResult(currentMission.missionID,false)
		PlaySound("UI_Garrison_Mission_Complete_Encounter_Fail")
	end
	if success then
		local resourceMultiplier=currentMission.resourceMultiplier or {}
		local goldMultiplier=currentMission.goldMultiplier or 1
		for k,v in pairs(currentMission.rewards) do
			v.quantity=v.quantity or 0
			if v.currencyID then
				rewards.currencies[v.currencyID].icon=v.icon
				local multi=resourceMultiplier[v.currencyID]
				if v.currencyID == 0 then
					rewards.currencies[v.currencyID].qt=rewards.currencies[v.currencyID].qt+v.quantity * goldMultiplier
				elseif resourceMultiplier[v.currencyID] then
					rewards.currencies[v.currencyID].qt=rewards.currencies[v.currencyID].qt+v.quantity * multi
				else
					rewards.currencies[v.currencyID].qt=rewards.currencies[v.currencyID].qt+v.quantity
				end
			elseif v.itemID then
				rewards.items[format("%d:%s",currentMission.missionID,v.itemID)]=1
			end
		end
	end
end
function module:MissionsPrintResults(success)
	stopTimer()
	local reported
	local followers
	--@debug@
	_G["testrewards"]=rewards
	--@end-debug@
	for k,v in pairs(rewards.currencies) do
		reported=true
		if k == 0 then
			-- Money reward
			report:AddIconText(v.icon,GetMoneyString(v.qt))
		else
			-- Other currency reward
			report:AddIconText(v.icon,GetCurrencyLink(k),v.qt)
		end
	end
	local items=new()
	for k,v in pairs(rewards.items) do
		local missionid,itemid=strsplit(":",k)
		if (not items[itemid]) then
			items[itemid]=1
		else
			items[itemid]=items[itemid]+1
		end
	end
	for itemid,qt in pairs(items) do
		reported=true
		report:AddItem(itemid,qt)
	end
	del(items)
	for k,v in pairs(rewards.followerXP) do
		reported=true
		followers=true
		local a=addon:GetChampionData(k)
		local b=addon:GetChampionData(k,'qLevel',0)
		local c=rewards.followerQLevel[k]
		report:AddFollower(a,v, b> addon:tonumber(c,0))
	end
	if not reported then
		report:AddRow(L["Nothing to report"])
	end
	if not followers then
		report:AddRow(L["No follower gained xp"])
	end
	report:AddRow(DONE)
	if addon.quick then
		self:ScheduleTimer("CloseReport",0.1)
		local qm=addon:GetModule("Quick",true)
		addon.ScheduleTimer(qm,"RunQuick",0.2)
	end
end
function addon:MissionComplete(...)
	return module:MissionComplete(...)
end
function addon:CloseMissionComplete()
	return module:CloseReport()
end