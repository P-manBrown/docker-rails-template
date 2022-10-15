ARG NGINX_IMAGE_TAG
FROM nginx:${NGINX_IMAGE_TAG}

ARG USER_NAME=nginx
ENV TZ=Asia/Tokyo

RUN rm -f /etc/nginx/conf.d/*
RUN chown -R ${USER_NAME} /var/cache/nginx

USER ${USER_NAME}

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
