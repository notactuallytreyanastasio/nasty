defmodule Nasty.Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "chat_messages" do
    field :content, :string
    belongs_to :user, Nasty.Accounts.User
    belongs_to :bookmark, Nasty.Bookmarks.Bookmark

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :user_id, :bookmark_id])
    |> validate_required([:content, :user_id, :bookmark_id])
    |> validate_length(:content, min: 1, max: 1000)
    |> assoc_constraint(:user)
    |> assoc_constraint(:bookmark)
  end
end
