# Building a little bookmarking thing in Elixir/Phoenix/LiveView (1.0)
## Initial Thoughts
At first, I built this on a Saturday.
I started the project at around 1pm and made the last major commits by about midnight.

I was able to move this fast because I used an LLM to assist me.

To reflect on the other topic I want to write about, using LLMs to build software today, and learning the tools, I decided to prove I knew how to build this by taking the finished product and breaking it down into bite size pieces that can become a tutorial that builds up the premises step by step.

So, from there, here we go

## Goals

This guide explores building a feature-rich bookmarking application that showcases many of the powerful capabilities of Elixir, Phoenix, and LiveView.
We'll create a system that publishes real-time events for bookmark creation and discussions, leveraging process-based messaging between domain models and event-driven architecture.
The application will demonstrate how to build reactive web UIs, implement efficient caching layers, and handle complex pub/sub patterns through websockets.

I really wanted to build something that could be a talking point that shows off all my favorite touchpoints of modern Elixir/Phoenix development.

This guide doesn't even get into the great new stuff with the type system, but it goes a long way towards showing how all the pieces fit together.

Along the way, we'll explore how the BEAM VM enables us to create robust, concurrent systems.
We'll build a traffic simulator to test our application at scale, implement channel-based event publishing, and see how Phoenix and LiveView make traditionally complex features surprisingly straightforward to implement.
The end result will be a fully functional bookmarking system that handles real-time updates, filtered feeds, and cached responses - all with clean, maintainable code.

This is meant to be an approachable guide for developers looking to understand how these pieces fit together in practice.
We'll start from a fresh Phoenix application and incrementally add features, explaining the concepts and patterns as we go.
The focus is on showing how Elixir and Phoenix can elegantly handle complex requirements while keeping the codebase simple and understandable.

### We will go so far as to provide a commit for each major step of the way along the project so even if you are a little unclear, you can follow along

## Project Overview
Let's break down how we'll implement the features mentioned above. While this guide provides a high-level overview, the accompanying repo serves as a reference implementation that may differ slightly in details.

Key Features:
- Real-time bookmark and chat streams
- Tag-based feed filtering
- Live firehose view of all bookmarks
- Randomized bookmark discovery page

Implementation Path:
- User authentication (simplified for this guide)
- Core bookmark and tag models
- In-memory caching layer
- PubSub event system
- Traffic simulation for testing
- LiveView UI components
- PostgreSQL persistence
- Event broadcasting system
  - Global firehose events
  - Tag-filtered events

While this guide focuses on building a bookmarking system, the patterns and approaches demonstrated here can be applied to many other real-time, event-driven applications.
The concepts of caching, pub/sub messaging, and LiveView UIs are foundational for modern Phoenix applications.

## Getting Started
We want to start off with a basic new Phoenix LiveView project.
This can be accomplished with `mix phx.new nasty --live` to ensure we have all the nice toys.
Note: Modules here dont list a filepath but assume you will name them matching their path-ish.
You can save files wherever, but make sure to keep the module names matching here if you are newer to Elixir.
The path doesn't matter so long as its compiled in most cases, just the module.
We're going to start by building up a relational schema from the ground up.
We ultimately will be serving it mostly via a cache...but for now this works well.
This can be done with a pretty simple setup.

Users have bookmarks.
Bookmarks have a title, description, url, public/not public bool, tags, and a user.
Tags are a many to many relationship on tags lumping them into categories.

### Every Step in this has a commit we can checkout of the [sibling repo](https://github.com/robertgrayson/nasty_clone), they will be highlighted in each section and you can clone that repo and check out each commit if you are following along and can't get something to compile

We can map these out pretty quickly.

### A Basic Data Model and Layer

```elixir
defmodule Nasty.Bookmarks.Bookmark do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookmarks" do
    field :title, :string
    field :description, :string
    field :url, :string
    field :public, :boolean, default: true

    belongs_to :user, Nasty.Accounts.User
    many_to_many :tags, Nasty.Bookmarks.Tag, join_through: Nasty.Bookmarks.BookmarkTag

    timestamps()
  end

  @doc false
  def changeset(bookmark, attrs) do
    bookmark
    |> cast(attrs, [:title, :description, :url, :public, :user_id])
    |> validate_required([:title, :url, :user_id])
    |> validate_url(:url)
    |> assoc_constraint(:user)
  end

  def new_changeset do
    %__MODULE__{
      public: true,
      tags: []
    }
    |> changeset(%{})
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      case URI.parse(url) do
        %URI{scheme: scheme, host: host} when not is_nil(scheme) and not is_nil(host) ->
          []

        _ ->
          [{field, "must be a valid URL"}]
      end
    end)
  end
end
```
Simple enough.
This is just represents everything in standard ecto and leverages some URI parsing to check URLs.
Nex we represent a bookmark tag.

