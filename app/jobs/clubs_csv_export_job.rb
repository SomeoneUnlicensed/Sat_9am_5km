# frozen_string_literal: true

class ClubsCsvExportJob < ApplicationJob
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
      csv << %w[id name country athletes_count results_count volunteering_count]
      clubs_with_stats.each do |club|
        csv << [
          club.id,
          club.name,
          club.country_code,
          club.athletes_count,
          club.results_count,
          club.volunteering_count
        ]
      end
    end
    tempfile.rewind
    tempfile
  end

  def clubs_with_stats
    Club
      .joins(:country)
      .left_joins(athletes: [:results, :volunteering])
      .select(
        'clubs.id, clubs.name, countries.code AS country_code',
        'COUNT(DISTINCT athletes.id) AS athletes_count',
        'COUNT(DISTINCT results.id) AS results_count',
        'COUNT(DISTINCT volunteers.id) AS volunteering_count'
      )
      .group('clubs.id, countries.code')
      .order('clubs.name')
  end

  def multipart_form_data(file)
    [
      ['document', file, { filename: "clubs_#{Time.zone.now.to_i}.csv", content_type: 'text/csv' }],
      ['caption', I18n.t('admin.utilities.reports.clubs_export_caption')],
      ['chat_id', @user.telegram_id.to_s]
    ]
  end
end
