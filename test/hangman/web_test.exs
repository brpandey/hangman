defmodule Hangman.Web.Test do
  use ExUnit.Case, async: false

  setup do
    IO.puts "Web Test"

    #File.rm_rf("./tmp/*_test_hangman_games.txt")
    {:ok, apps} = Application.ensure_all_started(:hangman_game)

    # We also need to start HTTPoison
    HTTPoison.start

    on_exit fn ->
      # When the test is finished, we'll stop all application we started.
      Enum.each(apps, &Application.stop/1)
    end

    :ok
  end

  test "cowboy http server with single secret woodpecker" do
    
    body1 = "(#) -----E--E-; score=1; status=KEEP_GUESSING (#) -----E--E-; score=2; status=KEEP_GUESSING (#) -----E--ER; score=3; status=KEEP_GUESSING (#) -----E--ER; score=4; status=KEEP_GUESSING (#) -----E--ER; score=5; status=KEEP_GUESSING (#) -----E--ER; score=6; status=KEEP_GUESSING (#) -----E--ER; score=7; status=KEEP_GUESSING (#) WOODPECKER; score=7; status=GAME_WON (#) Game Over! Average Score: 7.0, # Games: 1, Scores:  (WOODPECKER: 7) "
    
    {:ok, response1 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=julio&secret=woodpecker")
    
    assert response1.body == body1
    
  end


  test "cowboy http server with single secret kiwi" do
    body2 = "(#) ----; score=1; status=KEEP_GUESSING (#) ----; score=2; status=KEEP_GUESSING (#) ----; score=3; status=KEEP_GUESSING (#) -I-I; score=4; status=KEEP_GUESSING (#) -I-I; score=5; status=KEEP_GUESSING (#) -I-I; score=6; status=KEEP_GUESSING (#) -I-I; score=25; status=GAME_LOST (#) Game Over! Average Score: 25.0, # Games: 1, Scores:  (KIWI: 25) "
    
    {:ok, response2 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=carmen&secret=kiwi")
    
    assert response2.body == body2
  end

  test "cowboy http server with 20 random secrets" do
    
    {:ok, response3 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&random=20")

    assert response3.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=melvin&random=20 gives: #{inspect response3.body}\n\n"
  end


  test "cowboy http server with 15 random secrets" do
    
    {:ok, response3 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=orange&random=15")

    assert response3.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=orange&random=15 gives: #{inspect response3.body}\n\n"
  end

  test "cowboy http server with secrets list entries talented and hermetic" do

    # testing that 2 secrets don't give full game history just scores

    body2 = " (TALENTED: 6) (HERMETIC: 4)"

    {:ok, response2 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=carmen&secret[]=talented&secret[]=hermetic")
    
    assert response2.body == body2
  end

  test "cowboy http server with no name token just secret list" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?secret[]=talented&secret[]=hermetic")

    assert response.status_code == 500

#      %HangmanError{message: "Can't run hangman without secrets or a random option specified"}

  end


  test "cowboy http server with no name token just a random value" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?random=2")

    assert response.status_code == 500

#      %HangmanError{message: "Can't run hangman without secrets or a random option specified"}

  end


  test "cowboy http server with only a name token" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=daquiri")

    assert response.status_code == 500

  end


  test "cowboy http server with a name token, secret and random value, secret takes precedence" do

    # test also that for a single secret we get a game history output

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=daquiri&secret=instructive&random=2")


    assert response.body == "(#) ----------E; score=1; status=KEEP_GUESSING (#) ----------E; score=2; status=KEEP_GUESSING (#) ----------E; score=3; status=KEEP_GUESSING (#) I-------I-E; score=4; status=KEEP_GUESSING (#) INSTRUCTIVE; score=4; status=GAME_WON (#) Game Over! Average Score: 4.0, # Games: 1, Scores:  (INSTRUCTIVE: 4) "


  end


  test "cowboy http server with secrets list" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=cumulate&secret[]=avocado&secret[]=eruptive")

    assert response.body == " (CUMULATE: 8) (AVOCADO: 6) (ERUPTIVE: 5)"

  end

  test "cowboy http server with secrets list and word azerbaijan not in dictionary" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=masterful&secret[]=azerbaijan&secret[]=eruptive")

    assert response.body == " (MASTERFUL: 6) (AZERBAIJAN: 0) (ERUPTIVE: 5)"

  end


  @tag :wip
  test "cowboy http server with 200 random secrets" do
    
    {:ok, response3 = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=typhoon&random=200", [],  [recv_timeout: :infinity])

    assert response3.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=typhoon&random=200 gives: #{inspect response3.body}\n\n"
  end


end
