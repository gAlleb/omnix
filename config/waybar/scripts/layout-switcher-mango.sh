#!/bin/bash

# Функция для преобразования вывода mmsg в короткий формат
format_layout() {
    # Здесь мы ловим то, что выдает mmsg. 
    # Обычно это "English (US)" или "Russian". 
    # Если вывод другой, подправь строки в case.
    case "$1" in
        *"Russian"*) echo "RU" ;;
        *"English"*) echo "US" ;;
        *) echo "$1" ;; # Если не совпало, выведет как есть
    esac
}

# 1. Выводим начальное состояние при запуске
current=$(mmsg get keyboardlayout)
echo "{\"text\": \"$(format_layout "$current")\"}"

# 2. Слушаем изменения в реальном времени
mmsg watch keyboardlayout | while read -r layout; do
    echo "{\"text\": \"$(format_layout "$layout")\"}"
done
