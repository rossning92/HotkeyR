; Thanks to WAZAAAAA
; https://autohotkey.com/boards/viewtopic.php?t=6413

#NoEnv
#MaxHotkeysPerInterval 99000000
#HotkeyInterval 99000000
#KeyHistory 0
ListLines Off
Process, Priority, , High
SetBatchLines, -1
SetKeyDelay, -1, -1
SetMouseDelay, -1
SetDefaultMouseSpeed, 0
SetWinDelay, -1
SetControlDelay, -1
SendMode Input

; YOUR SCRIPT GOES HERE, but first some recommendations
; the Unicode x64bit version is the fastest AHK installation
; use PixelSearch without Fast if you're searching for a single pixel of a single shade
; DllCall("Sleep", UInt, 16.67) ; I just used the precise sleep function to wait exactly 16,67 milliseconds!