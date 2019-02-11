defmodule JayAuth.Graphql.Schema do
  @moduledoc false

  use Absinthe.Schema

  import_types JayAuth.Graphql.Queries
  import_types JayAuth.Graphql.Mutations
  import_types JayAuth.Graphql.Subscriptions
  import_types Absinthe.Plug.Types
  import_types Absinthe.Type.Custom

  import_types JayAuth.Accounts.Types

  query [], do: import_fields :queries
  mutation [], do: import_fields :mutations
  # subscription [], do: import_fields :subscriptions
end
