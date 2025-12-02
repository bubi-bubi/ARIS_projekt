#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Content-type: text/html; charset=UTF-8"
echo ""

# Pfad zur CSV-Datei
DATEI_PFAD="../data/encoded-todesfälle.csv"

# Paginierung
PER_PAGE=20
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# Filter auslesen
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)

# HTML Header
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# Tabelle
echo "<table class=\"anzeige-table\" border='1' cellpadding='6' cellspacing='0'>"

# Kopfzeile
head -n 1 "$DATEI_PFAD" | awk -F';' -v filter="$FILTER" '{
    print "<tr>";
    if (filter=="frauen") {
        print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Wochenstart</th><th>Frauen gesamt</th><th>Total</th>"
    } else if (filter=="maenner") {
        print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Wochenstart</th><th>Männer gesamt</th><th>Total</th>"
    } else {
        for(i=1;i<=NF;i++) print "<th>" $i "</th>";
    }
    print "</tr>"
}'

# Datenzeilen
tail -n +2 "$DATEI_PFAD" | sed -n "${START},${END}p" | \
awk -F';' -v filter="$FILTER" '{
    if(filter=="frauen") {
        sum=$5+$6; # Frauen 0-64 + 65+
        print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"sum"</td><td>"$9"</td></tr>"
    } else if(filter=="maenner") {
        sum=$7+$8; # Männer 0-64 + 65+
        print "<tr><td>"$1"</td><td>"$2"</td><td>"$3"</td><td>"$4"</td><td>"sum"</td><td>"$9"</td></tr>"
    } else {
        print "<tr>";
        for(i=1;i<=NF;i++) print "<td>" $i "</td>";
        print "</tr>"
    }
}'

echo "</table>"

# Paginierung
TOTAL_LINES=$(wc -l < "$DATEI_PFAD")
DATA_LINES=$((TOTAL_LINES-1))
TOTAL_PAGES=$(( (DATA_LINES + PER_PAGE - 1) / PER_PAGE ))

echo "<div style='margin-top:20px;'>"
echo "<p>Seiten: "
for i in $(seq 1 $TOTAL_PAGES); do
    if [ "$i" -eq "$PAGE" ]; then
        echo "<strong>$i</strong> "
    else
        if [ -n "$FILTER" ]; then
            echo "<a href='test1.sh?page=$i&filter=$FILTER'>$i</a> "
        else
            echo "<a href='test1.sh?page=$i'>$i</a> "
        fi
    fi
done
echo "</p>"
echo "</div>"

# Footer
echo "<section><p>Zurück zur <a href=\"../scripts/testindex.html\">Hauptseite</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"
