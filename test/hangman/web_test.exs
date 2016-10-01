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
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=julio&secret=woodpecker")
    
    assert response.body == body1
    
  end


  test "cowboy http server with single secret kiwi" do
    body2 = "(#) ----; score=1; status=KEEP_GUESSING (#) ----; score=2; status=KEEP_GUESSING (#) ----; score=3; status=KEEP_GUESSING (#) -I-I; score=4; status=KEEP_GUESSING (#) -I-I; score=5; status=KEEP_GUESSING (#) -I-I; score=6; status=KEEP_GUESSING (#) -I-I; score=25; status=GAME_LOST (#) Game Over! Average Score: 25.0, # Games: 1, Scores:  (KIWI: 25) "
    
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

    body2 = "Game Over! Average Score: 5.0, # Games: 2, Scores:  (TALENTED: 6) (HERMETIC: 4)"

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


    assert response.body == "(#) ----------E; score=1; status=KEEP_GUESSING (#) ----------E; score=2; status=KEEP_GUESSING (#) ----------E; score=3; status=KEEP_GUESSING (#) I-------I-E; score=4; status=KEEP_GUESSING (#) INSTRUCTIVE; score=4; status=GAME_WON (#) Game Over! Average Score: 4.0, # Games: 1, Scores:  (INSTRUCTIVE: 4) "


  end


  test "cowboy http server with secrets list" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=cumulate&secret[]=avocado&secret[]=eruptive")

    assert response.body == "Game Over! Average Score: 6.333333333333333, # Games: 3, Scores:  (CUMULATE: 8) (AVOCADO: 6) (ERUPTIVE: 5)"

  end

  test "cowboy http server with secrets list and word azerbaijan not in dictionary" do

    {:ok, response = %HTTPoison.Response{}} = 
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=gustav&secret[]=masterful&secret[]=azerbaijan&secret[]=eruptive")

    assert response.body == "Game Over! Average Score: 3.6666666666666665, # Games: 3, Scores:  (MASTERFUL: 6) (AZERBAIJAN: 0) (ERUPTIVE: 5)"

  end


  @tag timeout: 90000
  test "cowboy http server with 100 specified secrets" do
    
    secrets_args = "&secret[]=warrior&secret[]=cannelon&secret[]=squads&secret[]=anemographs&secret[]=beatific&secret[]=upwafting&secret[]=isocyanates&secret[]=retouchers&secret[]=camail&secret[]=aureole&secret[]=hoodie&secret[]=floppier&secret[]=switching&secret[]=worshiping&secret[]=disobediences&secret[]=merchanted&secret[]=motivate&secret[]=sunscald&secret[]=canonising&secret[]=benzoles&secret[]=retted&secret[]=superpatriot&secret[]=curia&secret[]=aquariums&secret[]=haplessnesses&secret[]=selfish&secret[]=gingelli&secret[]=personalizes&secret[]=bowfront&secret[]=muons&secret[]=suspenser&secret[]=polymer&secret[]=shrewing&secret[]=postneonatal&secret[]=weightless&secret[]=immanences&secret[]=favorably&secret[]=ungovernable&secret[]=worsen&secret[]=biconvexity&secret[]=ptyalins&secret[]=therapeutic&secret[]=peplums&secret[]=laniards&secret[]=rains&secret[]=gobioid&secret[]=invalidity&secret[]=sublimate&secret[]=fatherlike&secret[]=coombs&secret[]=equinity&secret[]=gathering&secret[]=martyrly&secret[]=avengers&secret[]=subconsciouses&secret[]=lixivia&secret[]=catalysts&secret[]=excrescency&secret[]=engages&secret[]=pagod&secret[]=buffeters&secret[]=jesuits&secret[]=coeducations&secret[]=microclimatic&secret[]=alarming&secret[]=strophe&secret[]=stateliest&secret[]=undernourished&secret[]=larval&secret[]=bushfire&secret[]=trusted&secret[]=gelee&secret[]=unhusk&secret[]=verify&secret[]=stabilizing&secret[]=whoever&secret[]=tastemakers&secret[]=glarier&secret[]=costumer&secret[]=dependableness&secret[]=curveballed&secret[]=zibeline&secret[]=scrimpiest&secret[]=colligation&secret[]=hydrodynamical&secret[]=quoth&secret[]=frequentations&secret[]=sunscald&secret[]=skinflints&secret[]=cartoned&secret[]=thoroughbraces&secret[]=commixtures&secret[]=heliac&secret[]=geographer&secret[]=wetproof&secret[]=speciousnesses&secret[]=megaspores&secret[]=upcurved&secret[]=skellums&secret[]=needlessnesses"

    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=typhoon" <> secrets_args, [],  [recv_timeout: :infinity])

    assert response.status_code == 200
 
   
