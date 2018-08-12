require 'logger'

require 'roda'
require 'tzinfo'

require 'timetable_presenter'

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

      r.post 'twilio' do
        response['Content-Type'] = 'text/plain'
        origin, destination = r.params['Body'].split(%r{[^[:alnum:][:space:]]+}).map(&:strip)
        timetable = TIMETABLE.(
          origin: origin,
          destination: destination,
          time: @now,
        )
        response.status = 200
        TimetablePresenter.new(timetable: timetable, now: @now).call
      end
    end
  end
end
