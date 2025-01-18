defmodule Nasty.Bookmarks do
  import Ecto.Query

  alias Nasty.Repo
  alias Nasty.Bookmarks.Bookmark
  alias Nasty.Bookmarks.Tag

  def list_bookmarks(user_id) do
    Bookmark
    |> where([b], b.user_id == ^user_id)
    |> preload(:tags)
    |> Repo.all()
  end

  def list_public_bookmarks do
    Bookmark
    |> where([b], b.public == true)
    |> preload([:tags, :user])
    |> Repo.all()
  end

  def get_bookmark!(id), do: Repo.get!(Bookmark, id) |> Repo.preload(:tags)

  def create_bookmark(attrs \\ %{}, tags) do
    %Bookmark{}
    |> Bookmark.changeset(attrs)
    |> put_tags(tags)
    |> Repo.insert()
  end

  def update_bookmark(%Bookmark{} = bookmark, attrs, tags) do
    bookmark
    |> Bookmark.changeset(attrs)
    |> put_tags(tags)
    |> Repo.update()
  end

  def delete_bookmark(%Bookmark{} = bookmark) do
    Repo.delete(bookmark)
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
      tag -> tag
    end
  end
end
