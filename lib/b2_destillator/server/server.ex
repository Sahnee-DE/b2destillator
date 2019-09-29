defmodule B2Destillator.Server.Server do

  use GenServer
  require Logger


  ####################################
  ## PUBLIC API
  ####################################


  ####################################
  ## PRIVATE API
  ####################################


  ####################################
  ##  CALLBACKS
  ####################################

  def init(args) do
    Logger.debug("Started the B2Destillator Server")
    {:ok, args}
  end

  def start_link(time) do
    GenServer.start_link(B2Destillator.Server.Server, time, name: B2Destillator.Server.Server)
  end
end
