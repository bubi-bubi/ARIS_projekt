#!/bin/bash
echo "Content-type: text/html"
echo ""

echo "<h1>Gefilterte Ergebnisse</h1>

CSV="/var/www/html/data/todesfälle.csv"
Gender=$(echo "$QUERY_STRING" | SED -n 's/^.*gender=\([^&]*\).*$/\1/p' | sed "s/%20/ /g")

echo "<ul>"
tail -n +2 "$CSV" | while IFS=, read -r col1 col2 col3
do
if [[ "$GENDER" == "alle" || "$col2" == "$GENDER"]
echo "<li>$col1, $col2, $col3, $col4, $col5, $col6</li>"
fi
done
echo "</ul>"
echo"a href='/index.html'>Zurück zum Filter</a>"
echo"</body></html>"
