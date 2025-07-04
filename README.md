# geoip2-haproxy-acl

GeoIP2 country blocking with HAProxy.

Downloads GeoLite2 country csv and splits it into per-country files. Output is
compatible with HAProxy ACL (Access Control Lists).

```
./etc/haproxy/geoip2
 |- AD.txt
 |- AE.txt
 |- ...
 |- CN.txt
 |- ...
 |- US.txt
 |- ...
 |- ZM.txt
 |- ZW.txt  
```

## Usage

### MaxMind License Key

MaxMind requires you to register an user account in order to download free GeoIP2 databases.

Register at maxmind.com, go to "My account" -> "My License Keys" and generate a new license key.

### Pull latest GeoIP2 data
```
git clone https://github.com/Hypernova-Oy/geoip2-haproxy-acl.git
cd geoip2-haproxy-acl
mkdir -p /etc/haproxy/geoip2
./generate.sh --accountid YOUR_MAXMIND_FREE_ACCOUNT_ID --license YOUR_MAXMIND_FREE_LICENSE_KEY --out /etc/haproxy/geoip2
```

### Add ACL to HAProxy
```
acl acl_CN src -f /etc/haproxy/geoip2/CN.txt
acl acl_US src -f /etc/haproxy/geoip2/US.txt

http-request deny if acl_CN
http-request deny if acl_US
```

The above example rejects connections from China and the United States.

### Cron

GeoLite2 Country database is [updated weekly, every Tuesday and Friday](https://support.maxmind.com/hc/en-us/articles/4408216129947-Download-and-Update-Databases).

Add the following cronjob if you wish to stay up to date (replace `/path/to/`
with your script path). It pulls latest updates every Wednesday and Saturday at 06:00 AM.

``
0 6 * * 3,6 bash -c '/path/to/geoip2-haproxy-acl/generate.sh --accountid YOUR_MAXMIND_FREE_ACCOUNT_ID --license YOUR_MAXMIND_FREE_LICENSE_KEY --out /etc/haproxy/geoip2 && /bin/systemctl reload haproxy'
``

## License

See [LICENSE](LICENSE).