```elixir
defmodule Nasty.Bookmarks.BookmarkTag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bookmark_tags" do
    belongs_to :bookmark, Nasty.Bookmarks.Bookmark
    belongs_to :tag, Nasty.Bookmarks.Tag

    timestamps()
  end

  @doc false
  def changeset(bookmark_tag, attrs) do
    bookmark_tag
    |> cast(attrs, [:bookmark_id, :tag_id])
    |> validate_required([:bookmark_id, :tag_id])
    |> unique_constraint([:bookmark_id, :tag_id])
    |> assoc_constraint(:bookmark)
    |> assoc_constraint(:tag)
  end
end
```
Same story.

And finally the tag.

```elixir
defmodule Nasty.Bookmarks.Tag do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tags" do
    field :name, :string

    many_to_many :bookmarks, Nasty.Bookmarks.Bookmark, join_through: Nasty.Bookmarks.BookmarkTag

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
    |> update_change(:name, &String.downcase/1)
  end
end
```

Now we can add some migrations to create all of this.

```elixir
defmodule Nasty.Repo.Migrations.CreateBookmarks do
  use Ecto.Migration

  def change do
    create table(:bookmarks) do
      add :title, :string, null: false
      add :description, :text
      add :url, :string, null: false
      add :public, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:bookmarks, [:user_id])
    create index(:bookmarks, [:public])
  end
end
```

And tags.

```elixir
defmodule Nasty.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string, null: false

      timestamps()
    end

    create unique_index(:tags, [:name])
  end
end
```

And our join table.

```elixir
defmodule Nasty.Repo.Migrations.CreateBookmarkTags do
  use Ecto.Migration

  def change do
    create table(:bookmark_tags) do
      add :bookmark_id, references(:bookmarks, on_delete: :delete_all), null: false
      add :tag_id, references(:tags, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:bookmark_tags, [:bookmark_id])
    create index(:bookmark_tags, [:tag_id])
    create unique_index(:bookmark_tags, [:bookmark_id, :tag_id])
  end
end
```

Give it a `mix do deps.get, compile, ecto.create, ecto.migrate, phx.server` and lets see if we can create anything.

```elixir
$ mix do deps.get, compile, ecto.create, ecto.migrate
$ iex -S mix phx.server
iex> alias Nasty.Bookmarks.Bookmark
iex> alias Nasty.Repo
iex> bm = %Bookmark{
  title: "My stuff",
  url: "https://google.com",
  description: "winning",
  tags: []
} |> Repo.insert
{:ok,
 %Nasty.Bookmarks.Bookmark{
   __meta__: #Ecto.Schema.Metadata<:loaded, "bookmarks">,
   id: 2886,
   title: "My stuff",
   description: "winning",
   url: "https://google.com",
   public: true,
   tags: [],
   inserted_at: ~N[2025-01-20 05:49:37],
   updated_at: ~N[2025-01-20 05:49:37]
 }}
```
#### Commit 53aca37178085861a4523d2b9c214b861dee843d
Great, so we can insert bookmarks, and lets just assume we have tags working (they do).

Next, we want to start thinking about the higher order usage of our system.

This isn't just a bookmarking tool, we want people to build on top of the feeds of bookmarks coming in as things develop.

In order to work towards a pubsub system, first we will need an in-memory store representing all of this so that we can track these records dynamically.

These cache setups in ETS are very easy in Elixir/Erlang, and really shine here.

We can have the ETS process listen to pubsub messages, and write accordingly.

Let's take a look at our highest level layer: `Cache`.

```elixir
defmodule Nasty.Bookmarks.Cache do
  use GenServer
  require Logger

  @table_name :bookmarks_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(@table_name, [:set, :protected, :named_table])
    {:ok, %{table: table}, {:continue, :load_bookmarks}}
  end

  def handle_cast({:create_bookmark, attrs, tags}, state) do
    # TODO handle tags
    GenServer.cast(__MODULE__, {:update_bookmark, attrs})
    {:noreply, state}
  end

  # Server callbacks
  def handle_cast({:update_bookmark, bookmark}, state) do
    [{:all_bookmarks, bookmarks}] = :ets.lookup(@table_name, :all_bookmarks)
    :ets.insert(@table_name, {:all_bookmarks, bookmarks ++ [bookmark]})
    {:noreply, state}
  end

  def handle_continue(:load_bookmarks, state) do
    :ets.insert(@table_name, {:all_bookmarks, []})
    {:noreply, state}
  end
end
```

