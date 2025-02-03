import json
from datetime import datetime

import uvicorn
from fastapi import FastAPI, Request

app = FastAPI(title="Stalker Webhook Test")


@app.post("/stalker")
async def receive_stats(request: Request):
    data = await request.json()
    timestamp = datetime.fromtimestamp(data["timestamp"])

    print("\n=== Stalker Update ===")
    print(f"Time: {timestamp}")
    print(f"Event: {data['event_type']}")
    print("Stats:")
    print(json.dumps(data["stats"], indent=2))
    print("===================\n")

    return {"status": "ok"}


if __name__ == "__main__":
    print("Starting Stalker receiver on http://localhost:8000/stalker")
    uvicorn.run(app, host="0.0.0.0", port=8000)
