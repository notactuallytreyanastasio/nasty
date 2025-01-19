defmodule NastyWeb.API.ScrambleController do
  use NastyWeb, :controller
  alias Nasty.Bookmarks

  @max_bookmarks 20

  def index(conn, _params) do
    bookmarks = Bookmarks.list_public_bookmarks()
    |> Enum.take_random(@max_bookmarks)
    |> Enum.map(fn bookmark ->
      %{
        title: bookmark.title,
        url: bookmark.url,
        description: bookmark.description,
        tags: Enum.map(bookmark.tags, & &1.name)
      }
    end)

    json(conn, %{bookmarks: bookmarks})
  end
end
