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
START=$(( (PAGE-1)*PER_PAGE + 1 ))
END=$(( START + PER_PAGE - 1 ))

# Filter auslesen (frauen, maenner oder leer)
FILTER=$(echo "$QUERY_STRING" | tr '&' '\n' | grep '^filter=' | cut -d'=' -f2)

# HTML Header
echo "<html><head>"
echo "<l"
#Footer
echo "<section><p>Zurück zur <a href=\"../testindex.html\">Hauptseite</a>.</p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p></footer>"
echo "</body></html>"