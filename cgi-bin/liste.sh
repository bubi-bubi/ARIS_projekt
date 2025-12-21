#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Pfad zur CSV-Datei
DATEI_PFAD="../data/tf.csv"

# Parameter festlegen
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}

FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^jahr=' | cut -d'=' -f2)

ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2 | tr 'A-Z' 'a-z')

PER_PAGE=20

# Filterung der Liste
FILTERED_DATA=$(awk -F';' -v filter="$FILTER" -v year="$YEAR" '
NR>1 {
    if(year!="" && $1!=year) next
    if(filter=="frauen") {
        sum=$5+$6
        print $1 ";" $2 ";" $3 ";" $4 ";" sum
    } else if(filter=="maenner") {
        sum=$7+$8
        print $1 ";" $2 ";" $3 ";" $4 ";" sum
    } else {
        print $0
    }
}' "$DATEI_PFAD")

# Sortierung der Liste (numerisch, absteigend nach Jahr
FILTERED_DATA=$(echo "$FILTERED_DATA" | sort -t';' -k1,1nr)

# Paginierung
TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# GNU-Plot
# Filter lesen
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)

# Action: anzeigen oder plot
ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2 | tr 'A-Z' 'a-z')

# PLOT KLICKEN
if [ "$ACTION" = "visualisierung" ]; then

    # Gnuplot-Daten vorbereiten
    # x = NR, y = Total / Summe Frauen / Summe Männer
    if [ "$FILTER" = "frauen" ] || [ "$FILTER" = "maenner" ]; then
        echo "$FILTERED_DATA" | awk -F';' '{print NR, $5}' > /tmp/plot_data.txt
    else
        echo "$FILTERED_DATA" | awk -F';' '{print NR, $NF}' > /tmp/plot_data.txt
    fi

    # Erstes und letztes Datum
    X1=$(head -n 1 /tmp/plot_data.txt | awk '{print $1}')
    LABEL1=$(echo "$FILTERED_DATA" | head -n 1 | awk -F';' '{print $4}')

    X2=$(wc -l < /tmp/plot_data.txt)
    LABEL2=$(echo "$FILTERED_DATA" | tail -n 1 | awk -F';' '{print $4}')

    TMP_PNG=$(mktemp /tmp/plotXXXXXX.png)

# Filtertext
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

#Gestaltung Gnuplot
gnuplot <<EOF
set term pngcairo size 900,600
set output "$TMP_PNG"

set title "Todesfälle Freiburg – $FILTER_TEXT – $YEAR_TEXT"
set xlabel "Zeitraum" offset 0,3
set ylabel "Anzahl Todesfälle"
set grid

set xtics rotate by 90 right
set xtics ("$LABEL1" $X1, "$LABEL2" $X2)

plot "/tmp/plot_data.txt" using 1:2 with lines lw 2 lc rgb "#0066cc" title "Anzahl"
EOF

    echo "Content-Type: image/png"
    echo ""
    cat "$TMP_PNG"

    rm "$TMP_PNG"
    rm /tmp/plot_data.txt

    exit 0  
fi

# HTML-Header
echo "Content-type: text/html; charset=UTF-8"
echo ""
echo "<html><head>"
echo '<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;600;700&display=swap" rel="stylesheet">'
echo '<link rel="stylesheet" href="../css/style.css">'
echo "<title>Todesfälle Freiburg</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# ---------------------- Tabelle ----------------------
echo "<table class=\"anzeige-table\" border='1' cellpadding='6' cellspacing='0'>"

# Tabellenkopf
head -n 1 "$DATEI_PFAD" | awk -F';' -v filter="$FILTER" '{
    print "<tr>";
    if(filter=="frauen") {
        print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Frauen gesamt</th><th>Total</th>"
    } else if(filter=="maenner") {
        print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Männer gesamt</th><th>Total</th>"
    } else {
        for(i=1;i<=NF;i++) print "<th>" $i "</th>";
    }
    print "</tr>"
}'

# Tabellenzeilen mit Paginierung
echo "$FILTERED_DATA" | awk -F';' -v start=$START -v end=$END '{
    row_num=NR
    if(row_num>=start && row_num<=end){
        print "<tr>"
        for(i=1;i<=NF;i++) print "<td>" $i "</td>"
        print "</tr>"
    }
}'

echo "</table>"

# ---------------------- Paginierung Links ----------------------
if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'>"

    LINK_BASE="test1.sh"
    PARAMS=()
    [ -n "$FILTER" ] && PARAMS+=("filter=$FILTER")
    [ -n "$YEAR" ] && PARAMS+=("jahr=$YEAR")

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

# ---------------------- Footer ----------------------
echo "<section><p>Zurück zur <a href=\"../index.html\">Auswahl</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"