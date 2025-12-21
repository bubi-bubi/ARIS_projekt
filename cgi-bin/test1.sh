#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# CGI Header
echo "Content-type: text/html; charset=UTF-8"
echo ""

# Pfad zur CSV-Datei
DATEI_PFAD="../data/tf.csv"

# ---------------------- Parameter ----------------------
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}

FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^jahr=' | cut -d'=' -f2)

ACTION=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^action=' | cut -d'=' -f2 | tr 'A-Z' 'a-z')

PER_PAGE=20

# ---------------------- Filterung ----------------------
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

# ---------------------- Sortierung ----------------------
# Sortiere nach Jahr (erste Spalte) absteigend
FILTERED_DATA=$(echo "$FILTERED_DATA" | sort -t';' -k1,1nr)

# ---------------------- Paginierung ----------------------
TOTAL_LINES=$(echo "$FILTERED_DATA" | wc -l)
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# ---------------------- HTML Header ----------------------
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