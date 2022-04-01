require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'


def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone.tr!('A-Za-z-._()\+\.\ ', '')
  phone.slice!(0) if phone[0] == '1' && phone.length == 11
  phone = 'Bad number' if phone.length != 10
  phone
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
hours = Hash.new(0)
days = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  phone = clean_phone(row[:homephone])
  time = Time.strptime(row[:regdate], '%m/%d/%y %k:%M')
  days[Date::DAYNAMES[time.wday]] += 1
  hours[time.hour] += 1

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  puts "#{name}, #{phone}"

  save_thank_you_letter(id,form_letter)
end

days = days.max_by(3) {|key, value| +value}
puts days
hours = hours.max_by(3) {|key, value| +value}
pos = 0
puts 'The top 3 hours with most users registered are:'
3.times do
  puts "#{hours.dig(pos, 0)}:00 with #{hours.dig(pos, 1)} users registered"
  pos += 1
end
pos = 0
puts 'The top 3 days with most users registered are:'
3.times do
  puts "#{days.dig(pos, 0)} with #{days.dig(pos, 1)} users registered"
  pos += 1
end
