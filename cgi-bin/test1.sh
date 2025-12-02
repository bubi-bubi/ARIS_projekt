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

# Filter auslesen
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)
ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2)

# HTML Header
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# Gefilterte Daten
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

# ---------------------------
# Wenn Plot angefordert wurde
# ---------------------------
if [ "$ACTION" = "plot" ]; then
    TMP_PLOT="/tmp/plot_data.txt"
    echo "$FILTERED_DATA" | awk -F';' '{print NR, $5}' > "$TMP_PLOT"  # Spalte 5 = je nach Filter summe

    # Erstes und letztes Datum für X-Achse
    LABEL1=$(echo "$FILTERED_DATA" | head -n 1 | awk -F';' '{print $4}')  # Wochenstart
    LABEL2=$(echo "$FILTERED_DATA" | tail -n 1 | awk -F';' '{print $4}')  # Wochenstart
    X1=1
    X2=$(wc -l < "$TMP_PLOT")

    # Titel vorbereiten
    if [ -z "$FILTER" ]; then
        FILTER_TEXT="Alle"
    else
        FILTER_TEXT="$FILTER"
    fi

    if [ -z "$YEAR" ]; then
        YEAR_TEXT="alle Jahre"
    else
        YEAR_TEXT="$YEAR"
    fi

    # Plot-Datei speichern
    PLOT_FILE="../data/plot.png"

    gnuplot <<EOF
set term pngcairo size 900,600
set output "$PLOT_FILE"
set title "Todesfälle Freiburg – $FILTER_TEXT – $YEAR_TEXT"
set xlabel "Zeitraum"
set ylabel "Anzahl Todesfälle"
set grid
set xtics ("$LABEL1" $X1, "$LABEL2" $X2)
plot "$TMP_PLOT" using 1:2 with lines lw 2 lc rgb "#0066cc" title "Anzahl"
EOF

    # Plot auf der HTML-Seite anzeigen
    echo "<section>"
    echo "<img src='../data/plot.png' alt='Plot Todesfälle' style='max-width:90%;'>"
    echo "</section>"

    echo "<section><p>Zurück zur <a href=\"../testindex.html\">Auswahl</a>.</p></section>"
    echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
    echo "</body></html>"

    exit 0
fi

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