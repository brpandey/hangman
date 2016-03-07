defmodule Hangman.Player.Logger.Handler do
	use GenEvent

  @moduledoc """
  Module implements event logger handler for player events
  Each event is logged to a file named after player id (name)
  """

  alias Hangman.{Guess}
  require Logger


  @callback init(term) :: tuple
	def init(_), do: {:ok, []}

  @doc """
  Handles :start notification event
  Opens and writes to player logger file
  """

  @callback handle_event(tuple, term) :: tuple
	def handle_event({:start, name}, _state) do

		file_name = "#{name}_hangman_games.txt"

		{:ok, file_pid} = File.open(file_name, [:append])

		{:ok, file_pid}
	end

  @doc """
  Handles :games_over notification event
  Writes to player logger file and then closes file
  """

  @callback handle_event(tuple, pid) :: tuple
	def handle_event({:games_over, _name, text}, file_pid) do

		msg = "\n# game over! --> #{text} \n"

		write(file_pid, msg)

		:ok = File.close(file_pid)

		{:ok, []}
	end

  @doc """
  Handles :secret_length notification event
  Writes to player logger file
  """

  @callback handle_event(tuple, pid) :: tuple
	def handle_event({:secret_length, _name, game_no, length}, file_pid) do

		msg = "\n# new game #{game_no}! secret length --> #{length}\n"

		write(file_pid, msg)

		{:ok, file_pid}
	end

  @doc """
  Handles :guessed_word notification event
  Writes to player logger file
  """

  @callback handle_event({Guess.t, tuple}, pid) :: tuple
	def handle_event({{:guess_word, word}, _info}, file_pid) do

		msg = "# word --> #{word} "

		write(file_pid, msg)

		{:ok, file_pid}
	end

  @doc """
  Handles :guessed_letter notification event
  Writes to player logger file
  """

  @callback handle_event({Guess.t, tuple}, pid) :: tuple
	def handle_event({{:guess_letter, letter}, _info}, file_pid) do

		msg = "# letter --> #{letter} "

		write(file_pid, msg)

		{:ok, file_pid}
	end


  @doc """
  Handles :round_status notification event
  Writes to player logger file
  """

  @callback handle_event(tuple, pid) :: tuple
	def handle_event({:round_status, _name, _game_no, round_no, text}, file_pid) do

		msg = "# round #{round_no} status --> #{text}\n"

		write(file_pid, msg)
		
		{:ok, file_pid}
	end

  # Write helper which writes out to player logger file using the IO module
  @spec write(pid, String.t) :: :ok
	defp write(file_pid, msg), do: IO.write(file_pid, msg)

  
	@doc """
	Terminate callback
	Close file
	"""
  
  @callback terminate(term, pid) :: :ok | tuple
	def terminate(_reason, file_pid) when is_pid(file_pid) do
		Logger.info "Terminating Player Logger Event Server"
    File.close(file_pid)
		:ok
	end

end
