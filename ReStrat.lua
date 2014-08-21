-----------------------------------------------------------------------------------------------
-- Client Lua Script for ReStrat
-- Copyright (c) NCsoft. All rights reserved
-- Created by Ryan Park, aka Reglitch of Codex
-----------------------------------------------------------------------------------------------
 
require "Window"
require "Sound"
 
local ReStrat = {} 
 
-----------------------------------------------------------------------------------------------
-- Initialization
-----------------------------------------------------------------------------------------------
function ReStrat:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self 

    return o
end

function ReStrat:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
	}
    Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end
 

-----------------------------------------------------------------------------------------------
-- ReStrat OnLoad
-----------------------------------------------------------------------------------------------
function ReStrat:OnLoad()
	self.xmlDoc = XmlDoc.CreateFromFile("ReStrat.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
end

-----------------------------------------------------------------------------------------------
-- ReStrat OnDocLoaded
-----------------------------------------------------------------------------------------------
function ReStrat:OnDocLoaded()

	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	    self.wndAlerts = Apollo.LoadForm(self.xmlDoc, "alertForm", nil, self);
		self.wndPop = Apollo.LoadForm(self.xmlDoc, "popForm", nil, self);

		
	    self.wndAlerts:Show(true, true)
		
		-- Register handlers for events, slash commands and timer, etc.
		Apollo.RegisterSlashCommand("restrat", "OnReStratOn", self)
		Apollo.RegisterEventHandler("UnitCreated", "OnUnitCreated", self)
		Apollo.RegisterEventHandler("UnitDestroyed", "OnUnitDestroyed", self)
		Apollo.RegisterEventHandler("UnitEnteredCombat", "OnEnteredCombat", self)
		
		--Color library, can't be stored in constants
		self.color = {
			red = "ffb8413d",
			orange = "ffdd7649",
			yellow = "fff8fd6b",
			green = "ff58cc5d",
			blue = "ff5196ec",
			purple = "ff915fc2",
			black = "black",
			white = "white",
		}
		
		--This timer drives UI events exclusively, in game checks are fired on a seperate timer
		self.alertTimer = ApolloTimer.Create(0.01, true, "OnAlarmTick", self);
		
		--This timer drives in game logging and event handling
		self.gameTimer = ApolloTimer.Create(0.1, true, "OnGameTick", self);

		-- Do additional Addon initialization here
		self.tAlerts = {}
		self.tUnits = {}
		self.bInCombat = false;
		
		
		if not self.tEncounters then
			self.tEncounters = {}
		end
		
		self.bLoaded = true;
	end
end

-----------------------------------------------------------------------------------------------
-- ReStrat Functions
-----------------------------------------------------------------------------------------------
--On alarm tick
function ReStrat:OnAlarmTick()

	--This counts down all alarms registered to self.tAlerts
	for i,v in ipairs(self.tAlerts) do
		if self.tAlerts[i].alert then
			local alertInstance = self.tAlerts[i];
			local timer = alertInstance.alert:FindChild("ProgressBarContainer"):FindChild("timeLeft");
			local pBar = alertInstance.alert:FindChild("ProgressBarContainer"):FindChild("progressBar");
			
			--Set timer
			alertInstance.currDuration = alertInstance.currDuration-0.01;
			
			--Update time and bar
			if alertInstance.currDuration >= -0.01 then
				timer:SetText(tostring(round(alertInstance.currDuration, 1)) .. "S");
				pBar:SetProgress(alertInstance.currDuration);
			else
				
				--Close bar
				alertInstance.alert:Close();
				
				--Execute callback
				if alertInstance.callback then
					alertInstance.callback()
				end
				
				--Remove from table
				table.remove(self.tAlerts, i);
				
				--Reshuffle windows
				self:arrangeAlerts();
			end
						
		end
	end
end

--When units are created by the game
function ReStrat:OnUnitCreated(unit)
	--Check if we have the unit in our library
	for i,v in ipairs(self.tUnits) do
		if self.tUnits[i].unit == unit then
			self.unitExists = true;
			return
		else
			self.unitExists = false;
		end
	end
	
	--If not then we add it
	if not self.unitExists then
		self.tUnits[#self.tUnits+1]  = {
				unit = unit,
				name = unit:GetName(),
				id = unit:GetId(),
				health = unit:GetMaxHealth(),
				shield = unit:GetShieldCapacityMax(),
				baseIA = unit:GetInterruptArmorMax(),
				bActive = true
		}
	end
end

function ReStrat:OnUnitDestroyed(unit)
	--Check if unit exists in our library
	for i,v in ipairs(self.tUnits) do
		if self.tUnits[i].id == unit:GetId() then
			--Since the unit has been destroyed we set it to non active and remove unit reference
			self.tUnits[i].bActive = false;
			self.tUnits[i].unit = nil;
			
			return
		end
	end
end

function ReStrat:OnEnteredCombat(unit, combat)
	--Is it the player?
	if GameLib.GetPlayerUnit() then
		if unit == GameLib.GetPlayerUnit() then
			if combat then
				self.bInCombat = true;
				return
			else
				self.bInCombat = false;
				return
			end
		end
	end
	
	--Is it a unit in our encounter library?
	if combat then
		for i,v in ipairs(self.tUnits) do
			if self.tEncounters[self.tUnits[i].name] then
				--We're entering combat with an encounter
				--Initiate pull function
				self.tEncounters[self.tUnits[i].name].fInitFunction();
				
				return
			end
		end
	end
end

--[TODO] make this a lot more customizable
function ReStrat:arrangeAlerts()
	for i,v in ipairs(self.tAlerts) do
		local wndHeight = self.tAlerts[i].alert:GetHeight();
		local spacing = 9;
		local vOffset = wndHeight*(i-1) + spacing*(i-1);
		
		self.tAlerts[i].alert:SetAnchorOffsets(0,vOffset,0,vOffset+wndHeight);
	end
end

--Generate alert
function ReStrat:createAlert(strLabel, duration, strIcon, strColor, fCallback)
	local alertBar = Apollo.LoadForm("ReStrat.xml", "alertInstance", self.wndAlerts, self);
	
	--Set bar label
	alertBar:FindChild("ProgressBarContainer"):FindChild("spellName"):SetText(strLabel);
	
	--Set max for pBar
	alertBar:FindChild("ProgressBarContainer"):FindChild("progressBar"):SetMax(duration);
	
	--Handle optional color
	if not strColor then
		alertBar:FindChild("ProgressBarContainer"):FindChild("progressBar"):SetBarColor(self.color.red);
	else
		alertBar:FindChild("ProgressBarContainer"):FindChild("progressBar"):SetBarColor(strColor);
	end
	
	--Handle optional icon
	if not strIcon then
		alertBar:FindChild("IconContainer"):Close();
	else
		alertBar:FindChild("IconContainer"):FindChild("Icon"):SetSprite(strIcon);
	end
	
	--Handle callback function
	if not fCallback then
		fCallback = nil
	end
	
	--Add to tAlerts
	self.tAlerts[#self.tAlerts+1] = {alert = alertBar, callback = fCallback, currDuration = duration, maxDuration = duration}
	
	--Arrange vertically
	self:arrangeAlerts();
end


--/restrat
function ReStrat:OnReStratOn()
	--self.wndMain:Invoke() -- show the window
	self:createAlert("Entered Combat", 3, nil, nil, nil)
	self:createAlert("Big Bad Casterino", 6, nil, self.color.purple, nil)
	self:createAlert("Next Phase", 8, nil, self.color.green, nil)
end


function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

-----------------------------------------------------------------------------------------------
-- ReStrat Instance
-----------------------------------------------------------------------------------------------
local ReStratInst = ReStrat:new()
ReStratInst:Init()
_G["ReStrat"] = ReStratInst
