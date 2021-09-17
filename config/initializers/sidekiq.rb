# https://uesaiso.netlify.com/entry/2019/04/06/_20190406sidekiq-on-heroku-redis/#sidekiq%E3%81%AE%E5%B0%8E%E5%85%A5
Sidekiq.configure_server do |config|
  # ローカルならこちら
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') }
  # Dockerを使う場合、redisはlocalhostではなく、redisで設定する。参考：https://qiita.com/okamos/items/8e9b258e3d610bdc2ed9 / https://teratail.com/questions/213473
  #config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379') }
end

Sidekiq.configure_client do |config|
  # ローカルならこちら
  config.redis = { url: ENV.fetch('REDIS_URL', 'redis://localhost:6379') }
  # Dockerを使う場合、redisはlocalhostではなく、redisで設定する。
  # config.redis = { url: ENV.fetch('REDIS_URL', 'redis://redis:6379')}
end


# routeでのユーザー認証 / https://qiita.com/leavescomic1/items/23f677ba90d2dae1e1b1
Sidekiq::Web.use(Rack::Auth::Basic) do |user, password|
  [user, password] == [ENV['BASIC_AUTH_USER'], ENV['BASIC_AUTH_PASSWORD']]
end
