@if "%SCM_TRACE_LEVEL%" NEQ "4" @echo off

:: This shell script heavily inspired by Ilia Karmanov's example:
:: https://github.com/ilkarman/Azure-WebApp-w-CNTK
::
:: Feel free to use newer wheels of your own if you like.

SET NUMPY_WHEEL=https://mawahstorage.blob.core.windows.net/cntkwebapp/wheels/numpy-1.13.1mkl-cp35-cp35m-win_amd64.whl
SET SCIPY_WHEEL=https://mawahstorage.blob.core.windows.net/cntkwebapp/wheels/scipy-0.19.1-cp35-cp35m-win_amd64.whl
SET CNTK_WHEEL=https://mawahstorage.blob.core.windows.net/cntkwebapp/wheels/cntk-2.0-cp35-cp35m-win_amd64.whl

:: ----------------------
:: KUDU Deployment Script
:: Version: 1.0.14
:: ----------------------

:: Prerequisites
:: -------------

:: Verify node.js installed
where node 2>nul >nul
IF %ERRORLEVEL% NEQ 0 (
  echo Missing node.js executable, please install node.js, if already installed make sure it can be reached from current environment.
  goto error
)

:: Setup
:: -----

setlocal enabledelayedexpansion

SET ARTIFACTS=%~dp0%..\artifacts

IF NOT DEFINED DEPLOYMENT_SOURCE (
  SET DEPLOYMENT_SOURCE=%~dp0%.
)

IF NOT DEFINED DEPLOYMENT_TARGET (
  SET DEPLOYMENT_TARGET=%ARTIFACTS%\wwwroot
)

IF NOT DEFINED NEXT_MANIFEST_PATH (
  SET NEXT_MANIFEST_PATH=%ARTIFACTS%\manifest

  IF NOT DEFINED PREVIOUS_MANIFEST_PATH (
    SET PREVIOUS_MANIFEST_PATH=%ARTIFACTS%\manifest
  )
)

IF NOT DEFINED KUDU_SYNC_CMD (
  :: Install kudu sync
  echo Installing Kudu Sync
  call npm install kudusync -g --silent
  IF !ERRORLEVEL! NEQ 0 goto error

  :: Locally just running "kuduSync" would also work
  SET KUDU_SYNC_CMD=%appdata%\npm\kuduSync.cmd
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Deployment
:: ----------

echo Handling Basic Web Site deployment.

:: 1. KuduSync
IF /I "%IN_PLACE_DEPLOYMENT%" NEQ "1" (
  call :ExecuteCmd "%KUDU_SYNC_CMD%" -v 50 -f "%DEPLOYMENT_SOURCE%" -t "%DEPLOYMENT_TARGET%" -n "%NEXT_MANIFEST_PATH%" -p "%PREVIOUS_MANIFEST_PATH%" -i ".git;.hg;.deployment;deploy.cmd"
  IF !ERRORLEVEL! NEQ 0 goto error
)

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
goto end

:: Execute command routine that will echo out when error
:ExecuteCmd
setlocal
set _CMD_=%*
call %_CMD_%
if "%ERRORLEVEL%" NEQ "0" echo Failed exitCode=%ERRORLEVEL%, command=%_CMD_%
exit /b %ERRORLEVEL%

:error
endlocal
echo An error has occurred during web site deployment.
call :exitSetErrorLevel
call :exitFromFunction 2>nul

:exitSetErrorLevel
exit /b 1

:exitFromFunction
()

:end
endlocal

echo Installing Python 3.5 wheels (hope you installed the Python 3.5.3 extension!)
D:\home\python353x64\python.exe -m pip install --upgrade %NUMPY_WHEEL%
D:\home\python353x64\python.exe -m pip install --upgrade %SCIPY_WHEEL%
D:\home\python353x64\python.exe -m pip install --upgrade %CNTK_WHEEL%
D:\home\python353x64\python.exe -m pip install --upgrade pillow
D:\home\python353x64\python.exe -m pip install --upgrade flask

echo Finished running custom deploy command successfully.
