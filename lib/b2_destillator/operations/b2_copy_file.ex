defmodule B2Destillator.Operations.B2CopyFile do
  require Logger

  ####################################
  ## PUBLIC API
  ####################################
  @typedoc """
  The "copy_file_error" contains one of the following errors:
  - :bad_request
  - :unauthorized
  - :bad_auth_token
  - :expired_auth_token
  - :cap_exceeded
  - :not_fount
  - :method_not_allowed
  - :request_timeout
  - :range_not_satisfiable
  - :file_copy_init_error
  """
  @type copy_file_error :: :bad_request | :unauthorized | :bad_auth_token | :expired_auth_token | :cap_exceeded | :not_fount | :method_not_allowed | :request_timeout | :range_not_satisfiable | :file_copy_init_error
  @doc """
  Copies a file from one bucket to another or to the bucket itself

  ## Parameters
  - api_url: The API Url __-> Get this one from b2_authorize_account__
  - source_fiel_id: The file that should be copied
  - destination_bucket_id: The bucket that the file should be copied into. If it's the same, doesn't matter.
  - file_name: The name of your copied file
  - range: The range of bytes to copy
  - metadata_directive:  Strategy for how to populate metadata for the new file. If used, _content_type_ and _file_info_ cannot be used.
  - content_type: Only use if the _metadata_directive_ is _REPLACE_. Sets a new contentType
  - file_info: Only use if the _metadata_directive_ is _REPLACE_. Sets the new fileinfo
  - auth_token: Your auth_token __-> Get this one from b2_authorize_account__

  ## Returns
  - copy_file_error: {:error, :copy_file_error}
  - Touple with a Map in it: {:ok, %{...}}
  """
  @spec copy_file(api_url :: String.t, source_file_id :: String.t, auth_token :: String.t, file_name :: String.t, destination_bucket_id :: String.t | none() | atom(), range :: String.t | none() | atom(), metadata_directive :: String.t | none() | atom(), content_type :: String.t | none() | atom(), file_info :: String.t | none() | atom()) :: {:ok, %{account_id: String.t,action: String.t, bucket_id: String.t, content_type: String.t, content_sha1: String.t, content_length: String.t, field_id: String.t, src_last_modified_milis: String.t, file_name: String.t, upload_time_stamp: String.t}} | {:error, :copy_file_error}
  def copy_file(api_url, source_file_id, auth_token, file_name, destination_bucket_id \\ :nil, range \\ :nil, metadata_directive \\ :nil, content_type \\ :nil, file_info \\ :nil) do
    copy_file_p(api_url, source_file_id, destination_bucket_id, file_name, range, metadata_directive, content_type, file_info, auth_token)
  end

  ####################################
  ## PRIVATE API
  ####################################

  #Makes the http POST
  defp copy_file_p(api_url, source_file_id, destination_bucket_id, file_name, range, metadata_directive, content_type, file_info, auth_token) do
    case HTTPoison.post("#{api_url}/b2api/v2/b2_copy_file",
      %{"sourceFileId" => source_file_id, "destinationBucketId" => destination_bucket_id, "fileName" => file_name, "range" => range, "metadataDirective" => metadata_directive, "contentType" => content_type, "fileInfo" => file_info},
      %{"Authorization" => auth_token}) do
        {:ok, res} ->
          Logger.info("Moved file sucessfully")
          clean_response(res.body)
        {:error, _error} -> {:error, :file_copy_init_error}
    end
  end

  #"Cleans" the response body to further analyze it and create a proper return
  defp clean_response(body) do
    json = Poison.decode!(body)
    code_cond = Map.get(json, "code")
    case code_cond do
      "bad_request" -> {:error, :bad_request}
      "unauthorized" -> {:error, :unauthorized}
      "bad_auth_token" -> {:error, :bad_auth_token}
      "expired_auth_token" -> {:error, :expired_auth_token}
      "cap_exceeded" -> {:error, :cap_exceeded}
      "not_found" -> {:error, :not_found}
      "method_not_allowed" -> {:error, :method_not_allowed}
      "request_timeout" -> {:error, :request_timeout}
      "range_not_satisfiable" -> {:error, :range_not_satisfiable}
      _ ->
        account_id = Map.get(json, "accountId")
        action = Map.get(json, "action")
        bucket_id = Map.get(json, "bucketId")
        content_type = Map.get(json, "contentType")
        content_sha1 = Map.get(json, "contentSha1")
        content_length = Map.get(json, "contentLength")
        field_id = Map.get(json, "fieldId")
        file_info = Map.get(json, "fileInfo")
        src_last_modified_milis = Map.get(file_info, "src_last_modified_millis")
        file_name = Map.get(json, "fileName")
        upload_time_stamp = Map.get(json, "uploadTimestamp")
        {:ok, %{
          account_id: account_id,
          action: action,
          bucket_id: bucket_id,
          content_type: content_type,
          content_sha1: content_sha1,
          content_length: content_length,
          field_id: field_id,
          src_last_modified_milis: src_last_modified_milis,
          file_name: file_name,
          upload_time_stamp: upload_time_stamp
        }}
    end
  end
end
