defmodule Nasty.Bookmarks.PubSub do
  alias Phoenix.PubSub
  alias Nasty.Bookmarks.Cache

  @topic "bookmarks"

  def subscribe do
    PubSub.subscribe(Nasty.PubSub, @topic)
  end

  def broadcast_create(attrs, tags) do
    PubSub.broadcast(Nasty.PubSub, @topic, {:create_bookmark, attrs, tags})
  end

  def broadcast_update(bookmark, attrs, tags) do
    PubSub.broadcast(Nasty.PubSub, @topic, {:update_bookmark, bookmark, attrs, tags})
  end

  def broadcast_delete(bookmark) do
    PubSub.broadcast(Nasty.PubSub, @topic, {:delete_bookmark, bookmark})
  end
end
