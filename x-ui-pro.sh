#!/bin/bash
#################### x-ui-pro v2.4.3 @ github.com/GFW4Fun ##############################################
[[ $EUID -ne 0 ]] && echo "not root!" && sudo su -
##############################INFO######################################################################
msg_ok() { echo -e "\e[1;42m $1 \e[0m";}
msg_err() { echo -e "\e[1;41m $1 \e[0m";}
msg_inf() { echo -e "\e[1;34m$1\e[0m";}
echo;msg_inf '           ___    _   _   _  '	;
msg_inf		 ' \/ __ | |  | __ |_) |_) / \ '	;
msg_inf		 ' /\    |_| _|_   |   | \ \_/ '	; echo
##################################Variables#############################################################
XUIDB="/etc/x-ui/x-ui.db";domain="";UNINSTALL="x";INSTALL="n";PNLNUM=1;CFALLOW="n"
Pak=$(type apt &>/dev/null && echo "apt" || echo "yum")
systemctl stop x-ui
rm -rf /etc/systemd/system/x-ui.service
rm -rf /usr/local/x-ui
rm -rf /etc/x-ui
rm -rf /etc/nginx/sites-enabled/*
rm -rf /etc/nginx/sites-available/*
rm -rf /etc/nginx/stream-enabled/*


##################################generate ports and paths#############################################################
get_port() {
	echo $(( ((RANDOM<<15)|RANDOM) % 49152 + 10000 ))
}

check_free() {
	local port=$1
	nc -z 127.0.0.1 $port &>/dev/null
	return $?
}

make_port() {
	while true; do
		PORT=$(get_port)
		if ! check_free $PORT; then 
			echo $PORT
			break
		fi
	done
}
sub_port=$(make_port)
panel_port=$(make_port)
sub_path=$(tr -dc A-Za-z0-9 </dev/urandom | head -c "$(shuf -i 6-12 -n 1)")
json_path=$(tr -dc A-Za-z0-9 </dev/urandom | head -c "$(shuf -i 6-12 -n 1)")
panel_path=$(tr -dc A-Za-z0-9 </dev/urandom | head -c "$(shuf -i 6-12 -n 1)")
ws_port=$(make_port)
ws_path=$(tr -dc A-Za-z0-9 </dev/urandom | head -c "$(shuf -i 6-12 -n 1)")

##################################Random Port and Path #################################################
#RNDSTR=$(tr -dc A-Za-z0-9 </dev/urandom | head -c "$(shuf -i 6-12 -n 1)")
#while true; do 
#    PORT=$(( ((RANDOM<<15)|RANDOM) % 49152 + 10000 ))
#    status="$(nc -z 127.0.0.1 $PORT < /dev/null &>/dev/null; echo $?)"
#    if [ "${status}" != "0" ]; then
#        break
#    fi
#done

################################Get arguments###########################################################
while [ "$#" -gt 0 ]; do
  case "$1" in
    -install) INSTALL="$2"; shift 2;;
    -panel) PNLNUM="$2"; shift 2;;
    -subdomain) domain="$2"; shift 2;;
    -reality_domain) reality_domain="$2"; shift 2;;
    -ONLY_CF_IP_ALLOW) CFALLOW="$2"; shift 2;;
    -uninstall) UNINSTALL="$2"; shift 2;;
    *) shift 1;;
  esac
done


##############################Uninstall#################################################################
UNINSTALL_XUI(){
	printf 'y\n' | x-ui uninstall
	rm -rf "/etc/x-ui/" "/usr/local/x-ui/" "/usr/bin/x-ui/"
	$Pak -y remove nginx nginx-common nginx-core nginx-full python3-certbot-nginx
	$Pak -y purge nginx nginx-common nginx-core nginx-full python3-certbot-nginx
	$Pak -y autoremove
	$Pak -y autoclean
	rm -rf "/var/www/html/" "/etc/nginx/" "/usr/share/nginx/" 
	crontab -l | grep -v "certbot\|x-ui\|cloudflareips" | crontab -
}
if [[ ${UNINSTALL} == *"y"* ]]; then
	UNINSTALL_XUI	
	clear && msg_ok "Completely Uninstalled!" && exit 1
fi
##############################Domain Validations########################################################
while true; do	
	if [[ -n "$domain" ]]; then
		break
	fi
	echo -en "Enter available subdomain (sub.domain.tld): " && read domain 
done

domain=$(echo "$domain" 2>&1 | tr -d '[:space:]' )
SubDomain=$(echo "$domain" 2>&1 | sed 's/^[^ ]* \|\..*//g')
MainDomain=$(echo "$domain" 2>&1 | sed 's/.*\.\([^.]*\..*\)$/\1/')

