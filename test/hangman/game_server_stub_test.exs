defmodule Hangman.Game.Server.Stub.Test do
  use ExUnit.Case, async: true

  alias Hangman.{Game}

  setup_all do
    IO.puts("Game Stub Test")

    # initialize params map for test cases
    # each test just needs to grab the current player pid
    map = %{
      :current_player_key => nil,
      :current_game_pid => nil,
      :cases => %{
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

    # Update case context params map, for current test
    map = Map.put(map, :current_game_pid, game_pid)

    # Update params map with player and round key for current test
    map = Map.put(map, :current_player_key, {name, self()})

    on_exit(fn ->
      Game.Server.Controller.stop_server(name)

      IO.puts("test finished")
    end)

    {:ok, params: map}
  end

  @tag case_key: :rabbit1
  test "rabbit1 - double games - cumulate avocado", context do
    IO.puts("\n1) Starting rabbit1 double game test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)

    assert %{
             key: {{"rabbit", 1}, 1, 0},
             code: :guessing,
             data: 8,
             text: "--------; score=0; status=KEEP_GUESSING"
           } = Game.Server.Stub.register(game_pid, player_key, {{"rabbit", 1}, 1, 0})

    IO.puts("rabbit1 1")

    assert %{
             key: {{"rabbit", 1}, 1, 1},
             result: :correct_letter,
             code: :guessing,
             pattern: "-------E",
             text: "-------E; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 1},
               {:guess_letter, "e"}
             )

    IO.puts("rabbit1 2")

    assert %{
             key: {{"rabbit", 1}, 1, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "-----A-E",
             text: "-----A-E; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 2},
               {:guess_letter, "a"}
             )

    IO.puts("rabbit1 3")

    assert %{
             key: {{"rabbit", 1}, 1, 3},
             result: :correct_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 3},
               {:guess_letter, "t"}
             )

    IO.puts("rabbit1 4")

    assert %{
             key: {{"rabbit", 1}, 1, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 4},
               {:guess_letter, "o"}
             )

    IO.puts("rabbit1 5")

    assert %{
             key: {{"rabbit", 1}, 1, 5},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-----ATE",
             text: "-----ATE; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 5},
               {:guess_letter, "i"}
             )

    IO.puts("rabbit1 6")

    assert %{
             key: {{"rabbit", 1}, 1, 6},
             result: :correct_letter,
             code: :guessing,
             pattern: "----LATE",
             text: "----LATE; score=6; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 6},
               {:guess_letter, "l"}
             )

    IO.puts("rabbit1 7")

    assert %{
             key: {{"rabbit", 1}, 1, 7},
             result: :correct_letter,
             code: :guessing,
             pattern: "C---LATE",
             text: "C---LATE; score=7; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 7},
               {:guess_letter, "c"}
             )

    IO.puts("rabbit1 8")

    assert %{
             key: {{"rabbit", 1}, 1, 8},
             result: :correct_letter,
             code: :guessing,
             pattern: "C-M-LATE",
             text: "C-M-LATE; score=8; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 8},
               {:guess_letter, "m"}
             )

    IO.puts("rabbit1 9")

    assert %{
             key: {{"rabbit", 1}, 1, 9},
             result: :correct_word,
             code: :won,
             pattern: "CUMULATE",
             text: "CUMULATE; score=8; status=GAME_WON"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 1, 9},
               {:guess_word, "cumulate"}
             )

    IO.puts("rabbit1 10")

    assert %{key: {{"rabbit", 1}, 1, 9}, code: :start} =
             Game.Server.Stub.status(game_pid, player_key, {{"rabbit", 1}, 1, 9})

    IO.puts("rabbit1 11")

    assert %{
             key: {{"rabbit", 1}, 2, 0},
             code: :guessing,
             data: 7,
             text: "-------; score=0; status=KEEP_GUESSING"
           } = Game.Server.Stub.register(game_pid, player_key, {{"rabbit", 1}, 2, 0})

    IO.puts("rabbit1 12")

    assert %{
             key: {{"rabbit", 1}, 2, 1},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "-------",
             text: "-------; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 1},
               {:guess_letter, "e"}
             )

    IO.puts("rabbit1 13")

    assert %{
             key: {{"rabbit", 1}, 2, 2},
             result: :correct_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 2},
               {:guess_letter, "a"}
             )

    IO.puts("rabbit1 14")

    assert %{
             key: {{"rabbit", 1}, 2, 3},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 3},
               {:guess_letter, "s"}
             )

    IO.puts("rabbit1 15")

    assert %{
             key: {{"rabbit", 1}, 2, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 4},
               {:guess_letter, "r"}
             )

    IO.puts("rabbit1 16")

    assert %{
             key: {{"rabbit", 1}, 2, 5},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "A---A--",
             text: "A---A--; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 5},
               {:guess_letter, "i"}
             )

    IO.puts("rabbit1 17")

    assert %{
             key: {{"rabbit", 1}, 2, 6},
             result: :correct_letter,
             code: :guessing,
             pattern: "A---AD-",
             text: "A---AD-; score=6; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 6},
               {:guess_letter, "d"}
             )

    IO.puts("rabbit1 18")

    assert %{
             key: {{"rabbit", 1}, 2, 7},
             result: :correct_word,
             code: :won,
             pattern: "AVOCADO",
             text: "AVOCADO; score=6; status=GAME_WON"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 1}, 2, 7},
               {:guess_word, "avocado"}
             )

    IO.puts("rabbit1 19")

    assert %{
             key: {{"rabbit", 1}, 2, 7},
             code: :finished,
             text:
               "Game Over! Average Score: 7.0, # Games: 2, Scores:  (CUMULATE: 8) (AVOCADO: 6)"
           } = Game.Server.Stub.status(game_pid, player_key, {{"rabbit", 1}, 2, 7})
  end

  @tag case_key: :rabbit2
  test "rabbit2 - single game - eruptive", context do
    IO.puts("\n2) Starting rabbit2 single game test \n")

    game_pid = context[:params] |> Map.get(:current_game_pid)
    player_key = context[:params] |> Map.get(:current_player_key)
    # round_key = context[:params] |> Map.get(:current_round_key)

    assert %{
             key: {{"rabbit", 2}, 1, 0},
             code: :guessing,
             data: 8,
             text: "--------; score=0; status=KEEP_GUESSING"
           } = Game.Server.Stub.register(game_pid, player_key, {{"rabbit", 2}, 1, 0})

    IO.puts("rabbit2 1")

    assert %{
             key: {{"rabbit", 2}, 1, 1},
             result: :correct_letter,
             code: :guessing,
             pattern: "E------E",
             text: "E------E; score=1; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 1},
               {:guess_letter, "e"}
             )

    IO.puts("rabbit2 2")

    assert %{
             key: {{"rabbit", 2}, 1, 2},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "E------E",
             text: "E------E; score=2; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 2},
               {:guess_letter, "a"}
             )

    IO.puts("rabbit2 3")

    assert %{
             key: {{"rabbit", 2}, 1, 3},
             result: :correct_letter,
             code: :guessing,
             pattern: "E----I-E",
             text: "E----I-E; score=3; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 3},
               {:guess_letter, "i"}
             )

    IO.puts("rabbit2 4")

    assert %{
             key: {{"rabbit", 2}, 1, 4},
             result: :incorrect_letter,
             code: :guessing,
             pattern: "E----I-E",
             text: "E----I-E; score=4; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 4},
               {:guess_letter, "o"}
             )

    IO.puts("rabbit2 5")

    assert %{
             key: {{"rabbit", 2}, 1, 5},
             result: :correct_letter,
             code: :guessing,
             pattern: "ER---I-E",
             text: "ER---I-E; score=5; status=KEEP_GUESSING"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 5},
               {:guess_letter, "r"}
             )

    IO.puts("rabbit2 6")

    assert %{
             key: {{"rabbit", 2}, 1, 6},
             result: :correct_word,
             code: :won,
             pattern: "ERUPTIVE",
             text: "ERUPTIVE; score=5; status=GAME_WON"
           } =
             Game.Server.Stub.guess(
               game_pid,
               player_key,
               {{"rabbit", 2}, 1, 6},
               {:guess_word, "eruptive"}
             )

    IO.puts("rabbit2 7")

    assert %{
             key: {{"rabbit", 2}, 1, 6},
             code: :finished,
             text: "Game Over! Average Score: 5.0, # Games: 1, Scores:  (ERUPTIVE: 5)"
           } = Game.Server.Stub.status(game_pid, player_key, {{"rabbit", 2}, 1, 6})
  end
end
