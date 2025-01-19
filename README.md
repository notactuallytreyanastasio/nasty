# Nasty

A cyberpunk-themed bookmark manager with real-time event feeds.

## Setup & Running

### Prerequisites
- Elixir 1.14+
- PostgreSQL
- Python 3.x (for feed client)

### Initial Setup

1. Clone the repository and install dependencies:
```bash
git clone <repo-url>
cd nasty
mix setup
```

2. Configure traffic simulation in `config/config.exs`:
```elixir
# Enable simulated bookmark creation
config :nasty, :simulate_traffic, true
```

3. Start the Phoenix server:
```bash
mix phx.server
```

4. Install the required Python package:
```bash
pip3 install websockets
```

2. Run the feed client:
```bash
python3 scripts/bookmark_feed.py
```

The script will connect to the WebSocket and display real-time events for:
- Bookmark creation
- Bookmark updates
- Bookmark deletion

Each event includes:
- Title
- Description
- URL
- Tags
- Timestamp
- Public/Private status

### Event Feed Integration

The WebSocket feed is available at `ws://localhost:4000/socket/websocket` and broadcasts on the `bookmark:feed` topic.

Events are published in the following format:
```json
{
  "event": "bookmark:created",
  "payload": {
    "title": "Example Title",
    "description": "Example Description",
    "url": "https://example.com",
    "tags": ["tag1", "tag2"],
    "timestamp": "2024-01-19T12:34:56Z"
  }
}
```

## Development

### Running Tests
```bash
mix test
```

### Useful Commands
- `mix phx.server` - Start the development server
- `mix ecto.reset` - Reset the database
- `iex -S mix` - Start an interactive Elixir shell with the project loaded

### Creating a User

1. Visit [`localhost:4000/users/register`](http://localhost:4000/users/register)
2. Fill in your details:
   - Email
   - Password (8 characters minimum)
3. You'll be automatically logged in after registration

### Using the Bookmark Manager

#### Manual Bookmark Creation
1. Click the `$ new_bookmark` button
2. Fill in the bookmark details:
   - URL
   - Title
   - Description (optional)
   - Tags (comma-separated)
   - Public/Private setting

#### Simulated Traffic
When `simulate_traffic` is enabled, the system will automatically generate sample bookmarks every 30 seconds.

### Connecting to the Event Feed

The application provides a WebSocket feed of all bookmark events. You can connect to it using the included Python script:

1. Install the required Python package:
```bash
pip3 install websockets
```

2. Run the feed client:
```bash
python3 scripts/bookmark_feed.py
```

The script will connect to the WebSocket and display real-time events for:
- Bookmark creation
- Bookmark updates
- Bookmark deletion

Each event includes:
- Title
- Description
- URL
- Tags
- Timestamp
- Public/Private status

### Event Feed Integration

The application provides a WebSocket feed of all bookmark events. You can connect to it using the included Python script:

1. Install the required Python package:
```bash
pip3 install websockets
```

2. Run the feed client:
```bash
python3 scripts/bookmark_feed.py
```

The script will connect to the WebSocket and display real-time events for:
- Bookmark creation
- Bookmark updates
- Bookmark deletion

Each event includes:
- Title
- Description
- URL
- Tags
- Timestamp
- Public/Private status

## Development

### Running Tests
```bash
mix test
```

### Useful Commands
- `mix phx.server` - Start the development server
- `mix ecto.reset` - Reset the database
- `iex -S mix` - Start an interactive Elixir shell with the project loaded
