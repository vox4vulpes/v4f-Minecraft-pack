# Установка модов — TLauncher / официальный Minecraft Launcher

## Шаг 1. Поставить Fabric

Скачайте официальный установщик Fabric: https://fabricmc.net/use/installer/

Запустите его, вкладка **Client**:
- Minecraft version: **26.2**
- Loader version: **0.19.3**
- Install location: оставьте по умолчанию (это создаст обычный `.minecraft` профиль)

Нажмите Install. Появится профиль `fabric-loader-0.19.3-26.2`.

- **Официальный лаунчер** — профиль появится в списке автоматически.
- **TLauncher** — откройте вкладку профилей, найдите/добавьте профиль `fabric-loader-0.19.3-26.2` (TLauncher обычно подхватывает его сам из `.minecraft/versions`, либо создайте новый профиль и укажите эту версию вручную).

## Шаг 2. Найти папку игры (game directory)

Это папка, где лежат `mods`, `config`, `saves` и т.д.

- **Официальный лаунчер**: обычно `%appdata%\.minecraft` (Windows) / `~/.minecraft` (Linux) / `~/Library/Application Support/minecraft` (Mac).
- **TLauncher**: откройте настройки профиля → там указан путь (может отличаться, например `%appdata%\.tlauncher\minecraft`).

## Шаг 3. Скачать packwiz-installer-bootstrap

https://github.com/packwiz/packwiz-installer-bootstrap/releases — скачайте `packwiz-installer-bootstrap.jar`.

Положите этот jar-файл **прямо в папку игры** (ту, что нашли в Шаге 2, где лежит папка `mods`).

## Шаг 4. Запустить установку модов

Откройте терминал/командную строку **в этой самой папке** (на Windows: зайти в папку → в адресной строке проводника набрать `cmd` и нажать Enter) и выполните:

```
java -jar packwiz-installer-bootstrap.jar https://raw.githubusercontent.com/vox4vulpes/v4f-Minecraft-pack/main/pack.toml
```

Моды скачаются в папку `mods` автоматически.

## Обновления

Модпак может обновляться. Автоматически это не подхватится (в отличие от Prism Launcher) — **перед запуском игры** нужно заново выполнить команду из Шага 4, чтобы подтянуть актуальные версии модов.

## Запуск

Выберите профиль `fabric-loader-0.19.3-26.2` в лаунчере и запускайте игру как обычно.
