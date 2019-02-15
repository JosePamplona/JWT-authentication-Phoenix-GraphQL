defmodule JayAuth.Graphql.Queries do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :queries do

    field :list_users, list_of(:user) do
      resolve &JayAuth.Accounts.Graphql.Resolver.list_users/3
    end

    field :login, :session do
      arg :email, non_null(:string)
      arg :pass, non_null(:string)
      resolve &JayAuth.Accounts.Graphql.Resolver.login/3
    end

    field :refresh, :session do
      arg :email, non_null(:string)
      arg :refresh_jwt, non_null(:string)
      resolve &JayAuth.Accounts.Graphql.Resolver.refresh/3
    end
    
    field :logout, :user do
      resolve &JayAuth.Accounts.Graphql.Resolver.logout/3
    end

    field :some_action, :user do
      resolve &JayAuth.Accounts.Graphql.Resolver.some_action/3
    end

  end
end
