defmodule AuthBantcultureCom.AccessList do
  @moduledoc false

  import Ecto.Query

  alias AuthBantcultureCom.CIDR
  alias AuthBantcultureCom.IpAccessEntry
  alias AuthBantcultureCom.Repo

  def allowed?(ip) when is_tuple(ip) do
    Enum.any?(stored_entries(), &CIDR.match?(ip, &1))
  end

  def allowed?(_ip), do: false

  def stored_entries do
    Repo.all(from(entry in IpAccessEntry, select: entry.ip))
  end
end
