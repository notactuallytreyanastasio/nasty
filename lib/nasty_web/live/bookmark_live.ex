defmodule NastyWeb.BookmarkLive do
  use NastyWeb, :live_view
  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.Bookmark

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: current_user}} = socket) do
    if connected?(socket) do
      bookmarks = Bookmarks.list_bookmarks(current_user.id)

      {:ok,
       socket
       |> assign(:bookmarks, bookmarks)
       |> assign(:form, to_form(Bookmark.new_changeset()))
       |> assign(:show_modal, false)}
    else
      {:ok,
       socket
       |> assign(:bookmarks, [])
       |> assign(:form, to_form(Bookmark.new_changeset()))
       |> assign(:show_modal, false)}
    end
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
      {:ok, _bookmark} ->
        bookmarks = Bookmarks.list_bookmarks(socket.assigns.current_user.id)

        {:noreply,
         socket
         |> assign(:bookmarks, bookmarks)
         |> assign(:form, to_form(Bookmark.new_changeset()))
         |> assign(:show_modal, false)
         |> put_flash(:info, "Bookmark saved.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
