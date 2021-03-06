; stahky
; by joedf - 2020.07.10
;
; inspried from Stacky (by Pawel Turlejski)
; https://github.com/pawelt/stacky
; https://web.archive.org/web/20130927190146/http://justafewlines.com/2013/04/stacky/

;@Ahk2Exe-SetMainIcon res\app.ico

#NoTrayIcon
#SingleInstance, Force

#Include lib\utils.ahk

; uses PUM by Deo
#Include lib\PUM_API.ahk
#Include lib\PUM.ahk

APP_NAME := "stahky"
APP_VERSION := "0.1.00.01"
APP_REVISION := "2020/07/13"

STAHKY_EXT := APP_NAME . ".lnk"
G_STAHKY_ARG := "/stahky"
StahkyConfigFile := A_ScriptDir "\" APP_NAME ".ini"

; AutoHotkey behavioural settings needed
GroupAdd APP_Self_WinGroup, ahk_id %A_ScriptHwnd%
GroupAdd APP_Self_WinGroup, % "ahk_pid " DllCall("GetCurrentProcessId")
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
MouseGetPos, mx, my

; Smart auto-create *lnk pinnable shortcut file, when folder dragged-on-top of this app
if ( (A_Args[1] != G_STAHKY_ARG) && (FileExist(A_Args[1])) )
{
	FileGetAttrib,_t, % A_Args[1]
	if InStr(_t,"D") {
		makeStahkyFile(A_Args[1])
	}
}

; check for first run, if we want to show the intro dialog
G_FirstRun_Trigger := false
if !FileExist(StahkyConfigFile)
	FirstRun_Trigger()

; get search path
searchPath := A_WorkingDir . "\*"
; use the Stahky file's path if available
if ( (A_Args[1] == G_STAHKY_ARG) && (FileExist(A_Args[2])) )
{
	FileGetAttrib,_t, % A_Args[2]
	if InStr(_t,"D") {
		searchPath := A_Args[2] . "\*"
	}
}

; get automatic colors
PixelGetColor, TaskbarColor, 0, % A_ScreenHeight - 1
TaskbarSColor := lightenColor(TaskbarColor)

; get/update settings
getSettingsOrDefaults(StahkyConfigFile)
updateConfigFile(StahkyConfigFile)

; update value for High DPI display
DPIScaleRatio := 1
if (useDPIScaleRatio) {
	DPIScaleRatio := (A_ScreenDPI / 96)
	icoSize *= DPIScaleRatio
	menuTextMargin *= DPIScaleRatio
	menuMarginX *= DPIScaleRatio
	menuMarginY *= DPIScaleRatio
}

; parameters of the PUM object, the manager of the menus
pumParams := {"SelMethod" : "fill" ;item selection method, may be frame,fill
	,"selTColor"   : stextColor    ;selection text color
	,"selBGColor"  : sbgColor      ;selection background color, -1 means invert current color
	,"oninit"      : "PUM_out"     ;function which will be called when any menu going to be opened
	,"onuninit"    : "PUM_out"     ;function which will be called when any menu going to be closing
	,"onselect"    : "PUM_out"     ;function which will be called when any item selected with mouse (hovered)
	,"onrbutton"   : "PUM_out"     ;function which will be called when any item right clicked
	,"onmbutton"   : "PUM_out"     ;function which will be called when any item clicked with middle mouse button
	,"onrun"       : "PUM_out"     ;function which will be called when any item clicked with left mouse button
	,"onshow"      : "PUM_out"     ;function which will be called before any menu shown using Show method
	,"onclose"     : "Pum_out"     ;function called just before quitting from Show method
	,mnemonicCMD   : "select"}

; PUM_Menu parameters
menuParams := {"bgcolor" : bgColor ;background color of the menu
	, "iconssize" : icoSize        ;size of icons in the menu
	, "tcolor"    : textColor      ;text color of the menu items
	, "textMargin": menuTextMargin
	, "xmargin"   : menuMarginX
	, "ymargin"   : menuMarginY }

; create an instance of PUM object, it is best to have only one of such in the program
pm := new PUM( pumParams )
; creating popup menu, represented by PUM_Menu object with given parameters
menu := pm.CreateMenu( menuParams )

; Populate Stahkys!
MakeStahkyMenu(menu, searchPath, pm, menuParams )

; Calculate postion of the menu near the Taskbar
SysGet m, MonitorWorkArea, 1
mpy := mBottom
menuWidth := menuTextMargin + icoSize + (2.5*menuMarginX)
mpx := mx - ( menuWidth//DPIScaleRatio )

; Display the PUM menu
item := menu.Show( mpx+offsetX, mpy+offsetY )

; Destroy everything PUM on program end
pm.Destroy()

; First Run triggered - don't auto-exit
if (!G_FirstRun_Trigger)
	ExitApp
return

; PUM's right-click / rbutton handler is not reliable
; do some extra handling here
; https://autohotkey.com/board/topic/94970-ifwinactive-reference-running-autohotkey-window/#entry598885
;
; No need for #If since the app only runs if we have a menu or a window shown
;#IfWinExist ahk_group APP_Self_WinGroup
+#a::
~$*RButton::
	FirstRun_Trigger()
return
;#IfWinExist

PUM_out( msg, obj ) {

	; run item normally
	if (msg == "onrun")
	{
		Run % obj.path
	}
	
	; On MButton, open the folder if we have a stahky
	if (msg == "onmbutton") {
		if (_p:=isStahkyFile(obj.path)) {
			if FileExist(_p)
				Run % _p
		}
	}
	
	; On RButton, open the about/firsttime use dialog
	if (msg == "onrbutton") {
		FirstRun_Trigger()
	}
}