if [[ "${SubDomain}.${MainDomain}" != "${domain}" ]] ; then
	MainDomain=${domain}
fi

while true; do	
	if [[ -n "$reality_domain" ]]; then
		break
	fi
	echo -en "Enter available subdomain for REALITY (sub.domain.tld): " && read reality_domain 
done

reality_domain=$(echo "$reality_domain" 2>&1 | tr -d '[:space:]' )
RealitySubDomain=$(echo "$reality_domain" 2>&1 | sed 's/^[^ ]* \|\..*//g')
RealityMainDomain=$(echo "$reality_domain" 2>&1 | sed 's/.*\.\([^.]*\..*\)$/\1/')

if [[ "${RealitySubDomain}.${RealityMainDomain}" != "${reality_domain}" ]] ; then
	RealityMainDomain=${reality_domain}
fi

###############################Install Packages#########################################################
ufw disable
if [[ ${INSTALL} == *"y"* ]]; then

         version=$(grep -oP '(?<=VERSION_ID=")[0-9]+' /etc/os-release)

         # Проверяем, является ли версия 20 или 22
        if [[ "$version" == "20" || "$version" == "22" ]]; then
              echo "Версия системы: Ubuntu $version"
        fi

	$Pak -y update
	$Pak -y install curl nginx-full certbot python3-certbot-nginx sqlite3 
	systemctl daemon-reload && systemctl enable --now nginx
fi
systemctl stop nginx 
fuser -k 80/tcp 80/udp 443/tcp 443/udp 2>/dev/null
##################################GET SERVER IPv4-6#####################################################
IP4_REGEX="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
IP6_REGEX="([a-f0-9:]+:+)+[a-f0-9]+"
IP4=$(ip route get 8.8.8.8 2>&1 | grep -Po -- 'src \K\S*')
IP6=$(ip route get 2620:fe::fe 2>&1 | grep -Po -- 'src \K\S*')
[[ $IP4 =~ $IP4_REGEX ]] || IP4=$(curl -s ipv4.icanhazip.com);
[[ $IP6 =~ $IP6_REGEX ]] || IP6=$(curl -s ipv6.icanhazip.com);
##############################Install SSL###############################################################
certbot certonly --standalone --non-interactive --agree-tos --register-unsafely-without-email -d "$domain"
if [[ ! -d "/etc/letsencrypt/live/${domain}/" ]]; then
 	systemctl start nginx >/dev/null 2>&1
	msg_err "$domain SSL could not be generated! Check Domain/IP Or Enter new domain!" && exit 1
fi

certbot certonly --standalone --non-interactive --agree-tos --register-unsafely-without-email -d "$reality_domain"
if [[ ! -d "/etc/letsencrypt/live/${reality_domain}/" ]]; then
 	systemctl start nginx >/dev/null 2>&1
	msg_err "$reality_domain SSL could not be generated! Check Domain/IP Or Enter new domain!" && exit 1
fi
################################# Access to configs only with cloudflare#################################
rm -f "/etc/nginx/cloudflareips.sh"
cat << 'EOF' >> /etc/nginx/cloudflareips.sh
#!/bin/bash
rm -f "/etc/nginx/conf.d/cloudflare_real_ips.conf" "/etc/nginx/conf.d/cloudflare_whitelist.conf"
CLOUDFLARE_REAL_IPS_PATH=/etc/nginx/conf.d/cloudflare_real_ips.conf
CLOUDFLARE_WHITELIST_PATH=/etc/nginx/conf.d/cloudflare_whitelist.conf
echo "geo \$realip_remote_addr \$cloudflare_ip {
	default 0;" >> $CLOUDFLARE_WHITELIST_PATH
for type in v4 v6; do
	echo "# IP$type"
	for ip in `curl https://www.cloudflare.com/ips-$type`; do
		echo "set_real_ip_from $ip;" >> $CLOUDFLARE_REAL_IPS_PATH;
		echo "	$ip 1;" >> $CLOUDFLARE_WHITELIST_PATH;
	done
