@echo off
REM Build everything for a new (MedMij) release.

call build-nts.bat
for %%d in (dev\FHIR3-0-2-MM201901-Test dev\FHIR3-0-2-MM201901-Cert dev\FHIR3-0-2-MM202001-Test dev\FHIR3-0-2-MM202001-Cert dev\FHIR3-0-2-MM202002-Test dev\FHIR3-0-2-MM202002-Cert) do call centralize-loadscripts.bat %%d

pause