#    assert response.body == " (WARRIOR: 25) (CANNELON: 7) (SQUADS: 8) (ANEMOGRAPHS: 5) (BEATIFIC: 5) (UPWAFTING: 8) (ISOCYANATES: 4) (RETOUCHERS: 6) (CAMAIL: 6) (AUREOLE: 5) (HOODIE: 8) (FLOPPIER: 10) (SWITCHING: 9) (WORSHIPING: 8) (DISOBEDIENCES: 4) (MERCHANTED: 4) (MOTIVATE: 6) (SUNSCALD: 6) (CANONISING: 5) (BENZOLES: 7) (RETTED: 4) (SUPERPATRIOT: 6) (CURIA: 6) (AQUARIUMS: 7) (HAPLESSNESSES: 6) (SELFISH: 5) (GINGELLI: 5) (PERSONALIZES: 7) (BOWFRONT: 7) (MUONS: 25) (SUSPENSER: 2) (POLYMER: 6) (SHREWING: 8) (POSTNEONATAL: 3) (WEIGHTLESS: 5) (IMMANENCES: 4) (FAVORABLY: 7) (UNGOVERNABLE: 4) (WORSEN: 9) (BICONVEXITY: 3) (PTYALINS: 7) (THERAPEUTIC: 2) (PEPLUMS: 25) (LANIARDS: 9) (RAINS: 7) (GOBIOID: 4) (INVALIDITY: 5) (SUBLIMATE: 7) (FATHERLIKE: 4) (COOMBS: 8) (EQUINITY: 3) (GATHERING: 8) (MARTYRLY: 7) (AVENGERS: 6) (SUBCONSCIOUSES: 4) (LIXIVIA: 4) (CATALYSTS: 25) (EXCRESCENCY: 1) (ENGAGES: 7) (PAGOD: 25) (BUFFETERS: 8) (JESUITS: 7) (COEDUCATIONS: 3) (MICROCLIMATIC: 3) (ALARUMING: 4) (STROPHE: 5) (STATELIEST: 4) (UNDERNOURISHED: 4) (LARVAL: 6) (BUSHFIRE: 6) (TRUSTED: 5) (GELEE: 3) (UNHUSK: 25) (VERIFY: 7) (STABILIZING: 6) (WHOEVER: 4) (TASTEMAKERS: 4) (GLARIER: 7) (COSTUMER: 8) (DEPENDABLENESS: 3) (CURVEBALLED: 5) (ZIBELINE: 5) (SCRIMPIEST: 6) (COLLIGATION: 7) (HYDRODYNAMICAL: 3) (QUOTH: 25) (FREQUENTATIONS: 2) (SUNSCALD: 6) (SKINFLINTS: 5) (CARTONED: 7) (THOROUGHBRACES: 5) (COMMIXTURES: 5) (HELIAC: 8) (GEOGRAPHER: 4) (WETPROOF: 7) (SPECIOUSNESSES: 2) (MEGASPORES: 6) (UPCURVED: 8) (SKELLUMS: 6) (NEEDLESSNESSES: 2)"


    IO.puts "#{inspect response.body}\n\n"
  end


  test "cowboy http server with 200 random secrets print out" do
    
    {:ok, response = %HTTPoison.Response{}} =
      HTTPoison.get("http://127.0.0.1:3737/hangman?name=melvin&random=200", [],  [recv_timeout: :infinity])

    assert response.status_code == 200
    
    IO.puts "HTTPoison.get http://127.0.0.1:3737/hangman?name=melvin&random=200 gives: #{inspect response.body}\n\n"
  end


end
