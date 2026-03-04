module Telegram
  module Notification
    class KudoJob < ApplicationJob
      queue_as :default

      def perform(telegram_id, giver_name, result_time, event_name)
        message = "✋ #{giver_name} дал вам пятюню за ваш результат #{result_time} на забеге #{event_name}!"
        Telegram.bot.send_message(
          chat_id: telegram_id,
          text: message,
          parse_mode: :HTML
        )
      rescue Telegram::Bot::Error => e
        Rails.logger.error "Failed to send kudo notification: #{e.message}"
      end
    end
  end
end
