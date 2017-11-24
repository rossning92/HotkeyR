#include <Gdip_All>
#include <SaveHICONtoFile>




if 0
{
  ptr := A_PtrSize = 8 ? "ptr" : "uint"   ;for AHK Basic
  FileName := A_WinDir "\notepad.exe"
  hIcon := DllCall("Shell32\ExtractAssociatedIcon" (A_IsUnicode ? "W" : "A")
   , ptr, DllCall("GetModuleHandle", ptr, 0, ptr)
   , str, FileName
   , "ushort*", lpiIcon
   , ptr)   ;only supports 32x32



  ; Gui, Margin, 20, 20
  ; Gui, Add, Text, w64 h64 hwndmypic1 0x3
  ; STM_SETICON := 0x0170
  ; SendMessage, STM_SETICON, hIcon, 0,, Ahk_ID %mypic1%
  ; Gui, Show
  SavehIconAsBMP(hIcon, "123.png")


  WinGet, active_id, ID, A
  SaveWindowIcon(active_id, "1234.png")
}












SaveWindowIcon(hwnd, fileName)
{
  hIcon := Get_Window_Icon(hwnd, 1)
  ; SavehIconAsBMP(hIcon, fileName)

  SaveHICONtoFile(hIcon, fileName)
}

SavehIconAsBMP(hIcon, sFile) {
  if pToken := Gdip_Startup() {
    pBitmap := Gdip_CreateBitmapFromHICON(hIcon)
    Gdip_SaveBitmapToFile(pBitmap, sFile)
    Gdip_DisposeImage(pBitmap)
    Gdip_Shutdown(pToken)
    return true
  }
  return false
}


Get_Window_Icon(wid, Use_Large_Icons_Current) ; (window id, whether to get large icons)
{
  ; Local NR_temp, h_icon
  ; Window_Found_Count += 1
  

  GetClassLong_API := A_PtrSize = 8 ? "GetClassLongPtr" : "GetClassLong"
  
  
  ; check status of window - if window is responding or "Not Responding"
  NR_temp := 0 ; init
  h_icon =
  Responding := DllCall("SendMessageTimeout"
    , "UInt", wid
    , "UInt", 0x0
    , "Int", 0
    , "Int", 0
    , "UInt", 0x2
    , "UInt", 150
    , "UInt *", NR_temp) ; 150 = timeout in millisecs

  If (Responding)
  {
    ; WM_GETICON values -    ICON_SMALL =0,   ICON_BIG =1,   ICON_SMALL2 =2
    If Use_Large_Icons_Current =1
    {
      SendMessage, 0x7F, 1, 0,, ahk_id %wid%
      h_icon := ErrorLevel
      ; msgbox % h_icon
    }
    If ( ! h_icon )
    {
      SendMessage, 0x7F, 2, 0,, ahk_id %wid%
      h_icon := ErrorLevel
      If ( ! h_icon )
      {
        SendMessage, 0x7F, 0, 0,, ahk_id %wid%
        h_icon := ErrorLevel
        If ( ! h_icon )
        {
          If Use_Large_Icons_Current =1
          {
            h_icon := DllCall( GetClassLong_API, "uint", wid, "int", -14 ) ; GCL_HICON is -14
          }
          If ( ! h_icon )
          {
            h_icon := DllCall( GetClassLong_API, "uint", wid, "int", -34 ) ; GCL_HICONSM is -34
            If ( ! h_icon )
            h_icon := DllCall( "LoadIcon", "uint", 0, "uint", 32512 ) ; IDI_APPLICATION is 32512
          }
        }
      }
    }
  }  
  
  return h_icon
  
  If ! ( h_icon = "" or h_icon = "FAIL") ; Add the HICON directly to the icon list
  Gui_Icon_Number := DllCall("ImageList_ReplaceIcon", UInt, ImageListID1, Int, -1, UInt, h_icon)
  Else	; use a generic icon
  Gui_Icon_Number := IL_Add(ImageListID1, "shell32.dll" , 3)
}
