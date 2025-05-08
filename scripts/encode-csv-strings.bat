call "%~dp0variables.cmd"

REM Clean previous final .w3strings outputs from modPath
if exist "%modPath%\en.w3strings" del /Q "%modPath%\en.w3strings"
if exist "%modTHfullPath%\tr.w3strings" del /Q "%modTHfullPath%\tr.w3strings"
if exist "%modENMenuPath%\tr.w3strings" del /Q "%modENMenuPath%\tr.w3strings"

"%modkitpath%\w3strings.exe" --encode "%modPath%\en.w3strings.csv" --id-space 5018
"%modkitpath%\w3strings.exe" --encode "%modTHfullPath%\tr.w3strings.csv" --id-space 5018
"%modkitpath%\w3strings.exe" --encode "%modENMenuPath%\tr.w3strings.csv" --id-space 5018

REM This still deletes from Current Working Directory. Adjust if .ws files are in modPath.
del "%modPath%\*.ws"
del "%modTHfullPath%\*.ws"
del "%modENMenuPath%\*.ws"

rename "%modPath%\en.w3strings.csv.w3strings" en.w3strings
rename "%modTHfullPath%\tr.w3strings.csv.w3strings" tr.w3strings
rename "%modENMenuPath%\tr.w3strings.csv.w3strings" tr.w3strings