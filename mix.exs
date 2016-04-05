defmodule TesslaServer.Mixfile do
  use Mix.Project

  def project do
    [app: :tessla_server,
     version: "0.0.1",
     elixir: "~> 1.2",
     escript: escript_config,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      applications: [
        :logger,
        :timex,
        :gproc
      ]
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
      {:timex, "~> 2.0"},
      {:tzdata, "~> 0.1.8", override: true},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
      {:gproc, "~> 0.5"}
    ]
  end

  defp escript_config do
    [main_module: TesslaServer]
  end
end
