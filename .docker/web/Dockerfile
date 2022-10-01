# syntax=docker/dockerfile:1
ARG NGINX_IMAGE_TAG
FROM nginx:${NGINX_IMAGE_TAG}

RUN rm -f /etc/nginx/conf.d/*
RUN <<-EOF
	set -e
	chown -R nginx /var/cache/nginx
	chown -R nginx /var/run
EOF
USER nginx

CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
