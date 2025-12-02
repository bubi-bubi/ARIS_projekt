#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

PER_PAGE=20

# Parameter aus QUERY_STRING auslesen
QUERY_STRING="${QUERY_STRING:-$1}"

FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}
PLOT=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^plot=' | cut -d'=' -f2)

DATEI_PFAD="../data/encoded-todesfälle.csv"

# Filtertext für Titel (optional, zur Anzeige)
filtertext="Alle"
if [ "$FILTER" = "frauen" ]; then
    filtertext="Frauen"
elif [ "$FILTER" = "maenner" ]; then
    filtertext="Männer"
fi
yeartext=${YEAR:-"Alle Jahre"}

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

# Funktion build_link außerhalb der if-Blöcke, für Paging
build_link() {
    local page=$1
    local link="test1.sh"
    local params=()
    [ -n "$FILTER" ] && params+=("filter=$FILTER")
    [ -n "$YEAR" ] && params+=("year=$YEAR")
    [ ${#params[@]} -gt 0 ] && link="${link}?$(IFS='&'; echo "${params[*]}")&page=$page" || link="${link}?page=$page"
    echo "$link"
}

# Plot-Ausgabe
if [ "$PLOT" == "1" ]; then
    # Temp Datei für Plot-Daten
    PLOT_DATA_FILE="/tmp/plot_data.txt"
    echo "$FILTERED_DATA" > "$PLOT_DATA_FILE"

    # Plot generieren (PNG-Datei)
    gnuplot <<EOF
set terminal png size 800,600
set output '/tmp/plot.png'
set title "Todesfälle Freiburg - Filter: $filtertext, Jahr: $yeartext"
set xlabel "Datenpunkte (Index)"
set ylabel "Anzahl"
set grid
plot '$PLOT_DATA_FILE' using 0:5 with lines title 'Gefilterte Werte'
EOF

    # Bild ausgeben (PNG)
    echo "Content-type: image/png"
    echo ""
    cat /tmp/plot.png

    exit 0
fi

# --- HTML-Ausgabe ---

echo "Content-type: text/html; charset=UTF-8"
echo ""

echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle - Filter: $filtertext, Jahr: $yeartext</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

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

TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

echo "$FILTERED_DATA" | awk -F';' -v start=$START -v end=$END '{
    row_num=NR
    if(row_num>=start && row_num<=end){
        print "<tr>";
        for(i=1;i<=NF;i++) print "<td>" $i "</td>";
        print "</tr>"
    }
}'

echo "</table>"

if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'>"

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
