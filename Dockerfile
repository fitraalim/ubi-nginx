FROM	registry.access.redhat.com/ubi8-minimal:latest

EXPOSE	8080

COPY	nginx.repo /etc/yum.repos.d/nginx.repo

RUN	set -x && \
	rpm --import https://nginx.org/keys/nginx_signing.key && \
	microdnf install -y --nodocs nginx && \
	microdnf clean all && \
	rm -f /etc/nginx/nginx.conf && \
	rm -f /etc/nginx/conf.d/default.conf

RUN	set -x \
	&& ln -sf /dev/stdout /var/log/nginx/access.log \
	&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY	["nginx.conf", "/etc/nginx/nginx.conf"]
COPY	["entrypoint.sh", "/entrypoint.sh"]

RUN	chown 1001:0 entrypoint.sh && \
	chmod +x entrypoint.sh && \
	chown -R 1001:0 /var/log/nginx && \
	chown -R 1001:0 /var/run && \
	chown -R 1001:0 /usr/share/nginx && \
	chown -R 1001:0 /var/cache/nginx

USER	1001

CMD	["/bin/sh", "./entrypoint.sh"]
