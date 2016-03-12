defmodule Web.Test do
  use ExUnit.Case, async: false

  setup do
    IO.puts "Web Test"

    #File.rm_rf("./tmp/*_test_hangman_games.txt")
    {:ok, apps} = Application.ensure_all_started(:hangman)

    # We also need to start HTTPoison
    HTTPoison.start

    on_exit fn ->
      # When the test is finished, we'll stop all application we started.
      Enum.each(apps, &Application.stop/1)
    end

    :ok
  end

  test "cowboy http server" do
    
    body1 = "(#) -----E--E-; score=1; status=KEEP_GUESSING (#) -----E--E-; score=2; status=KEEP_GUESSING (#) -----E--ER; score=3; status=KEEP_GUESSING (#) -----E--ER; score=4; status=KEEP_GUESSING (#) -----E--ER; score=5; status=KEEP_GUESSING (#) -----E--ER; score=6; status=KEEP_GUESSING (#) -----E--ER; score=7; status=KEEP_GUESSING (#) WOODPECKER; score=7; status=GAME_WON (#) Game Over! Average Score: 7.0, # Games: 1, Scores:  (WOODPECKER: 7) "

    
    {:ok, response1 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&secret=woodpecker")
    
    assert response1.body == body1
    
    body2 = "(#) ----; score=1; status=KEEP_GUESSING (#) ----; score=2; status=KEEP_GUESSING (#) ----; score=3; status=KEEP_GUESSING (#) -I-I; score=4; status=KEEP_GUESSING (#) -I-I; score=5; status=KEEP_GUESSING (#) -I-I; score=6; status=KEEP_GUESSING (#) -I-I; score=25; status=GAME_LOST (#) Game Over! Average Score: 25.0, # Games: 1, Scores:  (KIWI: 25) "

    
    {:ok, response2 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&secret=kiwi")
    
    assert response2.body == body2
    
    {:ok, response3 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/play?name=julio&random=2")
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/play?name=julio&random=2 gives: #{inspect response3.body}\n\n"
  end
end
