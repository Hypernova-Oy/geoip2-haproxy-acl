#!/bin/sh

COUNTRIES="countries"
COUNTRIES_ZIP="${COUNTRIES}.zip"
SUBNETS="subnets"

wget -q -O $COUNTRIES_ZIP https://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip

if [ "$?" != 0 ]; then
    echo "Error downloading file"
    exit 1
fi

unzip -qq -o $COUNTRIES_ZIP

cp -r GeoLite2-Country-CSV_* countries
rm -rf GeoLite2-Country-CSV_*

mkdir -p subnets
rm subnets/*.txt # delete old entries

# generate subnets/COUNTRYCODE.txt files and fill it with subnets
IFS=","
while read geoname_id locale_code continent_code continent_name country_iso_code country_name is_in_european union
do
    if [ ! "$country_iso_code" ]; then
        continue
    fi

    if [ "$country_iso_code" = 'country_iso_code' ]; then
        continue
    fi

    # IPv4
    for v in $(cat countries/GeoLite2-Country-Blocks-IPv4.csv | grep $geoname_id | sed "s/,.*$//g" | awk "{print $1}")
    do
        echo "$v" >> "${SUBNETS}/${country_iso_code}.txt"
    done

    # IPv6
    for v in $(cat countries/GeoLite2-Country-Blocks-IPv6.csv | grep $geoname_id | sed "s/,.*$//g" | awk "{print $1}")
    do
        echo "$v" >> "${SUBNETS}/${country_iso_code}.txt"
    done
done < countries/GeoLite2-Country-Locations-en.csv

# clean up
rm countries.zip
rm -rf countries

exit 0
