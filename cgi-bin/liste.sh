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

# Sortierung der Liste (numerisch, absteigend nach Jahr)
FILTERED_DATA=$(echo "$FILTERED_DATA" | sort -t';' -k1,1nr -k2,2nr -k3,3nr)

# Paginierung
TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# Action: anzeigen oder plot
ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2 | tr 'A-Z' 'a-z')

# PLOT KLICKEN
if [ "$ACTION" = "visualisierung" ]; then

    # Aufsteigende Sortierung fürs Plotten nach Jahr, Monat, Woche
    PLOT_DATA_SORTED=$(echo "$FILTERED_DATA" | sort -t';' -k1,1n -k2,2n -k3,3n)

    # Gnuplot-Daten vorbereiten
    # x = NR, y = Total / Summe Frauen / Summe Männer
    if [ "$FILTER" = "frauen" ] || [ "$FILTER" = "maenner" ]; then
        echo "$PLOT_DATA_SORTED" | awk -F';' '{print NR, $5}' > /tmp/plot_data.txt
    else
        echo "$PLOT_DATA_SORTED" | awk -F';' '{print NR, $NF}' > /tmp/plot_data.txt
    fi

    # Erstes und letztes Datum (Monat + Jahr) für X-Achse
    X1=1
    X2=$(wc -l < /tmp/plot_data.txt)

    # Sicherstellen, dass $1 = Jahr, $2 = Monat
    LABEL1=$(echo "$PLOT_DATA_SORTED" | head -n1 | awk -F';' '{printf "%d-%d",$1+0,$2+0}')
    LABEL2=$(echo "$PLOT_DATA_SORTED" | tail -n1 | awk -F';' '{printf "%d-%d",$1+0,$2+0}')

    TMP_PNG=$(mktemp /tmp/plotXXXXXX.png)

    # Filtertext für den Titel
    if [ -z "$FILTER" ]; then
        FILTER_TEXT="Männer und Frauen"
    elif [ "$FILTER" = "frauen" ]; then
        FILTER_TEXT="Frauen"
    elif [ "$FILTER" = "maenner" ]; then
        FILTER_TEXT="Männer"
    else
        FILTER_TEXT="$FILTER"
    fi

    # Jahrestext für den Titel
    if [ -z "$YEAR" ]; then
        YEAR_TEXT="alle Jahre"
    else
        YEAR_TEXT="$YEAR"
    fi

    # Gnuplot-Block
    gnuplot <<EOF
set term pngcairo size 900,600
set output "$TMP_PNG"

set title "$FILTER_TEXT – $YEAR_TEXT"
set xlabel "Zeitraum"
set ylabel "Anzahl Todesfälle"
set grid

set xtics rotate by 90 right
set xtics ("$LABEL1" $X1, "$LABEL2" $X2)

plot "/tmp/plot_data.txt" using 1:2 with lines lw 2 lc rgb "#0066cc" title "Anzahl"
EOF

    # PNG in HTML einbetten
    echo "Content-Type: text/html; charset=UTF-8"
    echo ""
    echo "<html><head>"
    echo '<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@300;400;600;700&display=swap" rel="stylesheet">'
    echo '<link rel="stylesheet" href="../css/style.css">'
    echo "<title>Visualisierung</title>"
    echo "<header><h1>Todesfälle Freiburg</h1></header>"
    echo "</head><body class=\"anzeige\">"
    echo "<img src='data:image/png;base64,$(base64 "$TMP_PNG")' style='display:block; margin:40px auto; max-width:100%; height:auto;'>"
    # Footer
    echo "<section><p>Zurück zur <a href=\"../index.html\">Auswahl</a>.</p></section>"
    echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
    echo "</body></html>"

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
echo "<title>Todesfälle Freiburg Liste</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# Tabelle
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

# Paginierung-Links
if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'>"

    LINK_BASE="/cgi-bin/liste.sh"
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

# Footer
echo "<section><p>Zurück zur <a href=\"../index.html\">Auswahl</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"
