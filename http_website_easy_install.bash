#!/bin/bash
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
echo "if you want to allow any domain name to visit your website,you can leave this input empty(just carrige return)"
read -p "> " web_domains
# TODO check the domain resolve dig +short domain
web_first_domain=$(echo $web_domains|tr -s [:blank:]|cut -d ' ' -f 1)
nginx_web_config_file=$web_first_domain".conf"
nginx_web_config_domain=$web_domains
web_names=$web_domains
if [[ -z $(echo $web_domains|sed 's/ //g') ]]; then
    nginx_web_config_domain=~^.*\$ 
    web_names="  any domain which has been resolved to this server"
    nginx_web_config_file="free_domain_web.conf"
fi
echo "please input your website absolute path"
echo "if your input is not absolute path,the current directory will be preappend"
read -p "> " web_dir
if [[ ! "$web_dir" == /* ]]; then
	web_dir=$(pwd)"/"$web_dir
fi
echo "your web directory will be "$web_dir
mkdir -p ${web_dir}
cur_chmod_dir=$web_dir
while [[ $cur_chmod_dir != / ]]; do
    chmod o+x "$cur_chmod_dir"
    cur_chmod_dir=$(dirname "$cur_chmod_dir")
done
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
web domain: $web_names
nginx config dir: $nginx_config_dir

please input the number to confirm these information
1):confirm
2):not correct,I want to quit
EOF
read -p "> " confirm
if [[  $confirm -eq 2 ]]; then
    exit 0
fi
cat > $nginx_config_dir"/conf.d/"$nginx_web_config_file <<EOF
server {
    listen 80;
    server_name $nginx_web_config_domain;
    index index.html index.htm;
    location / {
	root $web_dir;
    }
}
EOF
if [[ ! -f $web_dir/index.html ]]; then
cat > $web_dir/index.html << EOF
generate http website succssfully<br/>
this is the index.html of $web_names <br/>
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
generate http website succssfully
your website directory is $web_dir
your nginx config file is $nginx_config_dir/conf.d/$nginx_web_config_file
you can visit your website through $web_names
EOF
