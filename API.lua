-- DPSLight API Documentation
-- This file serves as reference for IDE autocompletion and IntelliSense
-- @author DPSLight Development Team
-- @version 1.1.1

---@class DPSLight_MainFrame
---@field Create fun():Frame Creates the main DPSLight window
---@field GetFrame fun():Frame Returns the main frame instance
---@field UpdateDisplay fun() Updates the display with current data
---@field ReloadSettings fun() Reloads settings from database into module variables
---@field ShowConfigMenu fun() Opens the configuration menu
---@field SetMode fun(mode:string) Sets display mode ("damage", "healing", "deaths", "dispels", "decurse")
---@field ToggleDPS fun() Toggles between DPS and Total display
---@field UpdateFooter fun() Updates footer information (combat timer, FPS, latency, memory)
DPSLight_MainFrame = {}

---@class DPSLight_Database
---@field Initialize fun() Initializes the database with default settings
---@field GetSetting fun(key:string):any Gets a setting value (returns nil if not set)
---@field SetSetting fun(key:string, value:any) Sets a setting value and saves to disk
---@field SaveCombatSegment fun(name:string, duration:number, damageData:table, healingData:table) Saves combat history
---@field UpdateRecords fun(dps:number, hps:number, playerName:string, duration:number) Updates personal records
---@field GetHistory fun():table Returns combat history
---@field GetRecords fun():table Returns personal records
---@field ResetAllSettings fun() Resets all settings to defaults
---@field SaveToDisk fun() Forces save to disk
DPSLight_Database = {}

---@class DPSLight_DataStore
---@field GetUserID fun(username:string):number Gets or creates user ID for username
---@field GetUsername fun(userID:number):string Gets username from user ID
---@field GetAbilityID fun(abilityName:string):number Gets or creates ability ID
---@field GetAbilityName fun(abilityID:number):string Gets ability name from ID
---@field AddDamage fun(username:string, targetName:string, abilityName:string, amount:number, isCrit:boolean, damageType:string) Records damage event
---@field AddHealing fun(username:string, targetName:string, abilityName:string, amount:number, overhealing:number, isCrit:boolean) Records healing event
---@field AddDeath fun(username:string, timestamp:number, killer:string, killerAbility:string) Records death event
---@field GetDamageData fun(segment:string, userID:number):table Gets damage data for segment/user
---@field GetHealingData fun(segment:string, userID:number):table Gets healing data
---@field GetTotalDamage fun(segment:string, userID:number):number Gets total damage for user
---@field GetTotalHealing fun(segment:string, userID:number):number Gets total healing for user
---@field GetSortedDamage fun(segment:string):table Gets sorted damage leaderboard
---@field GetSortedHealing fun(segment:string):table Gets sorted healing leaderboard
---@field NewSegment fun():string Creates new combat segment
---@field GetCurrentSegment fun():string Returns current segment ID
---@field StartCombat fun() Marks combat start
---@field EndCombat fun() Marks combat end
---@field Reset fun() Resets all stored data
DPSLight_DataStore = {}

---@class DPSLight_Utils
---@field GetPlayerClass fun(name:string):string Returns player class
---@field GetClassColor fun(class:string):table Returns class color RGB
---@field FormatNumber fun(num:number):string Formats number with K/M suffix
---@field GetCombatDuration fun():number Returns combat duration in seconds
---@field IsPlayerInGroup fun(name:string):boolean Checks if player is in group
---@field IsPlayerInRaid fun(name:string):boolean Checks if player is in raid
DPSLight_Utils = {}

---@class DPSLight_Config
---@field COLORS table Color definitions
---@field CLASSES table Class definitions
---@field MAX_PLAYERS number Maximum players to track
---@field UPDATE_INTERVAL number Display update interval
---@field DEFAULT_SETTINGS table Default configuration values
DPSLight_Config = {}

---@class DPSLight_MainMenu
---@field Create fun():Frame Creates the configuration menu
---@field Show fun() Shows the menu
---@field Hide fun() Hides the menu
---@field Toggle fun() Toggles menu visibility
DPSLight_MainMenu = {}

