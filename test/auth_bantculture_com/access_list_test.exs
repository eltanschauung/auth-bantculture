defmodule AuthBantcultureCom.AccessListTest do
  use ExUnit.Case, async: false

  alias AuthBantcultureCom.AccessList
  alias AuthBantcultureCom.IpAccessEntry
  alias AuthBantcultureCom.Repo

  setup do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Repo, shared: true)
    Repo.delete_all(IpAccessEntry)

    on_exit(fn ->
      Ecto.Adapters.SQL.Sandbox.stop_owner(pid)
    end)

    :ok
  end

  test "matches stored cidr entries against ipv4 addresses" do
    Repo.insert!(%IpAccessEntry{ip: "198.51.100.0/24", password: "tewi"})

    assert AccessList.allowed?({198, 51, 100, 9})
    refute AccessList.allowed?({203, 0, 113, 7})
  end
end
