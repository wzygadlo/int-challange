# Main image
FROM alpine:3.14

# Lock specific nginx version
ENV NGINX_VERSION=1.21.0

ARG BUILD_PKGS="build-base linux-headers openssl-dev pcre-dev wget zlib-dev "
ARG RUNTIME_PKGS="ca-certificates openssl pcre zlib tzdata git openssh"

# Install dependensies 
RUN \
  apk --no-cache add ${BUILD_PKGS} ${RUNTIME_PKGS}; \ 
  cd /tmp; \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz; \
  tar xzf nginx-${NGINX_VERSION}.tar.gz; \
  cd /tmp/nginx-${NGINX_VERSION}; \
  ./configure \
    --group=nginx \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --with-http_gzip_static_module \
    --with-http_stub_status_module \
    --with-pcre \
    --with-file-aio \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_fastcgi_module \
    --with-cc-opt=-O2 \
    --with-ld-opt=-Wl,-rpath,/usr/local/lib; \
  make; \
  make install; \
  addgroup -S nginx; \
  adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx; \
  # clear downloaded files and build packages
  rm -rf /tmp/*; \
  apk del ${BUILD_PKGS}; \
  rm -rf /var/cache/apk/*;

# Deploy simple page and nginx config 
COPY index.html /etc/nginx/html/
COPY nginx.conf /etc/nginx/nginx.conf

VOLUME ["/var/cache/nginx"]

EXPOSE 80

CMD ["nginx"]