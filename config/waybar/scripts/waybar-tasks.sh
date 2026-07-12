#!/usr/bin/env bash

# Путь к вашей папке с заметками
VAULT_DIR="$HOME/Notes/01 - diary"

# Проверяем, установлены ли необходимые утилиты
if ! command -v rg &> /dev/null || ! command -v jq &> /dev/null; then
    echo '{"text": "err", "tooltip": "Требуются утилиты rg (ripgrep) и jq", "class": "error"}'
    exit 1
fi

# Находим все незакрытые задачи
raw_list=$(rg --no-heading -g '*.md' '^\s*-\s*\[ \]' "$VAULT_DIR" 2>/dev/null)

# Если задач нет
if [ -z "$raw_list" ]; then
    echo '{"text": "0", "tooltip": "Нет активных задач 🎉", "class": "empty"}'
    exit 0
fi

# Считаем количество найденных задач
count=$(echo "$raw_list" | wc -l)

# 1. Сортируем список по путям (имена файлов с датами автоматически встанут по порядку)
sorted_list=$(echo "$raw_list" | sort)

# 2. Очищаем и форматируем:
#    - Сначала удаляем все блоки метаданных вида [ключ:: значение]
#    - Затем превращаем путь в красивую дату с Pango-разметкой (синий цвет и жирный шрифт)
#    - Вы можете заменить цвет #81a1c1 на любой другой HEX-код под вашу тему
tooltip_content=$(echo "$sorted_list" | \
    sed -E \
    -e 's|\s*\[[^]]+::[^]]+\]||g' \
    -e 's|.*/([^/]+)\.md:\s*-\s*\[ \]\s*(.*)|<span color="#81a1c1"><b>\1</b></span>  │  \2|')

# Формируем компактный JSON-вывод
jq -cn \
    --arg count "$count" \
    --arg tooltip "$tooltip_content" \
    --arg class "active" \
    '{"text": $count, "tooltip": $tooltip, "class": $class}'
