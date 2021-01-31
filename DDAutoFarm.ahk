#Include Gdip_All.ahk
#Include CustomTooltip.ahk
#IfWinExist, ahk_exe DunDefGame.exe
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, Pixel, Window
SetKeyDelay, 200, 10 

; DONT edit these
global AUTO_START := false
global AUTO_RESTART := false
global VICTORIES := 0
global GAME_OVERS := 0
global WAVE_NUMBER := 0
global CURRENT_MAP_INDEX := 1

; Edit these
global COORDINATES := {pixelColorX: 2450, pixelColorY: 160, replayButtonX: 2300, replayButtonY: 1250}
global PHASE_COLORS := {build: 4284322771, victory: 4285333125, gameOver: 4282663742, stuck: 4278847751}
global CHECK_INTERVAL_MS := 3000
global MONK_BOOST_HOTKEY := 3
global SUMMONER_BOOST_HOTKEY := 1
global MAPS 
:= [{   mapName: "No Towers Allowed"
      , loadTimeMS: 2500
      , startWave: 1
      , lastWave: 8
      , restartOnWave: 999
      , useMonkBoost: true
      , useSummonerBoost: false
      , monks: ["{F3}", "{F4}"]
      , summoners: ["{F2}", "{F5}"]
      , startBoostingOnWave: 4
      , afterWaveStartBoostWaitSec: 14
      , afterOtherBoosterBoostWaitSec: 23}  
,   {   mapName: "Alchemical Laboratory"
      , loadTimeMS: 3000
      , startWave: 3
      , lastWave: 7
      , restartOnWave: 5
      , useMonkBoost: true
      , useSummonerBoost: true
      , monks: ["{F3}", "{F4}"]
      , summoners: ["{F2}"]
      , startBoostingOnWave: 4
      , afterWaveStartBoostWaitSec: 14
      , afterOtherBoosterBoostWaitSec: 30}]

; Change Map
^NumpadAdd::
	if (++CURRENT_MAP_INDEX > MAPS.MaxIndex())
		CURRENT_MAP_INDEX := 1
	ShowTooltip("Map set to: " MAPS[CURRENT_MAP_INDEX].mapName)
return

; Change Map
^NumpadSub::
	if (--CURRENT_MAP_INDEX < 1)
		CURRENT_MAP_INDEX := MAPS.MaxIndex()
	ShowTooltip("Map set to: " MAPS[CURRENT_MAP_INDEX].mapName)
return

; Debug
^Numpad0::
	ControlGet, DDId, Hwnd,,, ahk_exe DunDefGame.exe
    MouseGetPos, mouseX, mouseY
	pixelColors := GetPixelColor(DDId, {x: COORDINATES.pixelColorX, y: COORDINATES.pixelColorY}, {x: mouseX, y: mouseY})
	s := "% win: " (100 - GAME_OVERS/VICTORIES * 100) "`nLast Wave: " LAST_WAVE "`nCurrent Wave: " WAVE_NUMBER "`nPixelColor: " pixelColors[1]
    s .= "`nMouse pos: " mouseX ", " mouseY "`nMouse Color: " pixelColors[2]
	MsgBox, , Debug Info, %s%
return

; Generic auto g in every build phase
^NumpadDot::
	AUTO_START := !AUTO_START
	AUTO_RESTART := false
	WAVE_NUMBER := MAPS[CURRENT_MAP_INDEX].startWave - 1
	ShowTooltip("Auto Start " (AUTO_START ? "Enabled" : "Disabled"), 18, (AUTO_START ? "Green" : "Red"), "White")
	SetTimer, Main, -1
return

; Auto g + restart map at the end
^NumpadEnter::
    AUTO_RESTART := !AUTO_RESTART
    AUTO_START := AUTO_RESTART
	WAVE_NUMBER := MAPS[CURRENT_MAP_INDEX].startWave - 1
	ShowTooltip("Auto Farming " (AUTO_RESTART ? "Enabled" : "Disabled"), 18, (AUTO_RESTART ? "Green" : "Red"), "White")
	SetTimer, Main, -1
return

Main:
	while (AUTO_START)
    {
		Sleep %CHECK_INTERVAL_MS%
		ControlGet, DDId, Hwnd,,, ahk_exe DunDefGame.exe
		pixelColors := GetPixelColor(DDId, {x: COORDINATES.pixelColorX, y: COORDINATES.pixelColorY})
		if (pixelColors[1] = PHASE_COLORS.build && AUTO_START) ; Build Phase
			StartRound()
		else if (pixelColors[1] = PHASE_COLORS.victory && AUTO_RESTART) ; Victory -> Restart
			Restart()
		else if (pixelColors[1] = PHASE_COLORS.gameOver && AUTO_RESTART) ; Game Over -> Replay
			Restart(false)
		else if (pixelColors[1] = PHASE_COLORS.stuck && AUTO_RESTART) ; Stuck
			ControlSend, , {Esc}, ahk_exe DunDefGame.exe
	}
