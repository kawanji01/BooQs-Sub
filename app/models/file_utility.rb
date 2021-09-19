class FileUtility < ApplicationRecord
  require 'google/cloud/storage'

  ####### S3の処理 ########
  # ファイルと拡張子含めたファイルネームを渡すことで、S3にファイルをアップロードして、ファイルのpathを取得する。
  def self.upload_file_and_get_s3_path(file, file_name_with_ext)
    file_path = "./tmp/#{file_name_with_ext}"
    p file_path
    p file
    File.write(file_path, file)
    # sidekiqで非同期で処理するために、CSVをS3にアップロードする
    uploader = TmpUploader.new
    uploader.store!(File.open(file_path, 'r'))
    uploaded_file_path = uploader.store_path(file_name_with_ext)
    if Rails.env.production?
      'https://kawanji.s3.ap-northeast-1.amazonaws.com/' + uploaded_file_path
    else
      "./public/#{uploaded_file_path}"
    end
  end

  # bucketを取得する / https://qiita.com/akiko-pusu/items/1508589146b3e5a35787
  def self.get_s3_bucket
    s3_resources = Aws::S3::Resource.new(
      access_key_id: ENV['S3_ACCESS_KEY'],
      secret_access_key: ENV['S3_SECRET_KEY'],
      region: ENV['S3_REGION']
    )
    s3_resources.bucket(ENV['S3_BUCKET'])
  end

  # S3のファリウを消す。
  def self.delete_file_from_s3(file_key, bucket)
    # file_keyは "uploads/import_file/fe98892f.csv"といった形式で記述する。
    # file_keyは、carrierwaveの"uploader.store_path(file_full_name)"で取得することもできる。
    # 削除 / https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3/Bucket.html#delete_objects-instance_method
    bucket.delete_objects({
                            delete: {
                              objects: [
                                {
                                  key: file_key,
                                }
                              ]
                            }
                          })
  end

  # 非同期処理のためにS3に一時的にアップロードしたファイル（主にCSV）を削除する。
  def self.delete_s3_tmp_file(file_name)
    uploader = TmpUploader.new
    file_key = uploader.store_path(file_name)
    bucket = FileUtility.get_s3_bucket
    FileUtility.delete_file_from_s3(file_key, bucket)
  end


  ######## Google Cloud Storage 関連の処理 #########
  # https://qiita.com/someone7140/items/6b0a587b779143b7c875
  # GCSのbucketを取得する
  def self.get_gcs_bucket(project_id, bucket_name)
    storage = Google::Cloud::Storage.new(
      project_id: project_id,
      credentials: JSON.parse(ENV['GOOGLE_CREDENTIALS'])
    )
    storage.bucket bucket_name
  end

  # gcsのbucketに書き込む
  def self.upload_file_to_gcs(file, file_name, bucket)
    file_path = "./tmp/#{file_name}"
    File.write(file_path, file)
    bucket.create_file(file_path, file_name)
  end

  # GCSのfileのurlを取得する
  def self.get_file_url(file_name, bucket)
    file = bucket.file(file_name)
    file&.signed_url(method: 'GET', expires: 60 * 60 * 24)
  end

  # GCSのfileを削除する。
  def self.delete_file_from_gcs(file_name, bucket)
    file = bucket.file(file_name)
    file&.delete
  end

end