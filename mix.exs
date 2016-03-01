defmodule Hangman.Mixfile do
  use Mix.Project

  def project do
    [app: :play_hangman,
     version: "0.1.1",
     elixir: "~> 1.2.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     escript: [main_module: Hangman.CLI],
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    dict_type = Hangman.Dictionary.Attribute.Tokens.type_normal
    # dict_type = Hangman.Dictionary.Attribute.Tokens.type_big
    args = [{dict_type, true}]

    [
      applications: [:logger, :gproc],
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
  defp deps do
    [
      {:gproc, "0.3.1"},
      {:exprof, "~> 0.2.0"} # to facilitate profiling
    ] 
  end
end
