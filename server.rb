require 'uri'
require 'json'

if ENV['ONLINE'] == 'true'
  require 'scrape'
  TIMETABLE = Scrape.new
else
  require 'dummy_timetable'
  TIMETABLE = DummyTimetable.new
end

class Server
  def initialize(timetable: TIMETABLE)
    @timetable = timetable
  end

  def call(env)
    params = Hash[URI.decode_www_form(env['QUERY_STRING'])]
    time = Time.now
    response = @timetable.(
      origin: params['origin'],
      destination: params['destination'],
      time: time,
    )
    times = response[:times]
      .select { |t| t[:start] >= time }
      .sort_by { |t| t[:start] }
    [
      200,
      { 'Content-Type' => 'text/plain' },
      [
        "#{response[:from]} -> #{response[:to]}\n",
        time.strftime("around %H:%M on %a %e %b\n")
      ] + times.map do |time|
        "#{time[:start].strftime('%H:%M')} -> #{time[:stop].strftime('%H:%M')}\n"
      end,
    ]
  end
end
