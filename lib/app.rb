require 'logger'

require 'roda'
require 'tzinfo'

require 'timetable_presenter'

LOGGER = Logger.new(STDERR)

if ENV['ONLINE']
  require 'scrape'
  TIMETABLE = Scrape.new logger: LOGGER
else
  require 'dummy_timetable'
  TIMETABLE = DummyTimetable.new
end

class App < Roda
  route do |r|
    r.post 'search/twilio' do
      # the MTA Web site always expects this time zone
      tz = TZInfo::Timezone.get 'America/New_York'
      @now = tz.utc_to_local Time.now.utc

      response['Content-Type'] = 'text/plain'
      origin, destination = r.params['Body'].split(%r{[./]}).map(&:strip)
      TIMETABLE.(
        origin: origin, destination: destination,
        time: @now,
      ).fmap do |timetable|
        TimetablePresenter.new(timetable: timetable, now: @now).call
      end.value_or(&:itself)
    end
  end
end
