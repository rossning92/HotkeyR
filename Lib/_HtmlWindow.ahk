#include <_WindowFader>


hw_width := 500
hw_height := 800
hw_url = %A_ScriptDir%\UI\index.html

hw_init()


    

hw_init()
{
    global g_webBrowser
    global g_hwndWebBrowser
    global hw_width
    global hw_height
    global hw_url
    global GuiHwnd
    global g_fader
    
    Gui, g_htmlWindow: New
    Gui, g_htmlWindow: Default


    Gui +AlwaysOnTop -SysMenu -Caption +HwndGuiHwnd +LastFound
    ; Gui +Disabled  ; Prevents the user from interacting
    WinSet, ExStyle, +0x08000000  ; WS_EX_NOACTIVATE
    WinSet, Transparent, 0, ahk_id %GuiHwnd%
    
    
    Gui, Add, ActiveX, vg_webBrowser hwndg_hwndWebBrowser x0 y0 w%hw_width% h%hw_height%, Shell.Explorer ; The final parameter is the name of the ActiveX component.

    
    
    
    g_webBrowser.silent := true ; Surpress JS Error boxes
    
    ComObjConnect(g_webBrowser, "IE_")
    
    g_webBrowser.Navigate(hw_url)
    
    g_webBrowser.document.parentWindow.AHK := Func("JS_AHK")
    
    g_fader := new WindowFader(GuiHwnd)
    
    
    
    ; Disable navigation sounds
    ; Thanks MrBubbles
	; https://autohotkey.com/boards/viewtopic.php?p=117029#p117029
	DllCall("urlmon\CoInternetSetFeatureEnabled"
        ,"Int",  21 ; FEATURE_DISABLE_NAVIGATION_SOUNDS
        ,"UInt", 0x00000002 ; SET_FEATURE_ON_PROCESS
        ,"Int", 1)
        
    
    
}


IE_DocumentComplete() ; "IE_" prefix corresponds to the 2nd param in ComObjConnect()
{
    global g_htmlStr
    global g_webBrowser
    global g_hwndWebBrowser
    global g_winList
    
    
    ; Scale UI by screen DPI.  My testing showed that Vista with IE7 or IE9
    ; did not scale by default, but Win8.1 with IE10 did.  The scaling being
    ; done by the control itself = deviceDPI / logicalDPI.
    ; w := g_webBrowser.document.parentWindow
    ; logicalDPI := w.screen.logicalXDPI, deviceDPI := w.screen.deviceXDPI
    ; zoomFactor := Floor(A_ScreenDPI/96 * (logicalDPI/deviceDPI) * 100)

    
    ; HACK
    dpiZoomMap := {96: 100, 120: 150, 144: 200}
    zoomFactor := dpiZoomMap[A_ScreenDPI]
    
    WB := g_webBrowser
    OLECMDID_OPTICAL_ZOOM        :=63
    OLECMDEXECOPT_DODEFAULT      :=0
    OLECMDEXECOPT_PROMPTUSER     :=1
    OLECMDEXECOPT_DONTPROMPTUSER :=2
    OLECMDEXECOPT_SHOWHELP       :=3
    
    WB.ExecWB(OLECMDID_OPTICAL_ZOOM,OLECMDEXECOPT_DONTPROMPTUSER, zoomFactor)
    
    
    
    
    
    



    
    
    return
    
    

    
    
    
    ; Update window size
    g_webBrowser.document.write(g_htmlStr)


    width := g_webBrowser.document.getElementById("container").offsetWidth
    height := g_webBrowser.document.getElementById("container").offsetHeight
   
   
    ; This is slow???
    ; WinMove, ahk_id %g_hwndWebBrowser%, , 0, 0, %width%, %height%


    
    

}




; Use DOM access just like javascript!
; MyButton1 := g_webBrowser.document.getElementById("MyButton1")
; MyButton2 := g_webBrowser.document.getElementById("MyButton2")
; MyButton3 := g_webBrowser.document.getElementById("MyButton3")
; ComObjConnect(MyButton1, "MyButton1_") ;connect button events
; ComObjConnect(MyButton2, "MyButton2_")
; ComObjConnect(MyButton3, "MyButton3_")









; Our Event Handlers
MyButton1_OnClick() {
	global g_webBrowser
	MsgBox % g_webBrowser.Document.getElementById("MyTextBox").Value
}
MyButton2_OnClick() {
	global g_webBrowser
	FormatTime, TimeString, %A_Now%, dddd MMMM d, yyyy HH:mm:ss
	data := "AHK Version " A_AhkVersion " - " (A_IsUnicode ? "Unicode" : "Ansi") " " (A_PtrSize == 4 ? "32" : "64") "bit`nCurrent time: " TimeString
	g_webBrowser.Document.getElementById("MyTextBox").value := data
}
MyButton3_OnClick() {
	MsgBox Hello world!
}




hw_show()
{
    global g_webBrowser
    global g_htmlStr
    global g_winList
    global hw_width
    global hw_height
    global GuiHwnd
    global g_winAlpha
    global g_fader
    
    ; Wait for IE to load the page, before we connect the event handlers
    ; g_htmlStr := htmlStr
    ; g_webBrowser.Navigate("about:blank")
    
    
    
    
    ; WinSet, ExStyle, +0x00000020, ahk_id %GuiHwnd%
    ; WinSet, Transparent, 0, ahk_id %GuiHwnd%
    
    
    Gui, g_htmlWindow:Show, w%hw_width% h%hw_height% NoActivate Hide xCenter yCenter
    
    
    g_fader.fadeIn()
}

hw_isReady()
{
    global g_webBrowser
    
    ret := not (g_webBrowser.readystate != 4 or g_webBrowser.busy)
    return ret
}





hw_hide()
{
    global g_fader
    
    g_fader.fadeOut()
    
    ; Gui, g_htmlWindow:Hide
}

; javascript:AHK('Func') --> Func()
JS_AHK(func, prms*)
{
    global g_webBrowser

	wb := g_webBrowser
	; Stop navigation prior to calling the function, in case it uses Exit.
	wb.Stop()
	return %func%(prms*)
}



















/*  Fix keyboard shortcuts in WebBrowser control.
 *  References:
 *    http://www.autohotkey.com/community/viewtopic.php?p=186254#p186254
 *    http://msdn.microsoft.com/en-us/library/ms693360
 */
OnMessage(0x100, "gui_KeyDown", 2)
gui_KeyDown(wParam, lParam, nMsg, hWnd) {
    global g_htmlWindow
	wb := g_htmlWindow
	if (Chr(wParam) ~= "[A-Z]" || wParam = 0x74) ; Disable Ctrl+O/L/F/N and F5.
		return
	
    
    ; pipa := ComObjQuery(wb, "{00000117-0000-0000-C000-000000000046}")
	; VarSetCapacity(kMsg, 48), NumPut(A_GuiY, NumPut(A_GuiX
	; , NumPut(A_EventInfo, NumPut(lParam, NumPut(wParam
	; , NumPut(nMsg, NumPut(hWnd, kMsg)))), "uint"), "int"), "int")
	; Loop 2
	; r := DllCall(NumGet(NumGet(1*pipa)+5*A_PtrSize), "ptr", pipa, "ptr", &kMsg)
	; ; Loop to work around an odd tabbing issue (it's as if there
	; ; is a non-existent element at the end of the tab order).
	; until wParam != 9 || wb.Document.activeElement != ""
	; ObjRelease(pipa)
	; if r = 0 ; S_OK: the message was translated to an accelerator.
	; 	return 0
}