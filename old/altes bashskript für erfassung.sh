
existing=$(awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
    'NR>1 && $1==j && $2==m && $3==w {print $0}' "$dataset")

if [ -z "$existing" ]; then
    # Neuer Eintrag
    total=$((f0_64 + f65 + m0_64 + m65))
    echo "$jahr;$monat;$woche;$wochenstart;$f0_64;$f65;$m0_64;$m65;$total" >> "$dataset"

    echo "<h3>Neuer Datensatz hinzugefügt.</h3>"
else
    # Alten Datensatz aktualisieren
    IFS=";" read -r ej em ew ews ef0 ef65 em0 em65 et <<< "$existing"

    new_f0=$((ef0 + f0_64))
    new_f65=$((ef65 + f65))
    new_m0=$((em0 + m0_64))
    new_m65=$((em65 + m65))
    new_total=$((new_f0 + new_f65 + new_m0 + new_m65))

    # Datei aktualisieren
    grep -v "^$jahr;$monat;$woche;" "$dataset" > "$tmpfile"
    awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" '{
        if (NR==1) {print; next}   # Kopfzeile immer behalten
        if ($1==j && $2==m && $3==w) next
        print
    }' "$dataset" > "$tmpfile"
    echo "$jahr;$monat;$woche;$wochenstart;$new_f0;$new_f65;$new_m0;$new_m65;$new_total" >> "$tmpfile"
    mv "$tmpfile" "$dataset"

    echo "<h3>Bestehender Datensatz aktualisiert.</h3>"
fi
