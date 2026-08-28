# Автоустановщик тестового сервера v4f (NeoForge 21.1.249 + Create) для официального лаунчера Minecraft.
# Запускать через PowerShell: правой кнопкой по файлу -> "Выполнить с помощью PowerShell",
# либо в PowerShell: .\install-create-test.ps1
#
# Что делает:
#   1) Скачивает и запускает установщик NeoForge 21.1.249, ставит версию в вашу настоящую .minecraft
#      (это нужно, чтобы лаунчер вообще знал про такую версию).
#   2) Создаёт ОТДЕЛЬНУЮ папку игры для этого сервера (не трогает основной .minecraft/mods).
#   3) Скачивает packwiz-installer-bootstrap и синхронизирует моды (сейчас — Create) в эту папку.
#   4) Добавляет профиль "v4f Create Test" в лаунчер с правильной Game Directory.
#
# Ничего в вашей существующей .minecraft (сохранения, другие моды, другие профили) не удаляется
# и не перезаписывается — добавляется только новая версия и новый профиль.

$ErrorActionPreference = "Stop"

$NeoForgeVersion = "21.1.249"
$McDir           = Join-Path $env:APPDATA ".minecraft"
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

Write-Host "=== Установка тестового сервера v4f (NeoForge $NeoForgeVersion + Create) ===" -ForegroundColor Cyan
Write-Host ""

# --- 0. Проверка Java ---
$javaCmd = Get-Command java -ErrorAction SilentlyContinue
if (-not $javaCmd) {
    Fail "Java не найдена в PATH. Установите Java 21+ (https://adoptium.net/) и запустите скрипт снова.`nЕсли Java у вас уже стоит вместе с Minecraft, но не в PATH - переустановите Java отдельно с adoptium.net."
}
Write-Host "[OK] Java найдена: $($javaCmd.Source)"

if (-not (Test-Path $McDir)) {
    Fail "Не найдена папка `"$McDir`". Запустите официальный Minecraft Launcher хотя бы один раз перед этим скриптом."
}

# --- 1. Установка NeoForge в реальную .minecraft ---
Write-Host ""
Write-Host "[1/4] Скачиваю установщик NeoForge $NeoForgeVersion..."
$installerUrl  = "https://maven.neoforged.net/releases/net/neoforged/neoforge/$NeoForgeVersion/neoforge-$NeoForgeVersion-installer.jar"
$installerPath = Join-Path $env:TEMP "neoforge-$NeoForgeVersion-installer.jar"
try {
    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Fail "Не удалось скачать установщик NeoForge: $_"
}

Write-Host "[1/4] Устанавливаю NeoForge $NeoForgeVersion в $McDir ..."
& java -jar $installerPath --install-client $McDir
if ($LASTEXITCODE -ne 0) {
    Fail "Установщик NeoForge завершился с ошибкой (код $LASTEXITCODE). Смотрите вывод выше."
}
Write-Host "[OK] NeoForge $NeoForgeVersion установлен."

# --- 2. Отдельная папка игры ---
Write-Host ""
Write-Host "[2/4] Создаю отдельную папку игры: $GameDir"
New-Item -ItemType Directory -Force -Path $GameDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $GameDir "mods") | Out-Null

# --- 3. packwiz: синхронизация модов ---
Write-Host ""
Write-Host "[3/4] Скачиваю packwiz-installer-bootstrap..."
$bootstrapUrl  = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/latest/download/packwiz-installer-bootstrap.jar"
$bootstrapPath = Join-Path $GameDir "packwiz-installer-bootstrap.jar"
try {
    Invoke-WebRequest -Uri $bootstrapUrl -OutFile $bootstrapPath -UseBasicParsing
} catch {
    Fail "Не удалось скачать packwiz-installer-bootstrap: $_"
}

Write-Host "[3/4] Синхронизирую моды (Create) в $GameDir\mods ..."
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

# --- 4. Профиль в лаунчере ---
Write-Host ""
Write-Host "[4/4] Добавляю профиль в лаунчер..."
$profilesPath = Join-Path $McDir "launcher_profiles.json"
if (-not (Test-Path $profilesPath)) {
    Write-Host "[!] launcher_profiles.json не найден - пропускаю авто-добавление профиля." -ForegroundColor Yellow
    Write-Host "    Добавьте профиль вручную: Installations -> New Installation -> Version: neoforge-$NeoForgeVersion" -ForegroundColor Yellow
    Write-Host "    -> More Options -> Game Directory: $GameDir" -ForegroundColor Yellow
} else {
    $backupPath = "$profilesPath.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    Copy-Item $profilesPath $backupPath
    Write-Host "    Резервная копия: $backupPath"

    try {
        $profiles = Get-Content $profilesPath -Raw | ConvertFrom-Json

        $nowIso = [DateTime]::UtcNow.ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        $newProfile = [PSCustomObject]@{
            name          = "v4f Create Test"
            type          = "custom"
            created       = $nowIso
            lastUsed      = $nowIso
            icon          = "Furnace"
            lastVersionId = "neoforge-$NeoForgeVersion"
            gameDir       = $GameDir
        }

        $profiles.profiles | Add-Member -MemberType NoteProperty -Name "v4f-create-test" -Value $newProfile -Force
        $profiles | ConvertTo-Json -Depth 10 | Set-Content $profilesPath -Encoding UTF8

        Write-Host "[OK] Профиль 'v4f Create Test' добавлен." -ForegroundColor Green
    } catch {
        Write-Host "[!] Не удалось автоматически прописать профиль: $_" -ForegroundColor Yellow
        Write-Host "    Восстанавливаю резервную копию launcher_profiles.json..." -ForegroundColor Yellow
        Copy-Item $backupPath $profilesPath -Force
        Write-Host "    Добавьте профиль вручную: Installations -> New Installation -> Version: neoforge-$NeoForgeVersion" -ForegroundColor Yellow
        Write-Host "    -> More Options -> Game Directory: $GameDir" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=== Готово! ===" -ForegroundColor Cyan
Write-Host "1. Перезапустите официальный Minecraft Launcher (если он был открыт)."
Write-Host "2. Выберите профиль 'v4f Create Test'."
Write-Host "3. Подключайтесь к серверу: $ServerAddress"
Write-Host ""
Read-Host "Нажмите Enter для выхода"
