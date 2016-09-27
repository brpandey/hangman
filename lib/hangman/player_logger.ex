
alias Experimental.GenStage

defmodule Hangman.Player.Logger.Handler do
  use GenStage

  require Logger

  @moduledoc """
  Module implements event logger handler for `Hangman.Events.Manager`.
  Each `event` is logged to a file named after the player `id`.
  """

  @root_path   :code.priv_dir(:hangman_game)

  @spec start_link(Keyword.t) :: GenServer.on_start
  def start_link(options) do
    GenStage.start_link(__MODULE__, options)
  end

  @spec stop(pid) :: tuple
  def stop(pid) when is_pid(pid) do
    GenStage.call(pid, :stop)
  end


  # Callbacks

  @callback init(term) :: {GenStage.type, tuple, GenStage.options} | {:stop, :normal}
  def init(options) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.

    with {:ok, key} <- Keyword.fetch(options, :id) do

      file_name = "#{@root_path}/#{key}_hangman_games.txt"

      {:ok, logger_pid} = File.open(file_name, [:append])

      {:consumer, {key, logger_pid}, subscribe_to: [Hangman.Game.Event.Manager]}

    else 
      ## ABORT if display output not true
      _ -> {:stop, :normal}
    end

  end

  @callback handle_call(atom, tuple, term) :: tuple
  def handle_call(:stop, _from, state) do
    {:stop, :normal, :ok, state}
  end


  @doc """
  The handle_events callback handles various events
  which ultimately write to `player` logger file.
  Only those that match the player id key are selected
  """

  def handle_events(events, _from, {key, logger_pid}) do

    for event <- events,  key == Kernel.elem(event, 1) do
      process_event(event, logger_pid)
    end

    {:noreply, [], {key, logger_pid}}    
  end


  @spec process_event({atom, term, tuple | binary}, pid) :: :ok
  defp process_event(event, logger_pid) do

    msg = 
      case event do
        {:register, _, {game_no, length}} -> 
          "\n# new game #{game_no}! secret length --> #{length}\n"
        {:guess, _, {{:guess_letter, letter}, _game_no}} ->
          "# letter --> #{letter} "
        {:guess, _, {{:guess_word, word}, _game_no}} ->
          "# word --> #{word} "
        {:status, _, {_game_no, round_no, text}} -> 
          "# round #{round_no} status --> #{text}\n"
        {:finished, _, text} ->     
          "\n# games over! --> #{text} \n"
      end

    IO.write(logger_pid, msg)

    :ok
  end


  @doc """
  Terminate callback. Closes player `logger` file
  """
  
#  @spec terminate(term, term) :: :ok
  def terminate(_reason, state) do
#    _ = Logger.debug "Terminating Player Logger Handler"

    case state do
      val when is_tuple(val) -> 
        {_key, logger_pid} = val
        File.close(logger_pid)
      _ -> ""
    end
    
    :ok
  end
end
