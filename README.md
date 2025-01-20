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

We can map these out pretty quickly:

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

```
$ mix do deps.get, compile, ecto.create, ecto.migrate
$ iex -S mix phx.server
```

## PubSub
## Traffic
## A LiveView Showing the Link Feed
## Websocket Firehose Publishing/Topic
## Filtered By Tag Publishing/Topic
## Final Features, Reflections


# --- snip --- this is the old README.md ----- snip ------
# Nasty

This is a project where we build out bookmarking that you are running on another website.

Is this stupid? Yeah, people want a bookmark thing that works as a bookmarklet.

We will eventually add this and build it out, but I wanted to also build out a firehose of events on a channel that could be subscribed to by other applications.

In this we will go through building out that application, with the following basic requirements:

- A bookmark is published on a pubsub feed to a channel
- that channel can be subscribed to by other applications or in-app clients
- the in-app client can be a live view that displays the bookmarks
- we will build a simple python client attaching to the socket as well
- we will back it all up in postgres to start
- then we will move on to using an ETS cache
- then we move on to publishing pubsub events when creates or updates happen
- the ETS cache is also wired into those events

We will also make it look hacker-chic as we go along, but I just had Claude do that.

This project is a bit of a 'painting' -- its me working with Claude to make broad strokes then I refine it into the final pieces.

As it starts, I am going to leave in some bad naming, weird boundaries, etc that came up with Claude but I helped have be reasoned through and improved as each piece went on.

## Getting Started

```bash
mix phx.new nasty --live

cd nasty
# change config/dev.exs to use the correct database and user etc
mix do deps.get, compile, ecto.create, ecto.migrate, iex -S mix phx.server
```

Now, we have a basic running app with a live view.

The first thing we really did was scaffold out users.
I am going to handwave this away.
There are many tutorials on how to add this.
If you really need a state set up with a new project where you can make users and have the basics, fork this off from commit `f837345c8299550d2be84e4f066b615f714bd020`.

Once we have users set up, we can start building out the bookmarking.
We will begin this by adding a bookmark schema, migrations, and their associated child tags as well, and provide some interfaces on top of this.

We begin by adding a bookmark schema.

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
    |> validate_required([:title, :url, :public, :user_id])
    |> validate_url(:url)
    |> assoc_constraint(:user)
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

This is all pretty standard, but we're putting it here for any beginners following along.
The idea here is to just represent a table `bookmarks` that can have titles/descriptions, some tags, and a URL they point to.

This would be a much better fit as a bookmarklet, but we're gonna build out our data model before we build a client like that to work with everything we want to play with.

We can see here we mention a `BookmarkTag` schema, which is a many-to-many relationship between bookmarks and tags.
If we want to scaffold that out, it will look like this:

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

This just checks the basic boxes as well, representing the table.

And finally, we have a `Tag` schema.
This one is related through the join we just created.



So now we have some basic schemas, but we dont have migrations that will create these tables for us.

We can generate three migrations and populate them with the following:

### Create Bookmarks
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

### Create Tags


### Create BookmarkTags


Now we can move through all of this with a `mix ecto.gen.migration` command.

With that, we can consider the basics scaffolded here.
We have bookmarks, we have users, and we have tags.
We can generate some simple migrations for all of this:


