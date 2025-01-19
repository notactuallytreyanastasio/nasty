defmodule NastyWeb.ScrambleLive do
  use NastyWeb, :live_view
  alias Nasty.Bookmarks
  require Logger

  @max_bookmarks 50
  @animation_interval 5000 # 5 seconds

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      :timer.send_interval(@animation_interval, :shuffle_positions)
    end

    bookmarks = Bookmarks.list_public_bookmarks()
    Logger.info("Scramble found #{length(bookmarks)} public bookmarks")

    bookmarks = bookmarks
    |> Enum.take_random(min(@max_bookmarks, length(bookmarks)))
    |> Enum.map(fn bookmark ->
      %{
        bookmark: bookmark,
        position: random_position()
      }
    end)

    {:ok, assign(socket,
      bookmarks: bookmarks,
      max_bookmarks: @max_bookmarks
    )}
  end

  @impl true
  def handle_info(:shuffle_positions, socket) do
    bookmarks = Enum.map(socket.assigns.bookmarks, fn item ->
      %{item | position: random_position()}
    end)

    {:noreply, assign(socket, bookmarks: bookmarks)}
  end

  defp random_position do
    %{
      top: :rand.uniform(80), # 0-80% from top
      left: :rand.uniform(80), # 0-80% from left
      rotation: :rand.uniform(360) - 180 # -180 to 180 degrees
    }
  end
end
