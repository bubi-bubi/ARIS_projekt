#!/bin/bash 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

DATEI_PFAD="../data/encoded-todesfälle.csv"
#es muss noch die Paginierung ermöglicht werden!

echo "Content-type: text/html; charset=UTF-8"
echo ""
#TEST FÜR PAGINIERUNG----------------------------
#konfiguration
DATEI_PFAD="../data/encoded-todesfälle.csv"
PER_PAGE=20
# GET-Parameter auslesen (z. B. ?page=2)
PAGE=$(echo "$QUERY_STRING" | sed -n 's/^page=\([0-9]*\)$/\1/p')
PAGE=${PAGE:-1}  # Standard: Seite 1
# Berechne Start- und Endzeile
START=$(( (PAGE-1)*PER_PAGE + 1 ))  # erste Zeile für diese Seite
END=$(( START + PER_PAGE - 1 ))
#TEST FÜR PAGINIERUNG----------------------------

echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle </title>"
echo "</head>"
echo "<body>"
echo "<header> <h1>Todesfälle</h1> </header>"

#TEST FÜR PAGINIERUNG----------------------------
# Kopfzeile der CSV anzeigen
head -n 1 "$DATEI_PFAD" | while read line; do
    echo "<p><strong>$line</strong></p>"
done

# Daten für die aktuelle Seite anzeigen
tail -n +2 "$DATEI_PFAD" | sed -n "${START},${END}p" | while read line; do
    echo "<p>$line</p>"
done

# Paging-Links
TOTAL_LINES=$(wc -l < "$DATEI_PFAD")
DATA_LINES=$((TOTAL_LINES-1))  # ohne Kopfzeile
TOTAL_PAGES=$(( (DATA_LINES + PER_PAGE - 1)/PER_PAGE ))

echo "<p>Seiten: "
for i in $(seq 1 $TOTAL_PAGES); do
    if [ "$i" -eq "$PAGE" ]; then
        echo "<strong>$i</strong> "
    else
        echo "<a href='anzeigen.sh?page=$i'>$i</a> "
    fi
done
echo "</p>"
#TEST FÜR PAGINIERUNG----------------------------

#echo "<section>"
#echo "<p>"
#cat "$DATEI_PFAD" | sed 's/$/<br>/'
#echo "</p></section>"
echo "<section><p>Zurück zur <a href=\"../index.html\">Haupseite.</a></p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p> </footer>"
echo "</body></html>"