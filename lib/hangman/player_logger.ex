
alias Experimental.GenStage

defmodule Hangman.Player.Logger.Handler do
  use GenStage

  require Logger

  @moduledoc """
  Module implements event logger handler for `Hangman.Events.Manager`.
  Each `event` is logged to a file named after the player `id`.
  """

  @root_path   :code.priv_dir(:hangman_game)

  def start_link(options) do
    GenStage.start_link(__MODULE__, options)
  end

  def stop(pid) when is_pid(pid) do
    GenStage.call(pid, :stop)
  end


  # Callbacks

  def init(options) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.

    with {:ok, key} <- Keyword.fetch(options, :id) do

      file_name = "#{@root_path}/#{key}_hangman_games.txt"

      {:ok, logger_pid} = File.open(file_name, [:append])

      {:consumer, {key, logger_pid}, subscribe_to: [Hangman.Event.Manager]}

    else 
      ## ABORT if display output not true
      _ -> {:stop, :normal}
    end

  end

  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end

  @doc """
  The handle_events callback handles various events
  which ultimately write to `player` logger file
  """

  def handle_events(events, _from, {key, logger_pid}) do

    for event <- events,  key == Kernel.elem(event, 1) do
      process_event(event, logger_pid)
    end

    {:noreply, [], {key, logger_pid}}    
  end

  defp process_event(event, logger_pid) do

    msg = 
      case event do
        {:start, _, game_no} ->
          "\n# new game #{game_no} started! \n"
        {:register, _, {game_no, length}} -> 
          "\n# new game #{game_no}! secret length --> #{length}\n"
        {:guess, _, {{:guess_letter, letter}, _game_no}} ->
          "# letter --> #{letter} "
        {:guess, _, {{:guess_word, word}, _game_no}} ->
          "# word --> #{word} "
        {:status, _, {_game_no, round_no, text}} -> 
          "# round #{round_no} status --> #{text}\n"
        {:games_over, _, text} ->     
          "\n# games over! --> #{text} \n"
      end

    IO.write(logger_pid, msg)
  end


  @doc """
  Terminate callback. Closes player `logger` file
  """
  
  @callback terminate(term, term) :: :ok
  def terminate(_reason, state) do
    Logger.info "Terminating Player Logger Handler"

    if true == is_tuple(state) do
      {_key, logger_pid} = state
      File.close(logger_pid) 
    end

    :ok
  end
end
