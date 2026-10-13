# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        g++ \
        make \
        pkg-config \
        libjpeg62-turbo-dev \
        libpng-dev \
        libfreetype-dev \
        libwebp-dev \
        ca-certificates
RUN update-ca-certificates

WORKDIR /app

ADD --checksum=sha256:53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384 \
    --unpack https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2 .
ADD --checksum=sha256:d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3 \
    --unpack https://zlib.net/zlib-1.3.2.tar.xz .
ADD --checksum=sha256:9acfe68419c4d06a45c550321b3212762d92f41465062ca4ea19e632ee5d216e \
    --unpack https://download.gnome.org/sources/libxslt/1.1/libxslt-1.1.45.tar.xz .
ADD --checksum=sha256:3fe822ece20796060af63b7c60acb151e5844204d289da0ce08f8fdf131e5a61 \
    --unpack https://github.com/libgd/libgd/releases/download/gd-2.3.3/libgd-2.3.3.tar.xz .
ADD --checksum=sha256:1dfb748003c5e4b7fd56ba8c4cd786633d5d6f409547584f6910398389636f80 \
    --unpack https://github.com/maxmind/geoip-api-c/releases/download/v1.6.12/GeoIP-1.6.12.tar.gz .
ADD --checksum=sha256:98087fd181d9070724f3fbc65c7377db03038eb92bd882374daff44940138821 \
    --unpack https://download.gnome.org/sources/libxml2/2.15/libxml2-2.15.4.tar.xz .
RUN cd libxml2-2.15.4 \
    && ./configure --disable-static --without-python \
    && make -j"$(nproc)" \
    && make install
RUN cd libxslt-1.1.45 \
    && ./configure --disable-static --without-python \
    && make -j"$(nproc)" \
    && make install
RUN cd libgd-2.3.3 \
    && ./configure --disable-static --with-jpeg --with-png --with-freetype --with-webp \
    && make -j"$(nproc)" \
    && make install
RUN cd GeoIP-1.6.12 \
    && ./configure --disable-static \
    && make -j"$(nproc)" \
    && make install
RUN ldconfig
ADD --checksum=sha256:a2157c2830efdec3788939b00c9b0638306d3f0bbb76dc4832ee503bb397df98 \
    --unpack https://github.com/openssl/openssl/releases/download/openssl-3.6.5/openssl-3.6.5.tar.gz .
RUN git clone --branch release-1.25.0 \
    https://github.com/nginx/nginx.git
RUN git clone --depth 1 --branch 0.7.12 \
    https://github.com/nginx/njs.git
WORKDIR ./nginx
COPY build/patches/ /tmp/patches/
RUN git apply /tmp/patches/CVE-2023-44487.patch

RUN ./auto/configure \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_xslt_module=dynamic \
    --with-http_geoip_module=dynamic \
    --with-http_image_filter_module=dynamic \
    --with-http_v2_module \
    --with-http_v3_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_geoip_module=dynamic \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module \
    --add-dynamic-module=../njs/nginx \
    --with-openssl=../openssl-3.6.5 \
    --with-openssl-opt=-fPIC \
    --with-cc-opt="-I/usr/local/include -I/usr/local/include/libxml2" \
    --with-ld-opt=-L/usr/local/lib \
    --with-pcre=../pcre2-10.49 \
    --with-zlib=../zlib-1.3.2
# libxml2 2.15 returns a const xmlError from xmlCtxtGetLastError().
RUN sed -i 's/xmlError       \*err;/const xmlError *err;/' \
    /app/njs/external/njs_xml_module.c
RUN make -j"$(nproc)"
RUN make install DESTDIR=/app/build
RUN mkdir -p /app/build/usr/local/lib \
    && cp -a /usr/local/lib/libxml2.so* /usr/local/lib/libxslt.so* /usr/local/lib/libexslt.so* \
        /usr/local/lib/libgd.so* /usr/local/lib/libGeoIP.so* \
        /app/build/usr/local/lib/
RUN sed -i '1i\
load_module modules/ngx_http_xslt_filter_module.so;\n\
load_module modules/ngx_http_geoip_module.so;\n\
load_module modules/ngx_stream_geoip_module.so;\n\
load_module modules/ngx_http_image_filter_module.so;\n\
load_module modules/ngx_http_js_module.so;\n\
load_module modules/ngx_stream_js_module.so;' \
    /app/build/usr/local/nginx/conf/nginx.conf

COPY build/control /app/build/DEBIAN/control
WORKDIR /app/build
RUN dpkg-deb --build --root-owner-group /app/build /app/nginx.deb


FROM scratch AS package
COPY --from=build /app/nginx.deb /nginx.deb
