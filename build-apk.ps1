# =============================================================================
# KAMAUI LAB — Script Automatizado de Empaquetado Android (.APK)
# =============================================================================
$ErrorActionPreference = "Stop"

Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "  KAMAUI LAB — EMPAREJADOR Y COMPILADOR ANDROID (.APK)   " -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Yellow

# 1. Preparar directorio www/ para Capacitor con la versión móvil nativa
Write-Host "`n[1/4] Preparando bundle móvil en carpeta ./www ..." -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "www\assets" | Out-Null
Copy-Item "kamaui-mobile-apk.html" "www\index.html" -Force
Copy-Item "kamaui-mobile-apk.html" "www\kamaui-mobile-apk.html" -Force
Copy-Item "index.html" "www\desktop.html" -Force
Copy-Item "landing-template.html" "www\landing-template.html" -Force
Copy-Item "manifest.json" "www\manifest.json" -Force
Copy-Item "sw.js" "www\sw.js" -Force
if (Test-Path "assets\logo-kamaui.jpg") {
    Copy-Item "assets\logo-kamaui.jpg" "www\assets\logo-kamaui.jpg" -Force
}

# 2. Instalar Capacitor si no existe node_modules
if (-not (Test-Path "node_modules\@capacitor\core")) {
    Write-Host "[2/4] Instalando Capacitor Android Core & CLI..." -ForegroundColor Cyan
    npm install
} else {
    Write-Host "[2/4] Dependencias Capacitor ya instaladas." -ForegroundColor Green
}

# 3. Crear o sincronizar proyecto nativo Android
if (-not (Test-Path "android")) {
    Write-Host "[3/4] Generando proyecto nativo Android..." -ForegroundColor Cyan
    npx cap add android
}
Write-Host "[3/4] Sincronizando activos web y aplicando Logo Kamaui como icono y Splash nativo..." -ForegroundColor Cyan
npx cap sync android

# Aplicar el logo de Kamaui como icono de la app Android y pantalla de carga (Splash)
if ((Test-Path "android\app\src\main\res") -and (Test-Path "assets\logo-kamaui.jpg")) {
    Get-ChildItem -Path "android\app\src\main\res\mipmap-*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item "assets\logo-kamaui.jpg" (Join-Path $_.FullName "ic_launcher.png") -Force
        Copy-Item "assets\logo-kamaui.jpg" (Join-Path $_.FullName "ic_launcher_round.png") -Force
        Copy-Item "assets\logo-kamaui.jpg" (Join-Path $_.FullName "ic_launcher_foreground.png") -Force
    }
    Get-ChildItem -Path "android\app\src\main\res\drawable*" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item "assets\logo-kamaui.jpg" (Join-Path $_.FullName "splash.png") -Force
    }
}

# 4. Compilar APK si Java y Android SDK están instalados
if ((Get-Command "java" -ErrorAction SilentlyContinue) -and ($env:ANDROID_HOME -or (Test-Path "$env:LOCALAPPDATA\Android\Sdk"))) {
    Write-Host "[4/4] Compilando archivo Kamaui-Validador-360.apk con Gradle..." -ForegroundColor Cyan
    Push-Location android
    .\gradlew.bat assembleDebug
    Pop-Location
    $apkSource = "android\app\build\outputs\apk\debug\app-debug.apk"
    if (Test-Path $apkSource) {
        Copy-Item $apkSource ".\Kamaui-Validador-360.apk" -Force
        Write-Host "`n¡ÉXITO! APK generado en: $(Resolve-Path .\Kamaui-Validador-360.apk)" -ForegroundColor Green
    }
} else {
    Write-Host "`n[4/4] Proyecto nativo Android (./android) y bundle (./www) generados correctamente." -ForegroundColor Green
    Write-Host "Nota: Para compilar el .APK sin instalar Android Studio ni Java en tu PC," -ForegroundColor Yellow
    Write-Host "usa el workflow incluido en .github/workflows/build-android-apk.yml o abre ./android en Android Studio." -ForegroundColor Yellow
}
