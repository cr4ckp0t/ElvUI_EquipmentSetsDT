-------------------------------------------------------------------------------
-- ElvUI Equipment Sets Datatext By Crackpotx
-------------------------------------------------------------------------------
local E, _, V, P, G = unpack(ElvUI)
ElvUI_ESDT = E:NewModule("ElvUI_EquipmentSetsDT")
local DT = E:GetModule("DataTexts")
local L = E.Libs.ACL:GetLocale("ElvUI_EquipmentSetsDT", false)
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local unpack = _G.unpack
local CreateFrame = _G.CreateFrame
local C_EquipmentSet_GetEquipmentSetInfo = C_EquipmentSet.GetEquipmentSetInfo
local C_EquipmentSet_ModifyEquipmentSet = C_EquipmentSet.ModifyEquipmentSet
local C_EquipmentSet_DeleteEquipmentSet = C_EquipmentSet.DeleteEquipmentSet
local C_EquipmentSet_GetNumEquipmentSets = C_EquipmentSet.GetNumEquipmentSets
local C_EquipmentSet_GetEquipmentSetID = C_EquipmentSet.GetEquipmentSetID
local IsShiftKeyDown = _G.IsShiftKeyDown
local IsControlKeyDown = _G.IsControlKeyDown
local IsAltKeyDown = _G.IsAltKeyDown
local C_EquipmentSet_UseEquipmentSet = C_EquipmentSet.UseEquipmentSet
local StaticPopup_Show = _G.StaticPopup_Show
local C_EquipmentSet_SaveEquipmentSet = C_EquipmentSet.SaveEquipmentSet
local ToggleCharacter = _G.ToggleCharacter
local EasyMenu = _G.EasyMenu

local join = string.join
local wipe = table.wipe
local sort = table.sort
local pairs = pairs

local displayString = ""
local chatString = ""
local iconString = "|T%s:14:14:0:0:64:64:4:60:4:60|t"
local hexColor = "ffffff"

-- for drop down menu
local menuFrame = CreateFrame("Frame", "ESDTEquipmentSetMenu", E.UIParent, "UIDropDownMenuTemplate")

