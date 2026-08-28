# Автоустановщик тестового сервера v4f (NeoForge 21.1.249 + Create) - вариант для TLauncher.
# Запускать через PowerShell (не двойным кликом - Windows блокирует скачанные скрипты):
#   powershell -ExecutionPolicy Bypass -File install-create-test-tlauncher.ps1
#
# В отличие от версии для официального лаунчера, этот скрипт НЕ пытается сам прописать профиль
# в TLauncher - у него своя, не до конца задокументированная система профилей, автоматическая
# правка вслепую рискует её сломать. Вместо этого скрипт делает всю файловую часть (установка
# NeoForge, отдельная папка, синхронизация модов), а профиль вы добавляете сами в интерфейсе
# TLauncher (2 клика, см. подсказку в конце) - это TLauncher умеет из коробки.
#
# По умолчанию TLauncher использует ту же папку %appdata%\.minecraft, что и официальный лаунчер.
# Если у вас настроена другая - смотрите путь в настройках TLauncher и передайте его параметром:
#   powershell -ExecutionPolicy Bypass -File install-create-test-tlauncher.ps1 -McDir "C:\путь\к\.minecraft"

param(
    [string]$McDir = (Join-Path $env:APPDATA ".minecraft")
)

$ErrorActionPreference = "Stop"

$NeoForgeVersion = "21.1.249"
$GameDir         = Join-Path $env:APPDATA ".minecraft-v4f-create-test"
$PackUrl         = "https://raw.githubusercontent.com/vox4vulpes/v4f-Minecraft-pack/main/test-server/pack.toml"
$ServerAddress   = "stulbia.qqwrd.com:25566"

function Fail($msg) {
    Write-Host ""
    Write-Host "ОШИБКА: $msg" -ForegroundColor Red
    Write-Host "Установка прервана, ничего лишнего не тронуто." -ForegroundColor Red
    Read-Host "Нажмите Enter для выхода"
    exit 1
}

Write-Host "=== Установка тестового сервера v4f для TLauncher (NeoForge $NeoForgeVersion + Create) ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Целевая папка TLauncher: $McDir"
Write-Host "(если это не ваша папка TLauncher - прервите (Ctrl+C) и запустите с параметром -McDir)"
Write-Host ""

# --- 0. Проверка Java ---
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Fail "Java не найдена в PATH. Установите Java 21+ (https://adoptium.net/) и запустите скрипт снова."
}
Write-Host "[OK] Java найдена: $($javaCmd.Source)"

if (-not (Test-Path $McDir)) {
    Fail "Не найдена папка `"$McDir`". Запустите TLauncher хотя бы один раз перед этим скриптом, либо укажите правильный путь через -McDir."
}

# --- 1. Установка NeoForge в папку TLauncher ---
Write-Host ""
Write-Host "[1/3] Скачиваю установщик NeoForge $NeoForgeVersion..."
$installerUrl  = "https://maven.neoforged.net/releases/net/neoforged/neoforge/$NeoForgeVersion/neoforge-$NeoForgeVersion-installer.jar"
$installerPath = Join-Path $env:TEMP "neoforge-$NeoForgeVersion-installer.jar"
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Fail "Не удалось скачать установщик NeoForge: $_"
}

Write-Host "[1/3] Устанавливаю NeoForge $NeoForgeVersion в $McDir ..."
& java -jar $installerPath --install-client $McDir
if ($LASTEXITCODE -ne 0) {
    Fail "Установщик NeoForge завершился с ошибкой (код $LASTEXITCODE). Смотрите вывод выше."
}
Write-Host "[OK] NeoForge $NeoForgeVersion установлен в versions\neoforge-$NeoForgeVersion."

# --- 2. Отдельная папка игры ---
Write-Host ""
Write-Host "[2/3] Создаю отдельную папку игры: $GameDir"
New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GameDir "mods") | Out-Null

# --- 3. packwiz: синхронизация модов ---
Write-Host ""
Write-Host "[3/3] Скачиваю packwiz-installer-bootstrap..."
$bootstrapUrl  = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"
$bootstrapPath = Join-Path $GameDir "packwiz-installer-bootstrap.jar"
try {
    Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapPath -UseBasicParsing
} catch {
    Fail "Не удалось скачать packwiz-installer-bootstrap: $_"
}

Write-Host "[3/3] Синхронизирую моды (Create) в $GameDir\mods ..."
Push-Location $GameDir
try {
    & java -jar $bootstrapPath $PackUrl
    if ($LASTEXITCODE -ne 0) {
        Fail "packwiz-installer завершился с ошибкой (код $LASTEXITCODE). Смотрите вывод выше."
    }
} finally {
    Pop-Location
}
Write-Host "[OK] Моды синхронизированы."

Write-Host ""
Write-Host "=== Файловая часть готова! Осталось 2 клика в самом TLauncher ===" -ForegroundColor Cyan
Write-Host "1. Откройте TLauncher -> вкладка версий/профилей."
Write-Host "2. Добавьте/выберите профиль версии 'neoforge-$NeoForgeVersion' (появится в списке версий)."
Write-Host "3. В настройках этого профиля укажите 'Директория игры': $GameDir"
Write-Host "4. Сохраните, запускайте, подключайтесь к: $ServerAddress"
Write-Host ""
Read-Host "Нажмите Enter для выхода"
