#!/bin/bash

echo "Content-type: text/html; charset=UTF-8"
echo ""

dataset="/var/www/html/data/copy_todesfaelle.csv"

echo "<!DOCTYPE html>"
echo "<html lang='de'>"
echo "<head>"
echo "<meta charset='UTF-8'>"
echo "<title>Todesfälle – Liste</title>"
echo "<style>
table { border-collapse: collapse; width: 90%; margin: 20px auto; }
th, td { border: 1px solid #444; padding: 8px; text-align: center; }
th { background: #ddd; }
</style>"
echo "</head>"
echo "<body>"
echo "<h2 style='text-align:center;'>Gespeicherte Todesfälle</h2>"

echo "<table>"

# Kopfzeile drucken
header=1
while IFS=";" read -r col1 col2 col3 col4 col5 col6 col7 col8 col9; do
    if [ $header -eq 1 ]; then
        echo "<tr><th>$col1</th><th>$col2</th><th>$col3</th><th>$col4</th><th>$col5</th><th>$col6</th><th>$col7</th><th>$col8</th><th>$col9</th></tr>"
        header=0
    else
        echo "<tr><td>$col1</td><td>$col2</td><td>$col3</td><td>$col4</td><td>$col5</td><td>$col6</td><td>$col7</td><td>$col8</td><td>$col9</td></tr>"
    fi
done < "$dataset"

echo "</table>"

echo "<div style='text-align:center; margin-top:20px;'>"
echo "<a href='/testindex.html'>Zurück</a>"
echo "</div>"

echo "</body></html>"
