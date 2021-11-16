REM Create a copy of all loadscripts from subfolders in the _LoadScripts folder, rewriting the paths to the fixtures.
REM Pass the directory of the main folder that holds the other folders as the first argument to this script.

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

set origPath=%cd%
cd %1
echo Creating centralized LoadResources for %1

if not exist _LoadResources (mkdir _LoadResources)

for /R %%s in (*load-resources-purgecreateupdate*.xml) do (
    set fullPath=%%~dps
    set relPath=!fullPath:%cd%=!
    if not "!relPath:~0,16!"=="\_LoadResources\" (
        echo Rewriting %%s
             
        call :normalizeRelPath !relPath! normalizedRelPath
        call :buildFileName !normalizedRelPath! fileName
        if exist !fileName! (del !fileName!)
        call :substInFile %%s !normalizedRelPath! !fileName!       
    )
)
cd %origPath%
exit /b

REM --- The following functions are needed to make search and replace work with variables, as this allows for mixing
REM     the % and ! notation.

REM Normalize the relative path from Windows so that it can be used in the new loadscript. 
REM param 1: The relative path to the loadscript, Windows style.
REM returns: The relative path from the centralized _LoadResources folder to the information standard folder.
:normalizeRelPath
    set passedPath=%1
    set normalizedPath=%passedPath:\=/%
    set %~2=..!normalizedPath:/_LoadResources/=!
exit /b

REM Builds a file name (relative to the working dir) for the new loadscript, based on the folder name. It is assumed
REM that the leaf dir is the name of the information standard.
REM param 1: The normalized path as returned by normalizeRelPath.
REM returns: The full path to the file name for the new loadscript.
:buildFileName
    set passedPath=%1
    for %%n in (%passedPath:/= %) do (
        set folderName=%%n
    )
    set %~2=_LoadResources\%folderName%-load-resources-purgecreateupdate-xml.xml
exit /b

REM Performs the magic of rewriting all reference paths.
REM param 1: The path to the existing loadscript.
REM param 2: The relative path as returned by normalizeRelPath.
REM param 3: The file name of the new file to write to.
:substInFile
    set newPath=%2
    for /F "delims=" %%l in (%1) do (
        set line=%%l
        echo !line:..=%2! >> %3
    )
exit /b
