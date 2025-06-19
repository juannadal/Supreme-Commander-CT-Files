--*****************************************************************************
--* File: lua/modules/ui/game/economy.lua
--* Author: Chris Blackwell
--* Summary: Economy bar UI
--*
--* Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
--*****************************************************************************

local UIUtil = import('/lua/ui/uiutil.lua')
local LayoutHelpers = import('/lua/maui/layouthelpers.lua')
local Group = import('/lua/maui/group.lua').Group
local Bitmap = import('/lua/maui/bitmap.lua').Bitmap
local Button = import('/lua/maui/button.lua').Button
local Checkbox = import('/lua/maui/checkbox.lua').Checkbox
local StatusBar = import('/lua/maui/statusbar.lua').StatusBar
local GameMain = import('/lua/ui/game/gamemain.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')
local Prefs = import('/lua/user/prefs.lua')
local Tooltip = import('/lua/ui/game/tooltip.lua')


local UIState = true

group = false
savedParent = false

GUI = {
    bg = false,
}

States = {
    energyDetail = Prefs.GetFromCurrentProfile("energyDetailedView"),
    energyViewState = Prefs.GetFromCurrentProfile("energyRateView") or 1,
    massDetail = Prefs.GetFromCurrentProfile("massDetailedView"),
    massViewState = Prefs.GetFromCurrentProfile("massRateView") or 1,
}

if States.energyDetail == nil then
    States.energyDetail = true
end

if States.massDetail == nil then
    States.massDetail = true
end

function Contract() 
    UIState = false
end

function Expand()
    UIState = true
end

function SetLayout(layout)
    GameMain.RemoveBeatFunction(_BeatFunction)
    import(UIUtil.GetLayoutFilename('economy')).SetLayout()
    return CommonLogic()
end

function CreateEconomyBar(parent)
    savedParent = parent
    CreateUI()
    return SetLayout()
end

function CreateUI()
    GUI.bg = Group(savedParent)
    GUI.bg.panel = Bitmap(GUI.bg)
    GUI.bg.leftBracket = Bitmap(GUI.bg)
    GUI.bg.leftBracketGlow = Bitmap(GUI.bg)
    
    GUI.bg.rightGlowTop = Bitmap(GUI.bg)
    GUI.bg.rightGlowMiddle = Bitmap(GUI.bg)
    GUI.bg.rightGlowBottom = Bitmap(GUI.bg)
    
    GUI.collapseArrow = Checkbox(savedParent)
    Tooltip.AddCheckboxTooltip(GUI.collapseArrow, 'econ_collapse')
    
    local function CreateResourceGroup(warningBitmap)
        local group = Group(GUI.bg)
        
		group.icon = Bitmap(group)
        group.curStorage = UIUtil.CreateText(group, '', 18, UIUtil.bodyFont)
        group.curStorage:SetDropShadow(true)

