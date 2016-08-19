defmodule Hangman.Player.FSM.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Game, Player}

  setup_all do
    IO.puts "Player FSM Test"

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :fsm_args => nil,
      :cases => %{
        :robot => [name: "wall_e_test", type: :robot, display: true,
                   secrets: ["immaculate"]],
        :human => [name: "socrates_test", type: :human, display: true,
                   secrets: ["tulip", "daisy"]]
      }
    }

    {:ok, params: map}
  end


  setup context do

    map = context[:params]
    case_key = context[:case_key]
    cases = Map.get(map, :cases)

    test_case_options = Map.get(cases, case_key)
    
    # fetch the test specific params
    name = Keyword.fetch!(test_case_options, :name)
    secrets = Keyword.fetch!(test_case_options, :secrets)
    type = Keyword.fetch!(test_case_options, :type)
    display = Keyword.fetch!(test_case_options, :display)

    # Retrieve game server pid given test specific params
    game_pid = Game.Pid.Cache.get_server_pid(name, secrets)

    # Update case context params map, for current test
    args = {name, type, display, game_pid}

    map = Map.put(map, :fsm_args, args)

    on_exit fn ->
      # Hangman.Game.Server.stop(game_pid)
      IO.puts "Player FSM Test finished"
    end

    {:ok, params: map}
  end

  @tag case_key: :human
  test "test human fsm play", context do

    args = context[:params] |> Map.get(:fsm_args)

    # create the FSM abstraction and then initalize it
    fsm = Player.FSM.new
    assert(Player.FSM.state(fsm) == :initial)
    assert(Player.FSM.data(fsm) == nil)

    fsm = Player.FSM.initialize(fsm, args) 
    assert(Player.FSM.state(fsm) == :begin)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:begin, "fsm begin"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 1, -----; score=0; status=KEEP_GUESSING.\n5 weighted letter choices :  s:4014 e*:3897 a:3514 r:2680 o:2548 (* robot choice)"}]})

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, "e"})

    assert(response == {:action, "-----; score=1; status=KEEP_GUESSING"})
    
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 2, -----; score=1; status=KEEP_GUESSING.\n5 weighted letter choices :  s:2413 a*:2257 o:1743 i:1588 r:1361 (* robot choice)"}]})

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, "i"})

    assert(response == {:action, "---I-; score=2; status=KEEP_GUESSING"})

    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 3, ---I-; score=2; status=KEEP_GUESSING.\n5 weighted letter choices :  a*:208 s:115 r:108 n:107 o:97 (* robot choice)"}]})

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, "a"})

    assert(response == {:action, "---I-; score=3; status=KEEP_GUESSING"})

    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 4, ---I-; score=3; status=KEEP_GUESSING.\n5 weighted letter choices :  o*:76 u:62 c:52 n:48 s:46 (* robot choice)"}]})


    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, "u"})


    assert(response == {:action, "-U-I-; score=4; status=KEEP_GUESSING"})

    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 5, -U-I-; score=4; status=KEEP_GUESSING.\n5 weighted letter choices :  c*:17 p:12 n:11 l:10 m:10 (* robot choice)"}]})

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, "p"})

    assert(response == {:action, "-U-IP; score=5; status=KEEP_GUESSING"})

    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_word, "tulip", "Player socrates_test, Round 6, -U-IP; score=5; status=KEEP_GUESSING.\nLast word left: tulip"}]})

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_word, "tulip"})

    assert(response == {:action, "TULIP; score=5; status=GAME_WON"})
    
    assert(Player.FSM.state(fsm) == :transit)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:transit, ""})

    assert(Player.FSM.state(fsm) == :begin)


    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:begin, "fsm begin"})

    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)

    assert(response == {:setup, [display: true, status: {:guess_letter, "Player socrates_test, Round 1, -----; score=0; status=KEEP_GUESSING.\n5 weighted letter choices :  s:4014 e*:3897 a:3514 r:2680 o:2548 (* robot choice)"}]})

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(response == {:action, "-A-SY; score=5; status=KEEP_GUESSING"})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :setup)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :action)

    {_response, fsm} = Player.FSM.guess(fsm, {:guess_letter, ""})

    assert(Player.FSM.state(fsm) == :transit)

    {_response, fsm} = Player.FSM.proceed(fsm)

    assert(Player.FSM.state(fsm) == :exit)

    {response, _fsm} = Player.FSM.proceed(fsm)

    assert(response == {:exit, "Game Over! Average Score: 6.5, # Games: 2, Scores:  (TULIP: 5) (DAISY: 8)"})

  end


  @tag case_key: :robot
  test "test robot fsm play", context do

    args = context[:params] |> Map.get(:fsm_args)

    # create the FSM abstraction and then initalize it
    fsm = Player.FSM.new
    assert(Player.FSM.state(fsm) == :initial)
    assert(Player.FSM.data(fsm) == nil)

    fsm = Player.FSM.initialize(fsm, args) 
    assert(Player.FSM.state(fsm) == :begin)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:begin, "fsm begin"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:setup, []})
    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, nil)
    assert(response == {:action, "---------E; score=1; status=KEEP_GUESSING"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:setup, []})
    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, nil)
    assert(response == {:action, "---A---A-E; score=2; status=KEEP_GUESSING"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:setup, []})
    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, nil)
    assert(response == {:action, "---A---ATE; score=3; status=KEEP_GUESSING"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:setup, []})
    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, nil)
    assert(response == {:action, "---AC--ATE; score=4; status=KEEP_GUESSING"})
    assert(Player.FSM.state(fsm) == :setup)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == {:setup, []})
    assert(Player.FSM.state(fsm) == :action)

    {response, fsm} = Player.FSM.guess(fsm, nil)
    assert(response == {:action, "IMMACULATE; score=4; status=GAME_WON"})
    assert(Player.FSM.state(fsm) == :transit)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == 
      {:transit, "Game Over! Average Score: 4.0, # Games: 1, Scores:  (IMMACULATE: 4)"})
    assert(Player.FSM.state(fsm) == :exit)

    {response, fsm} = Player.FSM.proceed(fsm)
    assert(response == 
      {:exit, "Game Over! Average Score: 4.0, # Games: 1, Scores:  (IMMACULATE: 4)"})
    assert(Player.FSM.state(fsm) == :exit)
  end

end
