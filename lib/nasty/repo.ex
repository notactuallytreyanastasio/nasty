defmodule Nasty.Repo do
  use Ecto.Repo,
    otp_app: :nasty,
    adapter: Ecto.Adapters.Postgres
end
