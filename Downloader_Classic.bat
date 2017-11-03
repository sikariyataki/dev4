@echo off
set /p url="URL: "
set /p title="Title: "
set d=%date:~-4%%date:~3,2%%date:~0,2%
ffmpeg -i "%url%" -c copy "%title%.ts"
ffmpeg -ss 00:00:15.0 -i "%title%.ts" -c copy "%title%.tmp.ts"
ffmpeg -i "%title%.tmp.ts" -c copy -bsf:a aac_adtstoasc "%title%_%d%.mp4"
del "%title%.ts"
pause