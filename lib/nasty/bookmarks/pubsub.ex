defmodule Nasty.Bookmarks.PubSub do
  alias Phoenix.PubSub
  alias Nasty.Bookmarks.Cache

  @pubsub Nasty.PubSub
  @topic "bookmarks"

  def subscribe do
    PubSub.subscribe(@pubsub, @topic)
  end

  def broadcast_create(attrs, tags) do
    # Update cache first
    GenServer.cast(Cache, {:create_bookmark, attrs, tags})
    # Then broadcast the event
    PubSub.broadcast(@pubsub, @topic, {:create_bookmark, attrs, tags})
  end

  def broadcast_update(bookmark, attrs, tags) do
    GenServer.cast(Cache, {:update_bookmark, bookmark, attrs, tags})
    PubSub.broadcast(@pubsub, @topic, {:update_bookmark, bookmark, attrs, tags})
  end

  def broadcast_delete(bookmark) do
    GenServer.cast(Cache, {:delete_bookmark, bookmark})
    PubSub.broadcast(@pubsub, @topic, {:delete_bookmark, bookmark})
  end

  def broadcast_chat_message(message) do
    payload = %{
      event: "bookmark:chat",
      bookmark_id: message.bookmark_id,
      bookmark_title: message.bookmark.title,
      user_email: message.user.email,
      content: message.content,
      timestamp: DateTime.utc_now()
    }

    PubSub.broadcast(@pubsub, @topic, {:chat_message, payload})
  end
end
