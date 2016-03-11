defmodule Web do
  use Plug.Router

  plug :match
  plug :dispatch

  def start_server do
    Plug.Adapters.Cowboy.http(__MODULE__, nil, port: 3737)
  end

  # curl 'http://localhost:3737/play?name=julio&secret=woodpecker'
  get "/play" do
    conn
    |> Plug.Conn.fetch_params
    |> fetch_play
    |> respond
  end

  defp fetch_play(conn) do
    Plug.Conn.assign(conn, 
                     :response,
                     play(conn.params["name"], conn.params["secret"])
    )
  end

  defp play(name, secret) do
    name
    |> Player.Game.run(:robot, secret, false, false)
    |> format_rounds
  end

  defp format_rounds(rounds) do
    for round <- rounds do
      #{round}
    end
    |> Enum.join("\n")
  end

  defp respond(conn) do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, conn.assigns[:response])
  end


  match _ do
    Plug.Conn.send_resp(conn, 404, "not found")
  end
end
