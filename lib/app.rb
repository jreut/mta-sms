require 'logger'

require 'dry/monads/maybe'
require 'roda'

require 'fuzzy'
require 'intent/retrieve_favorite'
require 'intent/save_favorite'
require 'intent/search'
require 'station_list/dummy'
require 'station_list/scrape'
require 'timetable/dummy'
require 'timetable/scrape'

LOGGER = Logger.new(STDERR)
FAVORITES = {}

if ENV['ONLINE']
  LOGGER.debug("ONLINE=#{ENV['ONLINE']} (truthy)")
  STATIONS = StationList::Scrape.new(logger: LOGGER).call.value_or { {} }
  TIMETABLE = Timetable::Scrape.new logger: LOGGER, stations: STATIONS
else
  LOGGER.debug("ONLINE=#{ENV['ONLINE']} (falsy)")
  STATIONS = StationList::Dummy.new.call.value!
  TIMETABLE = Timetable::Dummy.new
end

class App < Roda
  route do |r|
    r.post do
      intents = [
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
          source: TIMETABLE,
        ),
        Intent::Search.new(
          body: r.params['Body'],
          source: TIMETABLE,
        ),
      ]
      Dry::Monads::Maybe(intents.detect(&:match?))
        .bind(&:call)
        .value_or(nil)
    end
  end
end
