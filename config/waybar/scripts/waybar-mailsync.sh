#!/usr/bin/env bash

MAILROOT="$HOME/.local/share/mail"
total=0
tooltip=""

for acct in "$MAILROOT"/*/; do
    [ -d "$acct" ] || continue
    name=$(basename "$acct")
    n_new=$(find "$acct" -type f -path '*/new/*' 2>/dev/null | wc -l)
    n_cur=$(find "$acct" -type f -path '*/cur/*' ! -name '*,*S*' 2>/dev/null | wc -l)
    unread=$((n_new + n_cur))
    total=$((total + unread))
    if [ "$unread" -gt 0 ]; then
        # накапливаем с литеральным \n (два символа), не реальным переносом
        [ -n "$tooltip" ] && tooltip="${tooltip}\\n"
        tooltip="${tooltip}${name}: ${unread}"
    fi
done

[ -z "$tooltip" ] && tooltip="Нет новых писем"

if [ "$total" -gt 0 ]; then
    printf '{"text":" %d","tooltip":"%s","class":"unread"}\n' "$total" "$tooltip"
else
    printf '{"text":"","tooltip":"%s","class":"empty"}\n' "$tooltip"
fi

