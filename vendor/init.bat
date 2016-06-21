@echo off

:: Init Script for cmd.exe
:: Created as part of cmder project

:: !!! THIS FILE IS OVERWRITTEN WHEN CMDER IS UPDATED
:: !!! Use "%CMDER_ROOT%\etc\user-profile.cmd" to add your own startup commands

:: Find root dir
if not defined CMDER_ROOT (
    for /f "delims=" %%i in ("%ConEmuDir%\..\..") do set CMDER_ROOT=%%~fi
)

:: Remove trailing '\'
if "%CMDER_ROOT:~-1%" == "\" SET CMDER_ROOT=%CMDER_ROOT:~0,-1%

:: Change the prompt style
:: Mmm tasty lamb
prompt $E[1;32;40m$P$S{git}{hg}$S$_$E[1;30;40m{lamb}$S$E[0m

:: Pick right version of clink
if "%PROCESSOR_ARCHITECTURE%"=="x86" (
    set architecture=86
) else (
    set architecture=64
)

:: Tell the user about the clink config files...
if not exist "%CMDER_ROOT%\etc\settings" (
    echo Generating clink initial settings in %CMDER_ROOT%\etc\settings
    echo Additional *.lua files in %CMDER_ROOT%\etc are loaded on startup.
) 

:: Run clink
"%CMDER_ROOT%\lib\clink\clink_x%architecture%.exe" inject --quiet --profile "%CMDER_ROOT%\etc" --scripts "%CMDER_ROOT%\lib"

:: Prepare for git-for-windows

:: I do not even know, copypasted from their .bat
set PLINK_PROTOCOL=ssh
if not defined TERM set TERM=cygwin

:: Check if msysgit is installed
if exist "%ProgramFiles%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles%\Git"
) else if exist "%ProgramFiles(x86)%\Git" (
    set "GIT_INSTALL_ROOT=%ProgramFiles(x86)%\Git"
) else if exist "%USERPROFILE%\AppData\Local\Programs\Git" (
    set "GIT_INSTALL_ROOT=%USERPROFILE%\AppData\Local\Programs\Git"
) else if exist "%CMDER_ROOT%\lib\git-for-windows" (
    set "GIT_INSTALL_ROOT=%CMDER_ROOT%\lib\git-for-windows"
)

:: Add git to the path
if defined GIT_INSTALL_ROOT (
    set "PATH=%GIT_INSTALL_ROOT%\bin;%GIT_INSTALL_ROOT%\usr\bin;%GIT_INSTALL_ROOT%\usr\share\vim\vim74;%PATH%"
    :: define SVN_SSH so we can use git svn with ssh svn repositories
    if not defined SVN_SSH set "SVN_SSH=%GIT_INSTALL_ROOT:\=\\%\\bin\\ssh.exe"
)

:: Enhance Path
set "PATH=%CMDER_ROOT%\bin;%PATH%;%CMDER_ROOT%\"

:: Drop *.bat and *.cmd files into "%CMDER_ROOT%\etc\profile.d"
:: to run them at startup.
if not exist "%CMDER_ROOT%\etc\profile.d" (
  mkdir "%CMDER_ROOT%\etc\profile.d"
)

pushd "%CMDER_ROOT%\etc\profile.d"
for /f "usebackq" %%x in ( `dir /b *.bat *.cmd 2^>nul` ) do (
  REM echo Calling %CMDER_ROOT%\etc\profile.d\%%x...
  call "%CMDER_ROOT%\etc\profile.d\%%x"
)
popd

:: make sure we have an example file
if not exist "%CMDER_ROOT%\etc\aliases" (
    echo Creating intial aliases in %CMDER_ROOT%\etc\aliases
    copy "%CMDER_ROOT%\lib\aliases.example" "%CMDER_ROOT%\etc\aliases" > null
)

:: Add aliases
doskey /macrofile="%CMDER_ROOT%\etc\aliases"

:: See lib\git-for-windows\README.portable for why we do this
:: Basically we need to execute this post-install.bat because we are
:: manually extracting the archive rather than executing the 7z sfx
if exist "%CMDER_ROOT%\lib\git-for-windows\post-install.bat" (
    echo Running Git for Windows one time Post Install....
    cd /d "%CMDER_ROOT%\lib\git-for-windows\"
    "%CMDER_ROOT%\lib\git-for-windows\git-bash.exe" --no-needs-console --hide --no-cd --command=post-install.bat
    cd /d %USERPROFILE%
)

:: Set home path
if not defined HOME set HOME=%USERPROFILE%

:: This is either a env variable set by the user or the result of
:: cmder.exe setting this variable due to a commandline argument or a "cmder here"
if defined CMDER_START (
    cd /d "%CMDER_START%"
)

if exist "%CMDER_ROOT%\etc\user-profile.cmd" (
    rem create this file and place your own command in there
    call "%CMDER_ROOT%\etc\user-profile.cmd"
) else (
    echo Creating user startup file: "%CMDER_ROOT%\etc\user-profile.cmd"
    (
    echo :: use this file to run your own startup commands
    echo :: use  in front of the command to prevent printing the command
    echo.
    echo :: call "%%GIT_INSTALL_ROOT%%/cmd/start-ssh-agent.cmd
    echo :: set PATH=%%CMDER_ROOT%%\lib\whatever;%%PATH%%
    echo.
    ) > "%CMDER_ROOT%\etc\user-profile.cmd"
)
