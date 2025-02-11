defmodule NastyWeb.BookmarkLive do
  use NastyWeb, :live_view
  require Logger
  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.{Bookmark, PubSub}

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      PubSub.subscribe()
    end

    {:ok,
     socket
     |> assign(:bookmarks, user_bookmarks(socket))
     |> assign(:show_modal, false)
     |> assign(:show_chat, false)
     |> assign(:chat_bookmark, nil)
     |> assign(:form, to_form(Bookmark.new_changeset()))}
  end

  @impl true
  def handle_info({:create_bookmark, attrs, _tags}, socket = %{assigns: %{current_user: current_user}}) do
    current_user_id = current_user.id
    creator_id = attrs["user_id"]

    # If current user created the bookmark, prepend it, since it should be at the top for the user
    bookmarks =
      case current_user_id == creator_id do
        true -> user_bookmarks(socket)
        false -> socket.assigns.bookmarks ++ list_new_bookmarks(socket)
      end

    {:noreply, assign(socket, :bookmarks, bookmarks)}
  end

  def handle_info({:chat_message, _payload}, socket) do
    {:noreply, socket}
  end

  def handle_info({:new_message, _message}, socket) do
    {:noreply, socket}
  end

  def handle_info({:update_bookmark, _bookmark, _attrs, _tags}, socket) do
    {:noreply, assign(socket, :bookmarks, user_bookmarks(socket))}
  end

  def handle_info({:delete_bookmark, _bookmark}, socket) do
    {:noreply, assign(socket, :bookmarks, user_bookmarks(socket))}
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

  @impl true
  def handle_event("open-chat", %{"id" => id}, socket) do
    bookmark = Bookmarks.get_bookmark!(id)
    {:noreply, assign(socket, show_chat: true, chat_bookmark: bookmark)}
  end

  def handle_event("close-chat", _, socket) do
    {:noreply, assign(socket, show_chat: false, chat_bookmark: nil)}
  end

  defp user_bookmarks(%{assigns: %{current_user: current_user}}) do
    Bookmarks.user_bookmarks(current_user.id)
  end

  defp user_bookmarks(_socket), do: []

  # Private helper to get only new bookmarks since last update
  defp list_new_bookmarks(%{assigns: %{bookmarks: existing_bookmarks}} = socket) do
    all_bookmarks = user_bookmarks(socket)
    existing_ids = MapSet.new(existing_bookmarks, & &1.id)

    Enum.filter(all_bookmarks, fn bookmark ->
      !MapSet.member?(existing_ids, bookmark.id)
    end)
  end
end
