defmodule MinimalServer.Endpoint do
  use Plug.Router
  use Plug.Debugger
  use Plug.ErrorHandler

  alias MinimalServer.Router
  alias Plug.{Parsers, Cowboy, HTML}

  require Logger

  plug(Plug.Logger, log: :debug)
  plug(:match)

  plug(Parsers,
    parsers: [:json],
    pass: ["applcation/json"],
    json_decoder: Poison
  )

  plug(:dispatch)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(_opts) do
    with {:ok, [port: port] = config} <- config() do
      currentPort = Keyword.get(Application.get_env(:minimal_server, __MODULE__), :port)

      ip =
        if(currentPort !== "4000") do
          {0, 0, 0, 0}
        else
          {127, 0, 0, 1}
        end

      Logger.info("starting server at http://#{Enum.join(Tuple.to_list(ip), ".")}:#{port}/")

      Cowboy.http(__MODULE__, config,
        ip: ip,
        port: System.get_env("PORT") || 4000
      )
    end
  end

  forward("/bot", to: Router)

  match _ do
    conn
    |> put_resp_header("location", redirect_url())
    |> put_resp_content_type("text/html")
    |> send_resp(302, redirect_body())
  end

  defp redirect_body do
    ~S(<html><body>You are being <a href=")
    |> Kernel.<>(HTML.html_escape(redirect_url()))
    |> Kernel.<>(~S(">redirected</a></body></html>"))
  end

  defp config, do: Application.fetch_env(:minimal_server, __MODULE__)
  defp redirect_url, do: Application.get_env(:minimal_server, :redirect_url)

  def handle_errors(%{status: status} = conn, %{kind: _kind, reason: _reason, stack: _stack}),
    do: send_resp(conn, status, "Something went wrong!")
end
