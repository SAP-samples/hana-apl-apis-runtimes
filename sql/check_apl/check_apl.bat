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
REM   -o <output_file>            File path to store output (default: hana.md.txt)
REM   --check_apl-password <pwd>  Password for CHECK_APL user (default: Password01Password01)
REM   --show-cmd-only             Show the final hdbsql command and exit
REM   --help                      Show this help message and exit
REM When missing, the script will prompt for mandatory parameters (host,user,password) interactively.
REM Extra hdbsql parameters can be passed after the mandatory ones, and they will be appended to the hdbsql command.
REM
REM Examples:
REM  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md.txt
REM  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md.txt -e -ssltrustcert
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

set "PRECHECK_SQL_SCRIPT=%SCRIPT_DIR%check_create_CHECK_APL_user.sql"
if not exist "%PRECHECK_SQL_SCRIPT%" (
    echo Error: SQL script not found at "%PRECHECK_SQL_SCRIPT%"
    exit /b 1
)

REM Default values
set "DEFAULT_DB_HOST=hana:30015"
set "DEFAULT_DB_USER=SYSTEM"
set "DEFAULT_DB_PASSWORD=Manager1"
set "DEFAULT_OUTPUT_FORMAT=md"
set "DEFAULT_SIGNAL_ERROR=off"
set "DEFAULT_CHECK_APL_PASSWORD=Password01Password01"
set "DEFAULT_OUTPUT_FILE=hana.md.txt"
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
    set /p DB_PASSWORD=Enter HANA DB SYSTEM user password [Manager1]: 
    if "!DB_PASSWORD!"=="" set "DB_PASSWORD=%DEFAULT_DB_PASSWORD%"
)
if "%CHECK_APL_PASSWORD%"=="" (
    set /p CHECK_APL_PASSWORD=Enter CHECK_APL user password; Do not forget your current password policy [Password01Password01]: 
    if "!CHECK_APL_PASSWORD!"=="" set "CHECK_APL_PASSWORD=%DEFAULT_CHECK_APL_PASSWORD%"
)
if "%SIGNAL_ERROR%"=="" (
    set "SIGNAL_ERROR=%DEFAULT_SIGNAL_ERROR%"
)
if "%OUTPUT_FORMAT%"=="" (
    set "OUTPUT_FORMAT=%DEFAULT_OUTPUT_FORMAT%"
)
if "%OUTPUT_FILE%"=="" (
    set /p OUTPUT_FILE=Enter output file path Use 'stdout' to see results in console [hana.md.txt]: 
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

echo Checking SAP HANA instance %DB_HOST% as %DB_USER% to %OUTPUT_FILE% ...
echo.

REM Build the hdbsql commands
set "HDBSQL_CMD="%HDBSQL%" -n "%DB_HOST%" -u "%DB_USER%" -p "%DB_PASSWORD%" -V OUTPUT_FORMAT=%OUTPUT_FORMAT%,SIGNAL_ERROR=%SIGNAL_ERROR%,SYSTEM_USER=%DB_USER%,SYSTEM_PASSWORD=%DB_PASSWORD%,CHECK_APL_PASSWORD=%CHECK_APL_PASSWORD% -j -I "%SQL_SCRIPT%" -A -a -F "" "" !EXTRA_ARGS!"

set "PRECHECK_CMD="%HDBSQL%" -n "%DB_HOST%" -u "%DB_USER%" -p "%DB_PASSWORD%" -V SYSTEM_USER=%DB_USER%,SYSTEM_PASSWORD=%DB_PASSWORD%,CHECK_APL_PASSWORD=%CHECK_APL_PASSWORD% -j -I "%PRECHECK_SQL_SCRIPT%" -A -a -F "" "" !EXTRA_ARGS!"

set "CHECK_CONNECTION_CMD="%HDBSQL%" -n "%DB_HOST%" -u "%DB_USER%" -p "%DB_PASSWORD%" "" !EXTRA_ARGS!"

REM Only add >OUTPUT_FILE if not "stdout"
if /I not "%OUTPUT_FILE%"=="stdout" (
    set "HDBSQL_CMD=%HDBSQL_CMD% > "%OUTPUT_FILE%""
)

echo Running pre-check ...
REM Check if we can connect with provided information
%CHECK_CONNECTION_CMD% >nul 2>nul
if errorlevel 1 (
    echo Error: Unable to connect to HANA instance %DB_HOST% as user %DB_USER% with the provided password ^(hdbsql exit code 3 - authentication error^) >&2
    exit /b 3
)
echo Connection to HANA instance %DB_HOST% as user %DB_USER% successful.

REM Run the pre-check SQL (check_create_CHECK_APL_user.sql) using the exact same hdb parameters.
REM This script contains pre-checks that must pass before running check_apl.sql.

REM Create temporary file for pre-check output
set "PREOUT=%TEMP%\precheck_%RANDOM%.tmp"
%PRECHECK_CMD% 2>"%PREOUT%"

REM Fatal: check for specific error codes in output
findstr /C:"10001" "%PREOUT%" >nul
if not errorlevel 1 (
    echo Fatal Error: pre-check detected %DB_USER% user does not have 'USER ADMIN' privilege >&2
    del /f "%PREOUT%" 2>nul
    exit /b 10001
)

findstr /C:"10002" "%PREOUT%" >nul
if not errorlevel 1 (
    echo Fatal Error: pre-check detected provided password for temporary CHECK_APL user does not match current password policy >&2
    del /f "%PREOUT%" 2>nul
    exit /b 10002
)

REM Pre-check passed (no fatal errors)
del /f "%PREOUT%" 2>nul
echo Pre-check completed successfully. Actual check can be done

if "%SHOW_CMD_ONLY%"=="1" (
    REM Mask passwords in the displayed command and remove double quotes for an unquoted view
    set "DISPLAY_CMD=%HDBSQL_CMD%"
    if /I not "%OUTPUT_FILE%"=="stdout" (
        set "DISPLAY_CMD=%DISPLAY_CMD% > "%OUTPUT_FILE%""
    )
    setlocal enabledelayedexpansion
    REM Remove double quotes so the command is shown without quoted arguments (user requested)
    set "DISPLAY_CMD=!DISPLAY_CMD:"=!"
    REM Mask known passwords: DB system password and CHECK_APL password
    set "DISPLAY_CMD=!DISPLAY_CMD:%DB_PASSWORD%=****!"
    set "DISPLAY_CMD=!DISPLAY_CMD:SYSTEM_PASSWORD=%DB_PASSWORD%=SYSTEM_PASSWORD=****!"
    set "DISPLAY_CMD=!DISPLAY_CMD:CHECK_APL_PASSWORD=%CHECK_APL_PASSWORD%=CHECK_APL_PASSWORD=****!"
    echo Final hdbsql command:
    echo !DISPLAY_CMD!
    endlocal
    exit /b 0
)

REM Execute the command and filter out SQL warnings containing 'HY000'
if /I not "%OUTPUT_FILE%"=="stdout" (
    REM Output to file: filter warnings and redirect to file
    %HDBSQL_CMD% | findstr /V "HY000"
    set "exit_code=!ERRORLEVEL!"
) else (
    REM Output to stdout: filter warnings
    %HDBSQL_CMD% | findstr /V "HY000"
    set "exit_code=!ERRORLEVEL!"
)

echo Check completed with exit code !exit_code!.
exit /b !exit_code!

:show_help
echo Usage: check_apl.bat [OPTIONS]
echo.
echo Options:
echo   -h ^<host:port^>              HANA DB host and port (default: hana:30015)
echo   -u ^<user^>                   HANA DB user (default: SYSTEM)
echo   -p ^<password^>               HANA DB user password (default: Manager1)
echo   -f ^<format^>                 Output format: md (Markdown), raw, etc. (default: md)
echo   -s ^<on^|off^>                Signal error in output (default: off)
echo   -o ^<output_file^>            File path to store output (default: hana.md.txt)
echo   --check_apl-password ^<pwd^>  Password for CHECK_APL user (default: Password01Password01)
echo   --show-cmd-only               Show the final hdbsql command and exit
echo   --help                        Show this help message and exit
echo When missing, the script will prompt for mandatory parameters (host,user,password) interactively.
echo Extra hdbsql parameters can be passed after the mandatory ones, and they will be appended to the hdbsql command.
echo.
echo Examples:
echo  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md.txt
echo  check_apl -h hana:30015 -u SYSTEM -p MyPassword -o /tmp/hana.md.txt -e -ssltrustcert
echo.
exit /b 0
