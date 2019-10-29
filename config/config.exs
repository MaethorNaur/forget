import Config
config :libcluster, :topologies, []

config :forget, :configuration,
  cluster: [
    quorum: 1,
    schema: :ram
  ]
