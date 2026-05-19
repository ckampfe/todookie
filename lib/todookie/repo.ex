defmodule Todookie.Repo do
  use Ecto.Repo,
    otp_app: :todookie,
    adapter: Ecto.Adapters.SQLite3
end
