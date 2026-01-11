@echo off
setlocal enabledelayedexpansion

echo Updating package imports from ursafe to abhira...

for /r lib %%f in (*.dart) do (
    echo Processing: %%f
    powershell -Command "(Get-Content '%%f' -Raw) -replace 'package:ursafe', 'package:abhira' | Set-Content '%%f'"
)

echo Import update completed!
pause