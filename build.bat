@echo off
setlocal

rem Define paths and URLs
set FFmpegURL=https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip
set OutputDir=ffmpeg
set ZipFile=ffmpeg.zip
set SourceDir=src
set FFmpegFile=ffmpeg.exe
set OutputZip=discordifier1.0.zip
set FFmpegFolder=FFmpeg
set TranscodeFile=transcode.bat

rem Function to download and extract FFmpeg
:install_ffmpeg
if exist "%OutputDir%\bin\ffmpeg.exe" (
    echo FFmpeg is already installed.
    goto :after_ffmpeg
)

echo Downloading FFmpeg...
if not exist %ZipFile% (
    powershell -Command "Invoke-WebRequest -Uri '%FFmpegURL%' -OutFile '%ZipFile%'"
)

echo Creating output directory...
if not exist %OutputDir% mkdir %OutputDir%

echo Extracting FFmpeg...
powershell -Command "Expand-Archive -Path '%ZipFile%' -DestinationPath '%OutputDir%' -Force"

rem Optional: Commented out the cleanup step for ffmpeg.zip
rem echo Cleaning up...
rem del %ZipFile%

move "%OutputDir%\ffmpeg-master-latest-win64-gpl\bin\ffmpeg.exe" .
rmdir /S /Q "%OutputDir%"

if exist "%FFmpegFile%" (
    echo FFmpeg successfully installed.
) else (
    echo Failed to extract FFmpeg. Exiting.
    goto :end
)

:after_ffmpeg
rem Check for src folder and ffmpeg.exe
if not exist "%SourceDir%" (
    echo The src folder does not exist. Exiting.
    goto :end
)

if not exist "%FFmpegFile%" (
    echo ffmpeg.exe not found. Exiting.
    goto :end
)

rem Create the FFmpeg folder if it doesn't exist and move ffmpeg.exe into it
if not exist "%FFmpegFolder%" mkdir "%FFmpegFolder%"
move "%FFmpegFile%" "%FFmpegFolder%\ffmpeg.exe"

rem Copy transcode.bat from src to the current directory (not inside src)
if exist "%SourceDir%\%TranscodeFile%" (
    copy "%SourceDir%\%TranscodeFile%" .
)

rem Zip FFmpeg folder and transcode.bat into discordifier1.0.zip using PowerShell
echo Zipping FFmpeg folder and transcode.bat...
powershell -Command "Compress-Archive -Path '%FFmpegFolder%', '%TranscodeFile%' -DestinationPath '%OutputZip%'"

if %errorlevel% neq 0 (
    echo Failed to create the zip file. Exiting.
    goto :end
)

rem Clean up by deleting the FFmpeg folder and transcode.bat (only from working directory, not src)
echo Cleaning up...
rmdir /S /Q "%FFmpegFolder%"
del "%TranscodeFile%"

:end
pause
endlocal
