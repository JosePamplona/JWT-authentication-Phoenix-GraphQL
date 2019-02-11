defmodule JayAuthWeb.Router do
  use JayAuthWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug JayAuth.Context
    #plug :accepts, ["json"]
  end

  scope "/", JayAuthWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api" do
    pipe_through :api
    forward "/", Absinthe.Plug, schema: JayAuth.Graphql.Schema
  end

  # Other scopes may use custom stacks.
  # scope "/api", JayAuthWeb do
  #   pipe_through :api
  # end
      
  if Mix.env == :dev do
    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: JayAuth.Graphql.Schema,
      interface: :advanced,
      context: %{pubsub: JayAuth.Endpoint}
  end

end