We can start by playing in IEx with this interface

```elixir
iex> alias Nasty.Bookmarks.Cache
iex> alias Nasty.Repo
iex> GenServer.cast(
  Nasty.Bookmarks.Cache,
  {
    :create_bookmark,
    %{url: "https://foo.com", title: "bar", description: "baz", public: true},
    []
  }
)
:ok
```

Now, if we go in and look at things with `:ets.all` we can see that we have a table with all of our bookmarks.

This enforces no typing contract of what an entry in here looks like, and we have one of those though.

Let's instead wire things up to use `Bookmark` structs that are representing the Ecto table.

Since this is all native Elixir, we can just have the Ecto struct can just be the one that the cache uses too.

```elixir
  ## cache.ex
defmodule NastyClone.Bookmarks.Cache do
  alias Nasty.Bookmarks.Bookmark
  # --- snip ---
  def handle_cast({:create_bookmark, attrs = %{title: title, description: description, url: url, public: public}, tags}, state) do
    bookmark = %Bookmark{
      title: title,
      description: description,
      url: url,
      public: public,
      # TODO tags
      # tags: tags
    }

    GenServer.cast(__MODULE__, {:update_bookmark, bookmark})
    {:noreply, state}
  end

  def handle_cast({:create_bookmark, attrs, tags}, state) do
    Logger.error("Invalid props given to :create_bookmark. provide title, description, url, and public")
    {:noreply, state}
  end
  # --- snip ---
```

Now, we are at least passing around `Bookmark` structs.
We are still hand waving away tags, but we can come back to that.
We at least are enforcing the shape of the data that we are passing around.

```elixir
iex> alias NastyClone.Bookmarks.Cache
NastyClone.Bookmarks.Cache
iex> Cache.start_link(nil)
{:ok, #PID<0.358.0>}
iex> GenServer.cast(NastyClone.Bookmarks.Cache, {:create_bookmark, %{url: "https://bizzle.com", title: "baz", description: "bizz", public: true}, []})
:ok
iex> :ets.tab2list(:bookmarks_cache)
[
  all_bookmarks: [
    %NastyClone.Bookmarks.Bookmark{
      __meta__: #Ecto.Schema.Metadata<:built, "bookmarks">,
      id: nil,
      title: "baz",
      description: "bizz",
      url: "https://bizzle.com",
      public: true,
      user_id: nil,
      user: #Ecto.Association.NotLoaded<association :user is not loaded>,
      tags: #Ecto.Association.NotLoaded<association :tags is not loaded>,
      inserted_at: nil,
      updated_at: nil
    }
  ]
]
```

#### Commit 818e3d65422581e03538544d905b292e2960aefa

For now, let's create a common interface for the cache and also back this into Postgres.

We can do this pretty simply by creating a 'Bookmarks' context module.
This module will be how we access 'state' in bookmarks as a whole.
Since we have both postgres and the cache now, we want to have a single interface to set these values.

We will start with the `Bookmarks` context module.

```elixir
defmodule NastyClone.Bookmarks do
  import Ecto.Query

  alias NastyClone.Repo
  alias NastyClone.Bookmarks.Bookmark
  alias Tag
  alias Cache

  def get(id), do: Repo.get!(Bookmark, id) |> Repo.preload(:tags)

  def create(attrs \\ %{}, tags) do
    # TODO tags
    bookmark =
      %Bookmark{}
      |> Bookmark.changeset(attrs)
      |> Repo.insert!()

    GenServer.cast(Cache, {:create_bookmark, bookmark, tags})
    bookmark
  end
end
```

This does two things: create a bookmark, and then persist it to the cache as well.
It still returns the bookmark, for simplicity's sake.

Now, we will make some changes in the cache to handle this.
We are really just updating our handle_cast to accept the bookmark struct and then pass it to the cache.

```elixir
# Cache

  # snip
  def handle_cast(
        {
          :create_bookmark,
          bookmark = %Bookmark{title: title, description: description, url: url, public: public},
          tags
        },
        state
  ) do

    GenServer.cast(__MODULE__, {:update_bookmark, bookmark})
    {:noreply, state}
  end
  # snip
```

