#!/usr/bin/env bash

COUNTRIES="/tmp/countries"
COUNTRIES_ZIP="/var/cache/geoip/countries.zip"
SUBNETS="subnets"
YOUR_LICENSE_KEY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--out)        # Output directory of subnets
            SUBNETS="$2"
            shift
            shift
            ;;
        --license)        # Your MaxMind license key
            YOUR_LICENSE_KEY="$2"
            shift
            shift
            ;;
        *)   # Call a "show_help" function to display a synopsis, then exit.
            echo "./generate.sh --license YOUR_LICENSE_KEY --out /etc/haproxy/geoip2"
            echo ""
            echo "--out          Output directory for subnets"
            echo "--license      A MaxMind.com license key. Get it from maxmind.com -> My Account -> My License Key"
            exit 1
            ;;
    esac
done

if [ -z $YOUR_LICENSE_KEY ]; then
    echo "MaxMind license key must be set via --liecense parameter. See --help for more.";
    exit 1;
fi

# make sure the zip file exists and is recent enough to use
if [ ! $(find $COUNTRIES_ZIP -mtime -7 2>/dev/null) ]; then
    # remove it if it exists
    rm -f $COUNTRIES_ZIP

    # download a new copy
    echo "Downloading https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=xxxxx&suffix=zipGeoLite2-Country-CSV..."
    wget -q -O $COUNTRIES_ZIP "https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country-CSV&license_key=$YOUR_LICENSE_KEY&suffix=zip"

    # abort the script if the download failed
    if [ "$?" != 0 ]; then
        echo "Error downloading file"
        exit 1
    fi
fi

unzip -qq -o $COUNTRIES_ZIP

rm -rf $COUNTRIES
mv GeoLite2-Country-CSV_* $COUNTRIES

mkdir -p $SUBNETS
rm -f $SUBNETS/*.txt # delete old entries

echo "Generating files:"
# generate subnets/COUNTRYCODE.txt files and fill it with subnets
IFS=","
while read geoname_id locale_code continent_code continent_name country_iso_code country_name is_in_european_union
do
    if [ ! "$country_iso_code" ]; then
        continue
    fi

    if [ "$country_iso_code" = 'country_iso_code' ]; then
        continue
    fi

    # IPv4
    for v in $(cat $COUNTRIES/GeoLite2-Country-Blocks-IPv4.csv | grep $geoname_id | sed "s/,.*$//g" | awk "{print \$1}")
    do
        echo "$v" >> "${SUBNETS}/${country_iso_code}.txt"
    done

    echo "${SUBNETS}/${country_iso_code}.txt"
done < $COUNTRIES/GeoLite2-Country-Locations-en.csv

rm -rf $COUNTRIES

echo "Done."

exit 0
