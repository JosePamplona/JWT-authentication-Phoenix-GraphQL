defmodule JayAuth.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :type, :string, null: false, size: 3
      add :valid, :boolean, null: false, default: true
      add :user_id, references(:users, on_delete: :nothing), null: false

      timestamps()
    end
  end
end
