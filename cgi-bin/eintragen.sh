#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Content-type: text/html; charset=UTF-8"
echo ""

# Pfad zur CSV-Datei
dataset="/var/www/html/data/tf.csv"
tmpfile=$(mktemp)

# POST-Daten auslesen
POSTDATA=$(cat)

# Funktion zum Auslesen der POST-Parameter
getVal() {
    echo "$POSTDATA" | sed -n "s/.*$1=\([^&]*\).*/\1/p" \
    | sed 's/%20/ /g; s/%C3%A4/ä/g; s/%C3%B6/ö/g; s/%C3%BC/ü/g'
}

# Todesdatum vom Formular
todesdatum=$(getVal "todesdatum")

# Jahr, Monat, Woche berechnen (ohne führende Null)
jahr=$(date -d "$todesdatum" +%Y)
monat=$(date -d "$todesdatum" +%-m)   # 1-12 ohne führende Null
woche=$(date -d "$todesdatum" +%-V)   # 1-53 ohne führende Null

# Zahlen aus dem Formular
f0_64=$(getVal "f0_64")
m0_64=$(getVal "m0_64")
f65=$(getVal "f65")
m65=$(getVal "m65")
total=$((f0_64 + m0_64 + f65 + m65))

# Prüfen, ob Eintrag für Jahr/Monat/Woche bereits existiert
existing=$(awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
 'NR>1 && $1==j && $2==m && $3==w {print; exit}' "$dataset")

echo "<!DOCTYPE html>"
echo "<html lang='de'>"
echo "<head><meta charset='UTF-8'><title>Todesfälle – Eintrag</title></head>"
echo "<body>"
echo "<h2 style='text-align:center;'>Todesfälle – Eintrag</h2>"

if [ -z "$existing" ]; then
    # Neuer Eintrag
    printf "%s;%d;%d;%d;%d;%d;%d;%d\n" "$jahr" "$monat" "$woche" "$f0_64" "$f65" "$m0_64" "$m65" "$total" >> "$dataset"
    echo "<p style='text-align:center; color:green;'>Neuer Eintrag wurde hinzugefügt.</p>"
else
    # Update bestehender Eintrag
    IFS=";" read -r ej em ew ef0 ef65 em0 em65 et <<< "$existing"

    # Additionen (führende Null ignorieren)
    new_f0=$((10#$ef0 + 10#$f0_64))
    new_f65=$((10#$ef65 + 10#$f65))
    new_m0=$((10#$em0 + 10#$m0_64))
    new_m65=$((10#$em65 + 10#$m65))
    new_total=$((new_f0 + new_f65 + new_m0 + new_m65))

    awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
        -v nf0="$new_f0" -v nf65="$new_f65" \
        -v nm0="$new_m0" -v nm65="$new_m65" \
        -v nt="$new_total" \
    'NR==1 {print; next}
    $1==j && $2==m && $3==w {
        printf "%s;%d;%d;%d;%d;%d;%d;%d\n", j, m, w, nf0, nf65, nm0, nm65, nt
        next
    }
    {print}' "$dataset" > "$tmpfile"

    mv "$tmpfile" "$dataset"

    echo "<p style='text-align:center; color:blue;'>Bestehender Eintrag wurde aktualisiert.</p>"
fi

echo "<div style='text-align:center; margin-top:20px;'>"
echo "<a href='/formular.html'>Weiterer Todesfall erfassen</a> | "
echo "<a href='/cgi-bin/liste.sh'>Tabelle anzeigen</a>"
echo "</div>"

echo "</body></html>"
