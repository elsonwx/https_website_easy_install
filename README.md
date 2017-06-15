# https_website_easy_install
one command to generate https website on nginx.All you need to do is input your domains and set your web directory according the terminal prompt.

### Usage

- Step 1: install nginx on linux

  - ubuntu/debian

    ````
    $ sudo apt-get update && sudo apt-get install nginx
    ````

  - centos/redhat

    ```
    $ sudo yum update && sudo yum -y install nginx
    ```

- Step 2: download this script

  ``` 
  $ wget https://git.io/vHQLm -O https_website_easy_install.bash
  ```

- Step 3: generate https website on your linux server

  ```
  $ sudo bash https_website_easy_install.bash
  ```


### Issues

#### Error: establish the http website failed,please view the issue of github doc

SELinux cause the nginx 403 error

The SELinux mode may be opened in centos/redhat 6.6 and later,you will fail in the first step to establish a http website.you can check whethe the SELinux is enabled in your server by exec `sestatus -v` command.this error can be solved by closing the SELinux simply,you can close the SELinux and restart your server

```
$ sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
$ sudo init 6
```

or you can solve this problem through these solutions

https://stackoverflow.com/a/26228135

https://www.nginx.com/blog/nginx-se-linux-changes-upgrading-rhel-6-6/#gs.iz_rbNA


### screenshot

![screenshot](screenshot/20170613.gif)



###  inspired

[Let's Encrypt](https://letsencrypt.org)

[diafygi/acme-tiny](https://github.com/diafygi/acme-tiny)


