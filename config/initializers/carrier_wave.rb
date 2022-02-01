# tmpUploaderではS3にあげるので設定が必要。
CarrierWave.configure do |config|
  # NOTE: https://qiita.com/siruku6/items/a3a9021913749247d92b
  # config.fog_public = false
  config.fog_provider = 'fog/aws'
  config.fog_credentials = {
      # Amazon S3用の設定
      :provider => 'AWS',
      :region => ENV['S3_REGION'], # 例: 'ap-northeast-1'
      :aws_access_key_id => ENV['S3_ACCESS_KEY'],
      :aws_secret_access_key => ENV['S3_SECRET_KEY']
  }

  config.fog_directory = ENV['S3_BUCKET']
end