-- SC2 Proto, removing other UI elements for the time being, so we have the basic game economy values and no fluff. - GD 10/17/08
--[[        
        group.warningBG = Bitmap(group)
        group.warningBG.Depth:Set(group.Depth)
        group.warningBG.State = ''
        group.warningBG.ascending = 1
        group.warningBG.cycles = 0
        group.warningBG.flashMod = 1
        group.warningBG.warningBitmap = warningBitmap
        group.warningBG.SetToState = function(self, state)
            if self.State != state then
                if state == 'red' then
                    self:SetTexture(UIUtil.UIFile('/game/resource-panel/alert-'..self.warningBitmap..'-panel_bmp.dds'))
                    self.flashMod = 1.6
                elseif state == 'yellow' then
                    self:SetTexture(UIUtil.UIFile('/game/resource-panel/caution-'..self.warningBitmap..'-panel_bmp.dds'))
                    self.flashMod = 1.25
                end
                self.cycles = 0
                self.State = state
                self:SetNeedsFrameUpdate(true)
            end
        end
        
        group.warningBG.OnFrame = function(self, deltaTime)
            if self.State == 'hide' then
                local newAlpha = self:GetAlpha() - deltaTime
                if newAlpha < 0 then
                    self:SetAlpha(0)
                    self:SetNeedsFrameUpdate(false)
                else
                    self:SetAlpha(newAlpha)
                end
            else
                local newAlpha = self:GetAlpha() + ((deltaTime * self.flashMod) * self.ascending)
                if newAlpha > .5 then
                    newAlpha = .5
                    self.cycles = self.cycles + 1
                    self.ascending = -1
                elseif newAlpha < 0 then
                    newAlpha = 0
                    self.ascending = 1
                end
                self:SetAlpha(newAlpha)
                if self.cycles == 5 then
                    self:SetNeedsFrameUpdate(false)
                end
            end
        end
        
        group.icon = Bitmap(group)
        group.rate = UIUtil.CreateText(group, '', 18, UIUtil.bodyFont)
        group.rate:SetDropShadow(true)

        group.storageBar = StatusBar(group, 0, 100, false, false, 
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar-back_bmp.dds'), 
            UIUtil.UIFile('/game/resource-mini-bars/mini-energy-bar_bmp.dds'), false)
            
        group.curStorage = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
        group.curStorage:SetDropShadow(true)
        group.maxStorage = UIUtil.CreateText(group, '', 10, UIUtil.bodyFont)
        group.maxStorage:SetDropShadow(true)
        
        group.storageTooltipGroup = Group(group.storageBar)
        group.storageTooltipGroup.Depth:Set(function() return group.storageBar.Depth() + 10 end)
       
        group.income = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.income:SetDropShadow(true)
        group.expense = UIUtil.CreateText(group.warningBG, '', 10, UIUtil.bodyFont)
        group.expense:SetDropShadow(true)
      
        group.hideTarget = Group(group)
        group.hideTarget.Depth:Set(function() return group.income.Depth() + 1 end)
    
        group.warningBG:DisableHitTest()
        group.curStorage:DisableHitTest()
        group.maxStorage:DisableHitTest()
        group.storageBar:DisableHitTest()
        group.income:DisableHitTest()
        group.expense:DisableHitTest()
]]--
        return group
    end
    
    GUI.mass = CreateResourceGroup('mass')
	GUI.mass.curStorage:SetColor('green')
    GUI.energy = CreateResourceGroup('energy')
	GUI.energy.curStorage:SetColor('orange')
    GUI.research = CreateResourceGroup('research')
	GUI.research.curStorage:SetColor('cyan')
end

function CommonLogic()
    local function AddGroupLogic(group, prefix)
        group.warningBG.OnHide = function(self, hidden)
            if hidden then
                group.income:SetHidden(true)
                group.expense:SetHidden(true)
            else
                group.income:SetHidden(not States[prefix.."Detail"])
                group.expense:SetHidden(not States[prefix.."Detail"])
            end
            return true
        end
        
        group.hideTarget.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                if States[prefix.."Detail"] == false then
                    group.income:Show()
                    group.expense:Show()
                end
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_extended_display", nil, true)
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Rollover'})
                PlaySound(sound)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
                if States[prefix.."Detail"] == false then
                    group.income:Hide()
                    group.expense:Hide()
                end
            elseif event.Type == 'ButtonPress' then
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Click'})
                PlaySound(sound)
                States[prefix.."Detail"] = not States[prefix.."Detail"]
                group.income:SetHidden(not States[prefix.."Detail"])
                group.expense:SetHidden(not States[prefix.."Detail"])
                Prefs.SetToCurrentProfile(prefix.."DetailedView", States[prefix.."Detail"])
            end
            return true
        end
        
-- this causes errors, need to investigate why
--        Tooltip.AddControlTooltip(group.icon, prefix..'_button')
       
        group.storageTooltipGroup.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_storage", nil, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            end
            return true
        end
        
        group.rate.HandleEvent = function(self, event)
            if event.Type == 'MouseEnter' then
                Tooltip.CreateMouseoverDisplay(self, prefix .. "_rate", nil, true)
            elseif event.Type == 'MouseExit' then
                Tooltip.DestroyMouseoverDisplay()
            elseif event.Type == 'ButtonPress' then
                States[prefix..'ViewState'] = States[prefix..'ViewState'] + 1
                if States[prefix..'ViewState'] > 2 then
                    States[prefix..'ViewState'] = 1
                end
                Prefs.SetToCurrentProfile(prefix..'RateView', States[prefix..'ViewState'])
                local sound = Sound({Bank = 'Interface', Cue = 'UI_Economy_Click'})
                PlaySound(sound)
            end
            return true
        end
    end
    
	-- SC2 Proto, removing group logic for the time being, so we can see the pure economy numbers we are using now. - GD 10/17/08
    --AddGroupLogic(GUI.mass, 'mass')
    --AddGroupLogic(GUI.energy, 'energy')
        
    GameMain.AddBeatFunction(_BeatFunction)
    GUI.bg.OnDestroy = function(self)
        GameMain.RemoveBeatFunction(_BeatFunction)
    end
    
    GUI.collapseArrow.OnCheck = function(self, checked)
        ToggleEconPanel()
    end
    
    return GUI.mass, GUI.energy, GUI.research
