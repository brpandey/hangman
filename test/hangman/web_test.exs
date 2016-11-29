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
    
    body1 = "(H) -----E--E-; score=1; status=KEEP_GUESSING (H) -----E--E-; score=2; status=KEEP_GUESSING (H) -----E--ER; score=3; status=KEEP_GUESSING (H) -----E--ER; score=4; status=KEEP_GUESSING (H) -----E--ER; score=5; status=KEEP_GUESSING (H) -----E--ER; score=6; status=KEEP_GUESSING (H) -----E--ER; score=7; status=KEEP_GUESSING (H) WOODPECKER; score=7; status=GAME_WON (H) Game Over! Average Score: 7.0, Games: 1, Scores:  (WOODPECKER: 7) "
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=julio&secret=woodpecker")
    
    assert response.body == body1
    
  end


  test "cowboy http server with single secret kiwi" do
    body2 = "(H) ----; score=1; status=KEEP_GUESSING (H) ----; score=2; status=KEEP_GUESSING (H) ----; score=3; status=KEEP_GUESSING (H) -I-I; score=4; status=KEEP_GUESSING (H) -I-I; score=5; status=KEEP_GUESSING (H) -I-I; score=6; status=KEEP_GUESSING (H) -I-I; score=25; status=GAME_LOST (H) Game Over! Average Score: 25.0, Games: 1, Scores:  (KIWI: 25) "
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=carmen&secret=kiwi")
    
    assert response.body == body2
  end

  test "cowboy http server with 40 random secrets print out" do
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&random=40", [],  [recv_timeout: :infinity])

    assert response.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=melvin&random=40 gives: #{inspect response.body}\n\n"
  end


  test "cowboy http server with 15 random secrets" do
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=orange&random=15")

    assert response.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=orange&random=15 gives: #{inspect response.body}\n\n"
  end

  test "cowboy http server with secrets list entries talented and hermetic" do

    # testing that 2 secrets don't give full game history just scores

    body2 = "Game Over! Average Score: 5.0, Games: 2, Scores: (HERMETIC: 4) (TALENTED: 6)"

    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=carmen&secret[]=talented&secret[]=hermetic")
    
    assert response.body == body2
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


    assert response.body == "(H) ----------E; score=1; status=KEEP_GUESSING (H) ----------E; score=2; status=KEEP_GUESSING (H) ----------E; score=3; status=KEEP_GUESSING (H) I-------I-E; score=4; status=KEEP_GUESSING (H) INSTRUCTIVE; score=4; status=GAME_WON (H) Game Over! Average Score: 4.0, Games: 1, Scores:  (INSTRUCTIVE: 4) "


  end


  test "cowboy http server with secrets list" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=cumulate&secret[]=avocado&secret[]=eruptive")

    assert response.body == "Game Over! Average Score: 6.333333333333333, Games: 3, Scores: (AVOCADO: 6) (CUMULATE: 8) (ERUPTIVE: 5)"

  end

  test "cowboy http server with secrets list and word azerbaijan not in dictionary" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=masterful&secret[]=azerbaijan&secret[]=eruptive")

    assert response.body == "Game Over! Average Score: 3.6666666666666665, Games: 3, Scores: (AZERBAIJAN: 0) (ERUPTIVE: 5) (MASTERFUL: 6)"

  end


  @tag timeout: :infinity
  test "cowboy http server with 100 specified secrets" do
    
    secrets_args = "&secret[]=warrior&secret[]=cannelon&secret[]=squads&secret[]=anemographs&secret[]=beatific&secret[]=upwafting&secret[]=isocyanates&secret[]=retouchers&secret[]=camail&secret[]=aureole&secret[]=hoodie&secret[]=floppier&secret[]=switching&secret[]=worshiping&secret[]=disobediences&secret[]=merchanted&secret[]=motivate&secret[]=sunscald&secret[]=canonising&secret[]=benzoles&secret[]=retted&secret[]=superpatriot&secret[]=curia&secret[]=aquariums&secret[]=haplessnesses&secret[]=selfish&secret[]=gingelli&secret[]=personalizes&secret[]=bowfront&secret[]=muons&secret[]=suspenser&secret[]=polymer&secret[]=shrewing&secret[]=postneonatal&secret[]=weightless&secret[]=immanences&secret[]=favorably&secret[]=ungovernable&secret[]=worsen&secret[]=biconvexity&secret[]=ptyalins&secret[]=therapeutic&secret[]=peplums&secret[]=laniards&secret[]=rains&secret[]=gobioid&secret[]=invalidity&secret[]=sublimate&secret[]=fatherlike&secret[]=coombs&secret[]=equinity&secret[]=gathering&secret[]=martyrly&secret[]=avengers&secret[]=subconsciouses&secret[]=lixivia&secret[]=catalysts&secret[]=excrescency&secret[]=engages&secret[]=pagod&secret[]=buffeters&secret[]=jesuits&secret[]=coeducations&secret[]=microclimatic&secret[]=alarming&secret[]=strophe&secret[]=stateliest&secret[]=undernourished&secret[]=larval&secret[]=bushfire&secret[]=trusted&secret[]=gelee&secret[]=unhusk&secret[]=verify&secret[]=stabilizing&secret[]=whoever&secret[]=tastemakers&secret[]=glarier&secret[]=costumer&secret[]=dependableness&secret[]=curveballed&secret[]=zibeline&secret[]=scrimpiest&secret[]=colligation&secret[]=hydrodynamical&secret[]=quoth&secret[]=frequentations&secret[]=sunscald&secret[]=skinflints&secret[]=cartoned&secret[]=thoroughbraces&secret[]=commixtures&secret[]=heliac&secret[]=geographer&secret[]=wetproof&secret[]=speciousnesses&secret[]=megaspores&secret[]=upcurved&secret[]=skellums&secret[]=needlessnesses"

    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=typhoon" <> secrets_args, [],  [recv_timeout: :infinity])

    assert response.status_code == 200
 

    assert response.body == "Game Over! Average Score: 6.91, Games: 100, Scores: (ALARMING: 6) (ANEMOGRAPHS: 5) (AQUARIUMS: 7) (AUREOLE: 5) (AVENGERS: 6) (BEATIFIC: 5) (BENZOLES: 7) (BICONVEXITY: 3) (BOWFRONT: 7) (BUFFETERS: 8) (BUSHFIRE: 6) (CAMAIL: 6) (CANNELON: 7) (CANONISING: 5) (CARTONED: 7) (CATALYSTS: 25) (COEDUCATIONS: 3) (COLLIGATION: 7) (COMMIXTURES: 5) (COOMBS: 8) (COSTUMER: 8) (CURIA: 6) (CURVEBALLED: 5) (DEPENDABLENESS: 3) (DISOBEDIENCES: 4) (ENGAGES: 7) (EQUINITY: 3) (EXCRESCENCY: 1) (FATHERLIKE: 4) (FAVORABLY: 7) (FLOPPIER: 10) (FREQUENTATIONS: 2) (GATHERING: 8) (GELEE: 3) (GEOGRAPHER: 4) (GINGELLI: 5) (GLARIER: 7) (GOBIOID: 4) (HAPLESSNESSES: 6) (HELIAC: 8) (HOODIE: 8) (HYDRODYNAMICAL: 3) (IMMANENCES: 4) (INVALIDITY: 5) (ISOCYANATES: 4) (JESUITS: 7) (LANIARDS: 9) (LARVAL: 6) (LIXIVIA: 4) (MARTYRLY: 7) (MEGASPORES: 6) (MERCHANTED: 4) (MICROCLIMATIC: 3) (MOTIVATE: 6) (MUONS: 25) (NEEDLESSNESSES: 2) (PAGOD: 25) (PEPLUMS: 25) (PERSONALIZES: 7) (POLYMER: 6) (POSTNEONATAL: 3) (PTYALINS: 7) (QUOTH: 25) (RAINS: 7) (RETOUCHERS: 6) (RETTED: 4) (SCRIMPIEST: 6) (SELFISH: 5) (SHREWING: 8) (SKELLUMS: 6) (SKINFLINTS: 5) (SPECIOUSNESSES: 2) (SQUADS: 8) (STABILIZING: 6) (STATELIEST: 4) (STROPHE: 5) (SUBCONSCIOUSES: 4) (SUBLIMATE: 7) (SUNSCALD: 6) (SUNSCALD: 6) (SUPERPATRIOT: 6) (SUSPENSER: 2) (SWITCHING: 9) (TASTEMAKERS: 4) (THERAPEUTIC: 2) (THOROUGHBRACES: 5) (TRUSTED: 5) (UNDERNOURISHED: 4) (UNGOVERNABLE: 4) (UNHUSK: 25) (UPCURVED: 8) (UPWAFTING: 8) (VERIFY: 7) (WARRIOR: 25) (WEIGHTLESS: 5) (WETPROOF: 7) (WHOEVER: 4) (WORSEN: 9) (WORSHIPING: 8) (ZIBELINE: 5)"
   

    IO.puts "#{inspect response.body}\n\n"
  end

  @tag timeout: :infinity
  test "cowboy http server with 200 random secrets print out" do
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&random=200", [],  [recv_timeout: :infinity])

    assert response.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=melvin&random=200 gives: #{inspect response.body}\n\n"
  end


end
