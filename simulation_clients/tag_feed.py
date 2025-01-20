#!/usr/bin/env python3
import asyncio
import websockets
import json
import sys
from datetime import datetime

async def connect_to_tag_feed(tag_name):
    uri = "ws://localhost:4000/socket/websocket"

    async with websockets.connect(uri) as websocket:
        print(f"Connected to {uri} for tag: {tag_name}")

        # Join the tag feed channel
        join_message = {
            "topic": f"tag:{tag_name}",
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
                    print("\n=== New Bookmark with tag:", tag_name, "===")
                    print(f"Title: {data['payload']['title']}")
                    print(f"URL: {data['payload']['url']}")
                    print(f"Tags: {', '.join(data['payload']['tags'])}")

                elif data.get("event") == "bookmark:chat":
                    print("\n=== Chat Message for bookmark with tag:", tag_name, "===")
                    print(f"Bookmark: {data['payload']['bookmark_title']}")
                    print(f"User: {data['payload']['user_email']}")
                    print(f"Message: {data['payload']['content']}")
                    print(f"Time: {data['payload']['timestamp']}")

            except websockets.exceptions.ConnectionClosed:
                print("Connection lost. Reconnecting...")
                break

async def main():
    if len(sys.argv) != 2:
        print("Usage: python tag_feed.py <tag_name>")
        sys.exit(1)

    tag_name = sys.argv[1]

    while True:
        try:
            await connect_to_tag_feed(tag_name)
        except Exception as e:
            print(f"Error: {e}")
        await asyncio.sleep(5)

if __name__ == "__main__":
    print("Starting tag feed client...")
    asyncio.run(main())