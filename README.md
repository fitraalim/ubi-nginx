# NGINX on Red Hat Universal Base Image (UBI)

## Features

- Using Red Hat Universal Base Image (UBI) Minimal from registry.access.redhat.com
- Using NGINX 1.20.1 (I use stable stream, but mainline stream is there in nginx.repo)
- Using port 8080

## Content of the Repository

Dockerfile

```sh
FROM registry.access.redhat.com/ubi8-minimal:latest

EXPOSE 8080

COPY nginx.repo /etc/yum.repos.d/nginx.repo

RUN set -x && \
    rpm --import https://nginx.org/keys/nginx_signing.key && \
    microdnf install -y --nodocs nginx && \
    microdnf clean all && \
    rm -f /etc/nginx/nginx.conf && \
    rm -f /etc/nginx/conf.d/default.conf

RUN set -x \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

COPY ["nginx.conf", "/etc/nginx/nginx.conf"]
COPY ["entrypoint.sh", "/entrypoint.sh"]

RUN chown 1001:0 entrypoint.sh && \
    chmod +x entrypoint.sh && \
    chown -R 1001:0 /var/log/nginx && \
    chown -R 1001:0 /var/run && \
    chown -R 1001:0 /usr/share/nginx && \
    chown -R 1001:0 /var/cache/nginx

USER 1001

CMD ["/bin/sh", "./entrypoint.sh"]

```

entrypoint.sh

```sh
nginx -g "daemon off;"
```

nginx.repo

```sh
[nginx-stable]
name=nginx stable repo
baseurl=http://nginx.org/packages/centos/$releasever/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

[nginx-mainline]
name=nginx mainline repo
baseurl=http://nginx.org/packages/mainline/centos/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=https://nginx.org/keys/nginx_signing.key
module_hotfixes=true

```

nginx.conf
```
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /tmp/nginx.pid;
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
    server {
        listen       8080 default_server;
        listen       [::]:8080 default_server;
        server_name  _;
        root         /usr/share/nginx/html;
        include /etc/nginx/default.d/*.conf;
        location / {
        }
        error_page 404 /404.html;
            location = /40x.html {
        }
        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
    client_body_temp_path /tmp/client_temp;
    proxy_temp_path       /tmp/proxy_temp_path;
    fastcgi_temp_path     /tmp/fastcgi_temp;
    uwsgi_temp_path       /tmp/uwsgi_temp;
    scgi_temp_path        /tmp/scgi_temp;
}
```
