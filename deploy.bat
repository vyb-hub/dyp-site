@echo off
echo.
echo  DYP - Deploy to GitHub
echo  ========================
echo.

where git >nul 2>nul
if %errorlevel% neq 0 (
  echo X  Git not found. Install from https://git-scm.com and re-run.
  pause
  exit /b 1
)

set /p GITHUB_USER="Enter your GitHub username: "
set /p REPO_NAME="Enter repo name (press Enter for 'dyp-site'): "
if "%REPO_NAME%"=="" set REPO_NAME=dyp-site

echo.
echo Initialising git...
git init

echo Staging all files...
git add .

echo Creating first commit...
git commit -m "Initial DYP deployment"

echo Setting branch to main...
git branch -M main

echo Adding remote...
git remote remove origin 2>nul
git remote add origin https://github.com/%GITHUB_USER%/%REPO_NAME%.git

echo Pushing to GitHub...
git push -u origin main

echo.
echo  Files pushed to GitHub!
echo.
echo  Now go to https://pages.cloudflare.com
echo  Connect your repo: %REPO_NAME%
echo  Build command: (leave empty)
echo  Output directory: /
echo  Save and Deploy
echo.
echo  Your live URL: https://%REPO_NAME%.pages.dev
echo.
pause
