defmodule Nasty.Bookmarks do
  import Ecto.Query

  alias Nasty.Repo
  alias Nasty.Bookmarks.{Bookmark, Tag, Cache, PubSub}

  def list_bookmarks(user_id) do
    Cache.get_user_bookmarks(user_id)
  end

  def list_public_bookmarks do
    Cache.get_public_bookmarks()
  end

  def get_bookmark!(id), do: Repo.get!(Bookmark, id) |> Repo.preload(:tags)

  def create_bookmark(attrs \\ %{}, tags) do
    PubSub.broadcast_create(attrs, tags)
    {:ok, :creating}
  end

  def update_bookmark(%Bookmark{} = bookmark, attrs, tags) do
    PubSub.broadcast_update(bookmark, attrs, tags)
    {:ok, :updating}
  end

  def delete_bookmark(%Bookmark{} = bookmark) do
    PubSub.broadcast_delete(bookmark)
    {:ok, :deleting}
  end

  def list_tags do
    Repo.all(Tag)
  end

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  defp put_tags(changeset, tags) do
    tags = parse_and_get_tags(tags)

    changeset
    |> Ecto.Changeset.put_assoc(:tags, tags)
  end

  defp parse_and_get_tags(tags) when is_binary(tags) do
    tags
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&get_or_create_tag/1)
  end

  defp parse_and_get_tags(tags) when is_list(tags), do: tags
  defp parse_and_get_tags(nil), do: []

  defp get_or_create_tag(name) do
    name = String.downcase(name)

    case Repo.get_by(Tag, name: name) do
      nil ->
        {:ok, tag} = create_tag(%{name: name})
        tag

      tag ->
        tag
    end
  end

  # Internal functions that actually perform the database operations
  def do_create_bookmark(attrs, tags) do
    %Bookmark{}
    |> Bookmark.changeset(attrs)
    |> put_tags(tags)
    |> Repo.insert()
  end

  def do_update_bookmark(bookmark, attrs, tags) do
    bookmark
    |> Bookmark.changeset(attrs)
    |> put_tags(tags)
    |> Repo.update()
  end

  def do_delete_bookmark(bookmark) do
    Repo.delete(bookmark)
  end
end
