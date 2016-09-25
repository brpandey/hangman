defmodule Hangman.Web do
  use Plug.Router

  alias Hangman.{Web}

  require Logger

  @moduledoc """
  Module provides access to a http web server for playing 
  `Hangman` games via a tool such as curl or HTTPoison.

  Query params are specified after `/hangman?`

  These are name :: String.t, secret :: String.t | [String.t], random :: pos_integer
  
  The name at all times must be specified along with either a secret value or random value:
  true = name and (secret | random)

  The random param specifies how many secret words to generate.  Hence,
  random=5, will generate 5 secret game words for a total of 5 hangman games.

  If the secrets collection vector is only 1 item we show the game history if greater we 
  show the word and score summary only

  ## Example

      iex> HTTPoison.get("http://127.0.0.1:3737/hangman?name=julio&secret=kiwi")

      {:ok,
      %HTTPoison.Response{body: "(#) ----; score=1; status=KEEP_GUESSING (#) ----; score=2; status=KEEP_GUESSING (#) ----; score=3; status=KEEP_GUESSING (#) -I-I; score=4; status=KEEP_GUESSING (#) -I-I; score=5; status=KEEP_GUESSING (#) -I-I; score=6; status=KEEP_GUESSING (#) -I-I; score=25; status=GAME_LOST (#) Game Over! Average Score: 25.0, # Games: 1, Scores:  (KIWI: 25) ",
      headers: [{"server", "Cowboy"}, {"date", "Mon, 14 Mar 2016 04:27:39 GMT"},
      {"content-length", "345"},
      {"cache-control", "max-age=0, private, must-revalidate"},
      {"content-type", "text/plain; charset=utf-8"}], status_code: 200}}

      iex> HTTPoison.get("http://127.0.0.1:3737/hangman?name=julio&random=1")

      {:ok,
      %HTTPoison.Response{body: "(#) --E-----------; score=1; status=KEEP_GUESSING (#) --E--------O--; score=2; status=KEEP_GUESSING (#) --E--------O--; score=3; status=KEEP_GUESSING (#) --E----C---O--; score=4; status=KEEP_GUESSING (#) PREVARICATIONS; score=4; status=GAME_WON (#) Game Over! Average Score: 4, # Games: 1, Scores:  (PREVARICATIONS: 4) ",
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



  @docp "Get macro, matches GET request and /hangman"
  get "/hangman" do
    conn
    |> Plug.Conn.fetch_query_params
    |> run
    |> respond
  end

  @doc """
  Retrieves connection params `name` and either a `secret` or `random`. 
  Runs web game. Returns complete game results in connection response body
  """
  
  @spec run(Plug.Conn.t) :: Plug.Conn.t | no_return
  def run(conn) do

    # Let's catch most of the errors in the beginning using a "with" construct

    # name must be provided
    # and if provided, either the secrets is a string or a list of strings
    # and lastly either a secrets value is provided or a random count is provided

    # NOTE: random value is a string which will be error checked in Dictionary.random()

    with name when not is_nil(name) and is_binary(name) <- conn.params["name"],
    secrets when is_nil(secrets) or is_binary(secrets) or 
    (is_list(secrets) and is_binary(hd(secrets))) <- conn.params["secret"],
    count = conn.params["random"],
    false <- (is_nil(secrets) and is_nil(count)) do
      
      secrets = 
        case secrets do
          nil -> Hangman.Dictionary.random(conn.params["random"])
          secrets when is_binary(secrets) -> [secrets]
          secrets when is_list(secrets) -> secrets
        end

      results = Web.Flow.run(name, secrets)
      
      response = 
        case Enum.count(secrets) do 
          1 -> format_rounds(results)
          _ -> results
        end
      
      Plug.Conn.assign(conn, :response, response)
      
    else
      _error -> 
      #Logger.debug "error is #{inspect error}"
      raise HangmanError, "Can't run hangman without a name or either a secrets or a random option specified"
    end
    

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

  @spec format_rounds(list) :: list
  defp format_rounds(rounds) when is_list(rounds) do
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
