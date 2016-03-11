defmodule Web.Test do
  use ExUnit.Case, async: false

  setup do

    #File.rm_rf("games.txt")
    {:ok, apps} = Application.ensure_all_started(:play_hangman)

    # We also need to start HTTPoison
    HTTPoison.start

    on_exit fn ->
      # When the test is finished, we'll stop all application we started.
      Enum.each(apps, &Application.stop/1)
    end

    :ok
  end

  test "cowboy http server" do
    assert %HTTPoison.Response{body: "OK", status_code: 200} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&secret=woodpecker")

    assert %HTTPoison.Response{body: "OK", status_code: 200} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&secret=kiwi")

    assert %HTTPoison.Response{body: "OK", status_code: 200} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&random=2")

  end
end
