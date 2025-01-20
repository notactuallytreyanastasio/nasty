defmodule Nasty.Traffic.Simulator do
  use GenServer
  require Logger

  alias Nasty.Traffic.SampleData
  alias Nasty.{Accounts, Bookmarks}
  alias Nasty.Bookmarks.PubSub
  alias Nasty.Repo
  alias Nasty.Accounts.User

  @simulation_interval :timer.seconds(3)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    users = Repo.all(User)
    schedule_simulation()
    {:ok, %{users: users}}
  end

  def handle_info(:simulate, state) do
    simulate_traffic(state.users)
    schedule_simulation()
    {:noreply, state}
  end

  defp simulate_traffic(users) do
    user = Enum.random(users)
    title = SampleData.generate_title()

    bookmark_attrs = %{
      "title" => title,
      "description" => SampleData.generate_description(),
      "url" => SampleData.generate_url(title),
      "public" => true,
      "user_id" => user.id
    }

    tags = SampleData.generate_tags() |> Enum.join(", ")

    PubSub.broadcast_create(bookmark_attrs, tags)
    # Logger.info("Simulated traffic: Broadcasting bookmark creation '#{title}' for user #{user.email}")
    :ok
  end

  defp schedule_simulation do
    variance = :rand.uniform(1000)
    Process.send_after(self(), :simulate, @simulation_interval + variance)
  end
end
