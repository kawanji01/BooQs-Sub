# sitemapを作成する。
# ref: https://github.com/kjvarga/sitemap_generator

# Set the host name for URL creation
# Your website's host name
SitemapGenerator::Sitemap.default_host = "https://www.diqtsub.com"
# The remote host where your sitemaps will be hosted
SitemapGenerator::Sitemap.sitemaps_host = "https://s3-ap-northeast-1.amazonaws.com/#{ENV['S3_BUCKET']}"
# The directory to write sitemaps to locally
SitemapGenerator::Sitemap.public_path = 'tmp/'
# Set this to a directory/path if you don't want to upload to the root of your `sitemaps_host`
SitemapGenerator::Sitemap.sitemaps_path = 'diqtsub_sitemaps/'
SitemapGenerator::Sitemap.adapter = SitemapGenerator::AwsSdkAdapter.new(
  ENV['S3_BUCKET'],
  aws_access_key_id: ENV['S3_ACCESS_KEY'],
  aws_secret_access_key: ENV['S3_SECRET_KEY'],
  aws_region: ENV['S3_REGION'],
  )

SitemapGenerator::Sitemap.create do

  #add for_customer_articles_path, priority: 0.7, changefreq: 'daily'

  add root_path(locale: 'ja')
  add caption_downloader_path(locale: 'ja')
  add transcriber_path(locale: 'ja')

  # 記事
  Article.all.find_each do |article|
    add article_path(article.public_uid, locale: 'ja'), :lastmod => article.updated_at
  end

end