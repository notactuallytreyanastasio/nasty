defmodule NastyWeb.API.BookmarkController do
  use NastyWeb, :controller

  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.Bookmark
  alias Nasty.Accounts

  action_fallback NastyWeb.FallbackController

  def create(conn, params) do
    user = Accounts.get_user!(1)

    bookmark_params = params["bookmark"]
    |> Map.put("user_id", user.id)

    tags = String.split(Map.get(params["bookmark"], "tags", ""), ",")
    y = Bookmarks.create_bookmark(bookmark_params, tags)
    case y do
      {:ok, bookmark} ->
        tags = Map.get(bookmark, "tags")
        conn
        |> put_status(:created)
        # we just trust that they like, really created it right?
        # lol this is so useless to a user but it illustrates
        # the point because youre just sending it into the void
        # that is the higher order feed via pubsub for consumption
        # its totally async and should have another means of
        # doing the actual creation here than if it was the web UI
        # but lets just pretend when they make the bookmarklet
        # work in their browser they have a magic token that lets
        # them publish and if it ever fails to match (we change it here)
        # then they cannot publish at all and we 403
        |> json(%{
          title: Map.get(bookmark, "title"),
          url: Map.get(bookmark, "url"),
          description: Map.get(bookmark, :description),
          tags: tags
        }) |> IO.inspect

      {:error, changeset} ->
        IO.inspect(changeset, label: "Changeset errors")
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_errors(changeset)})
    end
  rescue
    e ->
      IO.inspect(e, label: "Error")
      conn
      |> put_status(:internal_server_error)
      |> json(%{error: "Internal server error", details: Exception.message(e)})
  end

  def update(conn, %{"id" => id, "bookmark" => bookmark_params}) do
    user = conn.assigns.current_user
    bookmark = Bookmarks.get_bookmark!(id)

    if bookmark.user_id == user.id do
      tags = Map.get(bookmark_params, "tags", [])

      case Bookmarks.update_bookmark(bookmark, bookmark_params, tags) do
        {:ok, :updating} ->
          conn
          |> put_status(:accepted)
          |> json(%{status: "accepted", message: "Bookmark update in progress"})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{errors: format_changeset_errors(changeset)})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized"})
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    bookmark = Bookmarks.get_bookmark!(id)

    if bookmark.user_id == user.id do
      case Bookmarks.delete(bookmark) do
        {:ok, :deleting} ->
          send_resp(conn, :accepted, "")

        {:error, _reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{error: "Failed to delete bookmark"})
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Not authorized"})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
