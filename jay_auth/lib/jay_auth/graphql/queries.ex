defmodule JayAuth.Graphql.Queries do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :queries do

    field :get_user, :user do
      arg :id, non_null(:integer)
      resolve &JayAuth.Accounts.Resolver.get_user/3
    end

    field :login, :session do
      arg :email, non_null(:string)
      arg :pass, non_null(:string)
      resolve &JayAuth.Accounts.Resolver.login/3
    end

    field :refresh, :session do
      arg :email, non_null(:string)
      arg :refresh_jwt, non_null(:string)
      resolve &JayAuth.Accounts.Resolver.refresh/3
    end
    
    field :logout, :user do
      resolve &JayAuth.Accounts.Resolver.logout/3
    end

    field :some_action, :string do
      resolve &JayAuth.Accounts.Resolver.some_action/3
    end

  end
end
