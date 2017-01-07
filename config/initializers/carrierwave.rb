if Rails.env.development? or Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
    config.enable_processing = false
  end

else
  CarrierWave.configure do |config|
    config.fog_credentials = {
        :provider               => 'AWS',            # required
        :aws_access_key_id      => ENV['S3_KEY_ID'],     # required
        :aws_secret_access_key  => ENV['S3_SECRET_KEY'],  # required
        :region                 => ENV['S3_REGION']
    }
    config.fog_use_ssl_for_aws = false
    config.storage             = :fog
    config.fog_directory       = ENV['S3_BUCKET_NAME']          # required
  end
end