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

class App < Roda
  route do |r|
    if ENV['ONLINE']
      LOGGER.debug("ONLINE=#{ENV['ONLINE']} (truthy)")
      @source = Scrape.new logger: LOGGER, stations: @stations
      @stations = StationList.new(logger: LOGGER).call.value_or { {} }
    else
      LOGGER.debug("ONLINE=#{ENV['ONLINE']} (falsy)")
      @source = DummyTimetable.new
      @stations = DummyStationList.new.call.value!
    end

    r.post do
      [
        Intent::SaveFavorite.new(
          sender: r.params['From'],
          body: r.params['Body'],
          map: FAVORITES,
          fuzzy: Fuzzy.new(strings: @stations.keys),
        ),
        Intent::RetrieveFavorite.new(
          sender: r.params['From'],
          body: r.params['Body'],
          map: FAVORITES,
          source: @source
        ),
        Intent::Search.new(
          body: r.params['Body'],
          source: @source,
        ),
      ].detect(&:match?).call.value_or(&:itself)
    end
  end
end
