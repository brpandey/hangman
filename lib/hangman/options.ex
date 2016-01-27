defmodule Hangman.Options do

	alias Hangman.{Cache, Player, Supervisor}

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

				IO.puts "--dictfile <file name> --name <player name> --word <hangman secrets> --baseline, or"
				IO.puts "-f <file name> -n <player name> -w <hangman secrets> -bl"
		    System.halt(0)

			:error -> parsed
		end
  end

  defp parse_args(args) do
    {parsed, _argv, _errors} = OptionParser.parse(args, 
    	[
	    	strict: [
	    		help: :boolean, # --help or alias -h, boolean only
	    		dictfile: :string,	 # --dictfile or alias -f, string only
	    		word: :string, # --word or alias -w, string only
	    		baseline: :boolean, # --baseline or alias -bl, boolean only
	    		name: :string, # --name or alias -n, string only
	    		#type: :string # --type or alias -t, string only
	    	],

	    	aliases: [f: :dictfile, w: :word,	bl: :baseline, n: :name, h: :help]

	    ])
    
    parsed
  end

  defp run(args) do
  	{:ok, player_name} = Keyword.fetch(args, :name)
  	{:ok, word} = Keyword.fetch(args, :word)

  	secrets = String.split(word, " ")

  	{:ok, _pid} = Supervisor.start_link()

		game_server_pid = Cache.get_server(player_name, secrets)

		{:ok, notify_pid} = Player.Events.Notify.start_link([display_output: false])

		Player.Stream.round(player_name, game_server_pid, notify_pid)		# reader stream
			|> Stream.each(fn text -> IO.puts("\n#{text}") end)							# printer stream
			|> Enum.take(100)
  end
end