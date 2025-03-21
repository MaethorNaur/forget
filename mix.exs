defmodule Forget.MixProject do
  use Mix.Project

  def project,
    do: [
      app: :forget,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: ["lib"],
      test_pattern: "*.test.exs",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mnesia],
        # plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        flags: [
          "-Wunmatched_returns",
          "-Werror_handling",
          "-Wrace_conditions",
          "-Wno_opaque",
          "-Wunderspecs"
        ],
        plt_add_deps: :transitive
      ],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: [
        description: "Bring Mnesia clustering to the cloud age",
        files: ["lib", ".formatter.exs", "mix.exs", "README.md", "LICENSE", "CHANGELOG.md"],
        maintainers: ["MaethorNaur"],
        licenses: ["MIT"],
        links: %{GitHub: "https://github.com/MaethorNaur/forget"}
      ],
      docs: [
        main: "readme",
        extras: ["README.md", "CHANGELOG.md"],
        formatters: ["html", "epub"]
      ],
      aliases: [
        check: [
          "format --check-formatted --dry-run",
          "compile --warning-as-errors --force",
          "credo --strict --all",
          "inch",
          "dialyzer"
        ]
      ],
      name: "Forget",
      source_url: "https://github.com/MaethorNaur/forget"
    ]

  def application,
    do: [
      extra_applications: [:logger],
      mod: {Forget.Application, []}
    ]

  defp deps,
    do: [
      {:ok, "~> 2.3"},
      {:libcluster, "~> 3.1"},
      {:credo, "~> 1.1", only: [:dev], runtime: false},
      {:dialyxir, "~> 1.0.0-rc.7", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev], runtime: false},
      {:ex_unit_clustered_case, "~> 0.4", only: [:test]},
      {:excoveralls, "~> 0.11", only: [:dev, :test], runtime: false},
      {:inch_ex, "~> 2.0", only: [:dev], runtime: false}
    ]
end
