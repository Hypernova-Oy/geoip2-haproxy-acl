#!/usr/bin/env bash

OUTPUT_DIRECTORY="/etc/haproxy/geoip2"
YOUR_ACCOUNT_ID=""
YOUR_LICENSE_KEY=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--out)        # Output directory of subnets
            OUTPUT_DIRECTORY="$2"
            shift
            shift
            ;;
        --accountid)        # Your MaxMind account id
            YOUR_ACCOUNT_ID="$2"
            shift
            shift
            ;;
        --license)        # Your MaxMind license key
            YOUR_LICENSE_KEY="$2"
            shift
            shift
            ;;
        *)   # Call a "show_help" function to display a synopsis, then exit.
            echo "./generate.sh --accountid YOUR_ACCOUNT_ID --license YOUR_LICENSE_KEY --out /etc/haproxy/geoip2"
            echo ""
            echo "--out          Output directory. Defaults to /etc/haproxy/geoip2"
            echo "--accountid    A MaxMind.com account id. Get it from maxmind.com -> My Account -> Account information"
            echo "--license      A MaxMind.com license key. Get it from maxmind.com -> My Account -> My License Key"
            exit 1
            ;;
    esac
done

if [ -z $YOUR_ACCOUNT_ID ]; then
    echo "MaxMind account id must be set via --accountid parameter. See --help for more.";
    exit 1;
fi

if [ -z $YOUR_LICENSE_KEY ]; then
    echo "MaxMind license key must be set via --license parameter. See --help for more.";
    exit 1;
fi

if [ ! -d "$OUTPUT_DIRECTORY" ]; then
    echo "Output directory ( $OUTPUT_DIRECTORY ) does not exist. Please create it first."
    exit 1
fi

COUNTRIES_DIR="$OUTPUT_DIRECTORY/countries"
COUNTRIES_ZIP="$OUTPUT_DIRECTORY/countries.zip"

# make sure the zip file exists and is recent enough to use
if [ ! $(find $COUNTRIES_ZIP -mtime -7 2>/dev/null) ]; then
    # remove it if it exists
    rm -f $COUNTRIES_ZIP

    # download a new copy
    echo "Downloading GeoIP2 databse from maxmind.com ..."
    wget --content-disposition --user=$YOUR_ACCOUNT_ID --password=$YOUR_LICENSE_KEY -q -O $COUNTRIES_ZIP "https://download.maxmind.com/geoip/databases/GeoLite2-Country-CSV/download?suffix=zip"

    # abort the script if the download failed
    if [ "$?" != 0 ]; then
        echo "Error downloading file"
        exit 1
    fi
fi

unzip -qq -o $COUNTRIES_ZIP

rm -rf $COUNTRIES_DIR
mv GeoLite2-Country-CSV_* $COUNTRIES_DIR

rm -f $OUTPUT_DIRECTORY/*.txt # delete old entries

echo "Generating files:"
# generate $OUTPUT_DIRECTORY/COUNTRYCODE.txt files and fill it with subnets
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
    for v in $(cat $COUNTRIES_DIR/GeoLite2-Country-Blocks-IPv4.csv | grep $geoname_id | sed "s/,.*$//g" | awk "{print \$1}")
    do
        echo "$v" >> "${OUTPUT_DIRECTORY}/${country_iso_code}.txt"
    done

    # IPv6
    for v in $(cat $COUNTRIES_DIR/GeoLite2-Country-Blocks-IPv6.csv | grep $geoname_id | sed "s/,.*$//g" | awk "{print \$1}")
    do
        echo "$v" >> "${OUTPUT_DIRECTORY}/${country_iso_code}.txt"
    done

    echo "${OUTPUT_DIRECTORY}/${country_iso_code}.txt"
done < $COUNTRIES_DIR/GeoLite2-Country-Locations-en.csv

rm -rf $COUNTRIES_DIR

echo "Done."

exit 0
