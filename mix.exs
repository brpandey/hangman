defmodule Hangman.Mixfile do
  use Mix.Project

  def project do
    [
      app: :hangman_game,
      name: "Hangman",
      version: "0.9.5",
      elixir: "~> 1.3.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      escript: [main_module: Hangman.CLI],
      deps: deps,
      test_pattern: "*_{test,eqc}.exs",
      docs: [
        source_url: "https://bitbucket.org/brpandey/elixir-hangman/",
        formatter: "html"
        ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information

  # Runtime dependencies
  def application do
    [
      applications: [:logger, :gproc, :httpoison, :cowboy, 
                     :plug, :exprof, :ex_doc, :runtime_tools, :gen_stage],
      mod: {Hangman.Application, [type: :regular, ingestion: true]}
#      mod: {Hangman.Application, [type: :big, ingestion: true]}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options

  # Compile time dependencies
  defp deps do
    [
      {:gproc, "0.5.0"}, # for pid registry
      {:exprof, "~> 0.2.0"}, # to facilitate profiling
      {:ex_doc, "~> 0.13.0"}, # for mix docs
      {:cowboy, "1.0.4"}, # for hangman web
      {:plug, "1.1.6"},  # for hangman web
      {:httpoison, "~> 0.9.0"}, # for hangman web
      {:exrm, "1.0.1"}, # for mix release
      {:fsm, "~> 0.2.0"}, # for state machine handling
      {:exactor, "~> 2.2.0", warn_missing: false}, # for simple GenServers
      {:gen_stage, "~> 0.6"}, # exp module for distinct producers and consumers
      {:eqc_ex, "~> 1.2.4"}, # for quick check property tests
      {:dialyxir, "~> 0.3", only: [:dev]} # for erlang dialyzer type checking
    ] 
  end
end
