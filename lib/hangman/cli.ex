defmodule Hangman.CLI do
  @moduledoc """

  Module provides a command line interpreter interface
  to the `Hangman` application.

  Runs interactive human games with manually specified
  secrets and also runs human and robot games with 
  randomly generated secrets.

  Robot games are auto-guessed based on simple strategy heuristics.

  Player game archival can be captured through logging, e.g. --log option

  The display and log options are exclusive to the CLI client. As well as the
  human guessing timeout option which allows values between 0 secs and 10 secs
  to choose a letter.

  `Usage:
  --name (player id) --type ("human" or "robot") --random (num random secrets, max 1000)
  [--secret (hangman word(s)) --baseline] [--log --display --timeout] [--parallel (40 secrets or more suggested)]`

  or

  `Aliase Usage: 
  -n (player id) -t ("human" or "robot") -r (num random secrets, max 1000)
  [-s (hangman word(s)) -bl] [-l -d -ti] [-pl (40 secrets or more suggested)]`

  NOTE: Should a player submit a secret hangman word that does not actually
  reside in the `Dictionary.Cache` the player will abort and then restart and the
  game will continue on - marking a score of 0 for the word not found game.
  """

  @min_secret_length 3
  @max_secret_length 28

  @max_guess_timeout 10000 # 10 secs
  @default_guess_timeout 5000 # 5 secs

  alias Hangman.{CLI, Flow}

  @human Hangman.Player.human
  @robot Hangman.Player.robot

  @doc """
  Gateway function to fetch and validate parameters.  Handles display
  of help information.  Proceeds to run the hangman game from the command line.
  """

  @spec main([String.t]) :: :ok
  def main(args) do
    args |> parse_args |> print |> fetch_params |> run
  end

  @spec parse_args([String.t]) :: Keyword.t
  defp parse_args(args) do
    {parsed, _argv, _errors} = OptionParser.parse(args, 
      [
        strict: [
          name: :string, # --name or alias -n, string only
          type: :string, # --type or alias -t, string only
          random: :string, # --random or alas -t, string only
          secret: :string, # --secret or alias -w, string only
          baseline: :boolean, # --baseline or alias -bl, boolean only
          log: :boolean, # -- log or alias -l, boolean only
          display: :boolean, # -- display or alias -d, boolean only
          timeout: :integer, # -- timeout or alias -ti, integer only
          parallel: :boolean, # --parallel or alias -pl, boolean only
          help: :boolean # --help or alias -h, boolean only
        ],

        aliases: [n: :name, t: :type, r: :random, s: :secret, 
                  bl: :baseline, l: :log, d: :display, ti: :timeout, 
                  pl: :parallel, h: :help]
      ])

    parsed
  end
  
  @spec print(Keyword.t | []) :: Keyword.t | no_return
  defp print([]) do
    IO.puts "No arguments given, try --help or -h"
    System.halt(0)
  end

  defp print(parsed) do
    case Keyword.fetch(parsed, :help) do
      # if no help supplied, resume normally and return parsed output
      :error -> 
        parsed

      {:ok, true} ->
        IO.puts "--name (player id) --type (\"human\" or \"robot\")" <> 
          " --random (num random secrets, max 1000)" <>
          " [--secret (hangman word(s)) --baseline] [--log --display --timeout] [--parallel  (40 secrets or more suggested)]\n"
        
        IO.puts "or aliases: -n (player id) -t (\"human\" or \"robot\") " <> 
          "-r (num random secrets, max 1000) [-s (hangman word(s)) -bl] [-l -d -ti] [-pl (40 secrets or more suggested)]"
        System.halt(0)
    end

  end


  @spec fetch_params(Keyword.t) :: {:parallel, {String.t, list}} 
  | {:sequential,  {String.t, atom, list, boolean, boolean, pos_integer}} 
  defp fetch_params(args) do

    case Keyword.fetch(args, :parallel) do
      {:ok, true} -> parallel_params(args)
      _ -> sequential_params(args)
    end
    
  end


  @spec parallel_params(Keyword.t) :: {:parallel, {String.t, list}} | no_return
  defp parallel_params(args) do

    # assert for name flag
    with {:ok, name} <- Keyword.fetch(args, :name) do
      {:parallel, {name, fetch_secrets(args)}}
    else
      _ -> raise HangmanError, "name argument missing"
    end
  end


  @spec sequential_params(Keyword.t) :: 
  {:sequential, {String.t, atom, list, boolean, boolean, pos_integer}} | no_return
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
      
      timeout = 
        case Keyword.fetch(args, :timeout) do
          {:ok, timeout} when is_integer(timeout) -> 
            if timeout > 0 and timeout <= @max_guess_timeout do
              timeout
            else
              @default_guess_timeout
            end
          
            :error -> @default_guess_timeout
        end
      
      {:sequential, {name, type, secrets, log, display, timeout}}

    else
      _ -> raise HangmanError, "name argument missing"
    end
  end


  @spec fetch_secrets(Keyword.t) :: [String.t] | no_return
  defp fetch_secrets(args) do
    # first check if there is a baseline option specified
    # so that we can get the secrets from there

    secrets1 = 
      case Keyword.fetch(args, :baseline) do
        {:ok, true} -> 
          ["comaker","cumulate", "elixir", "eruptive", "monadism",
           "mus", "nagging", "oses", "remembered", "spodumenes",
           "stereoisomers","toxics","trichromats","triose", "uniformed"]
        :error -> []
      end
         
    secrets2 = 
      case Keyword.fetch(args, :secret) do
        # split always returns a list
        {:ok, value} -> String.split(value, " ")
        :error -> []
      end

    secrets3 = 
      case Keyword.fetch(args, :random) do
        # ask dictionary for random words
        {:ok, value} -> Hangman.Dictionary.random(value)
        :error -> []
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
            String.length(x) < @min_secret_length or
            String.length(x) > @max_secret_length
          end) do
        raise HangmanError, "submitted secret is either too short or too long!"
      end
      
      secrets
    else
      _ -> raise HangmanError, "user must specify either --\"secret\" --\"random\" or --\"baseline\" option"
    end
  end


  @spec run({:sequential, {String.t, atom, list, boolean, boolean, pos_integer}}) :: :ok
  defp run({:sequential, {name, type, secrets, log, display, timeout}}) when is_binary(name) 
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) and is_integer(timeout) do
    CLI.Handler.run(name, type, secrets, log, display, timeout)
  end

  @spec run({:parallel, {String.t, list}}) :: :ok
  defp run({:parallel, {name, secrets}}) when is_binary(name) and is_list(secrets) 
  and is_binary(hd(secrets)) do
    Flow.run(name, secrets) |> IO.inspect
  end

end
  
