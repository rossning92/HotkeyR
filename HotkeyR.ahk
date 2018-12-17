#SingleInstance, Force
#NoTrayIcon


#include <Optimize>
#include <SerDes>
#include <RunAsAdmin>

#include <_HtmlWindow>
#include <_ShellRunEx>
#include <_GetWindowList>
#include <_GetWindowIcon>



RunAsAdmin()




; Thread, interrupt, 0  ; IMPORTANT: Make all threads always-interruptible



Suspend On  ; Disable all hotkeys by default


SetWorkingDir %A_ScriptDir%
SetCapsLockState, AlwaysOff


BEEP_FILE = %A_ScriptDir%\Resources\Beep.wav
APP_NAME = HotkeyR
TEMP_FOLDER = %A_Temp%\HotkeyR




FileCreateDir % TEMP_FOLDER
FileDelete %TEMP_FOLDER%\*.ico


; msgbox % TEMP_FOLDER


g_lastActivatedHwnd := {}
g_hotkeyProgramMap := {}
g_keyList := "a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 space"
g_iconCache := {}

loadConfig()


; If the script is run with 1 parameter
if 0 = 1
{
	path = %1%
	InputBox, htk, Please input a hotkey:
	if ErrorLevel <> 0
        return
}



onNewHotkeyTriggered()
{
    global INI_FILE

    htk := "#" SubStr(A_ThisHotkey, StrLen(A_ThisHotkey), 1)
    
    WinGet, exePath, ProcessPath, A
    MsgBox, 4, , Set %htk% = %exePath% ?
    IfMsgBox Yes
    {
        IniWrite, %exePath%, %INI_FILE%, Hotkey, %htk%
        Run % A_ScriptFullPath
    }
}



for i, v in g_config
{
    keyList := v.hotkey
    
    StringLower, keyList, keyList
    keyList := StrSplit(keyList, "+")
    
    key =
    htkInfo := {index: i, modifiers: []}
    for i, v in keyList {

        if (v = "shift" || v = "ctrl" || v = "alt") {
            htkInfo.modifiers.Push(v)
        } else {
            key := v
        }
    }
    
    g_hotkeyProgramMap[key] := htkInfo
}



; Setup hotkeys
Loop, Parse, g_keyList, %A_Tab%%A_Space%
{
    keyName := A_LoopField
    StringLower, keyName, keyName
    
    Hotkey, *$%keyName%, onKeyPressed
}



onKeyPressed()
{
    global g_lastActivatedHwnd
    global g_winList
    global g_hotkeyProgramMap
    global g_lastKeyPressed
    
    
    ; Get current pressed key name
    keyName := A_ThisHotkey
    StringReplace, keyName, keyName, $
    StringReplace, keyName, keyName, *
    StringReplace, keyName, keyName, ~
        
    
    if not GetKeyState("CapsLock", "P") ; Get physical state
    {
        SendEvent {Blind}{%keyName%}
        return
    }
    
    htkInfo := g_hotkeyProgramMap[keyName]
    if (htkInfo) {
    
        ; Check modifiers
        matchModifiers := True
        for i, v in htkInfo.modifiers {
            matchModifiers := matchModifiers && GetKeyState(v)
        }

        if (matchModifiers) {
            Run(htkInfo.index)
            return
        }
    }
    
    g_lastKeyPressed := keyName
    lastActivatedHwnd := g_lastActivatedHwnd[keyName]
    
        
    ; Skip current window
    WinGet, curHwnd, ID, A ; Get hwnd of active window
    if (lastActivatedHwnd
        and WinExist("ahk_id " lastActivatedHwnd)
        and lastActivatedHwnd <> curHwnd)
    {
        activateWnd(lastActivatedHwnd)
    }
    else
    {
        ; Find index of last activated window
        i := 0
        if (lastActivatedHwnd)
        {
            for j, v in g_winList
            {
                if (lastActivatedHwnd = v.hwnd)
                {
                    i := j
                    break
                }
            }
        }
        
        
        ; Activate next window for current hotkey
        loop % g_winList.Length()
        {
            ; Go to next window
            i := Mod(i, g_winList.Length()) + 1
            v := g_winList[i]
            
            ; ToolTip % i
        
            if ( SubStr(v.processName, 1, 1) = keyName
                and WinExist("ahk_id " v.hwnd) )
            {
                activateWnd(v.hwnd)   
                g_lastActivatedHwnd[keyName] := v.hwnd
                break
            }
        }
    }
   
}




