alias Hangman.Player.Generic
alias Hangman.Action.{Human, Robot}


defprotocol Hangman.Player.Action do

  @moduledoc """
  Module implements player action functionality 
  for various player types via protocol mechanism
  
  The Player Action protocol is implemented for the Human and Robot types, with
  Generic Player handling overlaps in functionality.  The Action protocol
  could be thought of as a sort of virtual player as it defers implementation
  to a combination of type specific functionality and generic type functionality.
  
  The goal of a player is to maximize our winning chances in conjunction
  with a letter strategy against the 'implicit' other player, the `game server`.
  
  Player action functionality handles choosing letters, guessing letters and words.
  
  Player action encapsulates via the action types, 
  the data used along with Strategy data. `Round` functionality
  extends the scope of the player to handle the actual game round details.
  
  Function names are `new/2`, `begin/1`, `setup/1`, `guess`, `transition/1`
  """

  @doc "Create new player"
  def new(player, args)

  @doc "Begin new game player action"
  def begin(player)

  @doc "Sets up each action state"
  def setup(player)
  
  @doc "Returns player guess"
  def guess(player, guess \\ nil)

  @doc "Returns the correct player transition at the game end"
  def transition(player)
end


defimpl Hangman.Player.Action, for: Human do
  def new(%Human{} = player, {name, display, game_pid})
  when (is_binary(name) or is_tuple(name)) and
  is_boolean(display) and is_pid(game_pid) do

    round = Generic.new(name, game_pid)
    %{player | display: display, round: round}
  end

  def begin(%Human{} = player) do
    {round, strategy, code} = Generic.begin(player.round, player.type)
    player = %{ player | round: round, strategy: strategy }
    {player, code}
  end

  def setup(%Human{} = player) do
    # returns {player, choices}
    # where choices is {:guess_letter, "choices_text"} 
    # or {:guess_word, last, "text"}
    Human.setup(player)
  end
  
  def guess(%Human{} = player, guess) do
    Human.guess(player, guess) # returns {player, status} tuple
  end

  def transition(%Human{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)
    {player, status}
  end
end


defimpl Hangman.Player.Action, for: Robot do

  def new(%Robot{} = player, {name, display, game_pid})
  when (is_binary(name) or is_tuple(name)) and
  is_boolean(display) and is_pid(game_pid) do
    round = Generic.new(name, game_pid)
    %{ player | display: display, round: round}
  end

  def begin(%Robot{} = player) do
    {round, strategy, code} = Generic.begin(player.round, player.type)
    player = %{ player | round: round, strategy: strategy }
    {player, code}
  end

  def setup(%Robot{} = player) do
    Robot.setup(player) # returns {player, []} tuple
  end
  
  def guess(%Robot{} = player, _guess) do
    Robot.guess(player, nil) # returns {player, status} tuple
  end

  def transition(%Robot{} = player) do
    {round, status} = Generic.transition(player.round)
    player = Kernel.put_in(player.round, round)
    {player, status}
  end
end
