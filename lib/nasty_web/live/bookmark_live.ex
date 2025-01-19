defmodule NastyWeb.BookmarkLive do
  use NastyWeb, :live_view
  require Logger
  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.{Bookmark, PubSub}

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      PubSub.subscribe()
      Logger.info("BookmarkLive subscribed to PubSub")
    end

    {:ok,
     socket
     |> assign(:bookmarks, list_bookmarks(socket))
     |> assign(:show_modal, false)
     |> assign(:form, to_form(Bookmark.new_changeset()))}
  end

  @impl true
  def handle_info({:create_bookmark, attrs, _tags}, socket) do
    Logger.info("BookmarkLive received create_bookmark message")
    current_user_id = socket.assigns.current_user.id
    creator_id = attrs["user_id"]

    # If current user created the bookmark, prepend it
    bookmarks =
      if current_user_id == creator_id do
        list_bookmarks(socket)
      else
        socket.assigns.bookmarks ++ list_new_bookmarks(socket)
      end

    {:noreply, assign(socket, :bookmarks, bookmarks)}
  end

  def handle_info({:update_bookmark, _bookmark, _attrs, _tags}, socket) do
    {:noreply, assign(socket, :bookmarks, list_bookmarks(socket))}
  end

  def handle_info({:delete_bookmark, _bookmark}, socket) do
    {:noreply, assign(socket, :bookmarks, list_bookmarks(socket))}
  end

  @impl true
  def handle_event("open-modal", _, socket) do
    {:noreply, assign(socket, :show_modal, true)}
  end

  def handle_event("close-modal", _, socket) do
    {:noreply, assign(socket, :show_modal, false)}
  end

  @impl true
  def handle_event("save", %{"bookmark" => params}, socket) do
    params = Map.put(params, "user_id", socket.assigns.current_user.id)
    tags = Map.get(params, "tags", "")

    case Bookmarks.create_bookmark(params, tags) do
      {:ok, _creating} ->
        {:noreply,
         socket
         |> assign(:form, to_form(Bookmark.new_changeset()))
         |> assign(:show_modal, false)
         |> put_flash(:info, "Bookmark saved.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # Private helper to get bookmarks for the current user
  defp list_bookmarks(%{assigns: %{current_user: current_user}}) do
    Logger.info("Fetching bookmarks for user #{current_user.id}")
    bookmarks = Bookmarks.list_bookmarks(current_user.id)
    Logger.info("Found #{length(bookmarks)} bookmarks")
    bookmarks
  end

  defp list_bookmarks(_socket), do: []

  # Private helper to get only new bookmarks since last update
  defp list_new_bookmarks(%{assigns: %{bookmarks: existing_bookmarks}} = socket) do
    all_bookmarks = list_bookmarks(socket)
    existing_ids = MapSet.new(existing_bookmarks, & &1.id)

    Enum.filter(all_bookmarks, fn bookmark ->
      !MapSet.member?(existing_ids, bookmark.id)
    end)
  end
end
