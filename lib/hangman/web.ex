defmodule Hangman.Web do
  use Plug.Router

  alias Hangman.{Player}

  @moduledoc """
  Module provides access to a http web server for playing 
  `Hangman` games via a tool such as curl or HTTPoison.
  
  ## Example

      iex> HTTPoison.get("http://127.0.0.1:3737/play?name=julio&secret=kiwi")

      {:ok,
      %HTTPoison.Response{body: "(#) ----; score=1; status=KEEP_GUESSING (#) ----; score=2; status=KEEP_GUESSING (#) ----; score=3; status=KEEP_GUESSING (#) -I-I; score=4; status=KEEP_GUESSING (#) -I-I; score=5; status=KEEP_GUESSING (#) -I-I; score=6; status=KEEP_GUESSING (#) -I-I; score=25; status=GAME_LOST (#) Game Over! Average Score: 25.0, # Games: 1, Scores:  (KIWI: 25) ",
      headers: [{"server", "Cowboy"}, {"date", "Mon, 14 Mar 2016 04:27:39 GMT"},
      {"content-length", "345"},
      {"cache-control", "max-age=0, private, must-revalidate"},
      {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}

      iex> HTTPoison.get("http://127.0.0.1:3737/play?name=julio&random=2")

      {:ok,
      %HTTPoison.Response{body: "(#) --E-----------; score=1; status=KEEP_GUESSING (#) --E--------O--; score=2; status=KEEP_GUESSING (#) --E--------O--; score=3; status=KEEP_GUESSING (#) --E----C---O--; score=4; status=KEEP_GUESSING (#) PREVARICATIONS; score=4; status=GAME_WON (#) ---------; score=1; status=KEEP_GUESSING (#) --A------; score=2; status=KEEP_GUESSING (#) -IA----I-; score=3; status=KEEP_GUESSING (#) -IA----I-; score=4; status=KEEP_GUESSING (#) -IAG---I-; score=5; status=KEEP_GUESSING (#) DIAGNOSIS; score=5; status=GAME_WON (#) Game Over! Average Score: 4.5, # Games: 2, Scores:  (PREVARICATIONS: 4) (DIAGNOSIS: 5) ",
      headers: [{"server", "Cowboy"}, {"date", "Mon, 14 Mar 2016 04:29:05 GMT"},
      {"content-length", "601"},
      {"cache-control", "max-age=0, private, must-revalidate"},
      {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}
  
  """

  plug :match
  plug :dispatch

  @doc "Starts the cowboy web server"
  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: 3737)
  end



  @docp "Get macro, matches GET request and /play"
  get "/play" do
    conn
    |> Plug.Conn.fetch_query_params
    |> run_game
    |> respond
  end

  @doc """
  Retrieves connection params `name` and either a `secret` or `random`. 
  Runs web game. Returns complete game results in connection response body
  """
  
  @spec run_game(Plug.Conn.t) :: Plug.Conn.t
  def run_game(conn) do
    name = conn.params["name"]
    secrets = conn.params["secret"]

    if secrets == nil do
      count = conn.params["random"]
      secrets = Player.Handler.random(count)
    else
      secrets = [secrets]
    end

    if secrets == nil, do: raise "Can't run hangman with no secrets"

    rounds = Player.Handler.run(name, :robot, secrets, false, false)
    value = format_rounds(rounds)
        
    Plug.Conn.assign(conn, :response, value)
  end

'''
  defp debug_spawn(file_name, term) do
    path = "./tmp"
    spawn(fn ->
      "{path}/{file_name}"
      |> File.write!(term)
      end)
  end
'''

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
