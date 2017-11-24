Decimal_to_Hex(var) {
  SetFormat, integer, hex
  var += 0
  SetFormat, integer, d
  return var
}
  
GetCPA_file_name( p_hw_target ) ; retrives Control Panel applet icon
{
  WinGet, pid_target, PID, ahk_id %p_hw_target%
  hp_target := DllCall( "OpenProcess", "uint", 0x18, "int", false, "uint", pid_target )
  hm_kernel32 := DllCall( "GetModuleHandle", "str", "kernel32.dll" )
  pGetCommandLineA := DllCall( "GetProcAddress", "uint", hm_kernel32, "str", "GetCommandLineA" )
  buffer_size = 6
  VarSetCapacity( buffer, buffer_size )
  DllCall( "ReadProcessMemory", "uint", hp_target, "uint", pGetCommandLineA, "uint", &buffer, "uint", buffer_size, "uint", 0 )
  loop, 4
    ppCommandLine += ( ( *( &buffer+A_Index ) ) << ( 8*( A_Index-1 ) ) )
  buffer_size = 4
  VarSetCapacity( buffer, buffer_size, 0 )
  DllCall( "ReadProcessMemory", "uint", hp_target, "uint", ppCommandLine, "uint", &buffer, "uint", buffer_size, "uint", 0 )
  loop, 4
    pCommandLine += ( ( *( &buffer+A_Index-1 ) ) << ( 8*( A_Index-1 ) ) )
  buffer_size = 260
  VarSetCapacity( buffer, buffer_size, 1 )
  DllCall( "ReadProcessMemory", "uint", hp_target, "uint", pCommandLine, "uint", &buffer, "uint", buffer_size, "uint", 0 )
  DllCall( "CloseHandle", "uint", hp_target )
  IfInString, buffer, desk.cpl ; exception to usual string format
    return, "C:\WINDOWS\system32\desk.cpl"

  ix_b := InStr( buffer, "Control_RunDLL" )+16
  ix_e := InStr( buffer, ".cpl", false, ix_b )+3
  StringMid, CPA_file_name, buffer, ix_b, ix_e-ix_b+1
  if ( ix_e )
    return, CPA_file_name
  else
    return, false
}

