require 'logger'

require 'tzinfo'
require 'roda'

if ENV['ONLINE']
  require 'scrape'
  TIMETABLE = Scrape.new
else
  require 'dummy_timetable'
  TIMETABLE = DummyTimetable.new
end

class App < Roda
  route do |r|
    @logger = Logger.new(STDERR)

    r.on 'search' do
      # the MTA Web site always expects this time zone
      tz = TZInfo::Timezone.get 'America/New_York'
      @now = tz.utc_to_local Time.now.utc

      r.get do
        timetable = TIMETABLE.(
          origin: r.params['origin'],
          destination: r.params['destination'],
          time: @now,
        )
        times = timetable[:times]
          .select { |t| t[:start] >= @now }
          .sort_by { |t| t[:start] }
        ([
          "#{timetable[:from]} -> #{timetable[:to]}\n",
          @now.strftime("around %H:%M on %a %e %b\n")
        ] + times.map do |time|
          "#{time[:start].strftime('%H:%M')} -> #{time[:stop].strftime('%H:%M')}\n"
        end).join
      end

      r.post 'twilio' do
        response['Content-Type'] = 'text/plain'
        origin, destination = r.params['Body'].split(%r{to|/|->}).map(&:strip)
        timetable = TIMETABLE.(
          origin: origin,
          destination: destination,
          time: @now,
        )
        response.status = 200
        times = timetable[:times]
          .select { |t| t[:start] >= @now }
          .sort_by { |t| t[:start] }
        ([
          "#{timetable[:from]} -> #{timetable[:to]}\n",
          @now.strftime("around %H:%M on %a %e %b\n")
        ] + times.map do |time|
          "#{time[:start].strftime('%H:%M')} -> #{time[:stop].strftime('%H:%M')}\n"
        end).join
      end
    end
  end
end
