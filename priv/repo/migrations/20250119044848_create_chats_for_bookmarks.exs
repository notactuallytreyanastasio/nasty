defmodule Nasty.Repo.Migrations.CreateChatMessages do
  use Ecto.Migration

  def change do
    create table(:chat_messages) do
      add :content, :text, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :bookmark_id, references(:bookmarks, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:chat_messages, [:user_id])
    create index(:chat_messages, [:bookmark_id])
  end
end
