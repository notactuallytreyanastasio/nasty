defmodule Nasty.Traffic.BookmarkSimulator do
  use GenServer
  require Logger
  @behaviour Nasty.Traffic.SimulatorBehaviour

  alias Nasty.{Accounts, Repo}
  alias Nasty.Bookmarks.PubSub
  alias Nasty.Traffic.SampleData

  @simulation_interval 15_000  # 15 seconds

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    users = Repo.all(Accounts.User)
    schedule_simulation()
    {:ok, %{users: users}}
  end

  @impl true
  def handle_info(:simulate, %{users: users} = state) do
    simulate(users)
    schedule_simulation()
    {:noreply, state}
  end

  @impl Nasty.Traffic.SimulatorBehaviour
  def simulation_interval, do: @simulation_interval

  @impl Nasty.Traffic.SimulatorBehaviour
  def simulate(users) do
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
    # Logger.info("Simulated bookmark: '#{title}' by #{user.email}")
  end

  defp schedule_simulation do
    variance = @simulation_interval |> div(2)
    interval = @simulation_interval + :rand.uniform(variance)
    Process.send_after(self(), :simulate, interval)
  end
end
