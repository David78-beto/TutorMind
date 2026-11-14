@echo off
REM Arranca TutorMind completo: backend, frontend y navegador.
cd /d "%~dp0"

if not exist ".env" (
  copy ".env.example" ".env" >nul
  echo Se creo .env desde .env.example. Pon tu GEMINI_API_KEY en .env para usar el chat.
)

echo Iniciando backend (puerto 8000)...
start "TutorMind - Backend" cmd /k "cd /d "%~dp0backend" && python -m pip install -q -r requirements.txt && python -m uvicorn main:app --host 127.0.0.1 --port 8000"

echo Iniciando frontend (puerto 4200)...
if not exist "frontend\node_modules" (
  start "TutorMind - Frontend" cmd /k "cd /d "%~dp0frontend" && npm install && npm start"
) else (
  start "TutorMind - Frontend" cmd /k "cd /d "%~dp0frontend" && npm start"
)

echo Esperando a que compile el frontend...
timeout /t 25 /nobreak >nul
start "" "http://localhost:4200"

echo.
echo Listo. Deja abiertas las ventanas "TutorMind - Backend" y "TutorMind - Frontend".
echo Para apagar la app, cierra esas dos ventanas.
timeout /t 5 >nul
