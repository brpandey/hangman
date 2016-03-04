defmodule Hangman.Player.Events.Server do
  @moduledoc """
  Module implements events manager for player abstraction
  """

  require Logger

	@doc """
	Start public interface method
	"""
  
  @spec start_link(Keyword.t) :: {:ok, pid}
	def start_link(options \\ [file_output: false, display_output: true]) do
		Logger.info "Starting Hangman Event Server, options #{inspect options}"

		{:ok, pid} = reply = GenEvent.start_link()

    # Given file_output is specified, add logger event handler to log events to file
		case Keyword.fetch(options, :file_output) do
			{:ok, true} ->
				GenEvent.add_handler(pid, Hangman.Player.Logger.Handler, [])
			_ -> ""
		end

    # Given display_output is specified, add a background task process which is setup to 
    # stream the gen events and according to event type display them on screen 
    # using a feed like syntax
		case Keyword.fetch(options, :display_output) do
			
			{:ok, true} ->

				Task.start_link fn ->
					stream = GenEvent.stream(pid)

          # the stream is the generator here in this list comprehension, 
          # as events come in we process them
					for event <- stream do
						case event do
							{:start, name} ->
								IO.puts "##{name}_feed --> Hangman_Game has started"

							{:secret_length, name, game_no, length} ->
								IO.puts "##{name}_feed Game #{game_no}, " <> 
                  "secret length --> #{length}"

							{:guessed_letter, name, game_no, letter} ->
								IO.puts "##{name}_feed Game #{game_no}, " <> 
                  "letter --> #{letter}"

							{:guessed_word, name, game_no, word} ->
								IO.puts "##{name}_feed Game #{game_no}, " <> 
                  "word --> #{word}"

							{:round_status, name, game_no, round_no, status} ->
								IO.puts "##{name}_feed Game #{game_no}, " <> 
                  "Round #{round_no}, status --> #{status}\n"

							{:games_over, name, text} ->
								IO.puts "##{name}_feed Game Over!! --> #{text}"
						end
					end
				end

			_ -> ""
		end

		reply
	end

  @doc """
  Sends :start tuple event notification to event manager
  """

  @spec notify_start(pid, String.t) :: :ok
	def notify_start(pid, name) do
		GenEvent.notify(pid, {:start, name})
	end

  @doc """
  Sends :secret_length tuple event notification to event manager
  """

  @spec notify_length(pid, tuple) :: :ok
	def notify_length(pid, {name, game_no, length}) do
		GenEvent.notify(pid, {:secret_length, name, game_no, length})
	end

  @doc """
  Sends :guessed_letter tuple event notification to event manager
  """

  @spec notify_letter(pid, tuple) :: :ok
	def notify_letter(pid, {name, game_no, letter}) when is_binary(letter) do
		GenEvent.notify(pid, {:guessed_letter, name, game_no, letter})
	end

  @doc """
  Sends :guessed_word tuple event notification to event manager
  """

  @spec notify_word(pid, tuple) :: :ok
	def notify_word(pid, {name, game_no, word}) when is_binary(word) do
		GenEvent.notify(pid, {:guessed_word, name, game_no, word})
	end

  @doc """
  Sends :round_status tuple event notification to event manager
  """

  @spec notify_status(pid, tuple) :: :ok
	def notify_status(pid, {name, game_no, round_no, status}) do
		GenEvent.notify(pid, {:round_status, name, game_no, round_no, status})
	end

  @doc """
  Sends :games_over tuple event notification to event manager
  """

  @spec notify_games_over(pid, String.t, String.t) :: :ok
	def notify_games_over(pid, name, text) do
		GenEvent.notify(pid, {:games_over, name, text})
	end

  @doc """
  Issues request to stop GenEvent manager
  """
  
  @spec stop(pid) :: :ok
  def stop(pid) do
    GenEvent.stop(pid)
  end


	@doc """
	Callback function for termination
	"""
  
  @callback terminate(term, term) :: :ok
	def terminate(_reason, _state) do
		:ok
	end

end
