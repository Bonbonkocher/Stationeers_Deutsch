@echo off
chcp 65001 >nul
title Stationeers Apply Translations Tool

echo ========================================================
echo   Stationeers Apply Translations Tool
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\Apply-StationeersTranslations.ps1"

echo.
echo ========================================================
echo Vorgang abgeschlossen.
pause