#Todo

Everything in _bold_ has been finished, otherwise is still being worked on. Any code is 

##Interface
- Mockup
- Assets
    - Graphics
    - Audio
- Importing to Game

##Code
###Profile Development Functionality
####Unit Casts
These functions will all handle casts, currently we have no event on iniation of a cast so these are intensive. Only operable on target, player, focus, or encounter units.

#####createCastAlert("strUnit", "strCast", [duration], ["strIcon"], [fCallback]);
Automatically creates an alert on cast for the indicated unit. If a callback is indicated it will be executed when the alert ends.  
#####isCasting("strUnit", "strCast")
Return whether or not the indicated cast is active on the indicated unit.
#####getCast("strUnit", "strCast")
Returns the length of a cast as indicated by the game.

####Buffs or Debuffs
These functions handle auras on the player, their target, their focus, or an encounter unit.

#####createAuraAlert("strUnit", "strAuraName", [duration], [icon], [fCallback])
Automatically creates an alert when the indicated aura is applied to the specified unit. If a callback is indicated it will be executed when the alert ends.

####Alert notifications
These functions handle generic alert creation. Alerts can traditionally be thought of as timers.

#####createAlert("strAlertLabel", duration, ["strIcon"], [fCallback])
Creates an alert with the indicated label, duration, and icon. If a callback is indicated it will be executed when the alert ends.
#####broadcastAlert("strAlert", [fCallback])
Broadcasts the alert in the party channel.
#####syncAlert("strAlertLabel", duration, ["strIcon"], [fCallback])
Syncs an alert to everyone in your party using reStrat, this is heplful for players "out of range."

####Pop notifications
These functions handle "pops", these are brief text notifications accompanied by a sound.

#####createPop("strPop", [fCallback])
Creates a pop with the indicated string. If a callback is indicated it will be executed when the alert ends.
#####createCastPop("strPop", "strUnit", "strCast", [fCallback])
Creates a  pop when the specified cast starts from the specified unit. If a callback is indicated it will be executed when the alert ends.
#####createAuraPop("strPop", "strUnit", "strAura", [fCallback])
Creates a pop when the specified unit gains the specified aura. If a callback is indicated it will be executed when the alert ends.


