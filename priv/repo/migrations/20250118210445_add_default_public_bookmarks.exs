defmodule Nasty.Repo.Migrations.SetBookmarksPublicDefaultTrue do
  use Ecto.Migration

  def change do
    # Update all existing bookmarks to have public = true
    execute "UPDATE bookmarks SET public = true WHERE public IS NULL"

    # Modify the column to set default value and not null constraint
    alter table(:bookmarks) do
      modify :public, :boolean, default: true, null: false
    end
  end
end
