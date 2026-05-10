# frozen_string_literal: true

puts "Generating expanded fake data (cleaned version)..."

# 1. Countries
ru = Country.find_or_create_by!(code: 'ru')
by = Country.find_or_create_by!(code: 'by')
rs = Country.find_or_create_by!(code: 'rs')

# 2. Events Mapping
locations_data = {
  'ru' => { 'Парк Горького' => 'gorky_park', 'Сокольники' => 'sokolniki', 'Царицыно' => 'tsaritsino', 'Битца' => 'bitsa', 'ВДНХ' => 'vdnh', 'Измайлово' => 'izmailovo', 'Коломенское' => 'kolomenskoe' },
  'by' => { 'Лошицкий парк' => 'loshitsa', 'Парк Победы Минск' => 'pobeda_minsk', 'Челюскинцев' => 'chelyuskincev' },
  'rs' => { 'Ada Ciganlija' => 'ada_ciganlija', 'Kalemegdan' => 'kalemegdan', 'Usce' => 'usce' }
}

all_events = []
locations_data.each do |country_code, map|
  country = Country.find_by(code: country_code)
  map.each do |name, code_name|
    all_events << Event.find_or_create_by!(code_name: code_name) do |e|
      e.name = name
      e.town = country_code == 'rs' ? 'Belgrade' : (country_code == 'by' ? 'Minsk' : 'Moscow')
      e.place = name
      e.place_description = "Near the main entrance"
      e.description = "Weekly Saturday 5km run"
      e.country = country
      e.timezone = country_code == 'rs' ? 'Europe/Belgrade' : 'Europe/Moscow'
      e.active = true
    end
  end
end

puts "Events synchronized: #{Event.count}"

# 3. Saturdays (last 20)
saturdays = []
last_sat = Date.current.beginning_of_week(:sunday) - 1.day
20.times { |i| saturdays << last_sat - i.weeks }

# 4. Athletes (Ensure pool of ~150)
current_athlete_count = Athlete.count
if current_athlete_count < 150
  (150 - current_athlete_count).times do |i|
    Athlete.create!(
      name: "Athlete Pool #{current_athlete_count + i}",
      gender: ['male', 'female'].sample,
      event: all_events.sample,
      parkrun_code: 300000 + current_athlete_count + i
    )
  end
end
pool_athletes = Athlete.all.to_a
puts "Athlete pool size: #{pool_athletes.size}"

# 5. Massive Results Generation
all_events.each do |event|
  base_attendance = rand(15..80)
  # Pre-pick a date for the all-time record
  record_date = saturdays.sample
  
  saturdays.each do |date|
    activity = Activity.find_or_create_by!(event: event, date: date) do |a|
      a.published = true
    end
    
    # Check if we already have results to avoid duplicates
    existing_count = activity.results.count
    target_count = (date == record_date) ? base_attendance + rand(20..40) : [5, base_attendance + rand(-15..15)].max
    
    if existing_count < target_count
      # Get athletes NOT already in this activity's results
      existing_athlete_ids = activity.results.pluck(:athlete_id)
      available_athletes = pool_athletes.reject { |a| existing_athlete_ids.include?(a.id) }.shuffle
      
      (target_count - existing_count).times do |i|
        break if available_athletes.empty?
        athlete = available_athletes.pop
        
        Result.create!(
          activity: activity,
          athlete: athlete,
          position: existing_count + i + 1,
          total_time: rand(1100..2800)
        )
      end
    end
  end
  print "✓"
end

puts "\nData generation completed!"
puts "Total Stats Page check: #{Activity.count} activities across #{Event.count} locations."
