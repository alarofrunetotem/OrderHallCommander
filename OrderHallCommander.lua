local __FILE__=tostring(debugstack(1,2,0):match("(.*):1:")) -- Always check line number in regexp and file, must be 1
--@debug@
print('Loaded',__FILE__)
--@end-debug@
local function pp(...) print(GetTime(),"|cff009900",__FILE__:sub(-15),strjoin(",",tostringall(...)),"|r") end
--*TYPE addon
--*CONFIG noswitch=false,profile=true,enhancedProfile=true
--*MIXINS "AceHook-3.0","AceEvent-3.0","AceTimer-3.0"
--*MINOR 41
-- Auto Generated
local me,ns=...
ns.die=true
local LibInit,minor=LibStub("LibInit",true)
assert(LibInit,me .. ": Missing LibInit, please reinstall")
local requiredVersion=41
assert(minor>=requiredVersion,me ..': Need at least Libinit version ' .. requiredVersion)
ns.die=false
local addon=LibInit:NewAddon(ns,me,{noswitch=false,profile=true,enhancedProfile=true},"AceHook-3.0","AceEvent-3.0","AceTimer-3.0") --#Addon
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
local dprint=print
local ddump
--@debug@
LoadAddOn("Blizzard_DebugTools")
ddump=DevTools_Dump
LoadAddOn("LibDebug")
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
local MISSING=ITEM_MISSING:format(""):gsub(' ','')
local IGNORED=IGNORED
local UNUSED=UNUSED
MISSING=C(MISSING:sub(1,1):upper() .. MISSING:sub(2),"Red")
local ctr=0
-- Sometimes matchmakimng starts before these are defined, so I put here a sensible default (actually, this values are constans)
function addon:MAXLEVEL()
	return OHF.followerMaxLevel or 110
end
function addon:MAXQUALITY()
	return OHF.followerMaxQuality or 6
end
function addon:MAXQLEVEL()
	return addon:MAXLEVEL()+addon:MAXQUALITY()
end
function addon.colors(c1,c2)
	return C[c1].r,C[c1].g,C[c1].b,C[c2].r,C[c2].g,C[c2].b
end
function addon:ColorFromBias(followerBias)
		if ( followerBias == -1 ) then
			--return 1, 0.1, 0.1
			return C:Red()
		elseif ( followerBias < 0 ) then
			--return 1, 0.5, 0.25
			return C:Orange()
		else
			--return 1, 1, 1
			return C:Green()
		end
end
-- todefault with default
function addon:todefault(value,default)
	if value~=value then return default
	elseif value==math.huge then return default
	else return tonumber(value) or default
	end
end

function addon:SetDbDefaults(default)
	default.profile=default.profile or {}
	default.profile.blacklist={}
end
local reservedFollowers={}
function addon:UnReserve(followerID)
	if not followerID then
		wipe(reservedFollowers)
	else
		reservedFollowers[followerID]=nil
	end
end
function addon:IsReserved(followerID)
	if not followerID then return reservedFollowers end
	return reservedFollowers[followerID]
end
local colors=addon.colors
_G.OrderHallCommanderMixin={}
_G.OrderHallCommanderMixinThreats={}
_G.OrderHallCommanderMixinFollowerIcon={}
_G.OrderHallCommanderMixinMenu={}
_G.OrderHallCommanderMixinMembers={}
local Mixin=OrderHallCommanderMixin --#Mixin
local MixinThreats=OrderHallCommanderMixinThreats --#MixinThreats
local MixinMenu=OrderHallCommanderMixinMenu --#MixinMenu
local MixinFollowerIcon= OrderHallCommanderMixinFollowerIcon --#MixinFollowerIcon
local MixinMembers=OrderHallCommanderMixinMembers --#MixinMembers

function Mixin:CounterTooltip()
	local tip=self:AnchorTT()
	tip:AddLine(self.Ability)
	tip:AddLine(self.Description)
	tip:Show()

end
function Mixin:DebugOnLoad()
	self:RegisterForDrag("LeftButton")
end
function Mixin:Bump(tipo,value)
	value = value or 1
	local riga=tipo..'Refresh'
	self[tipo]=self[tipo]+value
	self[riga]:SetFormattedText("%s: %d",tipo,self[tipo])
end
function Mixin:Set(tipo,value)
	value = value or 0
	local riga=tipo..'Refresh'
	self[tipo]=value
	self[riga]:SetFormattedText("%s: %d",tipo,self[tipo])
