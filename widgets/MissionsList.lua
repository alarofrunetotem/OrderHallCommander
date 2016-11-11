local me,addon=...
local C=addon:GetColorTable()
local module=addon:GetWidgets()
local Type,Version,unique="OHCMissionsList",1,0
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end
local G=C_Garrison
local m={} --#Widget
function m:ScrollDown()
	local obj=self.scroll
	if (#self.missions >1 and obj.scrollbar and obj.scrollbar:IsShown()) then
		obj:SetScroll(80)
		obj.scrollbar.ScrollDownButton:Click()
	end
end
function m:OnAcquire()
	wipe(self.missions)
end
function m:Show()
	self.frame:Show()
end
function m:Hide()
	self.frame:Hide()
	self:Release()
end
function m:AddButton(text,action)
	local obj=self.scroll
	local b=AceGUI:Create("Label")
	b:SetFullWidth(true)
	b:SetText(text)
	b:SetColor(C.yellow.r,C.yellow.g,C.yellow.b)
	--b:SetCallback("OnClick",action)
	obj:AddChild(b)
end
function m:AddMissionButton(mission,followers,perc,source)
	if not self.missions[mission.missionID] then
		local obj=self.scroll
		local b=AceGUI:Create("OHCMissionButton")
		b:SetMission(mission,followers,perc,source)
		b:SetScale(0.7)
		b:SetFullWidth(true)
		self.missions[mission.missionID]=b
		obj:AddChild(b)
		local extra=b.extra
		extra.Success:Hide()
		extra.Failure:Hide()
		extra.Spinner:Show()
		extra.Spinner.Anim:Play()
	end

end
function m:AddMissionResult(missionID,success)
	local mission=self.missions[missionID]
	if mission then
		local frame=mission.frame
		local extra=mission.extra
		extra.Spinner.Anim:Stop()
		extra.Spinner:Hide()
		if success then
			extra.Success:Show()
			extra.Failure:Hide()
			for i=1,#frame.Rewards do
				frame.Rewards[i].Icon:SetDesaturated(false)
				frame.Rewards[i].Quantity:Show()
			end
		else
			extra.Success:Hide()
			extra.Failure:Show()
			for i=1,#frame.Rewards do
				frame.Rewards[i].Icon:SetDesaturated(true)
				frame.Rewards[i].Quantity:Hide()
			end
		end
	end
end
function m:AddRow(data,...)
	local obj=self.scroll
	local l=AceGUI:Create("InteractiveLabel")
	l:SetFontObject(GameFontNormalSmall)
	l:SetText(data)
	l:SetColor(...)
	l:SetFullWidth(true)
	obj:AddChild(l)

end
function m:AddFollower(follower,xp,levelup)
	local followerID=follower.followerID
	local followerType=follower.followerTypeID
	local fullname=G.GetFollowerLink(followerID)
	if xp < 0 then
		return self:AddFollowerIcon(followerType,follower.portraitIconID,
							format("%s was destroyed",fullname or L["A ship"]))
	end
	if follower.isMaxLevel and not levelup then
		return
--			return self:AddFollowerIcon(followerType,follower.portraitIconID,format("%s is already at maximum xp",follower.fullname))
	end
	local quality=G.GetFollowerQuality(followerID) or follower.quality
	local level=G.GetFollowerLevel(followerID) or follower.level
	if levelup then
		PlaySound("UI_Garrison_CommandTable_Follower_LevelUp");
	end
	local message=GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT:format(fullname,xp)
	if levelup then
		message=message..GARRISON_FOLLOWER_XP_ADDED_ZONE_SUPPORT_LEVEL_UP:format(fullname,follower.level)
	end
	message=message ..
			GARRISON_FOLLOWER_XP_LEFT:format(follower.levelXP-follower.xp) ..
			follower.isMaxLevel and GARRISON_FOLLOWER_XP_UPGRADE_STRING or GARRISON_FOLLOWER_XP_STRING		
	return self:AddFollowerIcon(followerType,follower.portraitIconID,message)
end
function m:AddFollowerIcon(followerType,icon,text)
	local l=self:AddIconText(icon,text)
end
function m:AddIconText(icon,text,qt)
	local obj=self.scroll
	local l=AceGUI:Create("Label")
	l:SetFontObject(GameFontNormalSmall)
	if (qt) then
		l:SetText(format("%s x %s",text,qt))
	else
		l:SetText(text)
	end
	l:SetImage(icon)
	l:SetImageSize(24,24)
	l:SetHeight(26)
	l:SetFullWidth(true)
	obj:AddChild(l)
	if (obj.scrollbar and obj.scrollbar:IsShown()) then
		obj:SetScroll(80)
		obj.scrollbar.ScrollDownButton:Click()
	end
	return l
end
function m:AddItem(itemID,qt)
	local obj=self.scroll
	local _,itemlink,itemquality,_,_,_,_,_,_,itemtexture=GetItemInfo(itemID)
	if not itemlink then
		self:AddIconText(itemtexture,itemID,qt)
	else
		self:AddIconText(itemtexture,itemlink,qt)
	end
end
function m._Constructor()
	local widget=AceGUI:Create("OHCGUIContainer")
	widget:SetLayout("Fill")
	widget.missions={}
	local scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List") -- probably?
	scroll:SetFullWidth(true)
	scroll:SetFullHeight(true)
	widget:AddChild(scroll)
	for k,v in pairs(m) do widget[k]=v end
	widget._Constructor=nil
	widget:Show()
	widget.scroll=scroll
	widget.type=Type
	return widget
end
AceGUI:RegisterWidgetType(Type,m._Constructor,Version)
