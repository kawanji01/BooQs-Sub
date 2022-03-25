
# 公式ドキュメント / https://docs.sentry.io/platforms/ruby/guides/rails/
Sentry.init do |config|
  config.dsn = ENV['SENTRY_DSN']
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  # 本番環境でだけ動かす / https://blog.solunita.net/posts/set-up-sentry-for-rails-by-sentry-rails/
  config.enabled_environments = %w[production]
  config.environment = Rails.env
  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 1.0
  # or
  config.traces_sampler = lambda do |context|
    true
  end
end