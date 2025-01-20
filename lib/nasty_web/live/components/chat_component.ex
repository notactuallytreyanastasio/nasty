defmodule NastyWeb.ChatComponent do
  use NastyWeb, :live_component
  alias Nasty.Chat
  alias Phoenix.PubSub

  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      messages: [],
      form: to_form(%{"content" => ""})
    )}
  end

  @impl true
  def update(%{bookmark: bookmark} = assigns, socket) do
    if socket.assigns[:bookmark_id] != bookmark.id do
      topic = "bookmark_chat:#{bookmark.id}"
      if socket.assigns[:topic], do: PubSub.unsubscribe(Nasty.PubSub, socket.assigns.topic)
      PubSub.subscribe(Nasty.PubSub, topic)

      {:ok,
       socket
       |> assign(assigns)
       |> assign(
         bookmark_id: bookmark.id,
         topic: topic,
         messages: Chat.list_messages(bookmark.id)
       )}
    else
      {:ok, assign(socket, assigns)}
    end
  end

  @impl true
  def handle_event("send", %{"content" => content}, socket) do
    Chat.create_message(%{
      content: content,
      user_id: socket.assigns.current_user.id,
      bookmark_id: socket.assigns.bookmark_id
    })

    {:noreply, assign(socket, form: to_form(%{"content" => ""}))}
  end

  @impl true
  def handle_info({:new_message, message}, socket) do
    {:noreply, update(socket, :messages, &[message | &1])}
  end
end