end
function Mixin:DragStart()
	self:StartMoving()
end
function Mixin:DragStop()
	self:StopMovingOrSizing()
end
function Mixin:AnchorTT(anchor)
	anchor=anchor or "ANCHOR_TOPRIGHT"
	GameTooltip:SetOwner(self,anchor)
	return GameTooltip
end
function Mixin:ShowTT()
	if not self.tooltip then return end
	local tip=Mixin.AnchorTT(self)
	tip:SetText(self.tooltip)
	tip:Show()
end
function Mixin:HideTT()
	GameTooltip:Hide()
end
function Mixin:Dump(data)
	local	tip=self:AnchorTT("ANCHOR_CURSOR")
	if type(data)~="table" then
		data=self
	end
	tip:AddLine(data:GetName(),C:Green())
	self.DumpData(tip,data)
	tip:Show()
end
function Mixin.DumpData(tip,data)
	for k,v in kpairs(data) do
		local color="Silver"
		if type(v)=="number" then color="Cyan"
		elseif type(v)=="string" then color="Yellow" v=v:sub(1,30)
		elseif type(v)=="boolean" then v=v and 'True' or 'False' color="White"
		elseif type(v)=="table" then color="Green" if v.GetObjectType then v=v:GetObjectType() else v=tostring(v) end
		else v=type(v) color="Blue"
		end
		if k=="description" then v =v:sub(1,10) end
		tip:AddDoubleLine(k,v,colors("Orange",color))
	end
end
function MixinThreats:OnLoad()
	if not self.threatPool then self.threatPool=CreateFramePool("Frame",UIParent,"OHCThreatsCounters") end
	self.usedPool={}
end

function MixinThreats:AddIcons(mechanics,biases)
	local icons=OHF.abilityCountersForMechanicTypes
	local frame=self:GetParent()
	if not icons then
		--@debug@
		--@end-debug@
		return false
	end
	for i=1,#self.usedPool do
		self.threatPool:Release(self.usedPool[i])
	end
	wipe(self.usedPool)
	local previous
	for index,mechanic in pairs(mechanics) do
		local th=self.threatPool:Acquire()
		tinsert(self.usedPool,th)
		if mechanic and (mechanic.icon or mechanic.id) then
			th.Icon:SetTexture(mechanic.icon or icons[mechanic.id].icon)
			th.Name=mechanic.name
			th.Description=mechanic.description
			th.Ability=mechanic.ability and mechanic.ability.name or mechanic.name
			if mechanic.color then
				th.Border:SetVertexColor(C[mechanic.color]())
			else
				th.Border:SetVertexColor(addon:ColorFromBias(biases[mechanic] or mechanic.bias))
			end
			th:Show()
		else
			th:Hide()
		end
		th:SetParent(self)
		th:SetFrameStrata(self:GetFrameStrata())
		th:SetFrameLevel(self:GetFrameLevel()+1)
		th:ClearAllPoints()
		if not previous then
			th:SetPoint("BOTTOMLEFT",0,0)
			previous=th
		else
			th:SetPoint("BOTTOMLEFT",previous,"BOTTOMRIGHT",5,0)
			previous=th
		end
	end
	return previous
end

function MixinFollowerIcon:GetFollower()
	return self.followerID
end
function MixinFollowerIcon:SetFollower(followerID,checkStatus,blacklisted)
	local info=addon:GetFollowerData(followerID)
	if not info or not info.followerID then
		local rc
		rc,info=pcall(G.GetFollowerInfo,followerID)
		if not rc or not info then
			self.locked=false
			return self:SetEmpty(LFG_LIST_APP_TIMED_OUT)
		end
	end
	self.IsTroop=info.IsTroop
	self.followerID=followerID
	self:SetupPortrait(info)
	local status=(followerID and checkStatus) and G.GetFollowerStatus(followerID) or nil
	if info.isTroop then
		self:SetILevel(0)
		self.Level:SetText(FOLLOWERLIST_LABEL_TROOPS)
	else
		if info.isMaxLevel then
			self:SetILevel(info.iLevel)
		else
			self:SetLevel(info.level)
		end
	end
	self.locked=addon:IsReserved(followerID) and true or false
	if status or blacklisted then
		if not blacklisted then
			self:SetILevel(0) --CHAT_FLAG_DND
			self:GetParent():SetNotReady(true)
			self.Level:SetText(status);
		end
		self.Portrait:SetDesaturated(true)
		self:SetQuality(1)
	else
		self.Portrait:SetDesaturated(false)
	end
	self:ShowLock()
	return status
