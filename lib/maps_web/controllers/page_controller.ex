defmodule MapsWeb.PageController do
  use MapsWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
