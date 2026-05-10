# frozen_string_literal: true

ActiveAdmin.register_page 'Statistics' do
  menu priority: 2, label: -> { 'Статистика' }

  content title: 'Общая статистика системы' do
    # 1. Top Stat Tiles
    div class: 'blank_slate_container' do
      ul class: 'statistics_tiles', style: 'list-style: none; display: flex; gap: 20px; padding: 0; margin-bottom: 30px;' do
        li style: 'background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); flex: 1; text-align: center;' do
          div 'Локаций', style: 'color: #666; font-size: 14px; margin-bottom: 10px;'
          div Event.count, style: 'font-size: 28px; font-weight: bold; color: #222;'
        end
        li style: 'background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); flex: 1; text-align: center;' do
          div 'Стран', style: 'color: #666; font-size: 14px; margin-bottom: 10px;'
          div Country.count, style: 'font-size: 28px; font-weight: bold; color: #222;'
        end
        li style: 'background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); flex: 1; text-align: center;' do
          div 'Участников', style: 'color: #666; font-size: 14px; margin-bottom: 10px;'
          div Athlete.count, style: 'font-size: 28px; font-weight: bold; color: #222;'
        end
        li style: 'background: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); flex: 1; text-align: center;' do
          div 'Apple Wallet', style: 'color: #666; font-size: 14px; margin-bottom: 10px;'
          div style: 'font-size: 28px; font-weight: bold; color: #222;' do
            span WalletPassRegistration.count
            span link_to('→', admin_wallet_pass_registrations_path, style: 'font-size: 16px; margin-left: 10px; text-decoration: none; vertical-align: middle;')
          end
        end
      end
    end

    # 2. Attendance Matrix with Pagination
    offset = (params[:offset] || 0).to_i
    limit = 12

    # Fetch unique dates of activities
    all_dates = Activity.where('date <= ?', Date.current)
                       .order(date: :desc)
                       .pluck(:date)
                       .uniq
    
    current_page_dates = all_dates.slice(offset, limit)&.sort || []

    panel 'Матрица посещаемости' do
      div style: 'margin-bottom: 15px; display: flex; justify-content: space-between;' do
        if offset + limit < all_dates.size
          link_to '← Раньше', admin_statistics_path(offset: offset + limit), class: 'button'
        else
          span '← Раньше', class: 'button disabled', style: 'opacity: 0.5; cursor: not_allowed;'
        end

        if offset > 0
          link_to 'Позже →', admin_statistics_path(offset: [0, offset - limit].max), class: 'button'
        else
          span 'Позже →', class: 'button disabled', style: 'opacity: 0.5; cursor: not_allowed;'
        end
      end

      events_by_country = Event.includes(:country).order('countries.code', :name).group_by(&:country)
      
      # Data for current matrix
      activities = Activity.where(date: current_page_dates).includes(:results)
      attendance_data = activities.each_with_object({}) do |activity, memo|
        memo[activity.event_id] ||= {}
        memo[activity.event_id][activity.date] = { count: activity.results.size, id: activity.id }
      end

      # Calculate ALL-TIME records for each event to highlight them properly
      # This query counts results grouped by activity and event
      all_time_records = Result.joins(:activity)
                              .group('activities.event_id', 'activities.id')
                              .count
                              .group_by { |key, _| key[0] } # group by event_id
                              .transform_values { |v| v.map(&:last).max }

      div class: 'table_tools' do
        table class: 'index_table', style: 'width: 100%; border-collapse: collapse;' do
          thead do
            tr do
              th 'Локация', style: 'text-align: left; padding: 10px; border-bottom: 2px solid #eee;'
              current_page_dates.each do |date|
                th date.strftime('%d.%m.%y'), style: 'text-align: center; padding: 10px; border-bottom: 2px solid #eee;'
              end
            end
          end
          tbody do
            events_by_country.each do |country, events|
              tr style: 'background: #f9f9f9;' do
                td colspan: current_page_dates.size + 1, style: 'padding: 12px; font-weight: bold; color: #555; border-bottom: 1px solid #eee;' do
                  "#{country.name} (#{country.code.upcase})"
                end
              end

              events.each do |event|
                tr style: 'border-bottom: 1px solid #eee;' do
                  td event.name, style: 'padding: 8px 12px; font-weight: 500;'
                  
                  current_page_dates.each do |date|
                    data = attendance_data[event.id]&.[](date)
                    if data
                      count = data[:count]
                      is_record = count >= (all_time_records[event.id] || 0) && count > 0
                      
                      td style: "text-align: center; padding: 8px; #{is_record ? 'background: #ffebeb; color: #d00; font-weight: bold;' : ''}" do
                        link_to count, admin_activity_path(data[:id]), style: 'text-decoration: none; color: inherit; display: block;'
                      end
                    else
                      td '-', style: 'text-align: center; color: #ccc;'
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
