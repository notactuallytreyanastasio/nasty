defmodule Nasty.Chat do
  alias Nasty.Repo
  alias Nasty.Chat.Message
  alias Phoenix.PubSub
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
        message = Repo.preload(message, :user)
        PubSub.broadcast(Nasty.PubSub, "bookmark_chat:#{message.bookmark_id}",
          {:new_message, message})
        {:ok, message}
      error -> error
    end
  end
end