end
function MixinFollowerIcon:ShowLock()
	if self.locked then 
		self.LockIcon:Show()
	else
		self.LockIcon:Hide()
	end
end
function MixinFollowerIcon:SetEmpty(message)
	self.followerID=false
	self:SetLevel(message or MISSING)
	self:SetPortraitIcon()
	self:SetQuality(1)
	self.LockIcon:Hide()
	if message ~=UNUSED then
		self:GetParent():SetNotReady(true)
	end
end
local gft -- =GarrisonFollowerTooltip
local gft2
function MixinFollowerIcon:ShowTooltip()
	if not gft then gft=OHCFollowerTip end
	if not self.followerID then
--@debug@
		return self:Dump()
--@end-debug@
--[===[@non-debug@
		return
--@end-non-debug@]===]
	end
	local link = C_Garrison.GetFollowerLink(self.followerID);
	if link then
		local levelXP=G.GetFollowerLevelXP(self.followerID)
		local xp=G.GetFollowerXP(self.followerID)
		local _, garrisonFollowerID, quality, level, itemLevel, ability1, ability2, ability3, ability4, trait1, trait2, trait3, trait4, spec1 = strsplit(":", link)
		GarrisonFollowerTooltip_Show(
			tonumber(garrisonFollowerID), true, tonumber(quality), tonumber(level), xp,levelXP,  tonumber(itemLevel), 
			tonumber(spec1), tonumber(ability1), tonumber(ability2), tonumber(ability3), tonumber(ability4), 
			tonumber(trait1), tonumber(trait2), tonumber(trait3), tonumber(trait4),
			true,nil,nil,gft
		)
		gft:ClearAllPoints()
		gft:SetPoint("BOTTOM", self, "TOP")
		if not gft.Status then
			gft.Status=gft:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
			gft.Status:SetPoint("BOTTOM",0,5)
		end
		local status=G.GetFollowerStatus(self.followerID)
		if status then
			gft.Status:SetText(TOKEN_MARKET_PRICE_NOT_AVAILABLE.. ': ' .. status)
			gft.Status:SetTextColor(C:Orange())
			gft.Status:Show()
			gft:SetHeight(gft:GetHeight()+10)
		else
			gft.Status:Hide()
		end
		if self.locked then
			gft.Line1:SetText(KEY_BUTTON1 .. ' : ' .. C(L['Unlock this follower'],"Red"))
		else
			gft.Line1:SetText(KEY_BUTTON1 .. ' : ' .. C(L['Lock this follower'],"Green"))
		end		
		gft.Line2:SetText(SHIFT_KEY_TEXT .. KEY_BUTTON1 .. ' : ' .. L['Lock all']) 
		gft.Line3:SetText(SHIFT_KEY_TEXT .. KEY_BUTTON2 .. ' : ' .. L['Unlock all']) 
		gft.Line4:SetText(L["Locked follower are only used in this mission"])
		gft.Line4:SetTextColor(LIGHTBLUE_FONT_COLOR:GetRGBA())
		gft:SetHeight(gft:GetHeight()+80)
		if not gft2 then
			gft2=CreateFrame("Frame","OHCGarrisonFollowerTooltip",gft)--,"TooltipBorderedFrameTemplate")
			--gft2:SetPoint("BOTTOMLEFT",gft,"BOTTOMRIGHT",0,0)
			gft2:SetPoint("BOTTOMLEFT")
			gft2:SetPoint("BOTTOMRIGHT")
			gft2.lines={}
			gft2.AddLine=function(this,message,r,g,b,a)
				 tinsert(this.lines,this:CreateFontString(nil, "ARTWORK", "GameFontHighlight"))
				 local i=#this.lines
				 local line=this.lines[i]
				 line:SetJustifyH("LEFT")
				 if i==1 then 
				 	line:SetTextColor(GREEN_FONT_COLOR:GetRGBA())
				 	line:SetPoint("TOPLEFT",5,-5) 
				 	line:SetPoint("TOPRIGHT",5,-5) 
				 else 
				 	line:SetTextColor(YELLOW_FONT_COLOR:GetRGBA())
				 	line:SetPoint("TOPLEFT",this.lines[i-1],"BOTTOMLEFT",0,-5) 
				 	line:SetPoint("TOPRIGHT",this.lines[i-1],"BOTTOMRIGHT",0,-5) 
	end
				 if (r and g and b) then
				 	line:SetTextColor(r,g,b,a or 1)
				 end				 	
				 line:SetText(message)
			end
			gft2:AddLine("Finalize parties")
			gft2:AddLine(KEY_BUTTON1 .. ' : ' .. L['Lock/Unlock this follower to this mission'])
			gft2:AddLine(SHIFT_KEY_TEXT .. KEY_BUTTON1 .. ' : ' .. L['Lock all']) 
			gft2:AddLine(SHIFT_KEY_TEXT .. KEY_BUTTON2 .. ' : ' .. L['Unlock all']) 
			gft2:AddLine(L["Locked follower can not be used in other missions"],LIGHTBLUE_FONT_COLOR:GetRGBA())
			gft2:Show()
		end
	end
