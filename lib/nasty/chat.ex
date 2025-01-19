defmodule Nasty.Chat do
  alias Nasty.Repo
  alias Nasty.Chat.Message
  alias Phoenix.PubSub
  alias Nasty.Bookmarks.PubSub, as: BookmarkPubSub
  import Ecto.Query

  def list_messages(bookmark_id) do
    Message
    |> where(bookmark_id: ^bookmark_id)
    |> order_by(desc: :inserted_at)
    |> limit(100)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def create_message(attrs) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, message} ->
        message = Repo.preload(message, [:user, :bookmark])

        # Broadcast to chat channel
        PubSub.broadcast(Nasty.PubSub, "bookmark_chat:#{message.bookmark_id}",
          {:new_message, message})

        # Broadcast to bookmark firehose
        BookmarkPubSub.broadcast_chat_message(message)

        {:ok, message}
      error -> error
    end
  end
end
