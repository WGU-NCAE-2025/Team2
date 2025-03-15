#!/bin/bash
# This script assumes bind is already installed with all default configs in place

cat > "/etc/named.conf" <<EOL
options {
    listen-on port 53 { 127.0.0.1; 192.168.17.12; }; 
    listen-on-v6 port 53 { none; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    allow-query { localhost; 192.168.17.0/24; 172.18.0.0/16; }; 
    recursion yes;
};

zone "team17.ncaecybergames.org" IN {
    type master;
    file "/var/named/team17.ncaecybergames.zone";
    allow-transfer { none; }; 
};

zone "13.18.172.in-addr.arpa" IN {
    type master;
    file "/var/named/reverse.172.18.13.zone";
    allow-transfer { none; };
};

zone "14.18.172.in-addr.arpa" IN {
    type master;
    file "/var/named/reverse.172.18.14.zone";
    allow-transfer { none; };
};
EOL

#Creating forward zone
touch /var/named/team17.ncaecybergames.zone

cat > "/var/named/team17.ncaecybergames.zone" <<EOL
\$TTL 86400
@   IN  SOA  ns1.team17.ncaecybergames.org. admin.team17.ncaecybergames.org. (
        2024031401  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400 )     ; Minimum TTL

; Name Servers
@       IN  NS  ns1.team17.ncaecybergames.org.

; A Records
ns1     IN  A   172.18.13.17
www     IN  A   172.18.13.17
shell   IN  A   172.18.14.17
files   IN  A   172.18.14.17
EOL

#Reverse zone 172.18.13
touch /var/named/reverse.172.18.13.zone

cat > "/var/named/reverse.172.18.13.zone" <<EOL
\$TTL 86400
@   IN  SOA  ns1.team17.ncaecybergames.org. admin.team17.ncaecybergames.org. (
        2024031401  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400 )     ; Minimum TTL

; Name Servers
@       IN  NS  ns1.team17.ncaecybergames.org.

; PTR Records
17      IN  PTR  ns1.team17.ncaecybergames.org.
17      IN  PTR  www.team17.ncaecybergames.org.

EOL
#Reverse zone 172.18.14
touch /var/named/reverse.172.18.14.zone

cat > "/var/named/reverse.172.18.14.zone" <<EOL
\$TTL 86400
@   IN  SOA  ns1.team17.ncaecybergames.org. admin.team17.ncaecybergames.org. (
        2024031401  ; Serial
        3600        ; Refresh
        1800        ; Retry
        604800      ; Expire
        86400 )     ; Minimum TTL

; Name Servers
@       IN  NS  ns1.team17.ncaecybergames.org.

; PTR Records
17      IN  PTR  shell.team17.ncaecybergames.org.
17      IN  PTR  files.team17.ncaecybergames.org.
EOL

#Updating permissions
chown named:named /var/named/team17.ncaecybergames.zone
chown named:named /var/named/reverse.172.18.13.zone
chown named:named /var/named/reverse.172.18.14.zone

chmod 640 /var/named/team17.ncaecybergames.zone
chmod 640 /var/named/reverse.172.18.13.zone
chmod 640 /var/named/reverse.172.18.14.zone
chmod 000 /etc/rndc.key

echo "Done!"

