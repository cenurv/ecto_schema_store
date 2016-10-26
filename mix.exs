defmodule EctoStore.Mixfile do
  use Mix.Project

  @version "1.0.0"

  def project do
    [app: :ecto_schema_store,
     version: @version,
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     description: "Builds upon Ecto to create a ready to go customizable CRUD module for a schema.",
     name: "Ecto Schema Store",
     package: %{
       licenses: ["Apache 2.0"],
       maintainers: ["Joseph Lindley"],
       links: %{"GitHub" => "https://github.com/cenurv/ecto_schema_store"},
       files: ~w(mix.exs README.md lib)
     },
     docs: [source_ref: "v#{@version}", main: "EctoSchemaStore",
           canonical: "http://hexdocs.pm/ecto_schema_store",
           source_url: "https://github.com/cenurv/ecto_schema_store"]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger]]
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
    [{:ecto, "~> 2.0"},
     {:ex_doc, "~> 0.14.3", only: :dev}]
  end
end
