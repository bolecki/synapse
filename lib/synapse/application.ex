defmodule Synapse.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Initialize F1Api cache
    Synapse.F1Api.init_cache()

    children = [
      # Start the Telemetry supervisor
      SynapseWeb.Telemetry,
      # Start the Ecto repository
      Synapse.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Synapse.PubSub},
      # Start Finch
      {Finch, name: Synapse.Finch},
      # Start the Endpoint (http/https)
      SynapseWeb.Endpoint
      # Start a worker by calling: Synapse.Worker.start_link(arg)
      # {Synapse.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Synapse.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SynapseWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
