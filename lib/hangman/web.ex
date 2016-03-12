defmodule Web do
  use Plug.Router

  @moduledoc """
  Implements `Hangman` http web server for playing `Hangman` games.
  """

  plug :match
  plug :dispatch

  @doc "Starts the cowboy web server"
  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: 3737)
  end

  # curl 'http://localhost:3737/play?name=julio&secret=woodpecker'

  @docp "Get macro, matches GET request and /play"
  get "/play" do
    conn
    |> Plug.Conn.fetch_query_params
    |> run_game
    |> respond
  end

  @doc """
  Retrieves connection params `name` and `secret` or `random`. Runs web game.
  Returns complete game results in connection response body
  """
  
  @spec run_game(Plug.Conn.t) :: Plug.Conn.t
  def run_game(conn) do
    name = conn.params["name"]
    secrets = conn.params["secret"]

    if secrets == nil do
      count = conn.params["random"]
      secrets = Player.Game.random(count)
    else
      secrets = [secrets]
    end

    debug_spawn("secret.txt", secrets)

    rounds = Player.Game.web_run(name, :robot, secrets, false, false)
    value = format_rounds(rounds)
        
    Plug.Conn.assign(conn, :response, value)
  end

  defp debug_spawn(file_name, term) do
    path = "./tmp"
    spawn(fn ->
      "#{path}/#{file_name}"
      |> File.write!(term)
      end)
  end

  @spec format_rounds([String.t]) :: [String.t]
  defp format_rounds(rounds) do
    for round <- rounds do
      "(#) #{round} "
    end
  end

  @spec respond(Plug.Conn.t) :: Plug.Conn.t
  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, conn.assigns[:response])
  end

  # default match macro
  match _ do
    Plug.Conn.send_resp(conn, 404, "not found")
  end
end
