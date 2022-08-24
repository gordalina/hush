ExUnit.start()

Mox.defmock(Hush.Provider.MockProvider, for: Hush.Provider)
Mox.defmock(Hush.Transformer.MockTransformer, for: Hush.Transformer)

defmodule HustTest.MockAgent do
  use Agent

  def start_link(state) do
    Agent.start_link(fn -> state end, name: __MODULE__)
  end
end
