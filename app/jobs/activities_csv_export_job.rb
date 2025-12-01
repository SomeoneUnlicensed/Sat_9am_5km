# frozen_string_literal: true

class ActivitiesCsvExportJob < ApplicationJob
  queue_as :low

  def perform(user_id, date_from = nil, date_to = nil)
    @user = User.find(user_id)
    return unless @user.telegram_id

    @date_from = date_from&.to_date || 1.year.ago.to_date
    @date_to = date_to&.to_date || Date.current

    tempfile = generate_csv

    Telegram::Bot.call('sendDocument', form_data: multipart_form_data(tempfile))
  rescue StandardError => e
    Rollbar.error e, user_id: @user.id
  ensure
    tempfile&.close
    tempfile&.unlink
  end

  private

  def generate_csv
    tempfile = Tempfile.new
    CSV.open(tempfile.path, 'w') do |csv|
      csv << %w[date event published results_count volunteers_count first_place_time]
      activities_scope.each do |activity|
        csv << [
          activity.date,
          activity.event.name,
          activity.published,
          activity.results_count,
          activity.volunteers_count,
          activity.first_place_time&.strftime('%H:%M:%S')
        ]
      end
    end
    tempfile.rewind
    tempfile
  end

  def activities_scope
    Activity
      .joins(:event)
      .includes(:event)
      .where(date: @date_from..@date_to)
      .select(
        'activities.*',
        '(SELECT COUNT(*) FROM results WHERE results.activity_id = activities.id) AS results_count',
        '(SELECT COUNT(*) FROM volunteers WHERE volunteers.activity_id = activities.id) AS volunteers_count',
        '(SELECT total_time FROM results WHERE results.activity_id = activities.id AND results.position = 1 LIMIT 1) AS first_place_time'
      )
      .order(date: :desc)
  end

  def multipart_form_data(file)
    [
      ['document', file, { filename: "activities_#{@date_from}_#{@date_to}.csv", content_type: 'text/csv' }],
      ['caption', "Экспорт забегов за период #{@date_from} - #{@date_to}"],
      ['chat_id', @user.telegram_id.to_s]
    ]
  end
end
