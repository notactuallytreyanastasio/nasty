defmodule NastyWeb.APIAuthPlug do
  import Plug.Conn
  import Phoenix.Controller

  alias Nasty.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
#    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
#         {:ok, user_id} <- verify_token(token),
#         user when not is_nil(user) <- Accounts.get_user(user_id) do
#      assign(conn, :current_user, user)
#    else
#      _ ->
#        conn
#        |> put_status(:unauthorized)
#        |> json(%{error: "Invalid or missing authentication token"})
#        |> halt()
#    end
  end

  defp verify_token(token) do
    # Simple token verification for example purposes
    # In production, use proper JWT or similar
    case Phoenix.Token.verify(NastyWeb.Endpoint, "user auth", token, max_age: 86400) do
      {:ok, user_id} -> {:ok, user_id}
      {:error, _} -> :error
    end
  end
end
