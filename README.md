# dyndnsexception
Bash script to manage exceptions in a firewall for dynamic DNS hosts.
## Installation
UFW is required; this script is designed to interact and make use of UFW. information for UFW can be found here: https://help.ubuntu.com/community/UFW

Download. Make excecutable. Add a host, or five.
```
wget -O /usr/local/bin/dyndnsexception.sh https://raw.githubusercontent.com/mhleck/dyndnsexception/master/dyndnsexception.sh
chmod +x /usr/local/bin/dyndnsexception.sh
/usr/local/bin/dyndnsexception.sh add mydynamicdnshost.example.com
/usr/local/bin/dyndnsexception.sh add myotherdynhost.example.com
```
Add a cron job:
```
*/5 *   * * *   root    /usr/local/bin/dyndnsexception.sh > /dev/null 2>&1
```
## Usage examples
Add a new host
```
dyndnsexception.sh add example.com
```
Remove a host
```
dyndnsexception.sh del example.com
```
Update host records and the firewall
```
dyndnsexception.sh
OR
dyndnsexception.sh update
```
