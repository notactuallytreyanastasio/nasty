defmodule Nasty.Bookmarks.Cache do
  use GenServer

  alias Nasty.Bookmarks.Bookmark
  alias Nasty.Repo

  @table_name :bookmarks_cache

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(@table_name, [:set, :protected, :named_table])
    {:ok, %{table: table}, {:continue, :load_bookmarks}}
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
      [{:all_bookmarks, bookmarks}] -> Map.get(bookmarks, user_id, [])
      [] -> []
    end
  end

  def get_public_bookmarks do
    case :ets.lookup(@table_name, :all_bookmarks) do
      [{:all_bookmarks, bookmarks}] ->
        bookmarks
        |> Map.values()
        |> List.flatten()
        |> Enum.filter(& &1.public)
      [] -> []
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
      |> Enum.concat([bookmark])

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
