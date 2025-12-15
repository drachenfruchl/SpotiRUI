@echo off

python --version >nul 2>&1 || (
  echo Python is not installed!
  pause
  exit /b
)

python -m pip install --quiet -r requirements.txt
cls
python spotify_setup.py
pause
exit /b