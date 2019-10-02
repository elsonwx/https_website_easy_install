#!/bin/bash
python_command=''
if command -v python > /dev/null 2>&1; then
    echo 'python environment check succ..'
    python_command=python
else
    if command -v python3 > /dev/null 2>&1; then
        echo 'your python command is python3'
        python_command=python3
    else
        echo 'your server has no python environment,now install python for you'
        apt-get -y install python || yum -y install python
        echo 'python install succ..'
        python_command=python
    fi
fi 
if command -v openssl > /dev/null 2>&1; then
    echo 'openssl check succ..'
else
    echo 'no openssl,now install for you'
    apt-get -y install openssl || yum -y install openssl
fi 
exiterr()  {
    echo "Error: $1" >&2;
    exit 1; 
}
check_ip() {
    IP_REGEX="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
    printf %s "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}
PUBLIC_IP=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
check_ip "$PUBLIC_IP" || PUBLIC_IP=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
check_ip "$PUBLIC_IP" || exiterr "Cannot find your server ip address"

echo "your server ip is:${PUBLIC_IP}"
echo "please input your website domain name which has been resolved to $PUBLIC_IP"
echo "if you want to bind mutiple domain names,you can split them using space"
read -p "> " web_domains
# TODO check the domain resolve dig +short domain
domain_length=0
sign_domain_str=''
web_first_domain=$(echo $web_domains|tr -s [:blank:]|cut -d ' ' -f 1)
nginx_web_config_file=$web_first_domain".conf"
for web_domain in ${web_domains[@]}
do
    sign_domain_str=$sign_domain_str"DNS:"$web_domain","
    domain_length=$(($domain_length+1))
done
sign_domain_str=${sign_domain_str:0:${#sign_domain_str}-1}
echo "please input your website absolute path"
echo "if your input is not absolute path,the current directory will be preappend"
read -p "> " web_dir
if [[ ! "$web_dir" == /* ]]; then
	web_dir=$(pwd)"/"$web_dir
fi
echo "your web directory will be "$web_dir
echo "please input the nginx config dir"
echo "you can carrige return if it's default /etc/nginx"
read -p "> " nginx_config_dir
if [[ -z "$nginx_config_dir" ]]; then
    nginx_config_dir=/etc/nginx
fi
echo -e "\n"
cat << EOF
your configuration are as follows

web directory: $web_dir
web domain: $web_domains
nginx config dir: $nginx_config_dir

please input the number to confirm these information
1):confirm
2):not correct,I want to quit
EOF
read -p "> " confirm
if [[  $confirm -eq 2 ]]; then
    exit 0
fi
mkdir -p ${web_dir}"/certificate/challenges"
cur_chmod_dir=$web_dir
while [[ $cur_chmod_dir != / ]]; do
    chmod o+x "$cur_chmod_dir"
    cur_chmod_dir=$(dirname "$cur_chmod_dir")
done
cd $web_dir"/certificate"
# Create a Let's Encrypt account private key
openssl genrsa 4096 > account.key
# generate a domain private key
openssl genrsa 4096 > domain.key
if [[ $domain_length -gt 1 ]]; then
    openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=$sign_domain_str")) > domain.csr || openssl req -new -sha256 -key domain.key -subj "/" -reqexts SAN -config <(cat /etc/pki/tls/openssl.cnf <(printf "[SAN]\nsubjectAltName=$sign_domain_str")) > domain.csr
else
    openssl req -new -sha256 -key domain.key -subj "/CN=$web_domains" > domain.csr
fi
cat > $nginx_config_dir"/conf.d/"$nginx_web_config_file <<EOF
server {
    listen 80;
    server_name $web_domains;
    location /.well-known/acme-challenge/ {
        alias $web_dir/certificate/challenges/;
        try_files \$uri =404;
    }
}
EOF
service  nginx restart
wget --no-check-certificate https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
$python_command acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir $web_dir/certificate/challenges > ./signed.crt || exiterr "create the http website failed,please view the issue of github doc"
#NOTE: For nginx, you need to append the Let's Encrypt intermediate cert to your cert
wget --no-check-certificate  https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -O intermediate.pem
cat signed.crt intermediate.pem > chained.pem
cat > $nginx_config_dir"/conf.d/"$nginx_web_config_file <<EOF
server {
    listen 80;
    server_name $web_domains;
    rewrite ^(.*) https://\$host\$1 permanent;
}
server {
    listen 443;
    server_name $web_domains;
    root $web_dir;
    index index.html index.htm index.php;
    ssl on;
    ssl_certificate $web_dir/certificate/chained.pem;
    ssl_certificate_key $web_dir/certificate/domain.key;
    ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA;
    ssl_session_cache shared:SSL:50m;
    ssl_prefer_server_ciphers on;

    location /.well-known/acme-challenge/ {
            alias $web_dir/certificate/challenges/;
            try_files \$uri =404;
    }
    location /download {
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
    }
}
EOF
if [[ ! -f $web_dir/index.html ]]; then
cat > $web_dir/index.html << EOF
generate https website succssfully<br/>
this is the index.html of $web_first_domain <br/>
yout can visit this page from $web_domains
EOF
fi
# current_user=$USER
# current_user=$(id -un) not work for sudo
current_user=$(who am i|awk '{print $1}')
current_user_group=$(id -gn $current_user)
chown -R $current_user:$current_user_group $web_dir
chown $current_user:$current_user_group $nginx_config_dir"/conf.d/"$nginx_web_config_file
chmod -R 755 $web_dir
service nginx restart
echo -e "\n\n"
cat << EOF
generate https website succssfully
your website directory is $web_dir
your nginx config file is $nginx_config_dir/conf.d/$nginx_web_config_file
you can visit your website through these domains
EOF
for web_domain in ${web_domains[@]}
do
    echo https://$web_domain
done
cat > $web_dir/certificate/renew_cert.bash <<EOF
cd $web_dir/certificate
wget --no-check-certificate https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O acme_tiny.py
$python_command ./acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir $web_dir/certificate/challenges/ > /tmp/signed.crt || exit
wget --no-check-certificate -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat /tmp/signed.crt intermediate.pem > $web_dir/certificate/chained.pem
service nginx reload
EOF
if command -v crontab > /dev/null 2>&1; then
    echo 'crontab check succ..'
else
    echo 'no crontab program,now install for you'
    apt-get -y install cron || yum -y install cron
fi 
# (crontab -u $current_user -l ; echo "1 1 1 * * bash $web_dir/certificate/renew_cert.bash >> /var/log/renew_cert_error.log 2 >> /var/log/renew_cert.log") | crontab -u $current_user -
echo "1 1 1 * * root bash $web_dir/certificate/renew_cert.bash >> /var/log/renew_cert_error.log 2 >> /var/log/renew_cert.log" >> /etc/crontab
# nginx reload need root privilege,so the renew task need to be added in root's crontab
#(crontab -l; echo "1 1 1 * * bash $web_dir/certificate/renew_cert.bash > /var/log/renew_cert_stdout.log 2 > /var/log/renew_cert_stderr.log") | crontab -
echo "create renewal certificate task succ!"
read -p 'press any key to quit'
exit 0
