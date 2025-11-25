#!/bin/bash

sed 's/Année/jahr/' |
sed 's/Mois/monat/' |
sed 's/Semaine/woche/' |
sed 's/Date début semaine/wstart/' |
sed 's/Femmes 0-64/wjung/' |
sed 's/Femmes 65+/walt/' |
sed 's/Hommes 0-64/mjung/' |
sed 's/Hommes 65+/malt/' |
sed 's/Total/total/';