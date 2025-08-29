@echo off
REM ============================================================================
REM check_apl.bat - SAP HANA APL Installation & Runtime Checker (Windows version)
REM
REM This script connects to a SAP HANA instance and runs the APL check SQL script.
REM It supports interactive and non-interactive modes, help system, and robust
REM parameter handling.
REM
REM Usage:
REM   check_apl.bat [OPTIONS]
REM
REM Options:
REM   -h <host:port>              HANA DB host and port (default: hana:30015)
REM   -u <user>                   HANA DB user (default: SYSTEM)
REM   -p <password>               HANA DB user password (default: Manager1)
REM   -f <format>                 Output format: md (Markdown), raw, etc. (default: md)
REM   -s <on|off>                 Signal error in output (default: off)
REM   -o <output_file>            File path to store output (default: hana.md)
REM   --check_apl-password <pwd>  Password for CHECK_APL user (default: Password1)
REM   --show-cmd-only             Show the final hdbsql command and exit
REM   --help                      Show this help message and exit
REM When missing, the script will prompt for mandatory parameters (host,user,password) interactively.
REM Extra hdbsql parameters can be passed after the mandatory ones, and they will be appended to the hdbsql command.
REM
REM Examples:
REM  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md
REM  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md -e -ssltrustcert
REM

setlocal enabledelayedexpansion

REM Get script directory. Do it before shifting arguments
set "SCRIPT_DIR=%~dp0"
set "SQL_SCRIPT=%SCRIPT_DIR%check_apl.sql"

REM Check if check_apl.sql exists
if not exist "%SQL_SCRIPT%" (
    echo Error: SQL script not found at "%SQL_SCRIPT%"
    exit /b 1
)

REM Default values
set "DEFAULT_DB_HOST=hana:30015"
set "DEFAULT_DB_USER=SYSTEM"
set "DEFAULT_DB_PASSWORD=Manager1"
set "DEFAULT_OUTPUT_FORMAT=md"
set "DEFAULT_SIGNAL_ERROR=off"
set "DEFAULT_CHECK_APL_PASSWORD=Password1"
set "DEFAULT_OUTPUT_FILE=hana.md"
set "OUTPUT_FILE="
set "SHOW_CMD_ONLY=0"

REM Prepare to collect extra arguments
set "EXTRA_ARGS="

REM Parse arguments
:parse_args
if "%~1"=="" goto after_args
if "%~1"=="-h" (
    set "DB_HOST=%~2"
    shift
) else if "%~1"=="-u" (
    set "DB_USER=%~2"
    shift
) else if "%~1"=="-p" (
    set "DB_PASSWORD=%~2"
    shift
) else if "%~1"=="-f" (
    set "OUTPUT_FORMAT=%~2"
    shift
) else if "%~1"=="-s" (
    set "SIGNAL_ERROR=%~2"
    shift
) else if "%~1"=="-o" (
    set "OUTPUT_FILE=%~2"
    shift
) else if "%~1"=="--check_apl-password" (
    set "CHECK_APL_PASSWORD=%~2"
    shift
) else if "%~1"=="--show-cmd-only" (
    set "SHOW_CMD_ONLY=1"
) else if "%~1"=="--help" (
    goto show_help
) else (
    set "EXTRA_ARGS=!EXTRA_ARGS! %~1"
)
shift
goto parse_args

:after_args

REM Interactive prompts for missing parameters
if "%DB_HOST%"=="" (
    set /p DB_HOST=Enter HANA DB host:port [hana:30015]: 
    if "!DB_HOST!"=="" set "DB_HOST=%DEFAULT_DB_HOST%"
)
if "%DB_USER%"=="" (
    set /p DB_USER=Enter HANA DB user [SYSTEM]: 
    if "!DB_USER!"=="" set "DB_USER=%DEFAULT_DB_USER%"
)
if "%DB_PASSWORD%"=="" (
    set /p DB_PASSWORD=Enter HANA DB user password [Manager1]: 
    if "!DB_PASSWORD!"=="" set "DB_PASSWORD=%DEFAULT_DB_PASSWORD%"
)
if "%CHECK_APL_PASSWORD%"=="" (
    set "CHECK_APL_PASSWORD=%DEFAULT_CHECK_APL_PASSWORD%"
)
if "%SIGNAL_ERROR%"=="" (
    set "SIGNAL_ERROR=%DEFAULT_SIGNAL_ERROR%"
)
if "%OUTPUT_FORMAT%"=="" (
    set "OUTPUT_FORMAT=%DEFAULT_OUTPUT_FORMAT%"
)
if "%OUTPUT_FILE%"=="" (
    set /p OUTPUT_FILE=Enter output file path Use 'stdout' to see results in console [hana.md]: 
    if "!OUTPUT_FILE!"=="" set "OUTPUT_FILE=%DEFAULT_OUTPUT_FILE%"
)