done
echo "real_ip_header X-Forwarded-For;" >> $CLOUDFLARE_REAL_IPS_PATH
echo "}" >> $CLOUDFLARE_WHITELIST_PATH
EOF
sudo bash "/etc/nginx/cloudflareips.sh" > /dev/null 2>&1;
if [[ ${CFALLOW} == *"y"* ]]; then
	CF_IP="";
	else	
	CF_IP="#";
fi
###################################Get Installed XUI Port/Path##########################################
if [[ -f $XUIDB ]]; then
	XUIPORT=$(sqlite3 -list $XUIDB 'SELECT "value" FROM settings WHERE "key"="webPort" LIMIT 1;' 2>&1)
	XUIPATH=$(sqlite3 -list $XUIDB 'SELECT "value" FROM settings WHERE "key"="webBasePath" LIMIT 1;' 2>&1)
if [[ $XUIPORT -gt 0 && $XUIPORT != "54321" && $XUIPORT != "2053" ]] && [[ ${#XUIPORT} -gt 4 ]]; then
	RNDSTR=$(echo "$XUIPATH" 2>&1 | tr -d '/')
	PORT=$XUIPORT
	sqlite3 $XUIDB <<EOF
	DELETE FROM "settings" WHERE ( "key"="webCertFile" ) OR ( "key"="webKeyFile" ); 
	INSERT INTO "settings" ("key", "value") VALUES ("webCertFile",  "");
	INSERT INTO "settings" ("key", "value") VALUES ("webKeyFile", "");
EOF
fi
fi
#################################Nginx Config###########################################################
mkdir -p /etc/nginx/stream-enabled
cat > "/etc/nginx/stream-enabled/stream.conf" << EOF
map \$ssl_preread_server_name \$sni_name {
    hostnames;
    ${reality_domain}      xray;
    ${domain}           www;
    default              xray;
}

upstream xray {
    server 127.0.0.1:8443;
}

upstream www {
    server 127.0.0.1:7443;
}

server {
    proxy_protocol on;
    set_real_ip_from unix:;
    listen          443;
    proxy_pass      \$sni_name;
    ssl_preread     on;
}

EOF

grep -xqFR "stream { include /etc/nginx/stream-enabled/*.conf; }" /etc/nginx/* ||echo "stream { include /etc/nginx/stream-enabled/*.conf; }" >> /etc/nginx/nginx.conf
grep -xqFR "load_module modules/ngx_stream_module.so;" /etc/nginx/* || sed -i '1s/^/load_module \/usr\/lib\/nginx\/modules\/ngx_stream_module.so; /' /etc/nginx/nginx.conf
grep -xqFR "load_module modules/ngx_stream_geoip2_module.so;" /etc/nginx* || sed -i '2s/^/load_module \/usr\/lib\/nginx\/modules\/ngx_stream_geoip2_module.so; /' /etc/nginx/nginx.conf
grep -xqFR "worker_rlimit_nofile 16384;" /etc/nginx/* ||echo "worker_rlimit_nofile 16384;" >> /etc/nginx/nginx.conf
sed -i "/worker_connections/c\worker_connections 4096;" /etc/nginx/nginx.conf
cat > "/etc/nginx/sites-available/80.conf" << EOF
server {
    listen 80;
    server_name ${domain} ${reality_domain};
    return 301 https://\$host\$request_uri;
}
EOF


cat > "/etc/nginx/sites-available/${domain}" << EOF
server {
	server_tokens off;
	server_name ${domain};
	listen 7443 ssl http2 proxy_protocol;
	listen [::]:7443 ssl http2 proxy_protocol;
	index index.html index.htm index.php index.nginx-debian.html;
	root /var/www/html/;
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers HIGH:!aNULL:!eNULL:!MD5:!DES:!RC4:!ADH:!SSLv3:!EXP:!PSK:!DSS;
	ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
	if (\$host !~* ^(.+\.)?$MainDomain\$ ){return 444;}
	if (\$scheme ~* https) {set \$safe 1;}
	if (\$ssl_server_name !~* ^(.+\.)?$MainDomain\$ ) {set \$safe "\${safe}0"; }
	if (\$safe = 10){return 444;}
	if (\$request_uri ~ "(\"|'|\`|~|,|:|--|;|%|\\$|&&|\?\?|0x00|0X00|\||\\|\{|\}|\[|\]|<|>|\.\.\.|\.\.\/|\/\/\/)"){set \$hack 1;}
	error_page 400 401 402 403 500 501 502 503 504 =404 /404;
	proxy_intercept_errors on;
	#X-UI Admin Panel
	location /${panel_path}/ {
		proxy_redirect off;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_pass http://127.0.0.1:${panel_port};
		break;
	}
        location /${panel_path} {
		proxy_redirect off;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_pass http://127.0.0.1:${panel_port};
		break;
	}
 	#Subscription Path (simple/encode)
        location /${sub_path} {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	location /${sub_path}/ {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	#Subscription Path (json/fragment)
        location /${json_path} {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	location /${json_path}/ {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
 	#Xray Config Path
	location ~ ^/(?<fwdport>\d+)/(?<fwdpath>.*)\$ {
	$CF_IP	if (\$cloudflare_ip != 1) {return 404;}
		if (\$hack = 1) {return 404;}
		client_max_body_size 0;
		client_body_timeout 1d;
		grpc_read_timeout 1d;
		grpc_socket_keepalive on;
		proxy_read_timeout 1d;
		proxy_http_version 1.1;
		proxy_buffering off;
		proxy_request_buffering off;
		proxy_socket_keepalive on;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		#proxy_set_header CF-IPCountry \$http_cf_ipcountry;
		#proxy_set_header CF-IP \$realip_remote_addr;
		if (\$content_type ~* "GRPC") {
			grpc_pass grpc://127.0.0.1:\$fwdport\$is_args\$args;
			break;
		}
		if (\$http_upgrade ~* "(WEBSOCKET|WS)") {
			proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
			break;
	        }
		if (\$request_method ~* ^(PUT|POST|GET)\$) {
			proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
			break;
		}
	}
	location / { try_files \$uri \$uri/ =404; }
}
EOF

cat > "/etc/nginx/sites-available/${reality_domain}" << EOF
server {
	server_tokens off;
	server_name ${reality_domain};
	listen 9443 ssl http2;
	listen [::]:9443 ssl http2;
	index index.html index.htm index.php index.nginx-debian.html;
	root /var/www/html/;
	ssl_protocols TLSv1.2 TLSv1.3;
	ssl_ciphers HIGH:!aNULL:!eNULL:!MD5:!DES:!RC4:!ADH:!SSLv3:!EXP:!PSK:!DSS;
	ssl_certificate /etc/letsencrypt/live/$reality_domain/fullchain.pem;
	ssl_certificate_key /etc/letsencrypt/live/$reality_domain/privkey.pem;
	if (\$host !~* ^(.+\.)?$MainDomain\$ ){return 444;}
	if (\$scheme ~* https) {set \$safe 1;}
	if (\$ssl_server_name !~* ^(.+\.)?$MainDomain\$ ) {set \$safe "\${safe}0"; }
	if (\$safe = 10){return 444;}
	if (\$request_uri ~ "(\"|'|\`|~|,|:|--|;|%|\\$|&&|\?\?|0x00|0X00|\||\\|\{|\}|\[|\]|<|>|\.\.\.|\.\.\/|\/\/\/)"){set \$hack 1;}
	error_page 400 401 402 403 500 501 502 503 504 =404 /404;
	proxy_intercept_errors on;
	#X-UI Admin Panel
	location /${panel_path}/ {
		proxy_redirect off;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_pass http://127.0.0.1:${panel_port};
		break;
	}
        location /$panel_path {
		proxy_redirect off;
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		proxy_pass http://127.0.0.1:${panel_port};
		break;
	}
 	#Subscription Path (simple/encode)
        location /${sub_path} {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	location /${sub_path}/ {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	#Subscription Path (json/fragment)
        location /${json_path} {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
	location /${json_path}/ {
                if (\$hack = 1) {return 404;}
                proxy_redirect off;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_pass http://127.0.0.1:${sub_port};
                break;
        }
 	#Xray Config Path
	location ~ ^/(?<fwdport>\d+)/(?<fwdpath>.*)\$ {
	$CF_IP	if (\$cloudflare_ip != 1) {return 404;}
		if (\$hack = 1) {return 404;}
		client_max_body_size 0;
		client_body_timeout 1d;
		grpc_read_timeout 1d;
		grpc_socket_keepalive on;
		proxy_read_timeout 1d;
		proxy_http_version 1.1;
		proxy_buffering off;
		proxy_request_buffering off;
		proxy_socket_keepalive on;
		proxy_set_header Upgrade \$http_upgrade;
		proxy_set_header Connection "upgrade";
		proxy_set_header Host \$host;
		proxy_set_header X-Real-IP \$remote_addr;
		proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
		#proxy_set_header CF-IPCountry \$http_cf_ipcountry;
		#proxy_set_header CF-IP \$realip_remote_addr;
		if (\$content_type ~* "GRPC") {
			grpc_pass grpc://127.0.0.1:\$fwdport\$is_args\$args;
			break;
		}
		if (\$http_upgrade ~* "(WEBSOCKET|WS)") {
			proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
			break;
	        }
		if (\$request_method ~* ^(PUT|POST|GET)\$) {
			proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
			break;
		}
	}
	location / { try_files \$uri \$uri/ =404; }
}
EOF
##################################Check Nginx status####################################################
if [[ -f "/etc/nginx/sites-available/${domain}" ]]; then
	unlink "/etc/nginx/sites-enabled/default" >/dev/null 2>&1
	rm -f "/etc/nginx/sites-enabled/default" "/etc/nginx/sites-available/default"
	ln -s "/etc/nginx/sites-available/${domain}" "/etc/nginx/sites-enabled/" 2>/dev/null
        ln -s "/etc/nginx/sites-available/${reality_domain}" "/etc/nginx/sites-enabled/" 2>/dev/null
	ln -s "/etc/nginx/sites-available/80.conf" "/etc/nginx/sites-enabled/" 2>/dev/null
else
	msg_err "${domain} nginx config not exist!" && exit 1
fi

if [[ $(nginx -t 2>&1 | grep -o 'successful') != "successful" ]]; then
    msg_err "nginx config is not ok!" && exit 1
else
	systemctl start nginx 
fi


##############################generate uri's###########################################################
sub_uri=https://${domain}/${sub_path}/
json_uri=https://${domain}/${json_path}/
##############################generate keys###########################################################
shor=($(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8) $(openssl rand -hex 8))

########################################Update X-UI Port/Path for first INSTALL#########################
UPDATE_XUIDB(){
if [[ -f $XUIDB ]]; then
        x-ui stop
        var1=$(/usr/local/x-ui/bin/xray-linux-amd64 x25519)
        var2=($var1)
        private_key=${var2[2]}
        public_key=${var2[5]}
	client_id=$(/usr/local/x-ui/bin/xray-linux-amd64 uuid)
        client_id2=$(/usr/local/x-ui/bin/xray-linux-amd64 uuid)
       	sqlite3 $XUIDB <<EOF
             UPDATE settings SET value = '${panel_port}' WHERE key = 'webPort';
             UPDATE settings SET value = '/${panel_path}/' WHERE key = 'webBasePath';
             INSERT INTO "settings" ("key", "value") VALUES ("subPort",  '${sub_port}');
	     INSERT INTO "settings" ("key", "value") VALUES ("subPath",  '${sub_path}');
	     INSERT INTO "settings" ("key", "value") VALUES ("subURI",  '${sub_uri}');
             INSERT INTO "settings" ("key", "value") VALUES ("subJsonPath",  '${json_path}');
	     INSERT INTO "settings" ("key", "value") VALUES ("subJsonURI",  '${json_uri}');
             INSERT INTO "settings" ("key", "value") VALUES ("subEnable",  'true');
             INSERT INTO "settings" ("key", "value") VALUES ("webListen",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("webDomain",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("webCertFile",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("webKeyFile",  '');
      	     INSERT INTO "settings" ("key", "value") VALUES ("sessionMaxAge",  '60');
             INSERT INTO "settings" ("key", "value") VALUES ("pageSize",  '50');
             INSERT INTO "settings" ("key", "value") VALUES ("expireDiff",  '0');
             INSERT INTO "settings" ("key", "value") VALUES ("trafficDiff",  '0');
             INSERT INTO "settings" ("key", "value") VALUES ("remarkModel",  '-ieo');
             INSERT INTO "settings" ("key", "value") VALUES ("tgBotEnable",  'false');
             INSERT INTO "settings" ("key", "value") VALUES ("tgBotToken",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("tgBotProxy",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("tgBotAPIServer",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("tgBotChatId",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("tgRunTime",  '@daily');
	     INSERT INTO "settings" ("key", "value") VALUES ("tgBotBackup",  'false');
             INSERT INTO "settings" ("key", "value") VALUES ("tgBotLoginNotify",  'true');
	     INSERT INTO "settings" ("key", "value") VALUES ("tgCpu",  '80');
             INSERT INTO "settings" ("key", "value") VALUES ("tgLang",  'en-US');
	     INSERT INTO "settings" ("key", "value") VALUES ("timeLocation",  'Europe/Moscow');
             INSERT INTO "settings" ("key", "value") VALUES ("secretEnable",  'false');
	     INSERT INTO "settings" ("key", "value") VALUES ("subDomain",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("subCertFile",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("subKeyFile",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("subUpdates",  '12');
	     INSERT INTO "settings" ("key", "value") VALUES ("subEncrypt",  'true');
             INSERT INTO "settings" ("key", "value") VALUES ("subShowInfo",  'true');
	     INSERT INTO "settings" ("key", "value") VALUES ("subJsonFragment",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("subJsonNoises",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("subJsonMux",  '');
             INSERT INTO "settings" ("key", "value") VALUES ("subJsonRules",  '');
	     INSERT INTO "settings" ("key", "value") VALUES ("datepicker",  'gregorian');
             INSERT INTO "client_traffics" ("inbound_id","enable","email","up","down","expiry_time","total","reset") VALUES ('1','1','first','0','0','0','0','0');
	     INSERT INTO "client_traffics" ("inbound_id","enable","email","up","down","expiry_time","total","reset") VALUES ('2','1','first_1','0','0','0','0','0');
             INSERT INTO "inbounds" ("user_id","up","down","total","remark","enable","expiry_time","listen","port","protocol","settings","stream_settings","tag","sniffing","allocate") VALUES ( 
             '1',
	     '0',
             '0',
	     '0',
             'reality',
	     '1',
             '0',
	     '',
             '8443',
	     'vless',
             '{
	     "clients": [
    {
      "id": "${client_id}",
      "flow": "xtls-rprx-vision",
      "email": "first",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": "",
      "subId": "first",
      "reset": 0
    }
  ],
  "decryption": "none",
  "fallbacks": []
}',
	     '{
  "network": "tcp",
  "security": "reality",
  "externalProxy": [
    {
      "forceTls": "same",
      "dest": "${domain}",
      "port": 443,
      "remark": ""
    }
  ],
  "realitySettings": {
    "show": false,
    "xver": 0,
    "dest": "${reality_domain}:9443",
    "serverNames": [
      "$reality_domain"
    ],
    "privateKey": "${private_key}",
    "minClient": "",
    "maxClient": "",
    "maxTimediff": 0,
    "shortIds": [
      "${shor[0]}",
      "${shor[1]}",
      "${shor[2]}",
      "${shor[3]}",
      "${shor[4]}",
      "${shor[5]}",
      "${shor[6]}",
      "${shor[7]}"
    ],
    "settings": {
      "publicKey": "${public_key}",
      "fingerprint": "random",
      "serverName": "",
      "spiderX": "/"
    }
  },
  "tcpSettings": {
    "acceptProxyProtocol": true,
    "header": {
      "type": "none"
    }
  }
}',
             'inbound-8443',
	     '{
  "enabled": false,
  "destOverride": [
    "http",
    "tls",
    "quic",
    "fakedns"
  ],
  "metadataOnly": false,
  "routeOnly": false
}',
'{
  "strategy": "always",
  "refresh": 5,
  "concurrency": 3
}'
	     );
      INSERT INTO "inbounds" ("user_id","up","down","total","remark","enable","expiry_time","listen","port","protocol","settings","stream_settings","tag","sniffing","allocate") VALUES ( 
             '1',
	     '0',
             '0',
	     '0',
             'vless_ws',
	     '1',
             '0',
	     '',
             '${ws_port}',
	     'vless',
             '{
  "clients": [
    {
      "id": "${client_id2}",
      "flow": "",
      "email": "first_1",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": "",
      "subId": "first",
      "reset": 0
    }
  ],
  "decryption": "none",
  "fallbacks": []
}|{
  "network": "ws",
  "security": "none",
  "externalProxy": [
    {
      "forceTls": "tls",
      "dest": "${domain}",
      "port": 443,
      "remark": ""
    }
  ],
  "wsSettings": {
    "acceptProxyProtocol": false,
    "path": "/${ws_port}/${ws_path}",
    "host": "${domain}",
    "headers": {}
  }
},
             'inbound-${ws_port}',
	     '{
  "enabled": false,
  "destOverride": [
    "http",
    "tls",
    "quic",
    "fakedns"
  ],
  "metadataOnly": false,
  "routeOnly": false
}',
'{
  "strategy": "always",
  "refresh": 5,
  "concurrency": 3
}'
	     );
EOF
x-ui start
else
	msg_err "x-ui.db file not exist! Maybe x-ui isn't installed." && exit 1;
fi
}

###################################Install X-UI#########################################################
if systemctl is-active --quiet x-ui; then
	x-ui restart
else
	PANEL=( "https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh"
			"https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh"
			"https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install_en.sh"
		)

	printf 'n\n' | bash <(wget -qO- "${PANEL[$PNLNUM]}")
	UPDATE_XUIDB
	if ! systemctl is-enabled --quiet x-ui; then
		systemctl daemon-reload && systemctl enable x-ui.service
	fi
	x-ui restart
fi

######################enable bbr and tune system########################################################
apt-get install -yqq --no-install-recommends ca-certificates
echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
echo "fs.file-max=2097152" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps = 1" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_sack = 1" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_window_scaling = 1" | tee -a /etc/sysctl.conf
echo "net.core.rmem_max = 16777216" | tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" | tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" | tee -a /etc/sysctl.conf

sysctl -p







######################install_fake_site#################################################################

sudo su -c "bash <(wget -qO- https://raw.githubusercontent.com/mozaroc/x-ui-pro/refs/heads/master/randomfakehtml.sh)"


######################cronjob for ssl/reload service/cloudflareips######################################
crontab -l | grep -v "certbot\|x-ui\|cloudflareips" | crontab -
(crontab -l 2>/dev/null; echo '@daily x-ui restart > /dev/null 2>&1 && nginx -s reload;') | crontab -
(crontab -l 2>/dev/null; echo '@weekly bash /etc/nginx/cloudflareips.sh > /dev/null 2>&1;') | crontab -
(crontab -l 2>/dev/null; echo '@monthly certbot renew --nginx --non-interactive --post-hook "nginx -s reload" > /dev/null 2>&1;') | crontab -
##################################ufw###################################################################
ufw disable
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable  
##################################Show Details##########################################################

if systemctl is-active --quiet x-ui; then clear
	printf '0\n' | x-ui | grep --color=never -i ':'
	msg_inf "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	nginx -T | grep -i 'ssl_certificate\|ssl_certificate_key'
	msg_inf "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	certbot certificates | grep -i 'Path:\|Domains:\|Expiry Date:'

#	msg_inf "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
#	if [[ -n $IP4 ]] && [[ "$IP4" =~ $IP4_REGEX ]]; then 
#		msg_inf "IPv4: http://$IP4:$PORT/$RNDSTR/"
#	fi
#	if [[ -n $IP6 ]] && [[ "$IP6" =~ $IP6_REGEX ]]; then 
#		msg_inf "IPv6: http://[$IP6]:$PORT/$RNDSTR/"
#	fi

 msg_inf "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	msg_inf "X-UI Secure Panel: https://${domain}/${panel_path}/\n"
 	echo -n "Username:  " && sqlite3 $XUIDB 'SELECT "username" FROM users;'
	echo -n "Password:  " && sqlite3 $XUIDB 'SELECT "password" FROM users;'
	msg_inf "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	msg_inf "Please Save this Screen!!"	
else
	nginx -t && printf '0\n' | x-ui | grep --color=never -i ':'
	msg_err "sqlite and x-ui to be checked, try on a new clean linux! "
fi
#################################################N-joy##################################################
