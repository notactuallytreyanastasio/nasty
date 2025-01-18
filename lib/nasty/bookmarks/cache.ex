defmodule Nasty.Bookmarks.Cache do
  use GenServer
  require Logger

  alias Nasty.Bookmarks.{Bookmark, PubSub}
  alias Nasty.Repo

  @table_name :bookmarks_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(@table_name, [:set, :protected, :named_table])
    PubSub.subscribe()
    {:ok, %{table: table}, {:continue, :load_bookmarks}}
  end

  # Handle PubSub messages
  def handle_info({:create_bookmark, attrs, tags}, state) do
    case Nasty.Bookmarks.do_create_bookmark(attrs, tags) do
      {:ok, bookmark} ->
        update_cache(bookmark)
        Logger.info("Cache updated after bookmark creation: #{bookmark.title}")

      {:error, changeset} ->
        Logger.error("Failed to create bookmark in cache: #{inspect(changeset.errors)}")
    end

    {:noreply, state}
  end

  def handle_info({:update_bookmark, bookmark, attrs, tags}, state) do
    case Nasty.Bookmarks.do_update_bookmark(bookmark, attrs, tags) do
      {:ok, updated_bookmark} ->
        update_cache(updated_bookmark)
        Logger.info("Cache updated after bookmark update: #{updated_bookmark.title}")

      {:error, changeset} ->
        Logger.error("Failed to update bookmark in cache: #{inspect(changeset.errors)}")
    end

    {:noreply, state}
  end

  def handle_info({:delete_bookmark, bookmark}, state) do
    case Nasty.Bookmarks.do_delete_bookmark(bookmark) do
      {:ok, _} ->
        delete_from_cache(bookmark)
        Logger.info("Cache updated after bookmark deletion: #{bookmark.title}")

      {:error, changeset} ->
        Logger.error("Failed to delete bookmark from cache: #{inspect(changeset.errors)}")
    end

    {:noreply, state}
  end

  def handle_continue(:load_bookmarks, state) do
    # Load all bookmarks with their associations
    bookmarks =
      Bookmark
      |> Repo.all()
      |> Repo.preload([:tags, :user])
      |> Enum.group_by(& &1.user_id)

    # Store in ETS
    :ets.insert(@table_name, {:all_bookmarks, bookmarks})
    {:noreply, state}
  end

  # Client API

  def get_user_bookmarks(user_id) do
    case :ets.lookup(@table_name, :all_bookmarks) do
      [{:all_bookmarks, bookmarks}] ->
        bookmarks
        |> Map.get(user_id, [])
        |> Enum.sort_by(& &1.inserted_at, :desc)

      [] ->
        []
    end
  end

  def get_public_bookmarks do
    case :ets.lookup(@table_name, :all_bookmarks) do
      [{:all_bookmarks, bookmarks}] ->
        bookmarks
        |> Map.values()
        |> List.flatten()
        |> Enum.filter(& &1.public)
        |> Enum.sort_by(& &1.inserted_at, :desc)

      [] ->
        []
    end
  end

  def update_cache(%Bookmark{} = bookmark) do
    GenServer.cast(__MODULE__, {:update_bookmark, bookmark})
  end

  def delete_from_cache(%Bookmark{} = bookmark) do
    GenServer.cast(__MODULE__, {:delete_bookmark, bookmark})
  end

  # Server callbacks

  def handle_cast({:update_bookmark, bookmark}, state) do
    bookmark = Repo.preload(bookmark, [:tags, :user])

    [{:all_bookmarks, bookmarks}] = :ets.lookup(@table_name, :all_bookmarks)
    user_bookmarks = Map.get(bookmarks, bookmark.user_id, [])

    # Remove old version if it exists
    updated_user_bookmarks =
      user_bookmarks
      |> Enum.reject(&(&1.id == bookmark.id))

    # Add new bookmark to beginning or end based on ownership
    updated_user_bookmarks =
      if bookmark.user_id == bookmark.user_id do
        [bookmark | updated_user_bookmarks]
      else
        updated_user_bookmarks ++ [bookmark]
      end
      |> Enum.sort_by(& &1.inserted_at, :desc)

    updated_bookmarks = Map.put(bookmarks, bookmark.user_id, updated_user_bookmarks)
    :ets.insert(@table_name, {:all_bookmarks, updated_bookmarks})

    {:noreply, state}
  end

  def handle_cast({:delete_bookmark, bookmark}, state) do
    [{:all_bookmarks, bookmarks}] = :ets.lookup(@table_name, :all_bookmarks)
    user_bookmarks = Map.get(bookmarks, bookmark.user_id, [])

    updated_user_bookmarks = Enum.reject(user_bookmarks, &(&1.id == bookmark.id))
    updated_bookmarks = Map.put(bookmarks, bookmark.user_id, updated_user_bookmarks)
    :ets.insert(@table_name, {:all_bookmarks, updated_bookmarks})

    {:noreply, state}
  end
end