REM Find hdbsql.exe
set "HDBSQL="
where hdbsql.exe >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%i in ('where hdbsql.exe') do set "HDBSQL=%%i"
) else if exist "C:\Program Files\SAP\hdbclient\hdbsql.exe" (
    set "HDBSQL=C:\Program Files\SAP\hdbclient\hdbsql.exe"
) else (
    for /f "delims=" %%d in ('dir /b /ad /o-n "C:\Program Files\SAP\hdbclient*" 2^>nul') do (
        if exist "C:\Program Files\SAP\%%d\hdbsql.exe" (
            set "HDBSQL=C:\Program Files\SAP\%%d\hdbsql.exe"
            goto found_hdbsql
        )
    )
)
:found_hdbsql
if not defined HDBSQL (
    echo Error: hdbsql.exe not found in PATH or C:\Program Files\SAP\hdbclient*
    exit /b 1
)

REM Build the hdbsql command
set "HDBSQL_CMD="%HDBSQL%" -n "%DB_HOST%" -u "%DB_USER%" -p "%DB_PASSWORD%" -V OUTPUT_FORMAT=%OUTPUT_FORMAT%,SIGNAL_ERROR=%SIGNAL_ERROR%,SYSTEM_USER=%DB_USER%,SYSTEM_PASSWORD=%DB_PASSWORD%,CHECK_APL_PASSWORD=%CHECK_APL_PASSWORD% -j -I "%SQL_SCRIPT%" -A -a -F "" "" !EXTRA_ARGS!"

REM Only add >OUTPUT_FILE if not "stdout"
if /I not "%OUTPUT_FILE%"=="stdout" (
    set "HDBSQL_CMD=%HDBSQL_CMD% > "%OUTPUT_FILE%""
)

REM Show the command only if requested, masking passwords
if "%SHOW_CMD_ONLY%"=="1" (
    set "DISPLAY_CMD=%HDBSQL_CMD%"
    setlocal enabledelayedexpansion
    set "DISPLAY_CMD=!DISPLAY_CMD:"%DB_PASSWORD%"="****"!"
    set "DISPLAY_CMD=!DISPLAY_CMD:SYSTEM_PASSWORD=%DB_PASSWORD%=SYSTEM_PASSWORD=****!"
    set "DISPLAY_CMD=!DISPLAY_CMD:CHECK_APL_PASSWORD=%CHECK_APL_PASSWORD%=CHECK_APL_PASSWORD=****!"
    echo Final hdbsql command:
    echo !DISPLAY_CMD!
    endlocal
    exit /b 0
)

REM Run the check
echo Running check_apl.sql on %DB_HOST% as %DB_USER%, output to %OUTPUT_FILE% ...
%HDBSQL_CMD%

exit /b %ERRORLEVEL%

:show_help
echo Usage: check_apl.bat [OPTIONS]
echo.
echo Options:
echo   -h ^<host:port^>              HANA DB host and port (default: hana:30015)
echo   -u ^<user^>                   HANA DB user (default: SYSTEM)
echo   -p ^<password^>               HANA DB user password (default: Manager1)
echo   -f ^<format^>                 Output format: md (Markdown), raw, etc. (default: md)
echo   -s ^<on^|off^>                Signal error in output (default: off)
echo   -o ^<output_file^>            File path to store output (default: hana.md)
echo   --check_apl-password ^<pwd^>  Password for CHECK_APL user (default: Password1)
echo   --show-cmd-only               Show the final hdbsql command and exit
echo   --help                        Show this help message and exit
echo When missing, the script will prompt for mandatory parameters (host,user,password) interactively.
echo Extra hdbsql parameters can be passed after the mandatory ones, and they will be appended to the hdbsql command.
echo.
echo Examples:
echo  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md
echo  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md -e -ssltrustcert
echo.
exit /b 0
