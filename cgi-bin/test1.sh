#!/bin/bash
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

echo "Content-type: text/html; charset=UTF-8"
echo ""

DATEI_PFAD="../data/encoded-todesfälle.csv"
PER_PAGE=20

# QUERY_STRING auslesen
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)
JAHR=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^jahr=' | cut -d'=' -f2)
PAGE=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^page=' | cut -d'=' -f2)
PAGE=${PAGE:-1}

START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# Alle Jahre aus CSV für Dropdown
JAHRE=$(tail -n +2 "$DATEI_PFAD" | awk -F';' '{print $1}' | sort -u)

# HTML Header
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle</title>"
echo "</head><body class=\"anzeige\">"
echo "<header><h1>Todesfälle Freiburg</h1></header>"

# Filterformular
echo "<section>"
echo "<form action=\"test1.sh\" method=\"get\">"
echo "<label for=\"filter\">Filter:</label>"
echo "<select name=\"filter\" id=\"filter\">"
echo "<option value=\"\" $( [ -z "$FILTER" ] && echo "selected" )>Alle</option>"
echo "<option value=\"frauen\" $( [ "$FILTER" == "frauen" ] && echo "selected" )>Frauen</option>"
echo "<option value=\"maenner\" $( [ "$FILTER" == "maenner" ] && echo "selected" )>Männer</option>"
echo "</select>"

echo "<label for=\"jahr\">Jahr:</label>"
echo "<select name=\"jahr\" id=\"jahr\">"
echo "<option value=\"\" $( [ -z "$JAHR" ] && echo "selected" )>Alle Jahre</option>"
for y in $JAHRE; do
    SEL=$( [ "$y" == "$JAHR" ] && echo "selected" )
    echo "<option value=\"$y\" $SEL>$y</option>"
done
echo "</select>"

echo "<input type=\"submit\" value=\"Anzeigen\">"
echo "</form>"
echo "</section>"

# Tabelle beginnen
echo "<table class=\"anzeige-table\" border='1' cellpadding='6' cellspacing='0'>"

# Kopfzeile
head -n1 "$DATEI_PFAD" | awk -F';' -v filter="$FILTER" '{
    print "<tr>";
    if(filter=="frauen") { print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Wochenstart</th><th>Frauen gesamt</th><th>Total</th>" }
    else if(filter=="maenner") { print "<th>Jahr</th><th>Monat</th><th>Woche</th><th>Wochenstart</th><th>Männer gesamt</th><th>Total</th>" }
    else { for(i=1;i<=NF;i++) print "<th>" $i "</th>" }
    print "</tr>"
}'

# Gefilterte Daten in temporäre Datei
TMP=$(mktemp)
tail -n +2 "$DATEI_PFAD" | awk -F';' -v f="$FILTER" -v j="$JAHR" '{
    if((j=="" || $1==j)){
        if(f=="frauen"){ sum=$5+$6; print $1,$2,$3,$4,sum,$9 }
        else if(f=="maenner"){ sum=$7+$8; print $1,$2,$3,$4,sum,$9 }
        else{ print $0 }
    }
}' > "$TMP"

# Paginierung anpassen: nur vorhandene Seiten
TOTAL_LINES=$(wc -l < "$TMP")
TOTAL_PAGES=$(( (TOTAL_LINES + PER_PAGE - 1) / PER_PAGE ))

# Daten ausgeben
sed -n "${START},${END}p" "$TMP" | while read -r line; do
    echo "<tr>"
    for col in $line; do
        echo "<td>$col</td>"
    done
    echo "</tr>"
done

echo "</table>"

# Paginierung anzeigen
if [ "$TOTAL_PAGES" -gt 1 ]; then
    echo "<div style='margin-top:20px;'><p>Seiten: "
    for i in $(seq 1 $TOTAL_PAGES); do
        if [ "$i" -eq "$PAGE" ]; then
            echo "<strong>$i</strong> "
        else
            LINK="test1.sh?page=$i"
            [ -n "$FILTER" ] && LINK+="&filter=$FILTER"
            [ -n "$JAHR" ] && LINK+="&jahr=$JAHR"
            echo "<a href='$LINK'>$i</a> "
        fi
    done
    echo "</p></div>"
fi

echo "<section><p>Zurück zur <a href=\"../testindex.html\">Auswahl</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"

rm "$TMP"
