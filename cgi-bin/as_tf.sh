#!/usr/bin/env bash
# CGI-Bash-Skript: as_tf.sh
# Nimmt HTML-POST-Daten entgegen und trägt Todesfälle in die CSV-Datenbank ein.
# Funktioniert zuverlässig im Terminal-Test.

set -euo pipefail
DB="/var/www/html/data/copy_todesfälle.csv"

# --- CGI HEADER ---
echo "Content-type: text/html"
echo ""

# --- POST-Daten zuverlässig einlesen ---
if [[ -n "${CONTENT_LENGTH:-}" ]] && [[ "$CONTENT_LENGTH" -gt 0 ]]; then
    read -r -n "$CONTENT_LENGTH" POSTDATA || POSTDATA=""
else
    POSTDATA=$(cat)
fi

# Debug-Ausgabe ins Apache-Error-Log / Terminal
echo "DEBUG: Postdaten: $POSTDATA" >&2
echo "DEBUG: DB-Pfad: $DB" >&2

# --- Funktion: Feld aus POST extrahieren ---
get_field() {
    echo "$POSTDATA" | tr '&' '\n' | grep "^$1=" | cut -d'=' -f2 | \
    sed -e 's/%3A/:/g' -e 's/%2F/\//g' -e 's/%2D/-/g' -e 's/+/ /g' \
        -e 's/%C3%A4/ä/g' -e 's/%C3%B6/ö/g' -e 's/%C3%BC/ü/g' -e 's/%C3%9F/ß/g'
}

# --- Felder auslesen ---
JAHR=$(get_field jahr)
MONAT_RAW=$(get_field monat)
WOCHE_RAW=$(get_field woche)
TODESDATUM=$(get_field todesdatum)
F0=$(get_field f0_64)
M0=$(get_field m0_64)
F65=$(get_field f65)
M65=$(get_field m65)

# --- Monatsnamen in Zahlen umwandeln ---
case "${MONAT_RAW,,}" in
    januar) MONAT=1;;
    februar) MONAT=2;;
    märz|maerz) MONAT=3;;
    april) MONAT=4;;
    mai) MONAT=5;;
    juni) MONAT=6;;
    juli) MONAT=7;;
    august) MONAT=8;;
    september) MONAT=9;;
    oktober) MONAT=10;;
    november) MONAT=11;;
    dezember) MONAT=12;;
    *) MONAT=${MONAT_RAW#0};;
esac

# Woche normalisieren (01 → 1)
WOCHE=${WOCHE_RAW#0}

# --- ISO-Woche und Wochenstart berechnen ---
ISO_WOCHE=$(date -d "$TODESDATUM" +"%V")
ISO_WOCHE=${ISO_WOCHE#0}
ISO_JAHR=$(date -d "$TODESDATUM" +"%G")
ISO_MONTAG=$(date -d "$TODESDATUM -$(($(date -d "$TODESDATUM" +%u) - 1)) days" +%Y-%m-%d)

# --- CSV anlegen, falls nicht vorhanden ---
if [[ ! -f "$DB" ]]; then
    echo "Jahr;Monat;Woche;Wochenstart;Frauen 0-64;Frauen 65+;Männer 0-64;Männer 65+;Total" > "$DB"
fi

# --- Prüfen, ob Zeile für diese Woche existiert ---
LINE=$(grep "^$ISO_JAHR;$MONAT;$ISO_WOCHE;" "$DB" || true)

if [[ -n "$LINE" ]]; then
    # Alte Werte extrahieren und addieren
    OLD_F0=$(echo "$LINE" | cut -d';' -f5)
    OLD_F65=$(echo "$LINE" | cut -d';' -f6)
    OLD_M0=$(echo "$LINE" | cut -d';' -f7)
    OLD_M65=$(echo "$LINE" | cut -d';' -f8)

    NEW_F0=$((OLD_F0 + F0))
    NEW_F65=$((OLD_F65 + F65))
    NEW_M0=$((OLD_M0 + M0))
    NEW_M65=$((OLD_M65 + M65))
    NEW_TOTAL=$((NEW_F0 + NEW_F65 + NEW_M0 + NEW_M65))

    # Alte Zeile löschen
    grep -v "^$ISO_JAHR;$MONAT;$ISO_WOCHE;" "$DB" > /tmp/tmpfile && mv /tmp/tmpfile "$DB"

else
    NEW_F0=$F0
    NEW_F65=$F65
    NEW_M0=$M0
    NEW_M65=$M65
    NEW_TOTAL=$((F0 + F65 + M0 + M65))
fi

# --- Neue Zeile zusammenstellen ---
NEUEZEILE="$ISO_JAHR;$MONAT;$ISO_WOCHE;$ISO_MONTAG;$NEW_F0;$NEW_F65;$NEW_M0;$NEW_M65;$NEW_TOTAL"

# --- Kopfzeile speichern ---
KOPF=$(head -n1 "$DB")

# --- Zeile hinzufügen + CSV sortieren (neueste oben) ---
{
    echo "$KOPF"
    echo "$NEUEZEILE"
    tail -n +2 "$DB"
} | sort -t';' -k1,1nr -k2,2n -k3,3n > /tmp/tmpfile && mv /tmp/tmpfile "$DB"

# --- HTML-Ausgabe ---
echo "<html><body>"
echo "<h2>Aktualisierte Todesfall-Liste</h2>"
echo "<table class='anzeige-table'>"

# Kopfzeile
IFS=';' read -r A B C D E F G H I <<< "$KOPF"
echo "<tr><th>$A</th><th>$B</th><th>$C</th><th>$D</th><th>$E</th><th>$F</th><th>$G</th><th>$H</th><th>$I</th></tr>"

# Datenzeilen
tail -n +2 "$DB" | while IFS=';' read -r a b c d e f g h i; do
    echo "<tr><td>$a</td><td>$b</td><td>$c</td><td>$d</td><td>$e</td><td>$f</td><td>$g</td><td>$h</td><td>$i</td></tr>"
done

echo "</table>"
echo "</body></html>"