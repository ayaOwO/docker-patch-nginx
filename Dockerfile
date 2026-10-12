# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS build

RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        g++ \
        make

WORKDIR /app

ADD https://github.com/nginx/nginx.git#release-1.25.5 nginx
ADD --checksum=sha256:53c156e1ba416a20da8e65395daa132da0d80e76910424caca3fcdae7831d384 \
    --unpack https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.49/pcre2-10.49.tar.bz2 .
ADD --checksum=sha256:d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3 \
    --unpack https://zlib.net/zlib-1.3.2.tar.xz .

WORKDIR ./nginx

RUN ./auto/configure \
    --with-pcre=../pcre2-10.49 \
    --with-zlib=../zlib-1.3.2
RUN make -j"$(nproc)"
RUN make install DESTDIR=/app/build

COPY control /app/build/DEBIAN/control
WORKDIR /app/build
RUN dpkg-deb --build --root-owner-group /app/build /app/nginx-custom.deb