defmodule MapsWeb.VehicleChannel do
  use MapsWeb, :channel

  @impl true
  def join("vehicles:" <> user_id, _payload, socket) do
    if user_id == socket.assigns.user_id do
      topic = "vehicles:#{user_id}"

      stop_stale_simulator(user_id)

      {:ok, _pid} =
        DynamicSupervisor.start_child(Maps.Vehicles.Supervisor, {
          Maps.Vehicles.Simulator,
          user_id: user_id, topic: topic
        })

      {:ok, assign(socket, :topic, topic)}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_in("start-simulation", _payload, socket) do
    Maps.Vehicles.Simulator.start_simulation(socket.assigns.user_id)
    {:reply, :ok, socket}
  end

  def handle_in("stop-simulation", _payload, socket) do
    Maps.Vehicles.Simulator.stop_simulation(socket.assigns.user_id)
    {:reply, :ok, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    stop_stale_simulator(socket.assigns.user_id)
    :ok
  end

  defp stop_stale_simulator(user_id) do
    case Registry.lookup(Maps.Vehicles.Registry, user_id) do
      [{pid, _}] -> DynamicSupervisor.terminate_child(Maps.Vehicles.Supervisor, pid)
      [] -> :ok
    end
  end
end