And finally, when we get a create event, we can update the cache as well as postgres.

With all of this wired up, we can really start to get real with things if we add PubSub.

However, first we will make a brief detour and quickly build a chrome extension that we can create bookmarks with, and set up an API endpoint to service that usecase.


## PubSub
Now, its time to wire up pubsub.
This takes quite a few moving parts, but it will all make quite a bit of sense once we start seeing event streams.
We will start this by connecting to PubSub from the beginning, and proceed to broadcast messages to it when we write to the cache & postgres.

```elixir
# Cache
   def init(_) do
     # our new line
+    Phoenix.PubSub.subscribe(NastyClone.PubSub, "bookmarks")
     table = :ets.new(@table_name, [:set, :protected, :named_table])
     {:ok, %{table: table}, {:continue, :load_bookmarks}}
   end
```
And next, we delete our `handle_cast` function and instead just handle info now.

```elixir
# Cache
  def handle_info({:bookmark_created, bookmark, tags}, state) do
    Logger.info("Received bookmark created event, updating cache")
    [{:all_bookmarks, bookmarks}] = :ets.lookup(@table_name, :all_bookmarks)
    :ets.insert(@table_name, {:all_bookmarks, bookmarks ++ [bookmark]})
    {:noreply, state}
  end
```

With this, we can implement a channel:

```elixir
defmodule NastyCloneWeb.BookmarkChannel do
  use NastyCloneWeb, :channel

  @impl true
  def join("bookmarks:firehose", _payload, socket) do
    Phoenix.PubSub.subscribe(NastyClone.PubSub, "bookmarks")
    {:ok, socket}
  end

  @impl true
  def handle_info({:bookmark_created, bookmark, tags}, socket) do
    broadcast_bookmark = %{
      id: bookmark.id,
      title: bookmark.title,
      description: bookmark.description,
      url: bookmark.url,
      public: bookmark.public,
      tags: tags,
      inserted_at: bookmark.inserted_at
    }

    push(socket, "bookmark_created", broadcast_bookmark)
    {:noreply, socket}
  end
end
```

This is pretty straightforward thanks to Phoenix's PubSub.
We are simply handling a basic join when someone comes for the firehose, and then if a bookmark is created pushing it to the client over the socket.

They key point to take away is how now we dont have to handle the cast.
We simple created the top level flow of data, and by subscribing, we can intercept exactly what we need and do with it as we please.
In this case, that is handling the creation end to end.

We need to make a generic user socket to start things with.

```elixir
defmodule NastyCloneWeb.UserSocket do
  use Phoenix.Socket

  # Channels
  channel "bookmarks:*", NastyCloneWeb.BookmarkChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
```

Now, for this channel to work, we need to add a subscription to the socket in our `endpoint.ex`

```elixir
  socket "/socket", NastyWeb.UserSocket,
    websocket: true,
    longpoll: false
```

And finally we make a final entrypoint to interface with Bookmarks now.

```elixir
defmodule NastyClone.Bookmarks do
  import Ecto.Query

  alias NastyClone.Repo
  alias NastyClone.Bookmarks.Bookmark
  alias Tag
  alias Cache

  def get(id), do: Repo.get!(Bookmark, id) |> Repo.preload(:tags)

  def create(attrs \\ %{}, tags) do
    # TODO tags
    bookmark =
      %Bookmark{}
      |> Bookmark.changeset(attrs)
      |> Repo.insert!()

    Phoenix.PubSub.broadcast(NastyClone.PubSub, "bookmarks", {:bookmark_created, bookmark, tags})
    bookmark
  end
end
```

#### Commit 8991bf63b993a1de5f87395c9e0e8330a3c6b53c

With this, lets create a JSON API endpoint to create bookmarks easily from our chrome extension.

```elixir
defmodule NastyCloneWeb.Api.BookmarkController do
  use NastyCloneWeb, :controller

  alias NastyClone.Bookmarks

  def create(conn, %{"bookmark" => bookmark_params}) do
    # Extract tags from params or default to empty list
    tags = Map.get(bookmark_params, "tags", [])

    # Create the bookmark
    bookmark = Bookmarks.create(bookmark_params, tags)
    resp = %{
      data: %{
        id: bookmark.id,
        title: bookmark.title,
        description: bookmark.description,
        url: bookmark.url,
        public: bookmark.public,
        inserted_at: bookmark.inserted_at
      },
      message: "Bookmark created successfully"
    }

    conn
    |> put_status(:created)
    |> json(%{bookmark: resp})
  end

  # Add a fallback for invalid params
  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid parameters. Expected 'bookmark' object in request body"})
  end
end
```

