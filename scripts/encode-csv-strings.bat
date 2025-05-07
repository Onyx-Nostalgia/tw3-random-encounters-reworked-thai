call "%~dp0variables.cmd"

REM Clean previous final .w3strings outputs from modPath
if exist "%modPath%\en.w3strings" del /Q "%modPath%\en.w3strings"
if exist "%modPath%\tr.w3strings" del /Q "%modPath%\tr.w3strings"

"%modkitpath%\w3strings.exe" --encode "%modPath%\en.w3strings.csv" --id-space 5018
"%modkitpath%\w3strings.exe" --encode "%modPath%\tr.w3strings.csv" --id-space 5018

del "%modPath%\*.ws" REM This still deletes from Current Working Directory. Adjust if .ws files are in modPath.

rename "%modPath%\en.w3strings.csv.w3strings" en.w3strings
rename "%modPath%\tr.w3strings.csv.w3strings" tr.w3strings