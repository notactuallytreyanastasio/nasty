defmodule Nasty.Traffic.SimulatorBehaviour do
  @callback simulation_interval() :: integer()
  @callback simulate(users :: list()) :: any()
end
