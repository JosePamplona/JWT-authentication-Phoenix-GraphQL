defmodule JayAuth.Graphql.Mutations do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :mutations do

    field :create_user, :user do
      arg :email, non_null(:string)
      arg :pass, non_null(:string)
      resolve &JayAuth.Accounts.Graphql.Resolver.create_user/3
    end

  end
end