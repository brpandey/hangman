defmodule Hangman.Mixfile do
  use Mix.Project

  def project do
    [
      app: :play,
      name: "Hangman",
      version: "0.9.1",
      elixir: "~> 1.2.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      escript: [main_module: Hangman.CLI],
      deps: deps,
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
    dict_type = Hangman.Dictionary.regular
    # dict_type = Hangman.Dictionary.big
    args = [{dict_type, true}]

    [
      applications: [:logger, :gproc, :httpoison, :cowboy, 
                     :plug, :exprof, :ex_doc, :runtime_tools],
      mod: {Hangman.Application, args}
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
      {:ex_doc, "~> 0.11"}, # for mix docs
      {:cowboy, "1.0.4"}, # for hangman web
      {:plug, "1.1.2"},  # for hangman web
      {:httpoison, "~> 0.8.2"}, # for hangman web
      {:exrm, "1.0.1"} # for mix release
    ] 
  end
end
