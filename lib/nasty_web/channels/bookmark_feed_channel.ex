defmodule NastyWeb.BookmarkFeedChannel do
  use Phoenix.Channel
  require Logger
  alias Nasty.Bookmarks.PubSub

  def join("bookmark:feed", _payload, socket) do
    PubSub.subscribe()
    Logger.info("Client joined bookmark feed")
    {:ok, socket}
  end

  # Handle PubSub messages and push them directly to the client
  def handle_info({:create_bookmark, attrs, tags}, socket) do
    push(socket, "bookmark:created", %{
      title: attrs["title"],
      description: attrs["description"],
      url: attrs["url"],
      tags: tags,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def handle_info({:update_bookmark, bookmark, attrs, tags}, socket) do
    push(socket, "bookmark:updated", %{
      id: bookmark.id,
      title: attrs["title"],
      description: attrs["description"],
      url: attrs["url"],
      tags: tags,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end

  def handle_info({:delete_bookmark, bookmark}, socket) do
    push(socket, "bookmark:deleted", %{
      id: bookmark.id,
      timestamp: DateTime.utc_now()
    })

    {:noreply, socket}
  end
end
