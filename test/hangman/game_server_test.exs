defmodule Hangman.Game.Server.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Game, Player}

  setup_all do
    IO.puts("Game Test")

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :current_player_key => nil,
      :current_game_pid => nil,
      :cases => %{
        :stanley2 => [name: "stanley2", secrets: ["factual", "backpack"]],
        :hugo2 => [name: "hugo", secrets: ["heart", "lullaby"]],
        :stanley1 => [name: "stanley1", secrets: ["jovial"]],
        :rabbit1 => [name: {"rabbit", 1}, secrets: ["cumulate", "avocado"]],
        :rabbit2 => [name: {"rabbit", 2}, secrets: ["eruptive"]]
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

    # Retrieve game server pid given test specific params
    game_pid = Game.Server.Controller.get_server(name, secrets)

    apid =
      case name do
        name when is_binary(name) ->
          {:ok, apid} = Player.Alert.Supervisor.start_child(name, nil)
          apid

        name when is_tuple(name) ->
          nil
      end

    # Update case context params map, for current test
    map = Map.put(map, :current_game_pid, game_pid)

    # Update params map with player and round key for current test
    map = Map.put(map, :current_player_key, {name, self()})

    map =
      Map.put(map, :current_round_key, {name, "(game num goes here)", "(round num goes here)"})

    on_exit(fn ->
      # Stop game server
      Game.Server.Controller.stop_server(name)

      if apid != nil, do: Player.Alert.Handler.stop(apid)
      IO.puts("test finished")
    end)

    {:ok, params: map}
  end

  @tag case_key: :stanley2
  test "stanley - double games", context do
    IO.puts("\n1) Starting stanley 2 games test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    round_key = context[:params] |> Map.get(:current_round_key)

    Game.Server.register(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :guessing, text: "-------; score=0; status=KEEP_GUESSING"} =
             Game.Server.status(game_pid, player_key, round_key)

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "--C----",
             text: "--C----; score=1; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "c"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "--C-U--",
             text: "--C-U--; score=2; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "u"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "-AC-UA-",
             text: "-AC-UA-; score=3; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "FAC-UA-",
             text: "FAC-UA-; score=4; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "f"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "FACTUA-",
             text: "FACTUA-; score=5; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "t"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :won,
             pattern: "FACTUAL",
             text: "FACTUAL; score=6; status=GAME_WON"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})

    assert %{key: ^round_key, code: :start} = Game.Server.status(game_pid, player_key, round_key)

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "--C---C-",
             text: "--C---C-; score=1; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "c"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "-AC--AC-",
             text: "-AC--AC-; score=2; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "-ACK-ACK",
             text: "-ACK-ACK; score=3; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "k"})

    assert %{
             key: ^round_key,
             result: :correct_word,
             code: :won,
             pattern: "BACKPACK",
             text: "BACKPACK; score=3; status=GAME_WON"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "backpack"})

    assert %{
             key: ^round_key,
             code: :finished,
             text: "Game Over! Average Score: 4.5, Games: 2, Scores:  (FACTUAL: 6) (BACKPACK: 3)"
           } = Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :reset} = Game.Server.status(game_pid, player_key, round_key)
  end

  @tag case_key: :hugo2
  test "hugo - double games", context do
    IO.puts("\n2) Starting hugo 2 games test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    round_key = context[:params] |> Map.get(:current_round_key)

    Game.Server.register(game_pid, player_key, round_key)

    assert %{key: {"hugo", 1, 1}, code: :guessing, text: "-----; score=0; status=KEEP_GUESSING"} =
             Game.Server.status(game_pid, player_key, {"hugo", 1, 1})

    assert %{
             key: {"hugo", 1, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "H----",
             text: "H----; score=1; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 2}, {:guess_letter, "h"})

    assert %{
             key: {"hugo", 1, 3},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "H----",
             text: "H----; score=2; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 3}, {:guess_letter, "l"})

    assert %{
             key: {"hugo", 1, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "H----",
             text: "H----; score=3; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 4}, {:guess_letter, "g"})

    assert %{
             key: {"hugo", 1, 5},
             result: :correct_letter,
             code: :guessing,
             pattern: "H-A--",
             text: "H-A--; score=4; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 5}, {:guess_letter, "a"})

    assert %{
             key: {"hugo", 1, 6},
             result: :correct_letter,
             code: :guessing,
             pattern: "H-AR-",
             text: "H-AR-; score=5; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 6}, {:guess_letter, "r"})

    assert %{
             key: {"hugo", 1, 7},
             result: :correct_word,
             code: :won,
             pattern: "HEART",
             text: "HEART; score=5; status=GAME_WON"
           } = Game.Server.guess(game_pid, player_key, {"hugo", 1, 7}, {:guess_word, "heart"})

    assert %{key: ^round_key, code: :start} = Game.Server.status(game_pid, player_key, round_key)

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "----A--",
             text: "----A--; score=1; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "a"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "----A-Y",
             text: "----A-Y; score=2; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "y"})

    assert %{
             key: ^round_key,
             result: :incorrect_letter,
             code: :guessing,
             pattern: "----A-Y",
             text: "----A-Y; score=3; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "s"})

    assert %{
             key: ^round_key,
             result: :correct_letter,
             code: :guessing,
             pattern: "L-LLA-Y",
             text: "L-LLA-Y; score=4; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_letter, "l"})

    assert %{
             key: ^round_key,
             result: :correct_word,
             code: :won,
             pattern: "LULLABY",
             text: "LULLABY; score=4; status=GAME_WON"
           } = Game.Server.guess(game_pid, player_key, round_key, {:guess_word, "lullaby"})

    assert %{
             key: ^round_key,
             code: :finished,
             text: "Game Over! Average Score: 4.5, Games: 2, Scores:  (HEART: 5) (LULLABY: 4)"
           } = Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :reset} = Game.Server.status(game_pid, player_key, round_key)

    assert %{key: ^round_key, code: :reset} = Game.Server.status(game_pid, player_key, round_key)
  end

  @tag case_key: :stanley1
  test "stanley - single game", context do
    IO.puts("\n3) Starting stanley 1 game test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    # round_key = context[:params] |> Map.get(:current_round_key)

    assert %{
             key: {"stanley1", 1, 1},
             code: :guessing,
             data: 6,
             text: "------; score=0; status=KEEP_GUESSING"
           } = Game.Server.register(game_pid, player_key, {"stanley1", 1, 1})

    assert %{
             key: {"stanley1", 1, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "-----L",
             text: "-----L; score=1; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"stanley1", 1, 2}, {:guess_letter, "l"})

    assert %{
             key: {"stanley1", 1, 3},
             result: :correct_letter,
             code: :guessing,
             pattern: "----AL",
             text: "----AL; score=2; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"stanley1", 1, 3}, {:guess_letter, "a"})

    assert %{
             key: {"stanley1", 1, 4},
             result: :correct_letter,
             code: :guessing,
             pattern: "J---AL",
             text: "J---AL; score=3; status=KEEP_GUESSING"
           } = Game.Server.guess(game_pid, player_key, {"stanley1", 1, 4}, {:guess_letter, "j"})

    assert %{
             key: {"stanley1", 1, 5},
             result: :correct_word,
             code: :won,
             pattern: "JOVIAL",
             text: "JOVIAL; score=3; status=GAME_WON"
           } =
             Game.Server.guess(game_pid, player_key, {"stanley1", 1, 5}, {:guess_word, "jovial"})

    assert %{
             key: {"stanley1", 1, 6},
             code: :finished,
             text: "Game Over! Average Score: 3.0, Games: 1, Scores:  (JOVIAL: 3)"
           } = Game.Server.status(game_pid, player_key, {"stanley1", 1, 6})
  end

  @tag case_key: :rabbit1
  test "rabbit1 - double games - cumulate avocado", context do
    IO.puts("\n3) Starting rabbit1 double game test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)

    assert %{
             key: {{"rabbit", 1}, 1, 1},
             code: :guessing,
             data: 8,
             text: "--------; score=0; status=KEEP_GUESSING"
           } = Game.Server.register(game_pid, player_key, {{"rabbit", 1}, 1, 1})

    assert %{
             key: {{"rabbit", 1}, 1, 1},
             result: :correct_letter,
             code: :guessing,
             pattern: "-------E",
             text: "-------E; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 1}, {:guess_letter, "e"})

    assert %{
             key: {{"rabbit", 1}, 1, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "-----A-E",
             text: "-----A-E; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 2}, {:guess_letter, "a"})

    assert %{
             key: {{"rabbit", 1}, 1, 3},
             result: :correct_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 3}, {:guess_letter, "t"})

    assert %{
             key: {{"rabbit", 1}, 1, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 4}, {:guess_letter, "o"})

    assert %{
             key: {{"rabbit", 1}, 1, 5},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 5}, {:guess_letter, "i"})

    assert %{
             key: {{"rabbit", 1}, 1, 6},
             result: :correct_letter,
             code: :guessing,
             pattern: "----LATE",
             text: "----LATE; score=6; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 6}, {:guess_letter, "l"})

    assert %{
             key: {{"rabbit", 1}, 1, 7},
             result: :correct_letter,
             code: :guessing,
             pattern: "C---LATE",
             text: "C---LATE; score=7; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 7}, {:guess_letter, "c"})

    assert %{
             key: {{"rabbit", 1}, 1, 8},
             result: :correct_letter,
             code: :guessing,
             pattern: "C-M-LATE",
             text: "C-M-LATE; score=8; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 1, 8}, {:guess_letter, "m"})

    assert %{
             key: {{"rabbit", 1}, 1, 9},
             result: :correct_word,
             code: :won,
             pattern: "CUMULATE",
             text: "CUMULATE; score=8; status=GAME_WON"
           } =
             Game.Server.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 9},
               {:guess_word, "cumulate"}
             )

    assert %{key: {{"rabbit", 1}, 1, 9}, code: :start} =
             Game.Server.status(game_pid, player_key, {{"rabbit", 1}, 1, 9})

    assert %{
             key: {{"rabbit", 1}, 2, 1},
             code: :guessing,
             data: 7,
             text: "-------; score=0; status=KEEP_GUESSING"
           } = Game.Server.register(game_pid, player_key, {{"rabbit", 1}, 2, 1})

    assert %{
             key: {{"rabbit", 1}, 2, 1},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-------",
             text: "-------; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 1}, {:guess_letter, "e"})

    assert %{
             key: {{"rabbit", 1}, 2, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 2}, {:guess_letter, "a"})

    assert %{
             key: {{"rabbit", 1}, 2, 3},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 3}, {:guess_letter, "s"})

    assert %{
             key: {{"rabbit", 1}, 2, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 4}, {:guess_letter, "r"})

    assert %{
             key: {{"rabbit", 1}, 2, 5},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 5}, {:guess_letter, "i"})

    assert %{
             key: {{"rabbit", 1}, 2, 6},
             result: :correct_letter,
             code: :guessing,
             pattern: "A---AD-",
             text: "A---AD-; score=6; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 1}, 2, 6}, {:guess_letter, "d"})

    assert %{
             key: {{"rabbit", 1}, 2, 7},
             result: :correct_word,
             code: :won,
             pattern: "AVOCADO",
             text: "AVOCADO; score=6; status=GAME_WON"
           } =
             Game.Server.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 7},
               {:guess_word, "avocado"}
             )

    assert %{
             key: {{"rabbit", 1}, 2, 7},
             code: :finished,
             text: "Game Over! Average Score: 7.0, Games: 2, Scores:  (CUMULATE: 8) (AVOCADO: 6)"
           } = Game.Server.status(game_pid, player_key, {{"rabbit", 1}, 2, 7})
  end

  @tag case_key: :rabbit2
  test "rabbit2 - single game - eruptive", context do
    IO.puts("\n3) Starting rabbit2 single game test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    # round_key = context[:params] |> Map.get(:current_round_key)

    assert %{
             key: {{"rabbit", 2}, 1, 1},
             code: :guessing,
             data: 8,
             text: "--------; score=0; status=KEEP_GUESSING"
           } = Game.Server.register(game_pid, player_key, {{"rabbit", 2}, 1, 1})

    assert %{
             key: {{"rabbit", 2}, 1, 1},
             result: :correct_letter,
             code: :guessing,
             pattern: "E------E",
             text: "E------E; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 2}, 1, 1}, {:guess_letter, "e"})

    assert %{
             key: {{"rabbit", 2}, 1, 2},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "E------E",
             text: "E------E; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 2}, 1, 2}, {:guess_letter, "a"})

    assert %{
             key: {{"rabbit", 2}, 1, 3},
             result: :correct_letter,
             code: :guessing,
             pattern: "E----I-E",
             text: "E----I-E; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 2}, 1, 3}, {:guess_letter, "i"})

    assert %{
             key: {{"rabbit", 2}, 1, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "E----I-E",
             text: "E----I-E; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 2}, 1, 4}, {:guess_letter, "o"})

    assert %{
             key: {{"rabbit", 2}, 1, 5},
             result: :correct_letter,
             code: :guessing,
             pattern: "ER---I-E",
             text: "ER---I-E; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.guess(game_pid, player_key, {{"rabbit", 2}, 1, 5}, {:guess_letter, "r"})

    assert %{
             key: {{"rabbit", 2}, 1, 6},
             result: :correct_word,
             code: :won,
             pattern: "ERUPTIVE",
             text: "ERUPTIVE; score=5; status=GAME_WON"
           } =
             Game.Server.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 6},
               {:guess_word, "eruptive"}
             )

    assert %{
             key: {{"rabbit", 2}, 1, 6},
             code: :finished,
             text: "Game Over! Average Score: 5.0, Games: 1, Scores:  (ERUPTIVE: 5)"
           } = Game.Server.status(game_pid, player_key, {{"rabbit", 2}, 1, 6})
  end
end
