#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Pfad zur CSV-Datei
DATEI_PFAD="../data/encoded-todesfälle.csv"

# Query-Parameter einlesen
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}

FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)
ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2)

# Gefilterte Daten vorbereiten
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

#############################################
#   PLOT – wenn der Benutzer "Plot" klickt  #
#############################################
if [ "$ACTION" = "Plot" ]; then

    # Daten für gnuplot vorbereiten → Spalte Total als y-Wert
    echo "$FILTERED_DATA" | awk -F';' '{print NR, $NF}' > /tmp/plot_data.txt

    TMP_PNG=$(mktemp /tmp/plotXXXXXX.png)

gnuplot <<EOF
set term pngcairo size 900,600
set output "$TMP_PNG"
set title "Todesfälle Freiburg (gefiltert)"
set xlabel "Datenpunkte"
set ylabel "Total"
set grid
plot "/tmp/plot_data.txt" using 1:2 with lines lw 2 lc rgb "#0066cc" title "Total"
EOF

    echo "Content-Type: image/png"
    echo ""
    cat "$TMP_PNG"
    rm "$TMP_PNG"
    rm /tmp/plot_data.txt
    exit 0
fi

#############################################
#   NORMALE HTML-AUSGABE (Anzeigen)         #
#############################################

echo "Content-type: text/html; charset=UTF-8"
echo ""

# Paginierung
PER_PAGE=20
TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# HTML Header
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# Tabelle Header
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

# Daten anzeigen
echo "$FILTERED_DATA" | awk -F';' -v start=$START -v end=$END '{
    row_num=NR
    if(row_num>=start && row_num<=end){
        print "<tr>";
        for(i=1;i<=NF;i++) print "<td>" $i "</td>";
        print "</tr>"
    }
}'

echo "</table>"

# Paging
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

echo "<section><p>Zurück zur <a href=\"../testindex.html\">Auswahl</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"