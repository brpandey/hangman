defmodule Hangman.Player do

  alias Hangman.{Player, Player.Round, Player.Events, 
                 Round.Action, Strategy, Game}
  

	defstruct name: "", type: nil,
  round_no: 0,  round: %Hangman.Types.Game.Round{},
  strategy: Strategy.new,
  game_no: 0, game_summary: nil, game_server_pid: nil, 
  event_server_pid: nil,    
  mystery_letter: Game.Server.mystery_letter
  
  @type t :: %__MODULE__{}

  @human :human
  @robot :robot
    
  # CREATE
  
  def new(name, type, game_pid, event_pid)
  when is_binary(name) and is_atom(type)
  and is_pid(game_pid) and is_pid(event_pid) do
    
  	unless type in [@human, @robot] do 
      raise Hangman.Error, "invalid and unknown player type" 
    end
    
  	%Player{ name: name, type: type, 
  		       game_server_pid: game_pid, event_server_pid: event_pid }
  end

  # READ

  def last_word?(%Player{} = p) do
    case Strategy.last_word(p.strategy) do 
      {:guess_word, ""} -> false
      {:guess_word, _} -> true 
    end
  end

  def game_won?(%Player{} = p), do: p.round.status_code == :game_won
  def game_lost?(%Player{} = p), do: p.round.status_code == :game_lost
  def game_over?(%Player{} = p), do: p.game_summary != nil

  def game_summary(tuple_list) 
  when is_list(tuple_list) and is_tuple(Kernel.hd(tuple_list)) do
  	
		{:ok, avg} = Keyword.fetch(tuple_list, :average_score)
		{:ok, games} = Keyword.fetch(tuple_list, :games)
		{:ok, scores} = Keyword.fetch(tuple_list, :results)

		results = Enum.reduce(scores, "",  fn {k,v}, acc -> 
			acc <> " (#{k}: #{v})"  end)
			
		"Game Over! Average Score: #{avg}, " 
		<> "# Games: #{games}, Scores: #{results}"
	end

  def status(%Player{} = p, :game_round), do: Round.status(p)

  def status(%Player{} = p, :game_over) do
  	case game_over?(p) do
  		true -> {:game_over, p.game_summary}
  		false -> {p.round.status_code, p.round.status_text}
  	end
  end


	# UPDATE

	def start(%Player{} = p) do
    if p.game_no >= 1 do
      p = %Player{ name: p.name, type: p.type, 
                        game_server_pid: p.game_server_pid,
                        event_server_pid: p.event_server_pid,
                        game_no: p.game_no + 1 }
    else
      p = Kernel.put_in(p.game_no, p.game_no + 1)

      # Notify the event server that we've started playing hangman
      Events.Server.notify_start(p.event_server_pid, p.name)
    end

    case p.type do
      @robot ->
        fn_run = fn ->
          p = p |> Round.setup(:game_start) |> Action.perform(:guess)
          {p, Round.status(p)}
        end
        
        rescue_wrap(p, fn_run)

      @human -> 
        fn_run = fn ->
          p = p |> Round.setup(:game_start)
          choices = p |> Action.perform(:choose_letters)
          {p, choices}
        end

        rescue_wrap(p, fn_run)
      
      _ -> raise Hangman.Error, "Invalid and unknown player type"
    end
	end

  # human choose letter
  def choose(%Player{} = p, :letter), do: choose(p, p.type, :letter)

	def choose(%Player{} = p, @human, :letter) do
  	
    fn_run = fn ->
      p = p |> Round.setup # Setup round
      choices = Action.perform(p, :choose_letters)
      {p, choices}
    end

    rescue_wrap(p, fn_run)
  end

  # robot guess letter
  def guess(%Player{} = p), do: guess(p, p.type)

	def guess(%Player{} = p, @robot) do

    fn_run = fn ->
      p = p |> Round.setup # Setup round
      p = Action.perform(p, :guess)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end


  # human guess last word
  def guess(%Player{} = p, :last_word), do: guess(p, p.type, :last_word)

	def guess(%Player{} = p, @human, :last_word) do

    fn_run = fn ->
      p = Action.perform(p, :guess_last_word)
      status = Round.status(p)

      # If we can supposedly keep guessing, flag as error since this should be end
      case status do
        {:game_keep_guessing, _} -> 
          raise Hangman.Error, 
          "Last word was not actual last word, secret not in hangman dictionary"
        _ -> {p, status} # Return normal return value
      end
    end

    rescue_wrap(p, fn_run)
	end


  # human guess letter
  def guess(%Player{} = p, l, :letter), do: guess(p, p.type, l, :letter)

	def guess(%Player{} = p, @human, letter, :letter)
  when is_binary(letter) do

    fn_run = fn ->
      p = Action.perform(p, :guess_letter, letter)
      {p, Round.status(p)}
    end

    rescue_wrap(p, fn_run)
	end

  # Delay the running of function object until this method
  # if error, return status code :game_reset along with error message
  # if not return results of fn_run normally

  defp rescue_wrap(%Player{} = p, fn_run) do
    value = 
      try do 
        fn_run.() 
      rescue
        e in Hangman.Error -> {p, {:game_reset, e.message}}
      end
    
    value
  end

  # DELETE

  def delete(%Player{} = _p), do:	%Player{}


  # EXTRA

  def info(%Player{} = p) do

    round = [
        no: p.round.seq_no,
        guess: p.round.guess,
        guess_result: p.round.result_code,
        round_code: p.round.status_code,
        round_status: p.round.status_text,
        pattern: p.round.pattern
    ]
        
    _info = [
      name: p.name, 
      type: p.type,
      round_no: p.round_no,
      game_pid: p.game_server_pid,
      event_pid: p.event_server_pid,
      round_data: round
    ]
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(t, opts) do
      info = Inspect.List.inspect(Hangman.Player.info(t), opts)
      concat ["#Hangman.Player<", info, ">"]
    end
  end

end
