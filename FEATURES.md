Feature highlights:

* Ingests dictionary words via an Apache Spark-like map reduce engine (Flow/GenStage)
* Uses non-process state machine to cleanly handle player state transitions
* Provides fault-tolerance when a game word is not in the dictionary, 
   crashes worker process via supervision trees and resumes where it left off onto the next game if available, 
   otherwise denotes a 0 score to the game and displays Games Over!
* Supports the addition of other player types via protocols, currently supporting human and robot players
* Littered with functional programming idioms of reduce, map, flat_map, reduce_while, etc...
* Supports concurrent game play using all machine CPU cores
* Presents a simple command line interface to play games as well as a web interface
* Uses a simple letter retrieval heuristic of letter counts along with english letter frequency data
* Reduces the hangman word state through series of word reductions
* Implements a Counter abstraction similiar to Python's Counter class, with most_common method
* Enjoys the actor metaphor! Uses OTP/GenServer to represent key abstractions: 
  * Player.Worker, Game.Server, Pass.Cache, Dictionary.Cache, Reduction.Engine etc..
* Uses fast, concurrent, in memory tables via ETS, caches ETS dictionary table for quick load
* Utilizes process registries to keep track of player workers, game servers, and reduction worker processes
* Performance tested to shape dictionary load and letter tally generation,
* Uses macros to provide client handler loop functionality without exposing cycle/reduce-while trickery
* Has configurable system params for intuition testing
* Uses a liberal dose of unit and integration testing, along with stubs and even a quickcheck test!
* Uses Asynchronous Task for letter guess capture with timeout
* And mostly the Elixir code is a delight to look at!!!


