defmodule Hangman.CLI do
  @moduledoc """
  Module provides a command line interpreter interface
  to the `Hangman` application.

  Hangman runs both interactive human games with manually specified
  secrets e.g. --secrets or runs games with randomly generated secrets 
  e.g. --random, either with interactive game play (human) or not (robot).
  Therefore the type of the player `-t` determines the user interaction type.

  The random `-r` secret generation option allows you to play without
  knowing the secret hangman word(s) beforehand as the system randomly
  selects the secret(s) to play against.

  Robot games are auto-guessed based on simple strategy heuristics. 
  Player game archival can be captured through logging, e.g. --log option

  The display and log options are exclusive to the command line client. 
  The human guessing wait `-w` option allows values between 0 secs and 20 secs
  to choose a letter. The parallel `-p` option allows games to be played on 
  all the cores of your system

  `Usage:
  --name (player id) --type ("human" or "robot") --random (num random secrets, max 1000)
  [--secret (hangman word(s)) --baseline] [--log --display --wait (e.g. 15 secs)] [--parallel (40 secrets or more suggested)]`

  or

  `Aliase Usage: 
  -n (player id) -t ("human" or "robot") -r (num random secrets, max 1000)
  [-s (hangman word(s)) -b] [-l -d -w] [-p (40 secrets or more suggested)]`

  NOTE: Should a player submit a secret hangman word that does not actually
  reside in the `Dictionary.Cache` the player will abort and then restart and the
  game will continue on - marking a score of 0 for the word not found game.
  """

  alias Hangman.{CLI, Shard}

  @min_secret_length Application.get_env(:hangman_game, :min_secret_length)
  @max_secret_length Application.get_env(:hangman_game, :max_secret_length)

  @max_guess_wait Application.get_env(:hangman_game, :max_guess_wait)
  @default_guess_wait Application.get_env(:hangman_game, :default_guess_wait)
  # let tests run quicker
  @test_guess_wait 10

  @human Hangman.Player.Types.human()
  @robot Hangman.Player.Types.robot()

  @doc """
  Gateway function to fetch and validate parameters.  Handles display
  of help information.  Proceeds to run the hangman game from the command line.
  """

  @spec main([String.t()]) :: :ok
  def main(args) do
    args |> parse_args |> print |> fetch_params |> run
  end

  @spec parse_args([String.t()]) :: Keyword.t()
  defp parse_args(args) do
    {parsed, _argv, _errors} =
      OptionParser.parse(
        args,
        strict: [
          # --name or alias -n, string only
          name: :string,
          # --type or alias -t, string only
          type: :string,
          # --random or alas -t, string only
          random: :string,
          # --secret or alias -w, string only
          secret: :string,
          # --baseline or alias -bl, boolean only
          baseline: :boolean,
          # -- log or alias -l, boolean only
          log: :boolean,
          # -- display or alias -d, boolean only
          display: :boolean,
          # -- wait or alias -w, integer only
          wait: :integer,
          # --parallel or alias -pl, boolean only
          parallel: :boolean,
          # --help or alias -h, boolean only
          help: :boolean
        ],
        aliases: [
          n: :name,
          t: :type,
          r: :random,
          s: :secret,
          b: :baseline,
          l: :log,
          d: :display,
          w: :wait,
          p: :parallel,
          h: :help
        ]
      )

    parsed
  end

  @spec print(Keyword.t() | []) :: Keyword.t() | no_return
  defp print([]) do
    IO.puts("No arguments given, try --help or -h")
    System.halt(0)
  end

  defp print(parsed) do
    case Keyword.fetch(parsed, :help) do
      # if no help supplied, resume normally and return parsed output
      :error ->
        parsed

      {:ok, true} ->
        IO.puts(
          "--name (player id) --type (\"human\" or \"robot\")" <>
            " --random (num random secrets, max 1000)" <>
            " [--secret (hangman word(s)) --baseline] [--log --display --wait] [--parallel  (40 secrets or more suggested)]\n"
        )

        IO.puts(
          "or aliases: -n (player id) -t (\"human\" or \"robot\") " <>
            "-r (num random secrets, max 1000) [-s (hangman word(s)) -bl] [-l -d -w] [-pl (40 secrets or more suggested)]"
        )

        System.halt(0)
    end
  end

  @spec fetch_params(Keyword.t()) ::
          {:parallel, {String.t(), list}}
          | {:sequential, {String.t(), atom, list, boolean, boolean, pos_integer}}
  defp fetch_params(args) do
    case Keyword.fetch(args, :parallel) do
      {:ok, true} -> parallel_params(args)
      _ -> sequential_params(args)
    end
  end

  @spec parallel_params(Keyword.t()) :: {:parallel, {String.t(), list}} | no_return
  defp parallel_params(args) do
    # assert for name flag
    with {:ok, name} <- Keyword.fetch(args, :name) do
      {:parallel, {name, fetch_secrets(args)}}
    else
      _ -> raise HangmanError, "name argument missing"
    end
  end

  @spec sequential_params(Keyword.t()) ::
          {:sequential, {String.t(), atom, list, boolean, boolean, pos_integer}} | no_return
  defp sequential_params(args) do
    # assert for name flag
    with {:ok, name} <- Keyword.fetch(args, :name) do
      type =
        case Keyword.fetch(args, :type) do
          {:ok, "human"} -> @human
          {:ok, "robot"} -> @robot
          _ -> @robot
        end

      secrets = fetch_secrets(args)

      log =
        case Keyword.fetch(args, :log) do
          {:ok, true} -> true
          :error -> false
        end

      display =
        case Keyword.fetch(args, :display) do
          {:ok, true} -> true
          :error -> false
        end

      wait =
        case Keyword.fetch(args, :wait) do
          {:ok, wait} when is_integer(wait) ->
            secs_wait = wait * 1000

            cond do
              secs_wait == 0 -> @test_guess_wait
              secs_wait > 0 and secs_wait <= @max_guess_wait -> secs_wait
              true -> @default_guess_wait
            end

          :error ->
            @default_guess_wait
        end

      {:sequential, {name, type, secrets, log, display, wait}}
    else
      _ -> raise HangmanError, "name argument missing"
    end
  end

  @spec fetch_secrets(Keyword.t()) :: [String.t()] | no_return
  defp fetch_secrets(args) do
    # first check if there is a baseline option specified
    # so that we can get the secrets from there

    secrets1 =
      case Keyword.fetch(args, :baseline) do
        {:ok, true} ->
          [
            "comaker",
            "cumulate",
            "elixir",
            "eruptive",
            "monadism",
            "mus",
            "nagging",
            "oses",
            "remembered",
            "spodumenes",
            "stereoisomers",
            "toxics",
            "trichromats",
            "triose",
            "uniformed"
          ]

        :error ->
          []
      end

    secrets2 =
      case Keyword.fetch(args, :secret) do
        # split always returns a list
        {:ok, value} ->
          String.split(value, " ")

        :error ->
          []
      end

    secrets3 =
      case Keyword.fetch(args, :random) do
        # ask dictionary for random words
        {:ok, value} ->
          Hangman.Dictionary.random(value)

        :error ->
          []
      end

    vector = [secrets1] ++ [secrets2] ++ [secrets3]

    # If all the vector list elements are empty lists, error

    # Else filter the secrets vector to only those that are not empty
    # And choose the first one (precedence is baseline then secrets then random)

    with false <- Enum.all?(vector, fn x -> x == [] end) do
      vector = Enum.reject(vector, fn x -> x == [] end)

      # Choose the first secrets vector
      secrets = List.first(vector)

      # Check each of the secret strings for valid size
      if Enum.any?(secrets, fn x ->
           String.length(x) < @min_secret_length or String.length(x) > @max_secret_length
         end) do
        raise HangmanError, "submitted secret is either too short or too long!"
      end

      secrets
    else
      _ ->
        raise HangmanError,
              "user must specify either --\"secret\" --\"random\" or --\"baseline\" option"
    end
  end

  @spec run({:sequential, {String.t(), atom, list, boolean, boolean, pos_integer}}) :: :ok
  defp run({:sequential, {name, type, secrets, log, display, wait}})
       when is_binary(name) and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) and
              is_boolean(log) and is_boolean(display) and is_integer(wait) do
    CLI.Handler.run(name, type, secrets, log, display, wait)
  end

  @spec run({:parallel, {String.t(), list}}) :: :ok
  defp run({:parallel, {name, secrets}})
       when is_binary(name) and is_list(secrets) and is_binary(hd(secrets)) do
    Shard.Flow.run(name, secrets) |> IO.inspect()
  end
end
