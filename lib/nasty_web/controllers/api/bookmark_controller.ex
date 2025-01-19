defmodule NastyWeb.API.BookmarkController do
  use NastyWeb, :controller

  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.Bookmark

  action_fallback NastyWeb.FallbackController

  def create(conn, %{"bookmark" => bookmark_params}) do
    user = conn.assigns.current_user
    bookmark_params = Map.put(bookmark_params, "user_id", user.id)
    tags = Map.get(bookmark_params, "tags", [])

    case Bookmarks.create_bookmark(bookmark_params, tags) do
      {:ok, :creating} ->
        conn
        |> put_status(:accepted)
        |> json(%{status: "accepted", message: "Bookmark creation in progress"})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: format_changeset_errors(changeset)})
    end
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

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
