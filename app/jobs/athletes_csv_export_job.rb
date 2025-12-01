# frozen_string_literal: true

class AthletesCsvExportJob < ApplicationJob
  queue_as :low

  def perform(user_id)
    @user = User.find(user_id)
    return unless @user.telegram_id

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
      csv << %w[id name club event male parkrun_code fiveverst_code runpark_code results_count volunteering_count]
      athletes_with_stats.find_each do |athlete|
        csv << [
          athlete.id,
          athlete.name,
          athlete.club_name,
          athlete.event_name,
          athlete.male,
          athlete.parkrun_code,
          athlete.fiveverst_code,
          athlete.runpark_code,
          athlete.results_count,
          athlete.volunteering_count
        ]
      end
    end
    tempfile.rewind
    tempfile
  end

  def athletes_with_stats
    Athlete
      .left_joins(:club, :event)
      .select(
        'athletes.*',
        'clubs.name AS club_name',
        'events.name AS event_name',
        '(SELECT COUNT(*) FROM results WHERE results.athlete_id = athletes.id) AS results_count',
        '(SELECT COUNT(*) FROM volunteers WHERE volunteers.athlete_id = athletes.id) AS volunteering_count'
      )
  end

  def multipart_form_data(file)
    [
      ['document', file, { filename: "athletes_#{Time.zone.now.to_i}.csv", content_type: 'text/csv' }],
      ['caption', I18n.t('admin.utilities.reports.athletes_export_caption')],
      ['chat_id', @user.telegram_id.to_s]
    ]
  end
end
