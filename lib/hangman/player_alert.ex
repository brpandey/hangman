
alias Experimental.GenStage

defmodule Hangman.Player.Alert.Handler do
  use GenStage

  require Logger

  @moduledoc """
  Module implements event logger handler for `Hangman.Events.Manager`.
  Each `event` is logged to a file named after the player `id`.
  """

  def start_link(options) do
    GenStage.start_link(__MODULE__, options)
  end

  # Callbacks

  def init(options) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.

    with {:ok, write_pid} <- Keyword.fetch(options, :pid), 
    {:ok, key} <- Keyword.fetch(options, :id) do
      {:consumer, {key, write_pid}, subscribe_to: [Hangman.Event.Manager]}
    else 
      ## ABORT if display output not true
      _ -> {:stop, :normal}
    end
    
  end

  @doc """
  The handle_events callback handles various events
  which ultimately write to `player` logger file

  """

  def handle_events(events, _from, {key, write_pid}) do

    for event <- events, key == Kernel.elem(event, 1) do
      process_event(event, write_pid)
    end

    {:noreply, [], {key, write_pid}}    
  end

  defp process_event(event, write_pid) do

    msg = 
      case event do
        {:start, name, _} ->
          "##{name}_feed --> Hangman_Game has started"
        {:register, name, {game_no, length}} ->
          "##{name}_feed Game #{game_no}, " <> 
            "secret length --> #{length}"
        {:guess, name, {{:guess_letter, letter}, game_no}} ->
          "##{name}_feed Game #{game_no}, " <> 
            "letter --> #{letter}"
        {:guess, name, {{:guess_word, word}, game_no}} ->
          "##{name}_feed Game #{game_no}, " <> 
            "word --> #{word}"
        {:status, name, {game_no, round_no, text}} ->
          "##{name}_feed Game #{game_no}, " <> 
            "Round #{round_no}, status --> #{text}\n"
        {:games_over, name, text} ->
          "##{name}_feed Game Over!! --> #{text}"
      end

    case write_pid do
      nil -> IO.puts(msg)
      pid when is_pid(pid) -> IO.puts(pid, msg)
    end

  end


  @doc """
  Terminate callback. Closes player `logger` file
  """
  
  @callback terminate(term, term) :: :ok | tuple
  def terminate(_reason, _state) do
    Logger.info "Terminating Player Alert"
    :ok
  end
end
