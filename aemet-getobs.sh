#!/bin/bash

PROJDIR=~ivlivs/aemet

api_key=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJqbG5hdmFycm9AdGhld2VhdGhlcnBhcnRuZXIuY29tIiwianRpIjoiMWRjZTQ0YmEtNjkxZC00ODY1LTg3MDUtMTdjZGZkZDIwMWNiIiwiaXNzIjoiQUVNRVQiLCJpYXQiOjE1NDEzNzA4OTgsInVzZXJJZCI6IjFkY2U0NGJhLTY5MWQtNDg2NS04NzA1LTE3Y2RmZGQyMDFjYiIsInJvbGUiOiIifQ.GLSRbW3eEFjIc2AH9qbwdu11V0xPfgmBBw-2xdE3TSQ

url=https://opendata.aemet.es/opendata/api/observacion/convencional/todas/?api_key=$api_key
fout=out.json
fdata=data.json
flast=last.json
ffinal=final.json
fprev=prev.json

function prepare {
	cd $PROJDIR/data
	mv -f $ffinal $fprev
	rm -f $fdata $flast $fout
}

function getdata {
	echo "Descargando observaciones..."
	curl -s -X GET --header 'Accept: text/plain' -o $fout $url
	urldata=$(jq '.datos' $fout)
	eval "curl -s -o $fdata $urldata"
	nobs=$(jq '.[].idema' $fdata | wc -l)
	nsta=$(jq '.[].idema' $fdata | sort | uniq | wc -l)
	echo "...descargadas $nobs observaciones de $nsta estaciones."
}

function extractdata {
	echo "Extrayendo última observación..."
	last=$(jq '.[].fint' $fdata | sort -r | uniq | head -1)
	eval "jq '[ .[] | select( .fint | contains($last)) ]' data.json" > $flast
	#-- eval "jq '.[].fint=$last' $fdata" > $flast  #-- esto cambia en campo (no lo selecciona)
	nobs=$(jq '.[].idema' $flast | wc -l)
	nsta=$(jq '.[].idema' $flast | sort | uniq | wc -l)
	echo "...extraidas $nobs observaciones de $nsta estaciones para timestep $last."
}

function convertdata {
	echo "Formateando observaciones..."
	for ((i=0; i<$nobs; i++)); do
		# j=$(printf "%05d" $i); echo $j
		# jq --argjson ii $j '{ features: { type: "Feature" , properties: .[$ii] , geometry: { type: "Point", coordinates: [.[$ii].lon, .[$ii].lat ] } } }' data.json >> all.json
		eval "jq  '{ features: { type: \"Feature\" , properties: .[$i] , geometry: { type: \"Point\", coordinates: [.[$i].lon, .[$i].lat ] } } }' $flast" >> $ffinal
	done

	mv $ffinal tmp.json; jq -s '[.[][]]' tmp.json > $ffinal
	mv $ffinal tmp.json; jq  '{ type:"FeatureCollection", features: [.[]] }' tmp.json > $ffinal
	rm -f tmp.json
	echo "...done!"
}

function main {
	prepare 
	getdata
	extractdata
	convertdata
}

main