; Play beep sound
SoundPlay %BEEP_FILE%
return







~LButton & WheelUp::
Suspend, Permit
SoundSet +10
SoundPlay %BEEP_FILE%
return



~LButton & WheelDown::
Suspend, Permit
SoundSet -10
SoundPlay %BEEP_FILE%
return



#F4::
Suspend, Permit
WinGet, pid, PID, A
Process, Close, %pid%
SoundPlay %BEEP_FILE%
return



Run(index)
{
    global BEEP_FILE
    global g_config
    
    
    ; Activate by window title
    winTitle := g_config[index].winTitle
    if (winTitle and activateWindowByTitle(winTitle))
        return
    
    
    ; Activate by image name
    exePath := g_config[index].exePath
	SplitPath, exePath, fileName, workingDir, , , drive
	if activateWindowByTitle("ahk_exe " fileName)
        return
    
    ; Absolute working dir
    if RegExMatch(workingDir, "^\\?[^\/:*?""<>|\r\n%]+\\?$")
        workingDir = %A_ScriptDir%\%workingDir%
    
    
    ShellRunEx(exePath, workingDir)
    
    
    SoundPlay %BEEP_FILE%
}

activateWindowByTitle(winTitle)
{
    reason =

	WinGet, hwnds, List, %winTitle%
    
    
    
	loop % hwnds
	{
		hwnd := hwnds%A_Index%
		
		winGet, style, Style, ahk_id %hwnd%

		; Skip unimportant window
		if (style & WS_DISABLED) 
			continue
			
		; Skip window with no title
		winGetTitle, winTitle, ahk_id %hwnd%
		if (!winTitle)
			continue
		
        ; Skip active window
        if (WinActive("ahk_id " hwnd))
        {
            reason := "ACTIVATED"
            continue
        }

		winActivate ahk_id %hwnd%
		; winMaximize ahk_id %hwnd%
        
        return "SUCCESS"
	}
    
    return reason
}

getCfgFileName()
{
    SplitPath, A_ScriptName, , , , configFile
    configFile := A_ScriptDir . "\" . configFile . ".json"
    return configFile
}

saveConfig()
{
	global g_config
	configFile := getCfgFileName()
	SerDes(g_config, configFile, "`t")
}

loadConfig()
{
	global g_config
	configFile := getCfgFileName()
	FileRead, json, %configFile%
	g_config := SerDes(json)
}

toggleTop(hwnd)
{
    global g_webBrowser

    w := g_webBrowser.document.parentWindow

    WinGet, ExStyle, ExStyle, ahk_id %hwnd%
    if (ExStyle & 0x8) {  ; 0x8 is WS_EX_TOPMOST
        WinSet, AlwaysOnTop, Off, ahk_id %hwnd%

        w.jQuery("#tr_" hwnd " .topmost-btn").removeClass("red lighten-2").addClass("grey lighten-3")
    } else {
        WinSet, AlwaysOnTop, On, ahk_id %hwnd%

        w.jQuery("#tr_" hwnd " .topmost-btn").removeClass("grey lighten-3").addClass("red lighten-2")
    }
}

activateWnd(hwnd)
{
    WinActivate, ahk_id %hwnd%
    updateUI(hwnd)
}

onWindowSelected(hwnd)
{
    global g_lastKeyPressed

    g_lastKeyPressed = 
    
    activateWnd(hwnd)
}

updateUI(hwnd) {
    
    global g_webBrowser
    global g_lastKeyPressed
    global g_winList

    ; Remove active window class name from previous active window
    trList := g_webBrowser.document.getElementsByTagName("tr")
    Loop, % trList.length {
        trList[A_Index-1].className := ""
    }
    
    
    if (g_lastKeyPressed) {
        ; Highlight specified key
        for i, v in g_winList
        {
            ; If the window starts with keyName
            if (SubStr(v.processName, 1, 1) = g_lastKeyPressed) {
                g_webBrowser.document.getElementById("tr_" v.hwnd).className := "highlight-orange"
            }
        }
    }
    


    g_webBrowser.document.getElementById("tr_" hwnd).className := "activeWindow"
}



