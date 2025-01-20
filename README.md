# Building a little bookmarking thing in Elixir/Phoenix/LiveView (1.0)
I wanted to build something in LiveView with the 1.0 release that kind of touched all the best parts of Phoenix and LiveView.
So, this is a stab at that. What we end up with is a Bookmarking tracker that publishes a firehose of events for each bookmark being created, and each piece of discussion around the bookmarks.
We also bake in some caching that shows very fast response times.
We build a means to simulate traffic for the entire system that is self-contained but highly useful.
All of this is handled over pubsub and websockets.
On top of all this, we build it with a minimal amount of code.

## Goals
This is a high level guide.
The repo provided isn't guaranteed an exact reflection of what we are talking about.

- Publish a stream of bookmarks (cool links) and chats (commentary on the links)
- Organize bookmark feed by tag subscription
- Serve webpage showing link feed of firehose
- Serve webpage showing 20 random links or something

How do we get there
- Users: [Hand Wave away]
- Adding Bookmarks, and Tags
- A Cache Layer To Start
- Adding PubSub
- Simulating Traffic
- A Basic LiveView Showing The Feed
- Backing it in Postgres
- A Cache Layer to Start
- Publishing A Firehose of Events
- Publishing Events In A Filtered Manner

#### This is a post exploring how to build all of this up in general
However, it isn't an 'exact guide'.
But, the premises here are pretty portable and you should be able to take them away and apply them to a large swath of other concepts.

## Getting Started
We want to start off with a basic new Phoenix LiveView project.
This can be accomplished with `mix phx.new nasty --live` to ensure we have all the nice toys.
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

  alias Nasty.Bookmarks.Bookmark
  alias Nasty.Bookmarks.PubSub
  alias Nasty.Repo

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
    bookmarks = :ets.tab2list(@table_name)
    updated_bookmarks = [bookmark | bookmarks]
    :ets.insert(@table_name, {:all_bookmarks, updated_bookmarks})
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
  end
  # --- snip ---
```

Now, we are at least passing around `Bookmark` structs.
We are still hand waving away tags, but we can come back to that.
We at least are enforcing the shape of the data that we are passing around.

For now, let's create a common interface for the cache and also back this into Postgres.

## PubSub
## Traffic
## A LiveView Showing the Link Feed
## Websocket Firehose Publishing/Topic
## Filtered By Tag Publishing/Topic
## Final Features, Reflections
