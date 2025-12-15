#!/bin/bash

sed 's/Année/Jahr/' |
sed 's/Mois/Monat/' |
sed 's/Semaine/Woche/' |
sed 's/Date début semaine/Wochenstart/' |
sed 's/Femmes 0-64/Frauen 0-64/' |
sed 's/Femmes 65+/Frauen 65+/' |
sed 's/Hommes 0-64/Männer 0-64/' |
sed 's/Hommes 65+/Männer 65+/';

cut -d ';' -f1-3,5-9