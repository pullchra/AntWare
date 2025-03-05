@echo off
powershell -Command "Start-Process -FilePath 'powershell.exe' -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0AntWare.ps1\"' -Verb RunAs"
