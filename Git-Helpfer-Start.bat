@echo off
chcp 65001 >nul
:: Dateiname des Skripts
set OrdnerPfad=Scripts
set scriptName=Git-Helpfer-Programm.ps1

:: Startet PowerShell mit dem Skript aus dem Unterordner "Scripts"
powershell -NoExit -ExecutionPolicy Bypass -File "%~dp0%OrdnerPfad%\%scriptName%"