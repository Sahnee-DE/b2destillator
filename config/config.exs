use Mix.Config

#Keys for the Authorization process
config :b2_destillator, B2Destillator.B2AuthorizeAccount,
  app_key_id: "<YourKeyIDHere>",
  app_key: "<YourKeyHere>"

#Config for the Server
config :b2destillator, B2Destillator.Server.Server,
  startup_b2_authorize_account: true,
  startup_b2_list_buckets: false,
  startup_b2_get_upload_url: false,
  startup_b2_list_keys: false,
  startup_b2_get_download_authorization: false
