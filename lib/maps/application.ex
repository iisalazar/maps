defmodule Maps.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MapsWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:maps, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Maps.PubSub},
      {Registry, keys: :unique, name: Maps.Vehicles.Registry},
      {DynamicSupervisor, name: Maps.Vehicles.Supervisor, strategy: :one_for_one},
      MapsWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Maps.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MapsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
