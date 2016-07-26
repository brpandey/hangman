defmodule Hangman.CLI do
  @moduledoc """

  Module provides a command line interpreter interface
  to the `Hangman` application.

  Runs interactive human games with manually specified
  secrets and also runs human and robot games with 
  randomly generated secrets.

  Robot games are auto-guessed based on simple strategy heuristics.

  Player game archival can be captured through logging, e.g. --log option

  `Usage:
  --name (player id) --type ("human" or "robot") --random (num random secrets, max 10)
  [--secret (hangman word(s)) --baseline] [--log --display]`

  or

  `Aliase Usage: 
  -n (player id) -t ("human" or "robot") -r (num random secrets, max 10)
  [-s (hangman word(s)) -bl] [-l -d]`

  NOTE: Should a player submit a secret hangman word that does not actually
  reside in the `Dictionary.Cache` the entire game will currently be 
  prematurely aborted.
  """

  @min_secret_length 3
  @max_secret_length 28

  alias Hangman.{Player}

  @human Player.Types.human
  @robot Player.Types.robot

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
          help: :boolean # --help or alias -h, boolean only
        ],

        aliases: [n: :name, t: :type, r: :random, s: :secret, 
                  bl: :baseline, l: :log, d: :display, h: :help]
      ])

    parsed
  end
  
  @spec print([]) :: no_return
  defp print([]) do
    IO.puts "No arguments given, try --help or -h"
    System.halt(0)
  end

  @spec print(Keyword.t) :: Keyword.t | no_return
  defp print(parsed) do

    case Keyword.fetch(parsed, :help) do
      # if no help supplied, resume normally and return parsed output
      :error -> parsed

      {:ok, true} ->
        IO.puts "--name (player id) --type (\"human\" or \"robot\")" <> 
          " --random (num random secrets, max 10)" <>
          " [--secret (hangman word(s)) --baseline] [--log --display]\n"
        
        IO.puts "or aliases: -n (player id) -t (\"human\" or \"robot\") " <> 
          "-r (num random secrets, max 10) [-s (hangman word(s)) -bl] [-l -d]"
        System.halt(0)
    end

  end

  @spec fetch_secrets(Keyword.t) :: [String.t] | no_return
  defp fetch_secrets(args) do
    # first check if there is a baseline option specified
    # so that we can get the secrets from there

    secrets = 
      case Keyword.fetch(args, :baseline) do
        {:ok, true} -> 
          ["comaker","cumulate", "elixir", "eruptive", "monadism",
           "mus", "nagging", "oses", "remembered", "spodumenes",
           "stereoisomers","toxics","trichromats","triose", "uniformed"]

        :error -> 
          # if no baseline arg is specified
          
          secrets = 
            case Keyword.fetch(args, :secret) do
              {:ok, value} -> 
                # split always returns a list
                String.split(value, " ")
              :error -> nil
            end
          
          secrets = 
          if secrets == nil do
            case Keyword.fetch(args, :random) do
              {:ok, value} -> Player.Handler.random(value)
              :error -> nil
            end
          else secrets end

          if secrets == nil do
            raise HangmanError, "user must specify either --\"secret\" or --\"random\" option"
          end

          secrets
      end

    if Enum.any?(secrets, fn x -> String.length(x) < @min_secret_length end) do
      raise HangmanError, "submitted secret is too short!"
    end

    if Enum.any?(secrets, fn x -> String.length(x) > @max_secret_length end) do
      raise HangmanError, "submitted secret is too long!"
    end

    secrets
  end


  @spec fetch_params(Keyword.t) :: {} | no_return
  defp fetch_params(args) do

    name = 
      case Keyword.fetch(args, :name) do
        {:ok, value} -> value
        :error -> raise HangmanError, "name argument missing"
      end

    type = 
      case Keyword.fetch(args, :type) do
        {:ok, "human"} -> @human
        {:ok, "robot"} -> @robot
        _ -> :robot
      end

    secrets = fetch_secrets(args)

    log = 
      case Keyword.fetch(args, :log) do
        {:ok, true} -> true
        :error -> false
      end

    display = 
      case Keyword.fetch(args, :display) do
        {:ok, true} -> 
          # option only for robot guessing
          if type == :robot do true else false end
        :error -> false
      end
    
    
    {name, type, secrets, log, display}
  end

  @spec run({}) :: :ok
  defp run({name, type, secrets, log, display}) when is_binary(name) 
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    Player.Handler.run(name, type, secrets, log, display)
  end



end
  