$*CapsLock::
Suspend, Permit ; Mark the current subroutine as being exempt from suspension
{   
	; HACK: sometimes caps lock has been turned on
	SetCapsLockState, AlwaysOff

    if ( not hw_isReady() ) {
        KeyWait, CapsLock
        return
    }
    
    Critical
    
    g_winList := getWindowList()
    
    Suspend, Off   ; Enable all hotkeys
    
    Critical Off
    
    
    


    
    
    
    
    
    
    
    
    
    g_lastKeyPressed =
    
    updateTbody()
    
    sleep 10
    ; hw_height := g_webBrowser.document.body.offsetHeight
    ; if (hw_height > 600) {
    ;     hw_height := 600
    ; }
    ; hw_height := 600
    hw_show()
    

    SetTimer, onTimer, 500
    
    
    ; Extract Icons
    for i, v in g_winList
    {
        if (GetKeyState("CapsLock", "P") = 0)
            break
        
        if g_iconCache.HasKey(v.hwnd)
            continue
        
        iconFile := "icon_" v.hwnd ".ico"
        SaveWindowIcon( v.hwnd, TEMP_FOLDER "\" iconFile )
        g_webBrowser.document.getElementById("icon_" v.hwnd).src := TEMP_FOLDER "\" iconFile
        g_iconCache[v.hwnd] := TEMP_FOLDER "\" iconFile
    }
    
    ; TODO: remove nonexistent icon cache
    
    
    
    
    KeyWait CapsLock
    
    Suspend, On
    
    SetTimer, onTimer, Off

    hw_hide()
}
return







WheelUp::scrollPage(1)
WheelDown::scrollPage(-1)

; XXX
; https://gist.github.com/be5invis/6571037
scrollPage(delta)
{
    global GuiHwnd

    ControlGet, hwndTopControl, Hwnd,,, ahk_id %GuiHwnd%
    
    
    WHEEL_DELTA := (120 << 16) * delta
    WinGetPos, x, y, width, height, ahk_id %GuiHwnd%
    mX := x + width / 2
    mY := y + height / 2
    
    PostMessage, 0x20A, WHEEL_DELTA, (mY << 16) | mX,,% "ahk_id " hwndTopControl
}

exitApp()
{
    ExitApp
}

aboutApp()
{
    SetTimer, onTimer, Off

    text =
    ( LTrim
        HotkeyR
        version 1.0
        rossning92@gmail.com

        The MIT License
        
        Copyright (c) 2017 Ross Ning

        Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions: 
        
        The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
        
        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    )
    MsgBox, 4096, About, % text
}

updateTbody() {
    global GuiHwnd
    global g_winList
    global g_iconCache
    global g_webBrowser
    global TEMP_FOLDER


    ; Update web page
    tbody =
    for i, v in g_winList {
        if (v.hwnd = GuiHwnd) {
            continue
        }
    
    
        key := SubStr(v.processName, 1, 1)
        StringUpper, key, key
    
        hwnd := v.hwnd
        ; msgbox % hwnd
        processName := v.processName
        title := v.title
        toggleTopColor := v.onTop ? "red lighten-2" : "grey lighten-3"
        if g_iconCache.HasKey(hwnd)
            iconSrc = %TEMP_FOLDER%\icon_%hwnd%.ico
        else
            iconSrc = images/loading-spinner-grey.gif
        activeWindow := v.isActive ? "activeWindow" : ""
        
        row = 
        (
            <tr id="tr_%hwnd%" onclick="AHK('onWindowSelected', '%hwnd%')" class="%activeWindow%">
                <td><img class="icon" id="icon_%hwnd%" src="%iconSrc%"></td>
                <td><span class="key">%key%</span></td>
                <td>%processName%</td>
                <td class="winTitle">%title%</td>
                <td><a class="topmost-btn btn-flat %toggleTopColor%" onclick="AHK('toggleTop', '%hwnd%')"><i class="material-icons">vertical_align_top</i></a></td>
            </tr>
        )
    
        tbody .= row
    }
    
    g_webBrowser.document.getElementById("tbody").innerHTML := tbody
}

onTimer() {
    global GuiHwnd

    ; Reset AlwaysOnTop to keep HotkeyR front most
    WinSet, AlwaysOnTop, On, ahk_id %GuiHwnd%
}