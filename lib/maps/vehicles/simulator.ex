defmodule Maps.Vehicles.Simulator do
  use GenServer
  require Logger

  def start_link(opts) do
    user_id = Keyword.fetch!(opts, :user_id)
    topic = Keyword.fetch!(opts, :topic)

    GenServer.start_link(__MODULE__, {user_id, topic}, via: via_tuple(user_id))
  end

  defp via_tuple(user_id) do
    {:via, Registry, {Maps.Vehicles.Registry, user_id}}
  end

  @impl true
  def init({user_id, topic}) do
    vehicles = spawn_vehicles(5, Maps.Geo.manila_center())

    broadcast_init(topic, vehicles)

    {:ok, %{user_id: user_id, topic: topic, vehicles: vehicles, running: false, timer_ref: nil}}
  end

  def start_simulation(user_id) do
    GenServer.cast(via_tuple(user_id), :start_simulation)
  end

  def stop_simulation(user_id) do
    GenServer.cast(via_tuple(user_id), :stop_simulation)
  end

  @impl true
  def handle_cast(:start_simulation, state) do
    timer_ref = Process.send_after(self(), :tick, 500)
    {:noreply, %{state | running: true, timer_ref: timer_ref}}
  end

  def handle_cast(:stop_simulation, state) do
    if state.timer_ref, do: Process.cancel_timer(state.timer_ref)
    {:noreply, %{state | running: false, timer_ref: nil}}
  end

  @impl true
  def handle_info(:tick, %{running: true} = state) do
    updated_vehicles = tick_vehicles(state.vehicles)
    broadcast_tick(state.topic, updated_vehicles)

    timer_ref = Process.send_after(self(), :tick, 500)
    {:noreply, %{state | vehicles: updated_vehicles, timer_ref: timer_ref}}
  end

  def handle_info(:tick, state) do
    {:noreply, state}
  end

  defp spawn_vehicles(count, center) do
    Enum.map(1..count, fn i ->
      {lat, lng} = Maps.Geo.random_point_near(center, 2000)

      %{
        id: i,
        lat: lat,
        lng: lng,
        heading: :rand.uniform() * 360,
        speed_mps: 8.0
      }
    end)
  end

  defp tick_vehicles(vehicles) do
    Enum.map(vehicles, fn vehicle ->
      heading = jitter_heading(vehicle.heading)
      distance = vehicle.speed_mps * 0.5
      {lat, lng} = Maps.Geo.move(vehicle.lat, vehicle.lng, heading, distance)

      %{vehicle | lat: lat, lng: lng, heading: heading}
    end)
  end

  defp jitter_heading(heading) do
    jitter = :rand.uniform() * 30 - 15
    rem(heading + jitter + 360, 360)
  end

  defp broadcast_init(topic, vehicles) do
    MapsWeb.Endpoint.broadcast(topic, "vehicles:init", %{vehicles: vehicles})
  end

  defp broadcast_tick(topic, vehicles) do
    MapsWeb.Endpoint.broadcast(topic, "vehicles:tick", %{
      vehicles: vehicles,
      tick_at: :erlang.system_time(:millisecond)
    })
  end
end