end
function MixinFollowerIcon:Click(button)
	local missionID=self:GetParent():GetParent().info.missionID
	if IsShiftKeyDown() then
		local lockIt=button=="LeftButton"
		for _,champion in	pairs(self:GetParent().Champions) do
			if champion.followerID then
				champion.locked=lockIt
				if lockIt then
					reservedFollowers[champion.followerID]=missionID
				else
					reservedFollowers[champion.followerID]=nil
				end
			end
		end
	elseif self.followerID then
		-- we cant lock a busy follower or to a blacklisted mission
		if reservedFollowers[self.followerID] then
			self:Unlock()
		elseif not G.GetFollowerStatus(self.followerID) and not addon.db.profile.blacklist[missionID] then
			self:Lock(missionID)
		end
	else
		return
	end
	self:ShowTooltip()
	addon:GetMissionlistModule():RefreshButtons()
end
function MixinFollowerIcon:Lock(missionID)
	reservedFollowers[self.followerID]=missionID
	self.locked=true
	self:ShowLock()
end
function MixinFollowerIcon:Unlock()
	print("Unlocking",self.followerID)
	reservedFollowers[self.followerID]=nil
	self.locked=nil
	self:ShowLock()
end
function MixinFollowerIcon:HideTooltip()
	gft:Hide()
end
function MixinMembers:Followers()
	return 
		function(t,index)
			if not index then index =0 end
			index=index+1
			return index,t[index].followerID
		end,
		self.Champions,
		nil
end
function MixinMembers:OnLoad()
	for i=1,3 do
		if self.Champions[i] then
			self.Champions[1]:SetPoint("RIGHT")
		else
			self.Champions[i]=CreateFrame("Frame",nil,self,"OHCFollowerIcon")
			self.Champions[i]:SetPoint("RIGHT",self.Champions[i-1],"LEFT",-15,0)
		end
		self.Champions[i]:SetFrameLevel(self:GetFrameLevel()+1)
		self.Champions[i]:Show()
		self.Champions[i]:SetEmpty()
	end
	self:SetWidth(self.Champions[1]:GetWidth()*3+30)
	self.NotReady.Text:SetFormattedText(RAID_MEMBER_NOT_READY,STATUS_TEXT_PARTY)
	self.NotReady.Text:SetTextColor(C.Red())
end
function MixinMembers:OnShow()
	self:SetNotReady()
end
function MixinMembers:SetNotReady(show)
	if show then
		self.NotReady:Show()
	else
		self.NotReady:Hide()
	end
end
function MixinMembers:IsReady()
	return not self.NotReady:IsShown()
end
function MixinMembers:Lock()
	for i=1,3 do
		if addon:IsReserved(self.Champions[i].followerID or "") then
			self.Champions[i].LockIcon:Show()
		else
			self.Champions[i].LockIcon:Hide()
		end
	end
end
function MixinMenu:OnLoad()
	self.Top:SetAtlas("_StoneFrameTile-Top", true);
	self.Bottom:SetAtlas("_StoneFrameTile-Bottom", true);
	self.Left:SetAtlas("!StoneFrameTile-Left", true);
	self.Right:SetAtlas("!StoneFrameTile-Left", true);
	self.GarrCorners.TopLeftGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.TopRightGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.BottomLeftGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.GarrCorners.BottomRightGarrCorner:SetAtlas("StoneFrameCorner-TopLeft", true);
	self.CloseButton:SetScript("OnClick",function() MixinMenu.OnClick(self) end)
end

