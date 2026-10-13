# NGINX response comparison

From the repository root:

```sh
make image  # Build the rebuilt NGINX image first.
make test
```

Compose runs the baseline and rebuilt NGINX images with the same read-only
configuration, a FastAPI echo server, and pytest on a private network without
published ports. Echo and pytest share one Python image.
