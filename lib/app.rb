require 'logger'

require 'roda'

require 'dummy_station_list'
require 'dummy_timetable'
require 'fuzzy'
require 'intent/retrieve_favorite'
require 'intent/save_favorite'
require 'intent/search'
require 'scrape'
require 'station_list'

LOGGER = Logger.new(STDERR)
FAVORITES = {}

if ENV['ONLINE']
  LOGGER.debug("ONLINE=#{ENV['ONLINE']} (truthy)")
  STATIONS = StationList.new(logger: LOGGER).call.value_or { {} }
  SOURCE = Scrape.new logger: LOGGER, stations: STATIONS
else
  LOGGER.debug("ONLINE=#{ENV['ONLINE']} (falsy)")
  SOURCE = DummyTimetable.new
  STATIONS = DummyStationList.new.call.value!
end

class App < Roda
  route do |r|
    r.post do
      [
        Intent::SaveFavorite.new(
          sender: r.params['From'],
          body: r.params['Body'],
          map: FAVORITES,
          fuzzy: Fuzzy.new(strings: STATIONS.keys),
        ),
        Intent::RetrieveFavorite.new(
          sender: r.params['From'],
          body: r.params['Body'],
          map: FAVORITES,
          source: SOURCE,
        ),
        Intent::Search.new(
          body: r.params['Body'],
          source: SOURCE,
        ),
      ]
        .detect(&:match?)
        .call
        .value_or(nil)
    end
  end
end
