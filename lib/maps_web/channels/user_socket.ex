defmodule MapsWeb.UserSocket do
  use Phoenix.Socket

  channel "vehicles:*", MapsWeb.VehicleChannel

  @impl true
  def connect(%{"user_id" => user_id}, socket, _connect_info)
      when is_binary(user_id) and user_id != "" do
    {:ok, assign(socket, :user_id, user_id)}
  end

  def connect(_params, _socket, _connect_info) do
    :error
  end

  @impl true
  def id(socket) do
    "user_socket:#{socket.assigns.user_id}"
  end
end
