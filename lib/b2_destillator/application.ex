defmodule B2Destillator.Application do
  @moduledoc """
  Documentation for B2Destillator.
  """
  use Application
  require Logger

  def start(_type, _args) do
    Logger.debug("B2Destillator - OTP - application starting...")
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one]
    res = Supervisor.start_link(children(), opts)

    #starting...
    res
  end

  defp children do
    # List all child processes to be supervised
    [

    ]
  end

end
