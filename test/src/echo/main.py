from fastapi import FastAPI, Request

app = FastAPI()


@app.api_route("/{path:path}", methods=["GET", "POST"])
async def echo(request: Request) -> dict[str, str]:
    return {
        "method": request.method,
        "path": request.url.path,
        "body": (await request.body()).decode("utf-8"),
    }
