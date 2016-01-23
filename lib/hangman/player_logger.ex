defmodule Hangman.Player.Logger.Handler do
	use GenEvent

	def init(_), do: {:ok, []}

	def handle_event({:start, name}, _state) do
		file_name = "#{name}_hangman_games.txt"

		{:ok, file_pid} = File.open(file_name, [:append])

		{:ok, file_pid}
	end

	def handle_event({:game_over, _name, text}, file_pid) do

		msg = "\n# game over! --> #{text} \n"

		write(file_pid, msg)

		:ok = File.close(file_pid)

		{:ok, []}
	end

	def handle_event({:secret_length, _name, game_no, length}, file_pid) do

		msg = "\n# new game #{game_no}! secret length --> #{length}\n"

		write(file_pid, msg)

		{:ok, file_pid}
	end

	def handle_event({:guessed_word, _name, _game_no, word}, file_pid) do

		msg = "# guessed word --> #{word} "

		write(file_pid, msg)

		{:ok, file_pid}
	end

	def handle_event({:guessed_letter, _name, _game_no, letter}, file_pid) do

		msg = "# guessed letter --> #{letter}"

		write(file_pid, msg)

		{:ok, file_pid}
	end

	def handle_event({:round_status, _name, _game_no, round_no, text}, file_pid) do

		msg = " # round #{round_no} status --> #{text}\n"

		write(file_pid, msg)
		
		{:ok, file_pid}
	end

	defp write(file_pid, msg), do: IO.write(file_pid, msg)

end