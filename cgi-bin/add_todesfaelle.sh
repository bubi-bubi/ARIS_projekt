#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
echo "Content-type: text/html; charset=UTF-8"
echo ""

# Daten einlesen
read -n $CONTENT_LENGTH POSTDATA

# Funktion um POST-Parameter zu extrahieren
getVal() {
    echo "$POSTDATA" | sed -n "s/.*$1=\([^&]*\).*/\1/p" | sed 's/%20/ /g'
}

jahr=$(getVal "Jahr")
monat=$(getVal "Monat")
woche=$(getVal "Woche")
wochenstart=$(getVal "Todesdatum")
f0_64=$(getVal "Frauen bis 64")
f65=$(getVal "Frauen ab 65")
m0_64=$(getVal "Männer bis 64")
m65=$(getVal "Männer ab 65")

dataset="/var/www/html/data/todesfälle_final.csv"
tmpfile=$(mktemp)

#DAS FUNKTIONIERT NOCH NICHT!! ES WERDEN KEINE NEUEN DATEN HINZUGEFÜGT!

# Prüfen ob Datensatz existiert & zwar so dass es mit x oder 0x geht und keine neue Zeile gemacht wird
jahr=$(date -d "$wochenstart" +%Y)
monat=$(date -d "$wochenstart" +%m)
woche=$(date -d "$wochenstart" +%V)

existing=$(awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
    'NR>1 && $1==j && $2==m && $3==w {print; exit}' "$dataset")

if [ -z "$existing" ]; then
    # Neue KW → einfach neue Zeile anhängen
    echo "$jahr;$monat;$woche;$wochenstart;$f0_64;$f65;$m0_64;$m65;$total" >> "$dataset"
    echo "<h3>Neuer Eintrag hinzugefügt.</h3>"
else
    # KW existiert → Werte addieren
    IFS=";" read -r ej em ew ews ef0 ef65 em0 em65 et <<< "$existing"

    new_f0=$((ef0 + f0_64))
    new_f65=$((ef65 + f65))
    new_m0=$((em0 + m0_64))
    new_m65=$((em65 + m65))
    new_total=$((new_f0 + new_f65 + new_m0 + new_m65))

    # Alte Zeile ersetzen, Rest der Datei beibehalten
    awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" -v nf0="$new_f0" -v nf65="$new_f65" \
        -v nm0="$new_m0" -v nm65="$new_m65" -v nt="$new_total" -v nws="$wochenstart" '
        NR==1 {print; next}
        $1==j && $2==m && $3==w {
            print j ";" m ";" w ";" nws ";" nf0 ";" nf65 ";" nm0 ";" nm65 ";" nt
            next
        }
        {print}
    ' "$dataset" > "$tmpfile"

    mv "$tmpfile" "$dataset"
    echo "<h3>Bestehender Datensatz aktualisiert.</h3>"
fi

echo "<a href=\"/toderfassen.html\">Zurück</a>"
echo "<br>"
echo "<a href=\"/index.html\">Hauptseite</a>"



awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" '{
    if (NR==1) {print; next}   # Kopfzeile immer behalten
    if ($1==j && $2==m && $3==w) next
    print
}' "$dataset" > "$tmpfile"