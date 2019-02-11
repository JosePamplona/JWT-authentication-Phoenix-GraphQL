defmodule JayAuthWeb.PageController do
  use JayAuthWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
