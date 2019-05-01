defmodule MinimalServer.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  @content_type "application/json"

  get "/" do
    conn
    |> put_resp_content_type(@content_type)
    |> send_resp(200, message())
  end

  defp message do
    Poison.encode!(%{
      response_type: "in_channel",
      text: "Hello Elixir world!"
    })
  end
end
