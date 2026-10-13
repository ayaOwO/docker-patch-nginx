# NGINX response comparison

From the repository root:

```sh
make image  # Build the rebuilt NGINX image first.
make test
```

Compose runs the baseline and rebuilt NGINX images with the same read-only
configuration, a FastAPI echo server, and pytest on a private network without
published ports. Echo and pytest share one Python image.

The six tests compare GET `/`, GET `/test`, a 302 redirect from `/a` to `/b`
and its destination, POST at and above the 64 KiB body limit, and an invalid
HTTP request line. They compare status, body, and
Content-Type, Content-Length, Location, and Allow. Date, Server, and other
headers are ignored. Each test also checks the expected response.

Tests live in `tests/`, separate from the echo application in `src/`.
`pyproject.toml` configures discovery, importlib import mode, and strict mode.
The two GET cases use named parameters; a module-scoped fixture waits for
both proxies once before the tests run. Assertions remain plain Python asserts

Compose stops the services when pytest exits and returns pytest's exit code.
To override the NGINX images, use `make test BASELINE_IMAGE=... BUILD_IMAGE=...`.
