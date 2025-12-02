#!/bin/bash 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Pfad zur CSV-Datei
DATEI_PFAD="../data/encoded-todesfälle.csv"

# Konfiguration
PER_PAGE=20

# GET-Parameter (page)
PAGE=$(echo "$QUERY_STRING" | sed -n 's/^page=\([0-9]*\)$/\1/p')
PAGE=${PAGE:-1}

# Berechnung der Zeilen
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# HTML HEADER
echo "Content-type: text/html; charset=UTF-8"
echo ""
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body>"
echo "<header><h1>Todesfälle</h1></header>"

##############################################
#           CSV ALS TABELLE
##############################################

echo "<table border='1' cellpadding='6' cellspacing='0'>"

# Kopfzeile (Header)
head -n 1 "$DATEI_PFAD" | awk -F';' '{
    print "<tr>";
    for(i=1;i<=NF;i++) print "<th>" $i "</th>";
    print "</tr>";
}'

# Datenzeilen
tail -n +2 "$DATEI_PFAD" | sed -n "${START},${END}p" | \
awk -F';' '{
    print "<tr>";
    for(i=1;i<=NF;i++) print "<td>" $i "</td>";
    print "</tr>";
}'

echo "</table>"

##############################################
#             PAGINIERUNG
##############################################

TOTAL_LINES=$(wc -l < "$DATEI_PFAD")
DATA_LINES=$((TOTAL_LINES-1))
TOTAL_PAGES=$(( (DATA_LINES + PER_PAGE - 1) / PER_PAGE ))

echo "<div style='margin-top:20px;'>"
echo "<p>Seiten: "

for i in $(seq 1 $TOTAL_PAGES); do
    if [ "$i" -eq "$PAGE" ]; then
        echo "<strong>$i</strong> "
    else
        echo "<a href='anzeigen.sh?page=$i'>$i</a> "
    fi
done

echo "</p>"
echo "</div>"

##############################################
#            FUSS / FOOTER
##############################################

echo "<section><p>Zurück zur <a href=\"../index.html\">Hauptseite</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"