---@class DPSLight_VirtualScroll
---@field Create fun(parent:Frame, width:number, height:number, rowHeight:number):table Creates virtual scroll list
---@field SetData fun(data:table) Sets the data to display
---@field Update fun() Updates the display
---@field Refresh fun() Refreshes without rebuilding
DPSLight_VirtualScroll = {}

---@class DPSLight_ObjectPool
---@field GetTable fun(estimatedSize:number):table Gets a pooled table
---@field ReleaseTable fun(t:table, poolType:string) Returns table to pool
---@field GetCachedString fun(str:string):string Gets cached string reference
---@field Reset fun() Resets all pools
DPSLight_ObjectPool = {}

---@class DPSLight_EventEngine
---@field RegisterEvent fun(eventName:string, handler:function, priority:number) Registers event handler
---@field UnregisterEvent fun(eventName:string, handler:function) Unregisters event handler
---@field TriggerEvent fun(eventName:string, ...:any) Manually triggers event
---@field Suspend fun() Suspends event processing
---@field Resume fun() Resumes event processing
DPSLight_EventEngine = {}

---@class DPSLight_AdvancedStats
---@field RecordDamage fun(playerName:string, amount:number, timestamp:number) Records damage for burst calculations
---@field CalculateBurstDPS fun(playerName:string):number Calculates burst DPS
---@field GetBurstDPS fun(playerName:string):number Returns cached burst DPS
---@field GetActivityPercent fun(playerName:string, totalDuration:number):number Returns activity percentage
---@field Reset fun() Resets all statistics
DPSLight_AdvancedStats = {}

---@class Frame
---@field SetPoint fun(point:string, relativeTo:Frame, relativePoint:string, x:number, y:number)
---@field SetSize fun(width:number, height:number)
---@field SetBackdrop fun(backdrop:table)
---@field SetBackdropColor fun(r:number, g:number, b:number, a:number)
---@field SetBackdropBorderColor fun(r:number, g:number, b:number, a:number)
---@field Show fun()
---@field Hide fun()
---@field SetScript fun(event:string, handler:function)
---@field CreateFontString fun(name:string, layer:string, template:string):FontString
---@field SetMovable fun(movable:boolean)
---@field SetResizable fun(resizable:boolean)
---@field SetMinResize fun(width:number, height:number)
---@field SetMaxResize fun(width:number, height:number)
---@field EnableMouse fun(enable:boolean)
---@field SetClampedToScreen fun(clamped:boolean)

---@class FontString
---@field SetText fun(text:string)
---@field GetText fun():string
---@field SetPoint fun(point:string, relativeTo:Frame, relativePoint:string, x:number, y:number)
---@field SetTextColor fun(r:number, g:number, b:number, a:number)
---@field SetFont fun(font:string, size:number, flags:string)

---@class CheckButton : Frame
---@field SetChecked fun(checked:boolean)
---@field GetChecked fun():boolean

---@class Button : Frame
---@field SetNormalTexture fun(texture:string)
---@field SetHighlightTexture fun(texture:string, mode:string)
---@field SetPushedTexture fun(texture:string)

---@class Slider : Frame
---@field SetMinMaxValues fun(min:number, max:number)
---@field SetValue fun(value:number)
---@field GetValue fun():number
---@field SetValueStep fun(step:number)

-- WoW API Functions
---@param frameType string
---@param name string|nil
---@param parent Frame|nil
---@param template string|nil
---@return Frame
function CreateFrame(frameType, name, parent, template) end

---@return number
function GetTime() end

---@return number
function GetFramerate() end

---@return number, number, number
function GetNetStats() end

---@return number
function gcinfo() end

---@param name string
---@return any
function getglobal(name) end

---@param name string
---@param value any
function setglobal(name, value) end

---@param unit string
---@return string
function UnitName(unit) end

---@param unit string
---@return string
function UnitClass(unit) end

---@param unit string
---@return boolean
function UnitExists(unit) end

---@param unit string
---@return boolean
function UnitIsPlayer(unit) end

---@param unit string
---@return boolean
function UnitInParty(unit) end

---@param unit string
---@return boolean
function UnitInRaid(unit) end

---@return number
function GetNumPartyMembers() end

---@return number
function GetNumRaidMembers() end

---@return boolean
function IsInRaid() end
