defmodule JayAuth.Accounts.Token do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "tokens" do
    field :type, :string, null: false, size: 3
    field :valid, :boolean, null: false, default: true
    belongs_to :user, JayAuth.Accounts.User

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:valid, :user_id, :type])
    |> validate_required([:user_id, :type])
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :type])
    |> validate_required([:user_id, :type])
  end
end