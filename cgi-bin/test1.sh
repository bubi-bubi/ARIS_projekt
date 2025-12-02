#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Content-type: text/html; charset=UTF-8"
echo ""

# Pfadanagabe
DATEI_PFAD="../data/encoded-todesfälle.csv"

# Paginierung
PER_PAGE=20
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}

# Filter: Gender & Jahr
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
YEAR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^year=' | cut -d'=' -f2)

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

# Anzahl gefilterte Zeilen
TOTAL_LINES=$(echo "$F_
