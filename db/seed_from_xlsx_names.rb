# frozen_string_literal: true

puts "Starting seeding from XLSX-extracted names (with manual transliteration)..."

# 1. Countries
ru = Country.find_or_create_by!(code: 'ru')
by = Country.find_or_create_by!(code: 'by')
rs = Country.find_or_create_by!(code: 'rs')

# 2. Events Data with Manual Latin code_names
locations = {
  'ru' => {
    'Ангарские' => 'angarskie',
    'Гольяново' => 'golyanovo',
    'Кузьминки' => 'kuzminki',
    'Кусково' => 'kuskovo',
    'Олимпийка' => 'olimpika',
    'Царицыно' => 'tsaritsino',
    'Измайлово' => 'izmailovo',
    'Троицк' => 'troitsk',
    'Печатники' => 'pechatniki',
    'Екатерининский' => 'ekaterininsky',
    'ЗИЛ' => 'zil',
    'Вешняки' => 'veshnyaki',
    'Некрасовка' => 'nekrasovka',
    'Люблино' => 'lyublino',
    'Альметьевск' => 'almetievsk',
    'Щёлково' => 'shchelkovo',
    'Ленск' => 'lensk',
    'Орехово-Зуево' => 'orekhovo_zuevo',
    'Тверь' => 'tver',
    'Иваново' => 'ivanovo',
    'Хабаровск' => 'khabarovsk',
    'В.Новгород' => 'v_novgorod',
    'Саранск' => 'saransk',
    'Пенза' => 'penza',
    'Валдай' => 'valday',
    'Подольск' => 'podolsk'
  },
  'by' => {
    'Гомель' => 'gomel',
    'Гродно' => 'grodno',
    'Брест' => 'brest'
  },
  'rs' => {
    'Белград' => 'belgrade_park',
    'НовиСад' => 'novisad_park'
  }
}

all_events = []
locations.each do |country_code, names_map|
  country = Country.find_by(code: country_code)
  names_map.each do |name, code_name|
    all_events << Event.find_or_create_by!(code_name: code_name) do |e|
      e.name = name
      e.town = case country_code
               when 'ru' then 'Москва'
               when 'by' then 'Минск'
               else 'Белград'
               end
      e.place = name
      e.place_description = "Место сбора в парке"
      e.description = "Еженедельный забег S95"
      e.country = country
      e.timezone = country_code == 'rs' ? 'Europe/Belgrade' : 'Europe/Moscow'
      e.active = true
    end
  end
end

puts "Events synchronized: #{Event.count}"

# 3. Create a pool of athletes if needed
if Athlete.count < 300
  (300 - Athlete.count).times do |i|
    Athlete.create!(
      name: "Атлет #{Athlete.count + i}",
      gender: ['male', 'female'].sample,
      event: all_events.sample,
      parkrun_code: 500000 + Athlete.count + i
    )
  end
end
pool_athletes = Athlete.all.to_a
puts "Athlete pool size: #{pool_athletes.size}"

# 4. Generate activities and results for the last 20 Saturdays
saturdays = []
last_sat = Date.current.beginning_of_week(:sunday) - 1.day
20.times { |i| saturdays << last_sat - i.weeks }

all_events.each do |event|
  base_attendance = rand(15..120)
  # Pre-pick a date for the all-time record
  record_date = saturdays.sample
  
  saturdays.each do |date|
    activity = Activity.find_or_create_by!(event: event, date: date) do |a|
      a.published = true
    end
    
    existing_count = activity.results.count
    target_count = (date == record_date) ? base_attendance + rand(40..70) : [5, base_attendance + rand(-20..20)].max
    
    if existing_count < target_count
      existing_athlete_ids = activity.results.pluck(:athlete_id)
      available_athletes = pool_athletes.reject { |a| existing_athlete_ids.include?(a.id) }.shuffle
      
      (target_count - existing_count).times do |i|
        break if available_athletes.empty?
        athlete = available_athletes.pop
        
        Result.create!(
          activity: activity,
          athlete: athlete,
          position: existing_count + i + 1,
          total_time: rand(1100..3200)
        )
      end
    end
  end
  print "✓"
end

puts "\nSeeding completed!"
puts "Total Stats: #{Activity.count} activities generated."