-- for renaming the equipment set
StaticPopupDialogs["ESDT_RENAME"] = {
	text = L["Rename %s to what?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = true,
	maxLetters = 16,
	exclusive = 0,
	preferredIndex = 3,
	timeout = 0, 
	whileDead = true,
	hideOnEscape = true,
	OnShow = function(self) _G[self:GetName() .. "EditBox"]:SetFocus(); self.button1:Disable() end,
	OnHide = function(self)
		if _G[self:GetName() .. "EditBox"]:IsShown() then
			_G[self:GetName() .. "EditBox"]:SetFocus()
		end
		_G[self:GetName() .. "EditBox"]:SetText("")
	end,
	OnAccept = function(self, setId)
		local newName = _G[self:GetName() .. "EditBox"]:GetText()
		local oldName = C_EquipmentSet_GetEquipmentSetInfo(setId)
		if not newName or newName == "" or oldName == newName then return end
		C_EquipmentSet_ModifyEquipmentSet(setId, newName)
		DEFAULT_CHAT_FRAME:AddMessage(chatString:format((L["Renamed |cff%s%s|r to |cff%s%s|r!"]):format(hexColor, oldName, hexColor, newName)))
	end,
	EditBoxOnEnterPressed = function(self, setId)
		local newName = self:GetText()
		local oldName = C_EquipmentSet_GetEquipmentSetInfo(setId)
		if not newName or newName == "" or oldName == newName then return end
		C_EquipmentSet_ModifyEquipmentSet(setId, newName)
		DEFAULT_CHAT_FRAME:AddMessage(chatString:format((L["Renamed |cff%s%s|r to |cff%s%s|r!"]):format(hexColor, oldName, hexColor, newName)))
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
	EditBoxOnTextChanged = function(self)
		local parent = self:GetParent()
		if _G[parent:GetName() .. "EditBox"]:GetText() == "" then
			parent.button1:Disable()
		else
			parent.button1:Enable();
		end
	end
}

-- staticpoup for deleting
StaticPopupDialogs["ESDT_DELETE"] = {
	text = L["Are you sure you want to delete %s?"],
	button1 = ACCEPT,
	button2 = CANCEL,
	timeout = 10,
	whileDead = true,
	hideOnEscape = true,
	OnAccept = function(self, setId)
		local oldName = C_EquipmentSet_GetEquipmentSetInfo(setId)
		C_EquipmentSet_DeleteEquipmentSet(setId)
		DEFAULT_CHAT_FRAME:AddMessage(chatString:format((L["Deleted equipment set |cff%s%s|r!"]):format(hexColor, oldName)))
	end,
}

local function SendDebugMessage(message)
	DEFAULT_CHAT_FRAME:AddMessage(chatString:format(message))
end

local function GetEquippedSet()
	local num = C_EquipmentSet_GetNumEquipmentSets()
	if num == 0 then return false end
	for i = 0, num - 1 do
		local name, icon, _, isEquipped = C_EquipmentSet_GetEquipmentSetInfo(i)
		if isEquipped == true then
			if E.db.equipsetsdt.debug == true then
				SendDebugMessage((L["Current equipment set is |cff%s%s|r."]):format(hexColor, name))
			end
			return name, icon
		end
	end
	return false
end

local function EquipmentSetClick(self, info)
	local setId = C_EquipmentSet_GetEquipmentSetID(info)
	if not IsShiftKeyDown() and not IsControlKeyDown() and not IsAltKeyDown() then
		-- change set
		C_EquipmentSet_UseEquipmentSet(setId)
		if lastPanel ~= nil then
			local _, icon = C_EquipmentSet_GetEquipmentSetInfo(setId)
			lastPanel.text:SetFormattedText(displayString, E.db.equipsetsdt.dtIcon == true and iconString:format(("Interface\\Icons\\%s"):format(icon)) or "", info)
		end
		if E.db.equipsetsdt.debug == true then
			SendDebugMessage((L["Equipped |cff%s%s|r Set"]):format(hexColor, info))
		end
	elseif IsShiftKeyDown() then
		-- rename set
		local popup = StaticPopup_Show("ESDT_RENAME", info)
		if popup then
			popup.data = setId
		end
	elseif IsControlKeyDown() then
		-- save set
		C_EquipmentSet_SaveEquipmentSet(setId)
		SendDebugMessage((L["Saved |cff%s%s|r!"]):format(hexColor, info))
	elseif IsAltKeyDown() then
		-- delete set
		local popup = StaticPopup_Show("ESDT_DELETE", info)
		if popup then
			popup.data = setId
		end
	end
end

local function OnClick(self, button)
	if button == "LeftButton" then
		-- wish there was a cleaner way to do this
		ToggleCharacter("PaperDollFrame")
		PaperDollSidebarTab3:Click()
		if E.db.equipsetsdt.debug == true then
			SendDebugMessage(L["Toggling Equipment Manager"])
		end
	elseif button == "RightButton" then
		DT.tooltip:Hide()
		
		local menuList = {{text = L["Choose Equipment Set"], isTitle = true, notCheckable = true,},}
		local numSets, curNumSets = C_EquipmentSet_GetNumEquipmentSets(), 2
		local color = "ffffff"
		
		if numSets == 0 then
			menuList[curNumSets] = {text = ("|cffff0000%s|r"):format(L["No Equipment Sets"]), notCheckable = true,}
		else
			-- blizzard api is bass ackwards
			local minimum = numSets <= 2 and 1 or 0
			local maximum = numSets <= 2 and numSets or numSets - 1

			for i = minimum, maximum do
				local name, _, _, isEquipped, _, _, _, missing, _ = C_EquipmentSet_GetEquipmentSetInfo(i)
				if name then
					if missing > 0 then
						color = "ff0000"
					else
						color = isEquipped == true and hexColor or "ffffff"
					end
					
					menuList[curNumSets] = {text = ("|cff%s%s|r"):format(color, name), func = EquipmentSetClick, arg1 = name, checked = isEquipped == true and true or false,}
					curNumSets = curNumSets + 1
				end
			end
			
			-- add a hint
			menuList[curNumSets] = {text = L["Shift + Click to Rename"], isTitle = true, notCheckable = true, notClickable = true}
			menuList[curNumSets + 1] = {text = L["Ctrl + Click to Save"], isTitle = true, notCheckable = true, notClickable = true}
			menuList[curNumSets + 2] = {text = L["Alt + Click to Delete"], isTitle = true, notCheckable = true, notClickable = true}
		end
		EasyMenu(menuList, menuFrame, "cursor", 0, 0, "MENU", 2)
		
		if E.db.equipsetsdt.debug == true then
			SendDebugMessage(L["Showing drop down menu."])
		end
	end
end

local function OnEnter(self)
	local num = C_EquipmentSet_GetNumEquipmentSets()
	local color = "ffffff"
	local lineString = "%s |cff%s%s|r"
	local itemString = "|cff00ff00%d|r|cffffffff/|r|cff%s%d|r|cffffffff/|r|cff0000ff%d|r|cffffffff/|r|cffff0000%d|r"
	DT:SetupTooltip(self)
	
	if num == 0 then
		DT.tooltip:AddLine(displayString:format("", L["No Equipment Sets"]))
	else
		for i = 0, num - 1 do
			local name, icon, _, isEquipped, items, equipped, _, missing, ignored = C_EquipmentSet_GetEquipmentSetInfo(i)
			if name then
				if isEquipped then
					color = hexColor
				else
					color = missing > 0 and "ff0000" or "ffffff"
				end
				DT.tooltip:AddDoubleLine(lineString:format(E.db.equipsetsdt.ttIcon == true and iconString:format(icon) or "", color, name), itemString:format(equipped, hexColor, items, ignored, missing))
			end
		end
	end
	
	if E.db.equipsetsdt.hint == true then
		DT.tooltip:AddLine(" ")
		DT.tooltip:AddDoubleLine(("|cff00ff00%s|r"):format(L["Green Text"]), L["Equipped Items"], 1, 1, 1, 1, 1, 0)
		DT.tooltip:AddDoubleLine(("|cff%s%s|r"):format(hexColor, L["Color Text"]), L["Total Items"], 1, 1, 1, 1, 1, 0)
		DT.tooltip:AddDoubleLine(("|cff0000ff%s|r"):format(L["Blue Text"]), L["Ignored Items"], 1, 1, 1, 1, 1, 0)
		DT.tooltip:AddDoubleLine(("|cffff0000%s|r"):format(L["Red Text"]), L["Missing Items"], 1, 1, 1, 1, 1, 0)
		DT.tooltip:AddDoubleLine(L["Left Click"], L["Toggle Equipment Sets UI"], 1, 1, 1, 1, 1, 0)
		DT.tooltip:AddDoubleLine(L["Right Click"], L["Choose Equipment Set"], 1, 1, 1, 1, 1, 0)
	end
	DT.tooltip:Show()
end

local function OnEvent(self, event)
	local set, icon = GetEquippedSet()
	if not set then
		self.text:SetFormattedText(displayString, "", L["No Equipped Set"])
		return
	end
	self.text:SetFormattedText(displayString, E.db.equipsetsdt.dtIcon == true and iconString:format(icon) or "", set)
end

P["equipsetsdt"] = {
	["dtIcon"] = false,
	["ttIcon"] = true,
	["hint"] = true,
	["debug"] = false,
	["binds"] = {
		["outfit_1"] = "none",
		["outfit_2"] = "none",
		["outfit_3"] = "none",
		["outfit_4"] = "none",
		["outfit_5"] = "none",
		["outfit_6"] = "none",
		["outfit_7"] = "none",
		["outfit_8"] = "none",
		["outfit_9"] = "none",
		["outfit_10"] = "none",
	},
}

local function InjectOptions()
	if not E.Options.args.Crackpotx then
		E.Options.args.Crackpotx = ACH:Group(L["Plugins by |cff0070deCrackpotx|r"])
	end
	if not E.Options.args.Crackpotx.args.thanks then
		E.Options.args.Crackpotx.args.thanks = ACH:Description(L["Thanks for using and supporting my work!  -- |cff0070deCrackpotx|r\n\n|cffff0000If you find any bugs, or have any suggestions for any of my addons, please open a ticket at that particular addon's page on CurseForge."], 1)
	end

	-- main settings group
	E.Options.args.Crackpotx.args.equipsetdt = ACH:Group(L["Equipment Sets Datatext"], nil, nil, nil, function(info) return E.db.equipsetsdt[info[#info]] end, function(info, value) E.db.equipsetsdt[info[#info]] = value; DT:ForceUpdate_DataText("Equipment Sets") end)
	E.Options.args.Crackpotx.args.equipsetdt.args.dtIcon = ACH:Toggle(L["Datatext Icon"], L["Display the currently equipped set's icon on the datatext, if available."], 1)
	E.Options.args.Crackpotx.args.equipsetdt.args.ttIcon = ACH:Toggle(L["Tooltip Icons"], L["Display the icons for the equipment sets in the tooltip, if available."], 2)
	E.Options.args.Crackpotx.args.equipsetdt.args.hint = ACH:Toggle(L["Debug Mode"], L["Show the hint in the tooltip."], 3)
	E.Options.args.Crackpotx.args.equipsetdt.args.debug = ACH:Toggle(L["Debug Mode"], L["Toggle debug mode.  |cffff0000Useful if the addon is not functioning properly.|r"], 4)

	-- keybinds
	E.Options.args.Crackpotx.args.equipsetdt.args.binds = ACH:Group(L["Keybindings"], nil, 99, nil, function(info) return E.db.equipsetsdt.binds[info[#info]] end, function(info, value) E.db.equipsetsdt.binds[info[#info]] = value end)
	E.Options.args.Crackpotx.args.equipsetdt.args.binds.args.bindsHelp = ACH:Description(L["You can set the keybinds from within WOW's keybinding interface."], 1, nil, nil, nil, nil, nil, "full")
	
	for i = 1, 10 do
		E.Options.args.Crackpotx.args.equipsetdt.args.binds.args[("outfit_%d"):format(i)] = ACH:Select((L["Keybind %d"]):format(i), (L["Choose the outfit for keybind %d."]):format(i), i + 1, function()
			if C_EquipmentSet_GetNumEquipmentSets() == 0 then
				return {["none"] = L["No Sets Found"]}
			else
				local sets = {["none"] = L["None"]}
				for x = 1, C_EquipmentSet_GetNumEquipmentSets() do
					local name = C_EquipmentSet_GetEquipmentSetInfo(x)
					if name then
						sets[name] = name
					end
				end
				return sets
			end
		end)
	end
end

local function ValueColorUpdate(self, hex, r, g, b)
	displayString = join("", "|cffffffffSet:|r %s", hex, "%s|r")
	chatString = join("", hex, "ElvUI_ESDT|cffffffff: %s|r")
	hexColor = hex
	
	OnEvent(self)
end

function ElvUI_ESDT:OnInitialize()
	-- keybind handlers
	_G.BINDING_HEADER_ESDT_TITLE = L["ElvUI Equipment Sets Datatext"]
	for i = 1, 10 do
		_G[("BINDING_NAME_ESDT_OUTFIT%d"):format(i)] = L[("Outfit %d"):format(i)]
	end
end

function ElvUI_ESDT:EquipOutfit(outfit)
	local selOutfit = E.db.equipsetsdt.binds[("outfit_%d"):format(outfit)]
	if selOutfit == "none" then
		if E.db.equipsetsdt.debug == true then
			SendDebugMessage((L["Outfit not set for #%d."]):format(outfit))
		end
		return
	else
		C_EquipmentSet_UseEquipmentSet(selOutfit)
		if E.db.equipsetsdt.debug == true then
			SendDebugMessage((L["Changed outfit to |cff%s%s|r."]):format(hexColor, selOutfit))
		end
	end
end

EP:RegisterPlugin(..., InjectOptions)
DT:RegisterDatatext("Equipment Sets", nil, {"PLAYER_ENTERING_WORLD", "EQUIPMENT_SETS_CHANGED", "EQUIPMENT_SWAP_FINISHED"}, OnEvent, nil, OnClick, OnEnter, nil, L["Equipment Sets"], nil, ValueColorUpdate)