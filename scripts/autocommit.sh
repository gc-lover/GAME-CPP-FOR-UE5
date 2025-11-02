#!/bin/bash
# Скрипт автоматического коммита для агентов (Linux/Mac)
# Использование: ./autocommit.sh [сообщение коммита]

COMMIT_MESSAGE="${1:-Автоматический коммит: обновления от агента}"

# Получаем корневую директорию репозитория
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$REPO_ROOT" ]; then
    echo "Ошибка: Не найден git репозиторий в текущей директории" >&2
    exit 1
fi

cd "$REPO_ROOT" || exit 1

# Проверяем, есть ли изменения для коммита
if [ -z "$(git status --porcelain)" ]; then
    echo "Нет изменений для коммита"
    exit 0
fi

# Добавляем все изменения
echo "Добавление изменений..."
git add -A

# Генерируем сообщение коммита, если не указано явно
if [ "$COMMIT_MESSAGE" = "Автоматический коммит: обновления от агента" ]; then
    CHANGED_FILES=$(git diff --cached --name-only)
    
    if [ -n "$CHANGED_FILES" ]; then
        FILE_COUNT=$(echo "$CHANGED_FILES" | wc -l | tr -d ' ')
        
        # Определяем тип изменений
        ACTION="Обновление"
        if echo "$CHANGED_FILES" | grep -q "\.md$"; then
            ACTION="Документация"
        elif echo "$CHANGED_FILES" | grep -q "\.\(yaml\|yml\)$"; then
            ACTION="API спецификация"
        elif echo "$CHANGED_FILES" | grep -q "\.\(go\|java\|js\|ts\|py\)$"; then
            ACTION="Реализация"
        elif echo "$CHANGED_FILES" | grep -q "rules\.mdc$"; then
            ACTION="Обновление правил"
        fi
        
        COMMIT_MESSAGE="$ACTION: изменения в файлах ($FILE_COUNT файлов)"
    fi
fi

# Делаем коммит
echo "Создание коммита: $COMMIT_MESSAGE"
if ! git commit -m "$COMMIT_MESSAGE"; then
    echo "Ошибка при создании коммита" >&2
    exit 1
fi

echo "Коммит создан успешно"

# Отправляем изменения
echo "Отправка изменений в GitHub..."
if ! git push origin main; then
    echo "Предупреждение: Не удалось отправить изменения" >&2
    echo "Изменения закоммичены локально, но не отправлены" >&2
    exit 1
fi

echo "Изменения успешно отправлены в GitHub"
exit 0

