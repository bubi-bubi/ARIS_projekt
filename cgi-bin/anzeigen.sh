#!/bin/bash 
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

DATEI_PFAD="../data/encoded-todesfälle.csv"
#es muss noch die Paginierung ermöglicht werden!

echo "Content-type: text/html; charset=UTF-8"
echo ""
echo "<html><head>"
echo "<link rel=\"stylesheet\" href=\"../css/style.css\">"
echo "<title>Todesfälle </title>"
echo "</head>"
echo "<body>"
echo "<header> <h1>Todesfälle</h1> </header>"
echo "<section>"
echo "<p>"
cat "$DATEI_PFAD" | sed 's/$/<br>/'
echo "</p></section>"
echo "<section><p>Zurück zur <a href=\"../index.html\">Haupseite.</a></p></section>"
echo "<footer><p>&copy; Todesfälle Freiburg</p> </footer>"
echo "</body></html>"