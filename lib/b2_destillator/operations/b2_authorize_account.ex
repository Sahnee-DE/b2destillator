defmodule B2Destillator.Operations.B2AuthorizeAccount do
  require Logger

  ####################################
  ## PUBLIC API
  ####################################

  @typedoc """
  The "authorization_error" contains one of the following errors:
  - :bad_request
  - :unauthorized
  - :unsupported
  - :bad_auth_token
  """
  @type authorization_error :: :bad_request | :unauthorized | :unsupported | :bad_auth_token | :connection_error
  @doc """
  Authorizes the given Account

  ## Parameters

  - app_key: The app_key specified in your config.exs
  - app_key_id: The app_key_id specified in your config.exs

  ## Returns

  - authorization_error: {:error, authorization_error}
  - Touple with a Map in it: {:ok, %{...}}
  """
  @spec authorize_account(app_key :: String.t, app_key_id :: String.t) :: {:ok, %{absolute_minimum_part_size: String.t, account_id: String.t, api_url: String.t, authorization_token: String.t, download_url: String.t, recommended_part_size: String.t, bucket_id: String.t, bucket_name: String.t, capabilities: [String.t], name_prefix: STring.t}} | {:error, :authorization_error}
  def authorize_account(app_key, app_key_id) do
    authorize_account_p(app_key, app_key_id)
  end

  ####################################
  ## PRIVATE API
  ####################################

  #Initializes and makes the http request
  defp authorize_account_p(app_key, app_key_id) do
    credentials = Base.encode64("#{app_key_id}:#{app_key}", padding: false)
    #HttPoison Request
    case HTTPoison.get("https://api.backblazeb2.com/b2api/v2/b2_authorize_account", %{"Authorization" => "Basic #{credentials}"}) do
      {:ok, res} ->
        Logger.info("Backblaze account was authorized.")
        clean_response(res.body)
      {:error, _error} -> {:error, :connection_error}
    end
  end

  #"Cleans" the response body to further analyze it and create a proper return
  defp clean_response(body) do
    json = Poison.decode!(body)
    code_cond = Map.get(json, "code")
    #Check that the request did not return an error
    case code_cond do
      "bad_request" -> {:error, :bad_request}
      "unauthorized" -> {:error, :unauthorized}
      "unsupported" -> {:error, :unsupported}
      "bad_auth_token" -> {:error, :bad_auth_token}
      _ ->
        allowed = Map.get(json, "allowed")
        absolute_minimum_part_size = Map.get(json, "absoluteMinimumPartSize")
        account_id = Map.get(json, "accountId")
        api_url = Map.get(json, "apiUrl")
        authorization_token = Map.get(json, "authorizationToken")
        download_url = Map.get(json, "downloadUrl")
        recommended_part_size = Map.get(json, "recommendedPartSize")
        bucket_id = Map.get(allowed, "bucketId")
        bucket_name = Map.get(allowed, "bucketName")
        capabilities = Map.get(allowed, "capabilities")
        name_prefix = Map.get(allowed, "namePrefix")
        {:ok, %{absolute_minimum_part_size: absolute_minimum_part_size,
        account_id: account_id,
        api_url: api_url,
        authorization_token: authorization_token,
        download_url: download_url,
        recommended_part_size: recommended_part_size,
        bucket_id: bucket_id,
        bucket_name: bucket_name,
        capabilities: capabilities,
        name_prefix: name_prefix}}
    end
  end
end
