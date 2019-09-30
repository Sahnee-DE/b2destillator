defmodule B2Destillator.Operations.B2UploadFile do
  require Logger
  ####################################
  ## PUBLIC API
  ####################################
  @typedoc """
  The "upload_error" contains one of the following errors:
  - :bad_request
  - :unauthorized
  - :cap_exceeded
  - :you_pleb
  - :request_timeout
  - :upload_init_error
  """
  @type upload_error :: :bad_request | :unauthorized | :cap_exceeded | :you_pleb | :request_timeout | :upload_init_error
  @doc """
  Uploads a single file to Backblaze

  ## Params

  - url: The upload url
  - file_content: Binary file content
  - auth_token: The auth_token
  - file_name: Filename AND __extension__ of the file it should be called in the Backblaze B2
  - sha1: The encoded _file_content_ to base16 formatted to uppercase string

  ## Returns
  - upload_error: {:error, upload_error}
  - Touple with a Map in it: {:ok, %{...}}
  """
  @spec upload_file(url :: String.t, file_content :: String.t, auth_token :: String.t, file_name :: String.t, sha1 :: String.t) :: {:ok, %{file_id: String.t, file_name: String.t, account_id: String.t, bucketId: String.t, content_length: String.t, content_sha1: String.t, content_type: String.t, author: String.t}} | {:error, :upload_error}
  def upload_file(url, file_content, auth_token, file_name, sha1) do
    upload_file_p(url, file_content, auth_token, file_name, sha1)
  end

  ####################################
  ## PRIVATE API
  ####################################

  #Makes the Http Post to upload a file
  defp upload_file_p(url, file_content, auth_token, file_name, sha1) do
    ##TODO: Add a way to manually set the content type
    #HTTPoison Post
    case HTTPoison.post(url, file_content, %{"Authorization" => auth_token, "X-Bz-File-Name" => file_name, "X-Bz-Content-Sha1" => sha1 , "content-type" => "b2/x-auto"}) do
      {:ok, res} -> clean_response(res.body)
      {:error, _error} -> {:error, :upload_init_error}
    end

  end

  #"Cleans" the response body to further analyze it and create a proper return
  defp clean_response(body) do
    json = Poison.decode!(body)
    code_cond = Map.get(json, "code")
    case code_cond do
      "bad_request" -> {:error, :bad_request}
      "unauthorized" -> {:error, :unauthorized}
      "bad_auth_token" ->
        Logger.error("[Backblaze-Server]: Error: 401 - bad_auth_token - The auth token is invalid - Trying to get a new one...")
      "expired_auth_token" ->
        Logger.error("[Backblaze-Server]: Error: 401 - expired_auth_token - The auth token has expired - Trying to get a new one...")
      "cap_exceeded" -> {:error, :cap_exceeded}
      "method_not_allowed" -> {:error, :you_pleb}
      "request_timeout" -> {:error, :request_timeout}
      "service_unavailable" ->
        Logger.error("[Backblaze-Server]: Error: 503 - service_unavailable - Trying to get a new upload_url - If this keeps repeating check the backblaze status")
      _ ->
        file_id = Map.get(json, "fileId")
        file_name = Map.get(json, "fileName")
        account_id = Map.get(json, "accountId")
        bucketId = Map.get(json, "bucketId")
        content_length = Map.get(json, "contentLength")
        content_sha1 = Map.get(json, "contentSha1")
        content_type = Map.get(json, "contentType")
        file_info = Map.get(json, "fileInfo")
        author = Map.get(file_info, "author")
        {:ok, %{file_id: file_id,
        file_name: file_name,
        account_id: account_id,
        bucketId: bucketId,
        content_length: content_length,
        content_sha1: content_sha1,
        content_type: content_type,
        author: author}}
    end
  end
end
