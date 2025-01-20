defmodule Nasty.Traffic.ChatSimulator do
  use GenServer
  require Logger
  @behaviour Nasty.Traffic.SimulatorBehaviour

  alias Nasty.{Accounts, Repo, Chat, Bookmarks}

  @simulation_interval 8_000  # 8 seconds

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
    case Repo.all(Bookmarks.Bookmark) do
      [] ->
        Logger.info("No bookmarks available for chat simulation")

      bookmarks ->
        user = Enum.random(users)
        bookmark = Enum.random(bookmarks)
        content = generate_chat_message(bookmark)

        Chat.create_message(%{
          "content" => content,
          "user_id" => user.id,
          "bookmark_id" => bookmark.id
        })
        :ok

        # Logger.info("Simulated chat: #{user.email} commented on '#{bookmark.title}'")
    end
  end

  defp generate_chat_message(bookmark) do
    templates = [
      "Interesting article about #{extract_topic(bookmark.title)}!",
      "Has anyone implemented this #{extract_topic(bookmark.title)} approach in production?",
      "Great resource for learning #{extract_topic(bookmark.title)}.",
      "The section on #{extract_topic(bookmark.title)} was particularly helpful.",
      "Thanks for sharing this #{extract_topic(bookmark.title)} guide!",
      "This helped me understand #{extract_topic(bookmark.title)} much better.",
      "Bookmarking this for future #{extract_topic(bookmark.title)} projects.",
      "The examples in this #{extract_topic(bookmark.title)} tutorial are well explained.",
      "Anyone else using these #{extract_topic(bookmark.title)} techniques?",
      "Solid introduction to #{extract_topic(bookmark.title)}."
    ]

    Enum.random(templates)
  end

  defp extract_topic(title) do
    common_topics = ~w(
      DevOps Kubernetes Docker AWS Cloud Microservices
      API REST GraphQL Security Testing CI/CD
      Python Ruby Elixir JavaScript TypeScript React
      Vue Angular Node.js Machine\ Learning AI
      Data\ Science Blockchain IoT Architecture
    )

    Enum.find(common_topics, "tech", fn topic ->
      String.contains?(title, topic)
    end)
  end

  defp schedule_simulation do
    variance = @simulation_interval |> div(2)
    interval = @simulation_interval + :rand.uniform(variance)
    Process.send_after(self(), :simulate, interval)
  end
end
