defmodule NastyWeb.UserSocket do
  use Phoenix.Socket

  channel "bookmark:feed", NastyWeb.BookmarkFeedChannel
  channel "tag:*", NastyWeb.TagFeedChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
