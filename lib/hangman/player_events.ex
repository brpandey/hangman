defmodule Hangman.Player.Events.Notify do

	# options = [file_output: true, display_output: false]
	def start_link(options \\ [file_output: true]) do
		IO.puts "Starting Hangman GenEvent Server"

		{:ok, pid} = GenEvent.start_link()

		case Keyword.fetch(options, :file_output) do
			{:ok, true} ->
				GenEvent.add_handler(pid, Hangman.Player.Logger.Handler, [])
			_ -> ""
		end

		case Keyword.fetch(options, :display_output) do
			
			{:ok, true} ->
				Task.start_link fn ->
					stream = GenEvent.stream(pid)

					for event <- stream do
						case event do
							{:start, name} ->
								IO.puts "##{name}_feed setup --> _HAN__AN_ has started"

							{:secret_length, name, game_no, length} ->
								IO.puts "##{name}_feed Game #{game_no}, secret length --> #{length}"

							{:guessed_letter, name, game_no, letter} ->
								IO.puts "##{name}_feed Game #{game_no}, letter --> #{letter}"

							{:guessed_word, name, game_no, word} ->
								IO.puts "##{name}_feed Game #{game_no}, word --> #{word}"

							{:round_status, name, game_no, round_no, status} ->
								IO.puts "##{name}_feed Game #{game_no}, Round #{round_no}, status --> #{status}\n"

							{:game_over, name, text} ->
								IO.puts "##{name}_feed Game Over!! --> #{text}"
						end
					end
				end

			_ -> ""
		end

		{:ok, pid}
	end

	def start(pid, name) do
		GenEvent.notify(pid, {:start, name})
	end

	def secret_length(pid, {name, game_no, length}) do
		GenEvent.notify(pid, {:secret_length, name, game_no, length})
	end

	def guessed_letter(pid, {name, game_no, letter}) when is_binary(letter) do
		GenEvent.notify(pid, {:guessed_letter, name, game_no, letter})
	end

	def guessed_word(pid, {name, game_no, word}) when is_binary(word) do
		GenEvent.notify(pid, {:guessed_word, name, game_no, word})
	end

	def round_status(pid, {name, game_no, round_no, status}) do
		GenEvent.notify(pid, {:round_status, name, game_no, round_no, status})
	end

	def game_over(pid, name, text) do
		GenEvent.notify(pid, {:game_over, name, text})
	end

end