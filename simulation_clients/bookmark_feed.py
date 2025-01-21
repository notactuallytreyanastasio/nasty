#!/usr/bin/env python3
import asyncio
import websockets
import json
from datetime import datetime

async def connect_to_feed():
    uri = "ws://localhost:4000/socket/websocket"

    async with websockets.connect(uri) as websocket:
        print(f"Connected to {uri}")

        # Join the bookmark feed channel
        join_message = {
            "topic": "bookmark:feed",
            "event": "phx_join",
            "payload": {},
            "ref": "1"
        }
        await websocket.send(json.dumps(join_message))

        while True:
            try:
                message = await websocket.recv()
                data = json.loads(message)

                if data.get("event") == "bookmark:created":
                    print("\n=== New Bookmark ===")
                    print(f"Title: {data['payload']['title']}")
                    print(f"URL: {data['payload']['url']}")
                    print(f"Tags: {data['payload']['tags']}")
                elif data.get("event") == "bookmark:updated":
                    print(json.dumps(data["payload"], indent=2))
                elif data.get("event") == "bookmark:deleted":
                    print(json.dumps(data["payload"], indent=2))
                elif data.get("event") == "bookmark:chat":
                    print("\n=== Chat Message ===")
                    print(f"Bookmark: {data['payload']['bookmark_title']}")
                    print(f"User: {data['payload']['user_email']}")
                    print(f"Message: {data['payload']['content']}")
                    print(f"Time: {data['payload']['timestamp']}")

            except websockets.exceptions.ConnectionClosed:
                print("Connection lost. Reconnecting...")
                break

async def main():
    while True:
        try:
            await connect_to_feed()
        except Exception as e:
            print(f"Error: {e}")
        await asyncio.sleep(5)  # Wait before reconnecting

if __name__ == "__main__":
    print("Starting bookmark feed client...")
    asyncio.run(main())
