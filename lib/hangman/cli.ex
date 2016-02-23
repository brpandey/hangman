defmodule Hangman.CLI do

	alias Hangman.{Player}

  @min_secret_length 3

  def main(args) do
    args |> parse_args |> print |> fetch_params |> run
  end

  defp parse_args(args) do
    {parsed, _argv, _errors} = OptionParser.parse(args, 
    	[
	    	strict: [
	    		name: :string, # --name or alias -n, string only
	    		type: :string, # --type or alias -t, string only
	    		secret: :string, # --secret or alias -w, string only
	    		baseline: :boolean, # --baseline or alias -bl, boolean only
          log: :boolean, # -- log or alias -l, boolean only
          display: :boolean, # -- display or alias -d, boolean only
	    		help: :boolean # --help or alias -h, boolean only
	    	],

	    	aliases: [n: :name, t: :type, s: :secret, 
                  bl: :baseline, l: :log, d: :display, h: :help]
	    ])

    parsed
  end

  defp print([]) do
    IO.puts "No arguments given, try --help or -h"
    System.halt(0)
  end

  defp print(parsed) do

		case Keyword.fetch(parsed, :help) do
      # if no help supplied, resume normally and return parsed output
      :error -> parsed

			{:ok, true} ->
				IO.puts "--name <player id> --type <\"human\" or \"robot\">" <> 
          " --secret <hangman word(s)> --baseline, or"
				IO.puts "-n <player id> -t <\"human\" or \"robot\"> " <> 
          "-s <hangman word(s)> -bl"
		    System.halt(0)
		end

  end

  defp fetch_params(args) do

    name = 
      case Keyword.fetch(args, :name) do
  	    {:ok, value} -> value
        :error -> raise "name argument missing"
      end

    # first check if there is a baseline option specified
    # so that we can get the secrets from there

    secrets = 
      case Keyword.fetch(args, :baseline) do
        {:ok, true} -> 
          ["comaker","cumulate", "elixir", "eruptive", "monadism",
           "mus", "nagging", "oses", "remembered", "spodumenes",
           "stereoisomers","toxics","trichromats","triose", "uniformed"]

        :error -> 
          # if no baseline arg is specified grab the secrets
  	      case Keyword.fetch(args, :secret) do
            {:ok, value} -> 
              # split always returns a list
              String.split(value, " ")
            :error -> raise "secrets argument missing"
          end
      end

    if Enum.any?(secrets, fn x -> String.length(x) < @min_secret_length end) do
      raise "submitted secret is too short!"
    end

    type = 
      case Keyword.fetch(args, :type) do
        {:ok, "human"} -> :human
        {:ok, "robot"} -> :robot
        _ -> :robot
      end

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

  defp run({name, type, secrets, log, display}) when is_binary(name) 
  and is_atom(type) and is_list(secrets) and is_binary(hd(secrets)) 
  and is_boolean(log) and is_boolean(display) do

    Player.Game.run(name, type, secrets, log, display)
  end
end
  
