
FROM openresty/openresty:1.27.1.1-3-alpine
COPY nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
RUN chown -R 101:101 /usr/local/openresty/nginx/
EXPOSE 8080
USER 101