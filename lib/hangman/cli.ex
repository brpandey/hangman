defmodule Hangman.CLI do

	alias Hangman.{Player}

  @min_secret_length 3

  def main(args) do
    args |> parse_args |> print |> run
  end

  defp print([]) do
    IO.puts "No arguments given, try --help or -h"
    System.halt(0)
  end

  defp print(parsed) do
		case Keyword.fetch(parsed, :help) do
			{:ok, true} ->
				IO.puts "--name <player id> --type <\"human\" or \"robot\">" <> 
          " --secret <hangman word(s)> --baseline, or"
				IO.puts "-n <player id> -t <\"human\" or \"robot\"> " <> 
          "-s <hangman word(s)> -bl"
		    System.halt(0)

      # if no help supplied, resume normally and return parsed output
			:error -> 
        {name, type, secrets} = fetch_params(parsed)
		end
  end

  defp parse_args(args) do
    {parsed, _argv, _errors} = OptionParser.parse(args, 
    	[
	    	strict: [
	    		name: :string, # --name or alias -n, string only
	    		type: :string, # --type or alias -t, string only
	    		secret: :string, # --secret or alias -w, string only
	    		baseline: :boolean, # --baseline or alias -bl, boolean only
	    		help: :boolean # --help or alias -h, boolean only
	    	],

	    	aliases: [n: :name, t: :type, s: :secret, bl: :baseline, h: :help]
	    ])

    parsed
  end

  defp fetch_params(args) do

    name = 
      case Keyword.fetch(args, :name) do
  	    {:ok, value} -> value
        :error -> raise "name argument missing"
      end

    secrets = 
    # first check if there is a baseline option specified
    # so that we can get the secrets from there
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
    
    {name, type, secrets}
  end

  defp run({name, type, secrets}) when is_binary(name) and is_atom(type)
  and is_list(secrets) and is_binary(hd(secrets)) do

  	{:ok, _pid} = Hangman.Supervisor.start_link()

    name 
    |> Player.Game.setup(secrets)
		|> Player.Game.play_rounds_lazy(type)		
		|> Stream.each(fn text -> IO.puts("\n#{text}") end)							
		|> Stream.run

  end
end
