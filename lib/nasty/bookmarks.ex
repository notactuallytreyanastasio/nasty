defmodule Nasty.Bookmarks do
  import Ecto.Query

  alias Nasty.Repo
  alias Nasty.Bookmarks.{Bookmark, Tag, Cache}

  def list_bookmarks(user_id) do
    Cache.get_user_bookmarks(user_id)
  end

  def list_public_bookmarks do
    Cache.get_public_bookmarks()
  end

  def get_bookmark!(id), do: Repo.get!(Bookmark, id) |> Repo.preload(:tags)

  def create_bookmark(attrs \\ %{}, tags) do
    result =
      %Bookmark{}
      |> Bookmark.changeset(attrs)
      |> put_tags(tags)
      |> Repo.insert()

    case result do
      {:ok, bookmark} ->
        Cache.update_cache(bookmark)
        {:ok, bookmark}
      error ->
        error
    end
  end

  def update_bookmark(%Bookmark{} = bookmark, attrs, tags) do
    result =
      bookmark
      |> Bookmark.changeset(attrs)
      |> put_tags(tags)
      |> Repo.update()

    case result do
      {:ok, bookmark} ->
        Cache.update_cache(bookmark)
        {:ok, bookmark}
      error ->
        error
    end
  end

  def delete_bookmark(%Bookmark{} = bookmark) do
    result = Repo.delete(bookmark)

    case result do
      {:ok, bookmark} ->
        Cache.delete_from_cache(bookmark)
        {:ok, bookmark}
      error ->
        error
    end
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
end
