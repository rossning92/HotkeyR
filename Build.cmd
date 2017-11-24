@echo off

rd /s /q Build
md Build >nul 2>nul

Ahk2Exe /in HotkeyR.ahk /out Build\HotkeyR.exe /icon Icon.ico /mpress 1

:: /E   Copies directories and subdirectories
:: /I   Assumes that destination must be a directory
xcopy "UI" "Build\UI" /E /I
xcopy "Resources" "Build\Resources" /E /I

pause