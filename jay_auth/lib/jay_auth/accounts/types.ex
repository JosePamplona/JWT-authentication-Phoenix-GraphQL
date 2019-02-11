defmodule JayAuth.Accounts.Types do

  use Absinthe.Ecto, repo: Solitrade.Repo
  use Absinthe.Schema.Notation

  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :pass_hash, non_null(:string)
  end

  object :session do
    field :user, non_null(:user)
    field :access_jwt, non_null(:string)
    field :refresh_jwt, non_null(:string)
  end
end