# frozen_string_literal: true

class ResultsCsvExportJob < ApplicationJob
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
      csv << %w[date event position time athlete_name gender club personal_best first_run]
      results_scope.find_each do |result|
        csv << [
          result.activity.date,
          result.activity.event.name,
          result.position,
          result.total_time&.strftime('%H:%M:%S'),
          result.athlete&.name,
          result.athlete&.gender,
          result.athlete&.club&.name,
          result.personal_best,
          result.first_run
        ]
      end
    end
    tempfile.rewind
    tempfile
  end

  def results_scope
    Result
      .published
      .joins(activity: :event)
      .includes(:athlete, activity: :event)
      .where(activities: { date: @date_from..@date_to })
      .order('activities.date DESC, results.position ASC')
  end

  def multipart_form_data(file)
    [
      ['document', file, { filename: "results_#{@date_from}_#{@date_to}.csv", content_type: 'text/csv' }],
      ['caption', I18n.t('admin.utilities.reports.results_export_caption', date_from: @date_from, date_to: @date_to)],
      ['chat_id', @user.telegram_id.to_s]
    ]
  end
end
