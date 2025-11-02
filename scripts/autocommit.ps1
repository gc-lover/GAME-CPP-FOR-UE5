# Скрипт автоматического коммита для агентов
# Использование: .\autocommit.ps1 [сообщение коммита]

param(
    [string]$CommitMessage = "Автоматический коммит: обновления от агента"
)

# Получаем текущую директорию репозитория
$RepoRoot = git rev-parse --show-toplevel 2>$null
if (-not $RepoRoot) {
    Write-Host "Ошибка: Не найден git репозиторий в текущей директории" -ForegroundColor Red
    exit 1
}

Set-Location $RepoRoot

# Проверяем, есть ли изменения для коммита
$Status = git status --porcelain
if (-not $Status) {
    Write-Host "Нет изменений для коммита" -ForegroundColor Yellow
    exit 0
}

# Добавляем все изменения
Write-Host "Добавление изменений..." -ForegroundColor Cyan
git add -A

# Генерируем сообщение коммита, если не указано явно
if ($CommitMessage -eq "Автоматический коммит: обновления от агента") {
    # Пытаемся сгенерировать осмысленное сообщение на основе измененных файлов
    $ChangedFiles = git diff --cached --name-only
    
    if ($ChangedFiles) {
        $FileTypes = @()
        $ChangedFiles | ForEach-Object {
            $ext = [System.IO.Path]::GetExtension($_)
            if ($ext) { $FileTypes += $ext }
        }
        
        $FileTypes = $FileTypes | Group-Object | Sort-Object Count -Descending | Select-Object -First 3
        
        $Types = ($FileTypes | ForEach-Object { $_.Name }) -join ", "
        
        # Определяем тип изменений
        $Action = "Обновление"
        if ($ChangedFiles | Where-Object { $_ -match "\.md$" }) {
            $Action = "Документация"
        } elseif ($ChangedFiles | Where-Object { $_ -match "\.(yaml|yml)$" }) {
            $Action = "API спецификация"
        } elseif ($ChangedFiles | Where-Object { $_ -match "\.(go|java|js|ts|py)$" }) {
            $Action = "Реализация"
        } elseif ($ChangedFiles | Where-Object { $_ -match "rules\.mdc$" }) {
            $Action = "Обновление правил"
        }
        
        $FileCount = ($ChangedFiles | Measure-Object).Count
        $CommitMessage = "${Action}: изменения в файлах (${FileCount} файлов)"
    }
}

# Делаем коммит
Write-Host "Создание коммита: $CommitMessage" -ForegroundColor Cyan
$CommitResult = git commit -m $CommitMessage 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Ошибка при создании коммита: $CommitResult" -ForegroundColor Red
    exit 1
}

Write-Host "Коммит создан успешно" -ForegroundColor Green

# Отправляем изменения
Write-Host "Отправка изменений в GitHub..." -ForegroundColor Cyan
$PushResult = git push origin main 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Предупреждение: Не удалось отправить изменения: $PushResult" -ForegroundColor Yellow
    Write-Host "Изменения закоммичены локально, но не отправлены" -ForegroundColor Yellow
} else {
    Write-Host "Изменения успешно отправлены в GitHub" -ForegroundColor Green
}

exit 0

