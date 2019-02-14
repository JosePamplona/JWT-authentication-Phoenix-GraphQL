defmodule JayAuth.Accounts.User do
  @moduledoc false
  
  use Ecto.Schema
  import Ecto.Changeset

  alias JayAuth.FunctionsLibrary

  schema "users" do
    field :email, :string
    field :pass_hash, :string
    field :pass, :string, virtual: true
    has_many :tokens, JayAuth.Accounts.Token

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :pass_hash])
    |> validate_required([:email, :pass_hash])
    |> unique_constraint(:email)
  end

  @doc false
  def create_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :pass])
    |> validate_required([:email, :pass])
    |> unique_constraint(:email)
    |> FunctionsLibrary.hash(:pass)
  end
end