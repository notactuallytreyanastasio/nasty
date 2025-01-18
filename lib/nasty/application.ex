defmodule Nasty.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      [
        NastyWeb.Telemetry,
        Nasty.Repo,
        {DNSCluster, query: Application.get_env(:nasty, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Nasty.PubSub},
        # Start the Finch HTTP client for sending emails
        {Finch, name: Nasty.Finch},
        # Start to serve requests, typically the last entry
        NastyWeb.Endpoint,
        Nasty.Bookmarks.Cache
      ] ++ simulation_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nasty.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp simulation_children do
    if Application.get_env(:nasty, :simulate_traffic) do
      [Nasty.Traffic.Simulator]
    else
      []
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NastyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
