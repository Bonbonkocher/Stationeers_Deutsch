@echo off
chcp 65001 >nul
title Stationeers Language Diff Tool

echo ========================================================
echo   Stationeers Language Diff Tool
echo ========================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Scripts\Compare-StationeersLanguage.ps1"

echo.
echo ========================================================
echo Vorgang abgeschlossen.
pause