end

function _BeatFunction()
    local econData = GetEconomyTotals()
    local simFrequency = GetSimTicksPerSecond()
    
    local function DisplayEconData(controls, tableID, viewPref, label  )
		local value = econData["stored"][tableID]

		-- Modify the visible show research points available by any user queued
		-- research costs currently active.
		if tableID == 'Research' then
			value = value - GetResearchCosts()
		end

		controls.curStorage:SetText( (label or '') .. math.ceil(value) )

-- SC2 Proto, displaying only storage values now. Other economy information to be displayed, tbd. - GD 10/17/08
--[[

        local function FormatRateString(RateVal, StoredVal, IncomeAvg, ActualAvg, RequestedAvg)
            local retRateStr = string.format('%+d', math.min(math.max(RateVal, -999999), 999999))
            local retEffVal = 0
            if RequestedAvg == 0 then
                retEffVal = math.ceil(IncomeAvg) * 100
            else
                if StoredVal > 0.5 then
                    retEffVal = math.ceil( (IncomeAvg / ActualAvg) * 100 )
                else
                    retEffVal = math.ceil( (IncomeAvg / RequestedAvg) * 100 )
                end    
            end
            return retRateStr, retEffVal
        end
        
        local maxStorageVal = econData["maxStorage"][tableID]
        local storedVal = econData["stored"][tableID]
        local incomeVal = econData["income"][tableID]
        local lastRequestedVal = econData["lastUseRequested"][tableID]
        local lastActualVal = econData["lastUseActual"][tableID]
    
        local requestedAvg = math.min(lastRequestedVal * simFrequency, 999999)
        local actualAvg = math.min(lastActualVal * simFrequency, 999999)
        local incomeAvg = math.min(incomeVal * simFrequency, 999999)

        controls.storageBar:SetRange(0, maxStorageVal)
        controls.storageBar:SetValue(storedVal)
        controls.curStorage:SetText(math.ceil(storedVal))
        controls.maxStorage:SetText(math.ceil(maxStorageVal))
       
        controls.income:SetText(string.format("+%d", math.ceil(incomeAvg)))
        if storedVal > 0.5 then
            controls.expense:SetText(string.format("-%d", math.ceil(actualAvg)))
        else
            controls.expense:SetText(string.format("-%d", math.ceil(requestedAvg)))
        end
    
        local rateVal = 0
        if storedVal > 0.5 then
            rateVal = math.ceil(incomeAvg - actualAvg)
        else
            rateVal = math.ceil(incomeAvg - requestedAvg)
        end
        
        local rateStr, effVal = FormatRateString(rateVal, storedVal, incomeAvg, actualAvg, requestedAvg)
    -- CHOOSE RATE or EFFICIENCY STRING
        if States[viewPref] == 2 then
            controls.rate:SetText(string.format("%d%%", math.min(effVal, 100)))   
        else
            controls.rate:SetText(string.format("%+s", rateStr))
        end
    -- SET RATE/EFFICIENCY COLOR
        local rateColor
        if rateVal < 0 then
            if storedVal > 0 then
                rateColor = 'yellow'
            else
                rateColor = 'red'
            end
        else
            rateColor = 'ffb7e75f'
        end
        controls.rate:SetColor(rateColor)
        
    -- ECONOMY WARNINGS        
        if Prefs.GetOption('econ_warnings') and UIState then
            if storedVal / maxStorageVal < .2 then
                if effVal < 25 then
                    controls.warningBG:SetToState('red')
                elseif effVal < 75 then
                    controls.warningBG:SetToState('yellow')
                elseif effVal > 100 then
                    controls.warningBG:SetToState('hide')
                end
            else
                controls.warningBG:SetToState('hide')
            end
        else
            controls.warningBG:SetToState('hide')
        end
]]--
    end
     
	DisplayEconData(GUI.mass, 'MASS', 'massViewState' )
	DisplayEconData(GUI.energy, 'ENERGY', 'energyViewState' )
	DisplayEconData(GUI.research, 'RESEARCH', 'researchViewState', 'Research: ' )
end

function ToggleEconPanel(state)
    if import('/lua/ui/game/gamemain.lua').gameUIHidden and state != nil then
        return
    end
    import(UIUtil.GetLayoutFilename('economy')).TogglePanelAnimation(state)
end

function InitialAnimation()
    import(UIUtil.GetLayoutFilename('economy')).InitAnimation()
end