This is about as simple as phoenix can get, we are just taking the shape of the data being sent from the chrome extension and then creating a bookmark.
And it will work fine with `curl` or whatever else too.

Next, we add a route to the router.

```elixir
# Router
  scope "/api", NastyCloneWeb.Api do
    pipe_through :api

    resources "/bookmarks", BookmarkController, only: [:create]
  end
```

#### Commit c76ca38af883ca71b7195c1387a72130d5936d53

So now we have a pretty fully functioning system.
It can create bookmarks and pushes all this out to the firehose, and we have a cache we can serve a web app from.
We also have the tags system for soon creating multiple types of feeds.
We are backing everything in postgres so we can load the prior cache state pretty easily.

Restart your server, and give this a shot:

```bash
curl -X POST http://localhost:4000/api/bookmarks \
  -H "Content-Type: application/json" \
  -d '{
    "bookmark": {
      "title": "Example Site",
      "description": "An example bookmark",
      "url": "https://example.com",
      "public": true,
      "tags": ["example", "test"]
    }
  }'
```

Next, we kind of hand wave away building a Chrome extension.
It's super simple and you can skip it and just follow the advice in line 2 of the section.

## Chrome Extension
We're going to handwave most of this away, because its not the point of the guide.

In short, here is a [chrome extension](https://github.com/robertgrayson/nasty_chrome_extension) that we can use to create bookmarks.

Here is a super brief guide of the code.

We have a `popup.html` that is the UI of the extension.

We have `popup.js` that is the logic of the extension to submit the form and send the data to our API endpoint.

And finally we have `manifest.json` that is the metadata of the extension.

Now, you can throw this directory wherever you want.
But to load it, enable developer mode in Chrome and guide it to the directory.

The popup is mostly styles, the real meat is the input form:

```html
   <form id="bookmarkForm">
     <input type="text" id="title" placeholder="Title" required>
     <input type="text" id="tags" placeholder="Tags (comma separated)">
     <textarea id="description" placeholder="Description" rows="3"></textarea>
     <button type="submit">Save Bookmark</button>
   </form>
```

```javascript
document.addEventListener('DOMContentLoaded', function() {
  // Get current tab URL
  chrome.tabs.query({active: true, currentWindow: true}, function(tabs) {
    const currentTab = tabs[0];

    // Pre-fill form with page details
    document.getElementById('title').value = currentTab.title || '';

    // Handle form submission
    document.getElementById('bookmarkForm').addEventListener('submit', function(e) {
      e.preventDefault();
      const bookmark = {
        title: document.getElementById('title').value,
        url: currentTab.url,
        description: document.getElementById('description').value,
        tags: document.getElementById('tags').value,
        public: true
      };

      saveBookmark(bookmark);
    });
  });
});

async function saveBookmark(bookmark) {
  const statusDiv = document.getElementById('status');
  try {
    const response = await fetch('http://localhost:4000/api/bookmarks', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({ bookmark }),
    });

    const responseText = await response.text();
    let data;
    try {
      data = JSON.parse(responseText);
    } catch (e) {
      console.error('Failed to parse response as JSON:', e);
      throw new Error('Server returned invalid JSON');
    }

    if (!response.ok) {
      console.error('Error response:', data);
      throw new Error(JSON.stringify(data.errors || data.error || 'Unknown error'));
    }

    statusDiv.style.color = '#00ff00';
    statusDiv.textContent = 'Bookmark saved!';
    setTimeout(() => window.close(), 3000);
  } catch (error) {
    console.error('Error:', error);
    statusDiv.textContent = `Error: ${error.message}`;
  }
}
```

## Traffic
Now, for this to be interesting, we need to simulate some traffic to consume this firehose feed, and we need to have some clients active to see any of this happening.

We will quickly make a python client to listen to the firehose, and then we will also make a GenServer that will create bookmarks as if it were an API request as well.

We will wrap this all up to run alongside the system if an environment variable is set, and if so start creating fake traffic.

For sample data, I am going to seed the first 1000 messages from the simulator with some reddit data.

Consider this handwaved away, I saved it as a constant in a module.

It's accessible with `Reddit.link`

#### Commit ABCD



## A LiveView Showing the Link Feed
## Filtered By Tag Publishing/Topic
## Final Features, Reflections
