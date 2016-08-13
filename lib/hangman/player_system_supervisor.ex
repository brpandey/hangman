defmodule Hangman.Player.System.Supervisor do
  use Supervisor

  @moduledoc false

  '''
  Module supervises all components necessary for player and 
  strategic player game play including dictionary cache server,
  word pass server, reduction engine, pass writer, 
  and player events and fsm supervisor

  Module is a third line supervisor as it supervises two 
  first-line supervisors and 1 second-line supervisor.
  '''

  alias Hangman.{Dictionary, Pass, Reduction}

  require Logger

  import Supervisor.Spec

  @name __MODULE__

  @doc """
  Supervisor start and link wrapper function
  """

  @spec start_link(Keyword.t) :: Supervisor.on_start
  def start_link(args) do
    Logger.info "Starting Hangman Player System Supervisor," <> 
      " args: #{inspect args}"

    Supervisor.start_link(@name, args)
  end

  @doc """
  Specifies worker children specifications.  
  These consist of a mix of workers and supervisors.  
  Deploys a strategy of rest for one as these
  process trees are dependant on each other
  and not mutually exclusive
  """
  
  @callback init(Keyword.t) :: {:ok, tuple}
  def init(args) do

    children = [
      worker(Dictionary.Cache, [args]),
      worker(Pass.Cache, []),
      worker(Pass.Cache.Writer, []),
      supervisor(Reduction.Engine, [])
    ]

    supervise(children, strategy: :rest_for_one)
  end

end
