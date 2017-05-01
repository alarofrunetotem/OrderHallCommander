local me,ns=...
if ns.die then return end
local L=ns:GetLocale()
function ns:loadHelp()
self:HF_Title(me,"RELNOTES")
self:HF_Paragraph("Description")
self:Wiki([[
= OrderHallCommander helps you when choosing the right follower for the right mission =
== General enhancements ==
* Mission panel is movable (position not saved, it's jus to see things, panel is so huge...)
* Success chance extimation shown in mission list (optionally considering only available followers)
* Proposed party buttons and mission autofill
* "What if" switches to change party composition based on criteria
== Silent mode ==
typing /ohc silent in chat will eliminate every chat message from GarrisonCommander
]])
self:RelNotes(1,2,2,[[
Fix: #44 Error when changing options on send mission page
Fix: #47 Troops shipment not appearing on panel loading 
Fix: Not enough champions warning was appearing way too often
Feature: "Better party available" tooltip improvement, now also lists party composition
Fix: Removes an incompatibility with AuroraUI
]])
self:RelNotes(1,2,1,[[
Fix: #43 Added missing consumable items
Fix: #41 Consumables are now always shown
Fix: #39 Removed usage of Blizzard UIDropDown in order to avoid random taint
Feature: #40 Missions blacklisting available
]])
self:RelNotes(1,1,3,[[
Fix: #35 Now manages new champions ilevel upgrade token
Feature: #30 added option to sort unfilled missions as last 
]])
self:RelNotes(1,1,2,[[
Toc bump
]])
self:RelNotes(1,1,1,[[
Fix: Save troops honored (https://wow.curseforge.com/projects/orderhallcommander/issues/33)
Fix: restored future missions in tooltip
Fix: improved kill troop information, now the skull is green if klll troops is in effect but used troops only have 1 durability left
]])
self:RelNotes(1,1,0,[[
Fix: All cache error should be gone
Feature: new Don't use troops switch
Feature: Separate state rcap for Champions and Troops
Feature: you can decide if show busy or even inactive followers
Feature: shift click on reward prints wowhead link in chat
Feature: added icon to show active bonus and malus in mission buttons
Feature: added an informative message when the options you checked lead to not being able to fill missions
Fix: Healing Stream Totem is now considered as upgrade
]])
self:RelNotes(0,2,4,[[
Fix: lua errors in matchmaker.lua
]])
self:RelNotes(0,2,0,[[
Fix: sometimes cache was not refresh after completing missions,leaving al missions unpopulated
]])
self:RelNotes(0,1,1,[[
Fix: Checks we actually cached a follower before removing it from cache
Fix: one follower missions where not supported
Fix: Countered spells are now always marked
Feature: new options for party selection
]])
self:RelNotes(0,1,0,[[
Feature: First release
]])
end

