AssetSync.configure do |config|

  config.fog_provider = 'Google'
  config.google_storage_access_key_id     = ENV['ASSET_KEY']
  config.google_storage_secret_access_key = ENV['ASSET_SECRET']
  config.fog_directory = ENV['PUBLIC_ASSET_BUCKET_NAME']
  config.fog_path_style = true

  # Invalidate a file on a cdn after uploading files
  # config.cdn_distribution_id = "12345"
  # config.invalidate = ['file1.js']

  # Increase upload performance by configuring your region
  # config.fog_region = 'eu-west-1'
  #
  # Don't delete files from the store
  # config.existing_remote_files = "keep"
  #
  # Automatically replace files with their equivalent gzip compressed version
  config.gzip_compression = true
  #
  # Use the Rails generated 'manifest.yml' file to produce the list of files to
  # upload instead of searching the assets directory.
  config.manifest = true
  #
  # Fail silently.  Useful for environments such as Heroku
  # config.fail_silently = true
end