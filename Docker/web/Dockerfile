FROM nginx:1.22.0

ARG USER_NAME=nginx
ENV TZ=Asia/Tokyo

RUN rm -f /etc/nginx/conf.d/*
COPY ./nginx/nginx.conf /etc/nginx/nginx.conf
COPY ./nginx/conf.d/myapp.conf /etc/nginx/conf.d/myapp.conf
RUN chown -R ${USER_NAME} /etc/nginx

RUN chown -R ${USER_NAME} /var/cache/nginx

USER ${USER_NAME}

EXPOSE 80

CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-c", "/etc/nginx/nginx.conf"]