return

ActivateMonkBoost:
	nextBooster := MAPS[CURRENT_MAP_INDEX].monks.pop()
	MAPS[CURRENT_MAP_INDEX].monks.InsertAt(1, nextBooster)
	ControlSend, , %nextBooster%{Space}%MONK_BOOST_HOTKEY%{F2}, ahk_exe DunDefGame.exe
    if (WAVE_NUMBER = MAPS[CURRENT_MAP_INDEX].lastWave) {
        ms := MAPS[CURRENT_MAP_INDEX].afterOtherBoosterBoostWaitSec * -1000
        SetTimer, ActivateMonkBoost, %ms%
    }
return

ActivateSummonerBoost:
	nextBooster := MAPS[CURRENT_MAP_INDEX].summoners.pop()
	MAPS[CURRENT_MAP_INDEX].summoners.InsertAt(1, nextBooster)
	ControlSend, , %nextBooster%{Space}%SUMMONER_BOOST_HOTKEY%{F2}, ahk_exe DunDefGame.exe
    if (WAVE_NUMBER = MAPS[CURRENT_MAP_INDEX].lastWave) {
        ms := MAPS[CURRENT_MAP_INDEX].afterOtherBoosterBoostWaitSec * -1000
        SetTimer, ActivateSummonerBoost, %ms%
    }
return

StartRound() {
    if (AUTO_RESTART && ++WAVE_NUMBER >= MAPS[CURRENT_MAP_INDEX].restartOnWave) {
        Restart()
        return
    }

    ms := MAPS[CURRENT_MAP_INDEX].afterWaveStartBoostWaitSec * -1000
	if (AUTO_RESTART && MAPS[CURRENT_MAP_INDEX].useMonkBoost && WAVE_NUMBER >= MAPS[CURRENT_MAP_INDEX].startBoostingOnWave) {
        SetTimer, ActivateMonkBoost, %ms%
	}

	if (AUTO_RESTART && MAPS[CURRENT_MAP_INDEX].useSummonerBoost && WAVE_NUMBER >= MAPS[CURRENT_MAP_INDEX].startBoostingOnWave) {
        SetTimer, ActivateSummonerBoost, %ms%
	}
	
	ControlSend, , {F2}g, ahk_exe DunDefGame.exe
	Sleep 5000 ; Wait for the ready animation to complete
}

Restart(victory := true) {
	WAVE_NUMBER := MAPS[CURRENT_MAP_INDEX].startWave - 1
	ShowTooltip("Restarting in 3 sec...", 18, "Yellow")
	SoundBeep, , 500
	Sleep 2500
	MouseGetPos, x, y ; Save mouse position

	if (victory) {
		VICTORIES++
		ControlSend, , {F2}{Esc}{Down}{Left}{Space}{Space}, ahk_exe DunDefGame.exe ; Esc -> Restart -> Yes
	} else {
		GAME_OVERS++
		WinActivate, ahk_exe DunDefGame.exe
		Sleep 300
		MouseMove, COORDINATES.replayButtonX, COORDINATES.replayButtonY
		MouseMove, COORDINATES.replayButtonX, COORDINATES.replayButtonY ; Needed for multiple display setups
        Sleep 300
		ControlSend, , {Space}{Space}, ahk_exe DunDefGame.exe ; Replay -> Yes
	}
	
	loadTime := MAPS[CURRENT_MAP_INDEX].loadTimeMS
	Sleep %loadTime%
	ControlSend, , {Esc}, ahk_exe DunDefGame.exe ; Skip intro
	MouseMove, x, y ; Reset mouse position
}

; Gets the pixel's color in x,y coordinates of <WinId> Window which cannot be minimized
GetPixelColor(WinId, coords*) {
    token := Gdip_Startup()
	bitmap := Gdip_BitmapFromHWND(WinId)
    pixelColors := []
    for i, coord in coords {
        pixelColors.Push(Gdip_GetPixel(bitmap, coord.x, coord.y))
    }
	Gdip_DisposeImage(bitmap)
    Gdip_Shutdown(token)
	return pixelColors
}

RemoveToolTip:
    Tooltip
return

ShowTooltip(string, fontSize := 12, backgroundColor := "White", fontColor := "Black", tooltipHideMS := 3000) {
	ToolTipFont(("s" fontSize), "Calibri")
	ToolTipColor(backgroundColor, fontColor)
    Tooltip, %string%
	SetTimer, RemoveTooltip, -%tooltipHideMS%
}

SetKeyDelay, 0, 10, Play
^1::
    SendInput, 1{Space}
return

^2::
    SendInput, 2{Space}
return

^3::
    SendInput, 3{Space}
return
