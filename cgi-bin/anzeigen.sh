#!/bin/bash 

DATEI_PFAD="../data/todesfälle.csv"

echo "Content-type: text/html"
echo ""
echo "<html><head>"
echo "<meta charset="utf8">
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle </title>"
echo "</head>"
echo "<body>"
echo "<header> <h1>Todesfälle</h1> </header>"
echo "<section>"
echo "<p>"
cat "$DATEI_PFAD" | sed 's/$/<br>/'
echo "</p></section>"
echo "<section><p>Zurück zur <a href="../index.html">Haupseite.</a></p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p> </footer>"
echo "</body></html>"