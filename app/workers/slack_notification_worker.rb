class SlackNotificationWorker
  include Sidekiq::Worker
  sidekiq_options queue: :often

  def perform(channel, username, text, footer)
    notifier = Slack::Notifier.new(
      ENV['WEBHOOK_URL'],
      channel: channel,
      username: username,
      )
    a_ok_note = {
      title: footer,
    }
    notifier.post text: text,
                  icon_url: 'https://kawanji.s3.amazonaws.com/uploads/user/icon/1/diqt_icon.png',
                  attachments: [a_ok_note]
  end
end
