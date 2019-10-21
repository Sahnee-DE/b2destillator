defmodule B2Destillator.Server.Server do

  use GenServer
  require Logger


  ####################################
  ## PUBLIC API
  ####################################

  @type server_errors :: :retreival_error

  @doc """
  Authorizes the given Account

  ## Parameters

  - app_key: The app_key specified in your config.exs
  - app_key_id: The app_key_id specified in your config.exs

  ## Returns

  - authorization_error: {:error, authorization_error}
  - Touple with a Map in it: {:ok, %{...}}
  """
  @spec b2_authorize_account(app_key :: String.t, app_key_id :: String.t) :: {:ok, %{absolute_minimum_part_size: String.t, account_id: String.t, api_url: String.t, authorization_token: String.t, download_url: String.t, recommended_part_size: String.t, bucket_id: String.t, bucket_name: String.t, capabilities: [String.t], name_prefix: STring.t}} | {:error, :authorization_error}
  def b2_authorize_account(app_key, app_key_id) do
    return = B2Destillator.Operations.B2AuthorizeAccount.authorize_account(app_key, app_key_id)
    case return do
      {:ok, returns} ->
        insert_in_ets(:b2_authorize_account, returns)
      {:error, error} ->
        {:error, :retreival_error}
    end
  end



  ####################################
  ## PRIVATE API
  ####################################
  # The timeout to wait until the next request
  @spec take_timeout(interval :: pos_integer) :: {:error, any} | {:ok, pid}
  defp take_timeout(interval) do
    Process.send_after(self(), :work, interval * 60 * 60 * 1000)
  end

  #processes all the environment variables and returns what to init
  defp process_variables() do
    env = Application.get_env(:b2destillator, B2Destillator.Server.Server)
    b2_authorize_account = env[:startup_b2_authorize_account]
    b2_list_buckets = env[:startup_b2_list_buckets]
    b2_get_upload_url = env[:startup_b2_get_upload_url]
    b2_list_keys = env[:startup_b2_list_keys]
    b2_get_download_authorization = env[:startup_b2_get_download_authorization]
    return_list = []
    if b2_authorize_account do
      return_list = [:b2_authorize_account | return_list]
    end
    if b2_list_buckets do
      return_list = [:b2_list_buckets | return_list]
    end
    if b2_get_upload_url do
      return_list = [:b2_get_upload | return_list]
    end
    if b2_list_keys do
      return_list = [:b2_list_keys | return_list]
    end
    if b2_get_download_authorization do
      return_list = [:b2_get_download_authorization | return_list]
    end
    if length(return_list) >= 1 do
      {:ok, return_list}
    else
      {:error, :server_no_parameter}
    end
  end

  #creates a process specific ets store
  defp create_ets_store() do
    operations = [:b2_authorize_account, :b2_cancel_large_file, :b2_copy_file, :b2_copy_file, :b2_copy_part, :b2_create_bucket,
      :b2_create_key, :b2_delete_bucket, :b2_delete_file_version:, :b2_delete_key, :b2_download_file_by_id, :b2_download_file_by_name,
      :b2_finish_large_file, :b2_get_downloadauthorization, :b2_get_file_info, :b2_get_upload_part_url, :b2_get_upload_url,
      :b2_hide_file, :b2_list_buckets, :b2_list_file_names, :b2_list_file_versions, :b2_list_keys, :b2_list_parts, :b2_list_unfinished_large_file,
      :b2_start_large_file, :b2_update_bucket, :b2_upload_file, :b2_upload_part]

    for operation <- operations do
      :ets.new(operation, [set, protected])
    end
  end

  #inserts a map into the given ets store.
  #Overrides anything
  @spec insert_in_ets(name :: atom(), keylist :: map())
  defp insert_in_ets(name, keylist) do
    :ets.insert(name, keylist)
  end

  ####################################
  ##  CALLBACKS
  ####################################


  def init([time]) do
    Logger.debug("Started the B2Destillator Server")

    #create all ets store's
    create_ets_store()

    #Get all environment Variables
    case process_variables do
      {:ok, list} ->
        #
      {:error, :error} ->
        #
    end


    take_timeout(time)
    {:ok, args}
  end

  def start_link(time) do
    GenServer.start_link(B2Destillator.Server.Server, time, name: B2Destillator.Server.Server)
  end
end
