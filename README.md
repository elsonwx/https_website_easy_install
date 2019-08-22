# https_website_easy_install
one command to generate https website on nginx.All you need to do is input your domain names and set your web directory according the terminal prompt.

### Prerequisites

- **Port 80 and port 443 has been allowed in your server's firewall rule.**

### Usage

- Step 1: install nginx on linux

  - ubuntu/debian

    ````
    $ sudo apt-get update && sudo apt-get -y install nginx
    ````

  - centos/redhat

    ```
    $ sudo yum -y update && sudo yum -y install nginx
    ```

- Step 2: download this script

  ``` 
  $ wget --no-check-certificate https://git.io/vHQLm -O https_website_easy_install.bash
  ```

- Step 3: generate https website on your linux server

  ```
  $ sudo bash https_website_easy_install.bash
  ```


### Notes

- Nginx needs some permissions for your website directory,so it's better not to put your website under your $HOME directory.

- This script will set a cron task to update the certificate on the 1st of every month,so you do not have to worry about the free certificate would be expired.

- If you just want to generate a http website,you can download the `http_website_easy_install.bash` instead.

  ```
  $ wget https://git.io/vQfud -O http_website_easy_install.bash
  ```

- Some cloud platform's loading balance service has key length limit,e.g. Google Cloud loading balance only support RSA-2048.So if you want to deploy the ssl certificate on the loading balance.You can modify the key length before running this script.

  ```
  $ sed -i 's/4096/2048/g' https_website_easy_install.bash
  ```

- If you want to use chinese domain,you need to [convert chinese domain to punycode](http://www.jb51.net/article/101397.htm),then when you are asking to input the domain name by this script, just input the punycode.e.g.[https://王祥.我爱你](https://xn--qbyu8j.xn--6qq986b3xl),the punycode is `xn--qbyu8j.xn--6qq986b3xl`



### Issues

- #### SELinux cause the nginx 403 error

  The SELinux mode may be opened in centos/redhat 6.6 and later,you will fail in the first step to establish a http website.You can check whether the SELinux is enabled in your server through execute `sestatus -v` command.this error can be solved by closing the SELinux simply,you can close the SELinux and restart your server

  ```
  $ sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
  $ sudo init 6
  ```

  or you can solve this problem through these solutions

  https://stackoverflow.com/a/26228135

  https://www.nginx.com/blog/nginx-se-linux-changes-upgrading-rhel-6-6/#gs.iz_rbNA

- #### CentOS/RedHat No package nginx available

  you should enable the **EPEL**(*Extra Packages for Enterprise Linux*) repository or install nginx by other ways.

  [How to enable EPEL repository](https://www.liquidweb.com/kb/enable-epel-repository/)

  [Amazon EC2 enable EPEL](https://aws.amazon.com/cn/premiumsupport/knowledge-center/ec2-enable-epel/)

- #### Firewalls Issues

  - Vultr CentOS7 firewalls

    https://www.vultr.com/docs/using-firewalld-to-manage-your-firewall-on-centos-7

    ```
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    systemctl restart  firewalld
    ```

  - AWS EC2 Security Groups

    http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html

  - Google Cloud Firewall rules

    https://cloud.google.com/compute/docs/vpc/using-firewalls

  - Aliyun Security Groups

    https://help.aliyun.com/document_detail/25471.html?spm=5176.100241.0.0.SK8N6Y


### Screenshot

![screenshot](screenshot/20170613.gif)



###  Inspired

[Let's Encrypt](https://letsencrypt.org)

[diafygi/acme-tiny](https://github.com/diafygi/acme-tiny)


