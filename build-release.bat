@setlocal enabledelayedexpansion
@echo off

REM Build everything for a new (MedMij) release.

call build-nts.bat %*
call build-centralizeLoadResources.bat %*

pause