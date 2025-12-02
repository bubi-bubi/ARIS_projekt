#!/bin/bash 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
echo "Content-type: text/html; charset=UTF-8"
echo ""

DATEI_PFAD="../data/encoded-todesfälle.csv"

# Paginierung
PER_PAGE=20
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# HTML HEADER
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle</h1></header>"

# CSV als Tabelle
echo "<table class=\"anzeige-table\" border='1' cellpadding='6' cellspacing='0'>"

# Kopfzeile (Header)
head -n 1 "$DATEI_PFAD" | awk -F';' '{
    print "<tr>";
    for(i=1;i<=NF;i++) print "<th>" $i "</th>";
    print "</tr>";
}'

# Datenzeilen
FILTERED_DATA=$(tail -n +2 "$DATEI_PFAD")  # keine Filter, einfach alle Daten

echo "$FILTERED_DATA" | awk -F';' -v start=$START -v end=$END '{
    row_num=NR
    if(row_num>=start && row_num<=end){
        print "<tr>";
        for(i=1;i<=NF;i++) print "<td>" $i "</td>";
        print "</tr>"
    }
}'

echo "</table>"

# Paginierung Back / Next
TOTAL_LINES=$(wc -l < "$DATEI_PFAD")
DATA_LINES=$((TOTAL_LINES-1))
TOTAL_PAGES=$(( (DATA_LINES + PER_PAGE - 1) / PER_PAGE ))

if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'>"

    # Back-Button
    if [ "$PAGE" -gt 1 ]; then
        PREV=$((PAGE-1))
        echo "<a href='anzeigen.sh?page=$PREV'>Back</a> "
    fi

    # Aktuelle Seite
    echo "<strong>$PAGE</strong>"

    # Next-Button
    if [ "$PAGE" -lt "$TOTAL_PAGES" ]; then
        NEXT=$((PAGE+1))
        echo " <a href='anzeigen.sh?page=$NEXT'>Next</a>"
    fi

    echo "</div>"
fi

# Footer
echo "<section><p>Zurück zur <a href=\"../index.html\">Hauptseite</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"