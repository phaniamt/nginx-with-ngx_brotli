FROM ubuntu:16.04 AS nginx-build
ENV DEBIAN_FRONTEND noninteractive
#ENV NGINX_VERSION 1.16.1
RUN apt-get update -qq && \
apt install  -qq -y --no-install-recommends --no-install-suggests \
ca-certificates \
autoconf        \
automake        \
build-essential \
libtool         \
pkgconf         \
wget            \
git             \
zlib1g-dev      \
libssl-dev      \
libpcre3-dev    \
libxml2-dev     \
libyajl-dev     \
lua5.2-dev      \
libgeoip-dev    \
libcurl4-openssl-dev    \
openssl \
curl
RUN cd ~/ && curl -fSL https://nginx.org/download/nginx-$(nginx -v 2>&1 >/dev/null | tail -c 7).tar.gz -o nginx.tar.gz && tar zxvf nginx.tar.gz
RUN cd ~/ && git clone https://github.com/eustas/ngx_brotli.git && cd ~/ngx_brotli && git submodule update --init
RUN mkdir -p /opt/ngx_brotli
RUN cd ~/nginx-$(nginx -v 2>&1 >/dev/null | tail -c 7) && ./configure --with-compat --add-dynamic-module=../ngx_brotli && make modules && cp objs/*.so /opt/ngx_brotli
# Install the nginx
FROM ubuntu:16.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get update && apt-get install -y software-properties-common
RUN apt-get update && apt-get install -y iputils-ping vim wget curl
RUN add-apt-repository ppa:nginx/stable
RUN apt update
RUN apt install nginx -y
# Copy brotli modules
COPY --from=nginx-build /opt/ngx_brotli/* /usr/share/nginx/modules/
COPY brotli.conf /usr/share/nginx/modules-available/brotli.conf
RUN ln -s /usr/share/nginx/modules-available/brotli.conf /etc/nginx/modules-enabled/brotli.conf
# Copy nginx conf
COPY nginx.conf /etc/nginx/nginx.conf
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log
COPY virtual-hosts.com /etc/nginx/sites-available/virtual-hosts.com
RUN ln -s /etc/nginx/sites-available/virtual-hosts.com /etc/nginx/sites-enabled/virtual-hosts.com
EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]
