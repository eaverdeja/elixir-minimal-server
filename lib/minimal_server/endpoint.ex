defmodule MinimalServer.Endpoint do
  use Plug.Router
  require Logger

  plug(:match)

  plug(Plug.Parsers,
    parsers: [:json],
    pass: ["applcation/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  forward("/bot", to: MinimalServer.Router)

  match _ do
    send_resp(conn, 404, "Requested page not found!")
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    with {:ok, [port: port] = config} <- Application.fetch_env(:minimal_server, __MODULE__) do
      currentPort =
        Keyword.get(Application.get_env(:minimal_server, MinimalServer.Endpoint), :port)

      ip =
        if(currentPort !== "4000") do
          {0, 0, 0, 0}
        else
          {127, 0, 0, 1}
        end

      Logger.info("starting server at http://#{Enum.join(Tuple.to_list(ip), ".")}:#{port}/")

      Plug.Cowboy.http(__MODULE__, config,
        ip: ip,
        port: System.get_env("PORT") || 4000
      )
    end
  end
end
