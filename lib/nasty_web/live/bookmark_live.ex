defmodule NastyWeb.BookmarkLive do
  use NastyWeb, :live_view
  alias Nasty.Bookmarks
  alias Nasty.Bookmarks.Bookmark

  @impl true
  def mount(_params, _session, socket) do
    case socket.assigns do
      %{current_user: current_user} ->
        if connected?(socket) do
          bookmarks = Bookmarks.list_bookmarks(current_user.id)
          bookmarks_by_tag = group_bookmarks_by_tag(bookmarks)

          {:ok,
           socket
           |> assign(:bookmarks_by_tag, bookmarks_by_tag)
           |> assign(:form, to_form(Bookmark.new_changeset()))}
        else
          {:ok,
           socket
           |> assign(:bookmarks_by_tag, %{})
           |> assign(:form, to_form(Bookmark.new_changeset()))}
        end

      _ ->
        {:ok,
         socket
         |> assign(:bookmarks_by_tag, %{})
         |> assign(:form, to_form(Bookmark.new_changeset()))}
    end
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
         |> assign(:bookmarks_by_tag, group_bookmarks_by_tag(bookmarks))
         |> assign(:form, to_form(Bookmark.new_changeset()))
         |> put_flash(:info, "Bookmark saved.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp group_bookmarks_by_tag(bookmarks) do
    bookmarks
    |> Enum.flat_map(fn bookmark ->
      case bookmark.tags do
        [] -> [{"untagged", [bookmark]}]
        tags -> Enum.map(tags, &{&1.name, [bookmark]})
      end
    end)
    |> Enum.reduce(%{}, fn {tag, bookmarks}, acc ->
      Map.update(acc, tag, bookmarks, &(&1 ++ bookmarks))
    end)
    |> Enum.sort_by(&elem(&1, 0))
  end
end