getWindowList()
{

    WS_EX_CONTROLPARENT =0x10000
    WS_EX_DLGMODALFRAME =0x1
    WS_CLIPCHILDREN =0x2000000
    WS_EX_APPWINDOW =0x40000
    WS_EX_TOOLWINDOW =0x80
    WS_DISABLED =0x8000000
    WS_VSCROLL =0x200000
    WS_POPUP =0x80000000


  winInfoList := []
  

  if PID_Filter !=
  {
    WinGet, Window_List, List, ahk_pid %PID_Filter%
  }
  else {
    WinGet, Window_List, List ; Gather a list of running programs
  }

  Window_Found_Count =0
  Window_Found_Count_For_Top_Recent=0
  ; GuiControl, -Redraw, ListView1

  Loop, %Window_List%
  {
    ;TODO: filter according to process name
    wid := Window_List%A_Index%
    
    WinGetTitle, wid_Title, ahk_id %wid%

    If ((Style & WS_DISABLED) or ! (wid_Title)) ; skip unimportant windows ; ! wid_Title or
      Continue

    WinGet, es, ExStyle, ahk_id %wid%
    WinGetClass, cla, ahk_id %wid%
    
    ; ROSS
    if (cla == "Windows.UI.Core.CoreWindow") {
        continue
    }
    
    Parent := Decimal_to_Hex( DllCall( "GetParent", "uint", wid ) )
    If ((es & WS_EX_TOOLWINDOW)  and !(Parent)) or (es =0x00200008) ; filters out program manager, etc
      continue
    
    WinGet, Style_parent, Style, ahk_id %Parent%
    Owner := Decimal_to_Hex( DllCall( "GetWindow", "uint", wid , "uint", "4" ) ) ; GW_OWNER = 4
    WinGet, Style_Owner, Style, ahk_id %Owner%
    If (!( es & WS_EX_APPWINDOW ))
    {      
      ; NOTE - some windows result in blank value so must test for zero instead of using NOT operator!
      If ((Parent) and ((Style_parent & WS_DISABLED) =0)) ; filter out windows that have a parent 
        continue
      If ((Owner) and ((Style_Owner & WS_DISABLED) =0))  ; filter out owner window that is NOT disabled -
        continue

      ; This filter's logic is copy from the internet, I don't know the detail.
      If ( Owner or ( es & WS_EX_TOOLWINDOW )) 
      {
        WinGetClass, Win_Class, ahk_id %wid%
        If ( ! ( Win_Class ="#32770" ) )
          Continue
      }
    }
    
    WinGet, Exe_Name, ProcessName, ahk_id %wid%
    WinGetClass, Win_Class, ahk_id %wid%
    hw_popup := Decimal_to_Hex(DllCall("GetLastActivePopup", "uint", wid))

    Window_Found_Count_For_Top_Recent += 1
    if Window_Found_Count_For_Top_Recent !=2  ; the last window will escap from GROUP FILTERING
    {
      ; CUSTOM GROUP FILTERING
      If (Group_Active != "ALL") ; i.e. list is filtered, check filter contents to include
      {
        Custom_Group_Include_wid_temp = ; initialise/reset

        Loop, %Group_Active_0% ; check current window id against the list to filter
        {
          Loop_Item := Group_Active_%A_Index%
            StringLeft, Exclude_Item, Loop_Item, 1
          If Exclude_Item =! ; remove ! for matching strings
            StringTrimLeft, Loop_Item, Loop_Item, 1
          If ((Loop_Item = Exe_Name) or InStr(wid_Title, Loop_Item)) ; match exe name, title
          {
            Custom_Group_Include_wid_temp =1 ; include this window
            Break
          }
        }

        If  (((Custom_Group_Include_wid_temp =1) and (Exclude_Item ="!"))
          or ((Custom_Group_Include_wid_temp !=1) and (Exclude_Not_In_List =1)))
          Continue
      }
    }

    
    
    
    
    ; Dialog =0 ; init/reset
    ; If (Parent and ! Style_parent)
    ;   CPA_file_name := GetCPA_file_name( wid ) ; check if it's a control panel window
    ; Else
    ;   CPA_file_name =
    ;   If (CPA_file_name or (Win_Class ="#32770") or ((style & WS_POPUP) and (es & WS_EX_DLGMODALFRAME)))
    ;     Dialog =1 ; found a Dialog window
      
      
    ;  If (CPA_file_name)
    ;  {
    ;    Window_Found_Count += 1
    ;    Gui_Icon_Number := IL_Add( ImageListID1, CPA_file_name, 1 )
    ;  }
    ;  Else
    ;    Get_Window_Icon(wid, Use_Large_Icons_Current) ; (window id, whether to get large icons)
      
      
      
      
      ; Window__Store_attributes(Window_Found_Count, wid, "") ; Index, wid, parent (or blank if none)
      
      
      
      ; wid_Title
      ; hw_popup
      ; ID_Parent
      ; Dialog  ; 1 if found a Dialog window, else 0
    

      WinGet, Exe_Name, ProcessName, ahk_id %wid% ; store processes to a list
      WinGet, PID, PID, ahk_id %wid% ; store pid's to a list
      
      WinGet, State_temp, MinMax, ahk_id %wid%
      If State_temp =1
        winState =Max
      Else If State_temp =-1
        winState =Min
      Else If State_temp =0
        winState =
      WinGet, es_hw_popup, ExStyle, ahk_id %hw_popup% ; eg to detect on top status of zoomplayer window
      If ((es & 0x8) or (es_hw_popup & 0x8))  ; 0x8 is WS_EX_TOPMOST.
      {
        OnTop =Top
        OnTop_Found =1
      }
      Else
        OnTop =

      If Responding
        Status =
      Else
      {
        Status =Not Responding
        Status_Found =1
      }
      
      
      
      
      winInfo := {}
      
      winInfo.hwnd := wid
      winInfo.index := Window_Found_Count
      winInfo.title := wid_Title
      winInfo.processName := Exe_Name
      winInfo.state := winState
      winInfo.onTop := OnTop
      winInfo.status := Status
      winInfo.isActive := WinActive("ahk_id" wid)
      
      
      ; a := "Icon" . Window_Found_Count . "|"  . "" . "|"  . Window_Found_Count . "|"  . wid_Title . "|"  . Exe_Name . "|"  . winState . "|"  . OnTop . "|"  . Status

      
      winInfoList.Push(winInfo)
  }
 
  return winInfoList
}


; a := getWindowList()
; for k, v in a
; {
;     msgbox % v.processName
; }