defmodule Nasty.Traffic.Simulator do
  use GenServer
  require Logger

  alias Nasty.Traffic.SampleData
  alias Nasty.{Accounts, Bookmarks}

  @simulation_interval :timer.seconds(30)

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # Get or create test users for simulation
    users = ensure_test_users()
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

    case Bookmarks.create_bookmark(bookmark_attrs, tags) do
      {:ok, :creating} ->
        Logger.info("Simulated traffic: Creating bookmark '#{title}' for user #{user.email}")

      {:error, changeset} ->
        Logger.error("Failed to create simulated bookmark: #{inspect(changeset.errors)}")
    end
  end

  defp schedule_simulation do
    # Add some randomness to the interval
    variance = :rand.uniform(5000)
    Process.send_after(self(), :simulate, @simulation_interval + variance)
  end

  defp ensure_test_users do
    1..5
    |> Enum.map(fn i ->
      email = "test_user_#{i}@example.com"

      case Accounts.get_user_by_email(email) do
        nil ->
          {:ok, user} =
            Accounts.register_user(%{
              email: email,
              password: "password123456"
            })

          user

        user ->
          user
      end
    end)
  end
end
