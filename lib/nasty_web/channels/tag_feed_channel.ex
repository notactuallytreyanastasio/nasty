defmodule NastyWeb.TagFeedChannel do
  use Phoenix.Channel
  require Logger
  alias Nasty.Bookmarks.PubSub
  alias Nasty.Bookmarks

  def join("tag:" <> tag_name, _payload, socket) do
    PubSub.subscribe()
    Logger.info("Client joined tag feed for: #{tag_name}")
    {:ok, assign(socket, :tag_name, tag_name)}
  end

  # Handle bookmark creation - only broadcast if it has the relevant tag
  def handle_info({:create_bookmark, attrs, tags}, socket) do
    tag_name = socket.assigns.tag_name

    if tag_matches?(tags, tag_name) do
      push(socket, "bookmark:created", %{
        title: attrs["title"],
        description: attrs["description"],
        url: attrs["url"],
        tags: tags,
        timestamp: DateTime.utc_now()
      })
    end

    {:noreply, socket}
  end

  # Handle chat messages - only broadcast if the bookmark has the relevant tag
  def handle_info({:chat_message, payload}, socket) do
    bookmark = Bookmarks.get_bookmark!(payload.bookmark_id)
    tag_name = socket.assigns.tag_name

    if has_tag?(bookmark, tag_name) do
      push(socket, "bookmark:chat", payload)
    end

    {:noreply, socket}
  end

  defp tag_matches?(tags, tag_name) when is_list(tags) do
    Enum.any?(tags, &(normalize_tag(&1) == normalize_tag(tag_name)))
  end

  defp tag_matches?(tags, tag_name) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> tag_matches?(tag_name)
  end

  defp has_tag?(bookmark, tag_name) do
    Enum.any?(bookmark.tags, &(normalize_tag(&1.name) == normalize_tag(tag_name)))
  end

  defp normalize_tag(tag) do
    tag
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end
end
