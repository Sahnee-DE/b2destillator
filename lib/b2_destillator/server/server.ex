defmodule B2Destillator.Server.Server do

  use GenServer
  require Logger


  ####################################
  ## PUBLIC API
  ####################################


  ####################################
  ## PRIVATE API
  ####################################

   # The timeout to wait until the next request
   @spec take_timeout(interval :: pos_integer) :: {:error, any} | {:ok, pid}
   defp take_timeout(interval) do
     Process.send_after(self(), :work, interval * 60 * 60 * 1000)
   end

  ####################################
  ##  CALLBACKS
  ####################################

  def init([time, auth_account]) do
    Logger.debug("Started the B2Destillator Server")
    #renew the wanted things
      #start the timer to frequently renew
    {:ok, time}
  end

  def start_link(time) do
    GenServer.start_link(B2Destillator.Server.Server, time, name: B2Destillator.Server.Server)
  end
end
