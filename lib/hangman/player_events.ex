defmodule Hangman.Player.Events.Notify do

	def start_link() do
		{:ok, pid} = GenEvent.start_link()
		GenEvent.add_handler(pid, Hangman.Player.Logger.Handler, [])

		Task.start_link fn ->
			stream = GenEvent.stream(pid)

			for event <- stream do
				case event do
					{:start, name} ->
						IO.inspect "#Player #{name} --> _Ha_Ng_m_An_ has started"

					{:secret_length, name, game_no, length} ->
						IO.inspect "#Player #{name}, Game #{game_no}, secret length --> #{length}"

					{:guessed_letter, name, game_no, letter} ->
						IO.inspect "#Player #{name}, Game #{game_no}, guessed letter --> #{letter}"

					{:guessed_word, name, game_no, word} ->
						IO.inspect "#Player #{name}, Game #{game_no}, guessed word --> #{word}"

					{:round_status, name, game_no, round_no, status} ->
						IO.inspect "#Player #{name}, Game #{game_no}, Round #{round_no}, status --> #{status}"

					{:game_over, name, text} ->
						IO.inspect "#Player #{name}, Game Over!! --> #{text}"
				end		
			end
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