defmodule AuthBantcultureCom.AuthThrottleTest do
  use ExUnit.Case, async: false

  alias AuthBantcultureCom.AuthThrottle

  test "allows ten failures and throttles the eleventh within the window" do
    key = "203.0.113.99"
    now = System.system_time(:second)

    AuthThrottle.clear(key)

    for _ <- 1..10 do
      assert :ok == AuthThrottle.allowed?(key, now)
      assert :ok == AuthThrottle.record_failure(key, now)
    end

    assert {:error, :throttled} == AuthThrottle.allowed?(key, now)
    assert :ok == AuthThrottle.allowed?(key, now + 601)
  after
    AuthThrottle.clear("203.0.113.99")
  end

  test "clear removes throttle state" do
    key = "198.51.100.7"
    now = System.system_time(:second)

    assert :ok == AuthThrottle.record_failure(key, now)
    assert true == AuthThrottle.clear(key)
    assert :ok == AuthThrottle.allowed?(key, now)
  end
end
