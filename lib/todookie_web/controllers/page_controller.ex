defmodule TodookieWeb.PageController do
  use TodookieWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
