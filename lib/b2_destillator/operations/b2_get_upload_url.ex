defmodule B2Destillator.Operations.B2GetUploadUrl do
  require Logger

  ####################################
  ## PUBLIC API
  ####################################
  @typedoc """
  The upload_error contains one of the following errors:
  - :bad_request_url
  - :unauthorized_url
  - :bad_auth_token
  - :expired_auth_token
  - :service_unavailable
  """
  @type upload_error :: :bad_request_url | :unauthorized_url | :bad_auth_token | :expired_auth_token | :service_unavailable
  @doc """
  Requests the upload URL from Backblaze

  ## Parameters

  - bucket_id: The bucketID the files should be uploaded to __-> Get this one from b2_list_buckets__
  - api_url: The API_URL __-> Get this one from b2_authorize_account__
  - auth_token: Your auth_token __-> Get this one from b2_authorize_account__
  """
  @spec get_upload_url(bucket_id :: String.t, api_url :: String.t, auth_token :: String.t) :: {:error, :upload_error}| {:ok, %{authorization_token: any, bucket_id: any, upload_url: any}}
  def get_upload_url(bucket_id, api_url, auth_token) do
    get_upload_url_p(bucket_id, api_url, auth_token)
  end

  ####################################
  ## PRIVATE API
  ####################################

  #Initializes and makes the http post
  defp get_upload_url_p(bucket_id, api_url, auth_token) do
    body = %{"bucketId" => bucket_id}
    #HttPoison Post
    case HTTPoison.post("#{api_url}/b2api/v2/b2_get_upload_url", Poison.encode!(body), %{"Authorization" => auth_token, "content-type" => "application/json"}) do
      {:ok, res} ->
        Logger.info("Generated Backblaze upload URL")
        clean_response(res.body)
      {:error, _error} ->
        {:error, :upload_url_retrieval_error}
    end
  end

  #"Cleans" the response body to further analyze it and create a proper return
  defp clean_response(body) do
    json = Poison.decode!(body)
    code_cond = Map.get(json, "code")
    case code_cond do
      "bad_request" -> {:error, :bad_request_url}
      "unauthorized" -> {:error, :unauthorized_url}
      "bad_auth_token" -> {:error, :bad_auth_token}
      "expired_auth_token" -> {:error, :expired_auth_token}
      "service_unavailable" -> {:error, :service_unavailable}
      _ ->
        bucket_id = Map.get(json, "bucketId")
        upload_url = Map.get(json, "uploadUrl")
        authorization_token = Map.get(json, "authorizationToken")
        {:ok, %{bucket_id: bucket_id, upload_url: upload_url, authorization_token: authorization_token}}
    end
  end
end
