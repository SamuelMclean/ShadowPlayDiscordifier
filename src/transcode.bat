@echo off
setlocal enabledelayedexpansion

:: Get the directory where the batch script is located
set "SCRIPT_DIR=%~dp0"

:: Set source and destination directories relative to the script location
set "SOURCE_DIR=%SCRIPT_DIR%Clips"
set "DEST_DIR=%SCRIPT_DIR%ClipsTranscoded"
set "TEMP_DIR=C:\temp"

:: Ensure FFmpeg is in the PATH
set "FFMPEG=FFmpeg"

:: Create the TEMP_DIR if it doesn't exist
if not exist "%TEMP_DIR%" (
    mkdir "%TEMP_DIR%"
    if !errorlevel! neq 0 (
        echo Failed to create temp directory: %TEMP_DIR%
        exit /b 1
    )
)

:: Variables to keep track of the progress
set /a total_files=0
set /a processed_files=0

:: Target file size in megabytes
set /a target_size_mb=9
set /a target_size_bytes=target_size_mb*1024*1024

:: Function to count .mp4 files
for /r "%SOURCE_DIR%" %%f in (*.mp4) do (
    set /a total_files+=1
)

echo Total .mp4 files to process: %total_files%
echo.

:: Function to process each .mp4 file
for /r "%SOURCE_DIR%" %%f in (*.mp4) do (
    set "input_file=%%f"
    
    :: Get the directory name of the input file relative to the source directory
    set "relative_path=%%~dpf"
    set "relative_path=!relative_path:%SOURCE_DIR%\=!"

    :: Construct the output directory and file name
    set "output_dir=%DEST_DIR%\!relative_path!"
    set "output_file=!output_dir!%%~nxf"

    :: Create the destination directory if it doesn't exist
    if not exist "!output_dir!" (
        mkdir "!output_dir!"
    )

    echo Processing file: !input_file!

    :: Calculate bitrate for the target file size
    for /f "tokens=1-2" %%a in ('%FFMPEG% -i "!input_file!" 2^>^&1 ^| findstr /r /c:"Duration: "') do (
        set "duration=%%b"
    )

    :: Convert duration to seconds
    for /f "tokens=1-3 delims=:.," %%a in ("!duration!") do (
        set /a "duration_s=%%a*3600 + %%b*60 + %%c"
    )

    :: Calculate video bitrate (in bits per second)
    set /a "video_bitrate=(target_size_bytes*8)/duration_s - 128000" :: 128k for audio

    if !video_bitrate! LEQ 0 (
        set video_bitrate=500000  :: Minimum bitrate safety net
    )

    :: First pass with log file in TEMP_DIR
    %FFMPEG% -y -i "!input_file!" -vf scale=1920:1080 -c:v libx264 -b:v !video_bitrate! -g 30 -pass 1 -passlogfile "%TEMP_DIR%\ffmpeg2pass" -an -f null NUL

    :: Second pass with log file in TEMP_DIR
    %FFMPEG% -i "!input_file!" -vf scale=1920:1080 -c:v libx264 -b:v !video_bitrate! -preset slow -pass 2 -passlogfile "%TEMP_DIR%\ffmpeg2pass" -g 30 -maxrate 7M -bufsize 14M -profile:v high -level:v 4.1 -bf 3 -movflags +faststart -x264-params rc-lookahead=60:ref=4:me=umh:subme=8:trellis=2 -c:a aac -b:a 128k -y "!output_file!"

    if !errorlevel! == 0 (
        echo Successfully re-encoded: !input_file!
        del "!input_file!"  REM This line deletes the original file after successful re-encoding
        echo Deleted original file: !input_file!
    ) else (
        echo Failed to re-encode: !input_file!
    )

    set /a processed_files+=1
    echo Progress: !processed_files! / %total_files%
    echo.
)

echo.
echo All files processed.
pause
