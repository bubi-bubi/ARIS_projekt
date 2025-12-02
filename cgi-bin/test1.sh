#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Parameter aus QUERY_STRING auslesen
QUERY_STRING="${QUERY_STRING:-$1}"

FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}
PLOT=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^plot=' | cut -d'=' -f2)

DATEI_PFAD="../data/encoded-todesfälle.csv"

# Filterte Daten vorbereiten (wie vorher, evtl. anpassen)

FILTERED_DATA=$(awk -F';' -v filter="$FILTER" -v year="$YEAR" '
NR>1 {
    if(year!="" && $1!=year) next
    if(filter=="frauen") {
        sum=$5+$6
        print $1 ";" $2 ";" $3 ";" $4 ";" sum ";" $9
    } else if(filter=="maenner") {
        sum=$7+$8
        print $1 ";" $2 ";" $3 ";" $4 ";" sum ";" $9
    } else {
        print $0
    }
}' "$DATEI_PFAD")

# Wenn Plot angefordert, Bild erzeugen und direkt ausgeben:
if [ "$PLOT" == "1" ]; then
    # Temporäre Datei für Plot-Daten
    PLOT_DATA_FILE="/tmp/plot_data.txt"

    echo "$FILTERED_DATA" > "$PLOT_DATA_FILE"

    # Beispiel: Plot erzeugen (anpassen nach Wunsch)
    gnuplot <<EOF
set terminal png size 800,600
set output '../data/plot.png'
set title "Todesfälle Freiburg - Filter: ${FILTER:-Alle}, Jahr: ${YEAR:-Alle}"
set xlabel "Datenpunkte (Index)"
set ylabel "Anzahl"
set grid
plot '$PLOT_DATA_FILE' using 0:5 with lines title 'Gefilterte Werte'
EOF

    # Bild direkt ausgeben
    echo "Content-type: image/png"
    echo ""
    cat ../data/plot.png

    # Link zurück kann hier nicht als HTML ausgegeben werden,
    # da es reines PNG ist. Der Browser zeigt nur das Bild an.
    # Nutzer muss per Browser-Back zurück oder URL neu eingeben.

    exit 0
fi

# --------- Rest: Ausgabe der HTML-Tabelle (wie gehabt) -----------

# HTML-Header, Tabelle, Paginierung, Footer ... (dein bestehender Code)
# ...


# ---------------------------
# Tabelle anzeigen (wie bisher)
# ---------------------------
echo "<table class=\"anzeige-table\" border='1' cellpadding='6' cellspacing='0'>"
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

# Anzahl gefilterte Zeilen
TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# Ausgabe Datenzeilen
echo "$FILTERED_DATA" | awk -F';' -v start=$START -v end=$END '{
    row_num=NR
    if(row_num>=start && row_num<=end){
        print "<tr>";
        for(i=1;i<=NF;i++) print "<td>" $i "</td>";
        print "</tr>"
    }
}'

echo "</table>"

# Paging: Back / Next
if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'>"

    LINK_BASE="test1.sh"
    PARAMS=()
    [ -n "$FILTER" ] && PARAMS+=("filter=$FILTER")
    [ -n "$YEAR" ] && PARAMS+=("year=$YEAR")
    build_link() {
        local page=$1
        local link="$LINK_BASE"
        if [ ${#PARAMS[@]} -gt 0 ]; then
            link="${link}?$(IFS='&'; echo "${PARAMS[*]}")&page=$page"
        else
            link="${link}?page=$page"
        fi
        echo "$link"
    }

    if [ "$PAGE" -gt 1 ]; then
        PREV=$((PAGE-1))
        echo "<a href='$(build_link $PREV)'>Back</a> "
    fi

    echo "<strong>$PAGE</strong>"

    if [ "$PAGE" -lt "$TOTAL_PAGES" ]; then
        NEXT=$((PAGE+1))
        echo " <a href='$(build_link $NEXT)'>Next</a>"
    fi

    echo "</div>"
fi

# Footer
echo "<section><p>Zurück zur <a href=\"../testindex.html\">Auswahl</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"