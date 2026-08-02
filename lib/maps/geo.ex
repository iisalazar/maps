defmodule Maps.Geo do
  @manila_center {14.5995, 120.9842}

  def manila_center, do: @manila_center

  def random_point_near({lat, lng}, radius_m) do
    angle = :rand.uniform() * 2 * :math.pi()
    r = :math.sqrt(:rand.uniform()) * radius_m

    dlat = r / 111_320
    dlng = r / (111_320 * :math.cos(lat * :math.pi() / 180))

    {lat + dlat * :math.cos(angle), lng + dlng * :math.sin(angle)}
  end

  def move(lat, lng, heading_deg, distance_m) do
    heading_rad = heading_deg * :math.pi() / 180
    dlat = distance_m / 111_320
    dlng = distance_m / (111_320 * :math.cos(lat * :math.pi() / 180))

    {lat + dlat * :math.cos(heading_rad), lng + dlng * :math.sin(heading_rad)}
  end
end
