# frozen_string_literal: true

class VolunteersCsvExportJob < ApplicationJob
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
      csv << %w[date event athlete_name role comment]
      volunteers_scope.find_each do |volunteer|
        csv << [
          volunteer.activity.date,
          volunteer.activity.event.name,
          volunteer.athlete.name,
          Volunteer.human_attribute_name("roles.#{volunteer.role}"),
          volunteer.comment
        ]
      end
    end
    tempfile.rewind
    tempfile
  end

  def volunteers_scope
    Volunteer
      .published
      .joins(activity: :event)
      .includes(:athlete, activity: :event)
      .where(activities: { date: @date_from..@date_to })
      .order('activities.date DESC')
  end

  def multipart_form_data(file)
    [
      ['document', file, { filename: "volunteers_#{@date_from}_#{@date_to}.csv", content_type: 'text/csv' }],
      ['caption', "Экспорт волонтёрств за период #{@date_from} - #{@date_to}"],
      ['chat_id', @user.telegram_id.to_s]
    ]
  end
end
