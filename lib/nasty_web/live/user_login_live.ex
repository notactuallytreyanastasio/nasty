defmodule NastyWeb.UserLoginLive do
  use NastyWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-black text-fuchsia-500 font-mono p-4">
      <div class="max-w-md mx-auto mt-16">
        <div class="border-2 border-cyan-500 bg-black/30 p-6">
          <div class="flex items-center gap-2 mb-6">
            <span class="font-bold text-cyan-400">root@nasty:</span>
            <span class="text-fuchsia-400">~/auth</span>
            <span class="animate-pulse text-cyan-500">$</span>
            <span class="text-cyan-400">login</span>
          </div>

          <.form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore">
            <div class="space-y-4">
              <div
                :if={@flash["error"]}
                class="border-2 border-red-500/50 bg-red-500/10 p-3 mb-4 text-red-400"
              >
                {String.capitalize(@flash["error"])}
              </div>

              <div class="space-y-1">
                <.input
                  field={@form[:email]}
                  type="email"
                  placeholder="email://"
                  autocomplete="username"
                  class="w-full bg-black/50 border-2 border-cyan-500 text-fuchsia-400 placeholder-cyan-700 p-2 focus:outline-none focus:border-fuchsia-500"
                  value={@flash["email"]}
                />
              </div>

              <div class="space-y-1">
                <.input
                  field={@form[:password]}
                  type="password"
                  placeholder="password://"
                  autocomplete="current-password"
                  class="w-full bg-black/50 border-2 border-cyan-500 text-fuchsia-400 placeholder-cyan-700 p-2 focus:outline-none focus:border-fuchsia-500"
                />
              </div>

              <div class="flex items-center gap-2 text-sm">
                <label class="flex items-center gap-2 text-cyan-400">
                  <.input
                    field={@form[:remember_me]}
                    type="checkbox"
                    class="appearance-none w-4 h-4 border-2 border-cyan-500 bg-black/50 checked:bg-fuchsia-500 cursor-pointer"
                  />
                  <span>keep_session_alive://</span>
                </label>
                <div class="ml-auto">
                  <.link
                    href={~p"/users/reset_password"}
                    class="text-cyan-400 hover:text-fuchsia-400 transition-colors"
                  >
                    forgot_password://
                  </.link>
                </div>
              </div>

              <div>
                <.button
                  phx-disable-with="Authenticating..."
                  class="w-full bg-cyan-500 hover:bg-fuchsia-500 text-black font-bold py-2 transition-all duration-300 ease-in-out"
                >
                  authenticate://
                </.button>
              </div>
            </div>
          </.form>

          <div class="mt-6 text-sm text-center border-t-2 border-cyan-500/30 pt-6">
            <span class="text-cyan-700">new_user?</span>
            <.link
              navigate={~p"/users/register"}
              class="text-cyan-400 hover:text-fuchsia-400 ml-1 transition-colors"
            >
              register://
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = live_flash(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
