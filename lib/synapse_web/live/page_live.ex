defmodule SynapseWeb.PageLive do
  use Phoenix.LiveView, layout: {SynapseWeb.Layouts, :app}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, message: "Welcome to Synapse!")}
  end

  def render(assigns) do
    ~H"""
    <div class="container mx-auto p-4">
      <h1 class="text-3xl font-bold mb-6">Synapse Home</h1>
      <p><%= @message %></p>
    </div>
    """
  end
end
