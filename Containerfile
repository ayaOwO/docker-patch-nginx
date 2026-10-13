FROM debian:bookworm-slim
COPY dist/nginx.deb /tmp/nginx.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends /tmp/nginx.deb \
    && ldconfig \
    && rm /tmp/nginx.deb \
    && rm -rf /var/lib/apt/lists/*

RUN /usr/local/nginx/sbin/nginx -t
CMD ["/usr/local/nginx/sbin/nginx", "-g", "daemon off;"]
