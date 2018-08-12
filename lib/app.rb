require 'logger'

require 'roda'
require 'tzinfo'

require 'timetable_presenter'
require 'intent/search'

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
    r.post do
      Intent::Search.new(body: r.params['Body']).(response: response)
    end
  end
end
