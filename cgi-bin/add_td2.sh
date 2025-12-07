#!/bin/bash

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Content-type: text/html; charset=UTF-8"
echo ""

POSTDATA=$(cat)

# Funktion zum Auslesen der POST-Parameter
getVal() {
    echo "$POSTDATA" | sed -n "s/.*$1=\([^&]*\).*/\1/p" \
    | sed 's/%20/ /g; s/%C3%A4/ä/g; s/%C3%B6/ö/g; s/%C3%BC/ü/g'
}

todesdatum=$(getVal "todesdatum")
f0_64=$(getVal "f0_64")
m0_64=$(getVal "m0_64")
f65=$(getVal "f65")
m65=$(getVal "m65")

jahr=$(date -d "$todesdatum" +%Y)
monat=$(date -d "$todesdatum" +%m)
woche=$(date -d "$todesdatum" +%V)

total=$((f0_64 + m0_64 + f65 + m65))

dataset="/var/www/html/data/copy_todesfaelle2.csv"
tmpfile=$(mktemp)

# Prüfen, ob Eintrag für Jahr/Monat/Woche existiert
existing=$(awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
 'NR>1 && $1==j && $2==m && $3==w {print; exit}' "$dataset")

if [ -z "$existing" ]; then
    echo "$jahr;$monat;$woche;$todesdatum;$f0_64;$f65;$m0_64;$m65;$total" >> "$dataset"
    echo "<h3>Neuer Eintrag hinzugefügt.</h3>"
else
    IFS=";" read -r ej em ew ed ef0 ef65 em0 em65 et <<< "$existing"

    new_f0=$((ef0 + f0_64))
    new_f65=$((ef65 + f65))
    new_m0=$((em0 + m0_64))
    new_m65=$((em65 + m65))
    new_total=$((new_f0 + new_f65 + new_m0 + new_m65))

    awk -F";" -v j="$jahr" -v m="$monat" -v w="$woche" \
        -v dd="$todesdatum" \
        -v nf0="$new_f0" -v nf65="$new_f65" \
        -v nm0="$new_m0" -v nm65="$new_m65" \
        -v nt="$new_total" \
    '
    NR==1 {print; next}
    $1==j && $2==m && $3==w {
        print j ";" m ";" w ";" dd ";" nf0 ";" nf65 ";" nm0 ";" nm65 ";" nt
        next
    }
    {print}
    ' "$dataset" > "$tmpfile"

    mv "$tmpfile" "$dataset"

    echo "<h3>Bestehender Datensatz aktualisiert.</h3>"
fi

echo "<a href=\"/testindex.html\">Zurück</a><br>"
echo "<a href=\"/cgi-bin/show_list.sh\">Neue Liste anzeigen</a><br>"