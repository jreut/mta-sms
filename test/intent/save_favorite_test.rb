require 'minitest/autorun'
require 'set'

require 'dry/monads/maybe'

require 'intent/save_favorite'

class DummyFuzzy
  def initialize
    @rejects = Set.new
  end

  def call(input)
    Dry::Monads::Maybe(@rejects.member?(input) ? nil : input)
  end

  def reject(string)
    @rejects << string
  end
end

module Intent
  class SaveFavoriteTest < Minitest::Test
    def test_happy_path
      map = {}
      fuzzy = DummyFuzzy.new
      sender = '3528675309'
      from = 'foo'
      to = 'bar'
      body = "save #{from} / #{to}"
      intent = SaveFavorite.new(
        sender: sender,
        body: body,
        map: map,
        fuzzy: fuzzy
      )

      intent.call

      assert_includes map, sender
      assert_equal({ from: from, to: to }, map[sender])
    end

    def test_bad_from_station
      map = {}
      fuzzy = DummyFuzzy.new
      sender = '3528675309'
      from = 'foo'
      fuzzy.reject from
      to = 'bar'
      body = "save #{from} / #{to}"
      intent = SaveFavorite.new(
        sender: sender,
        body: body,
        map: map,
        fuzzy: fuzzy
      )

      intent.call
        .or { flunk }
        .fmap do |response|
          assert_equal "Could not find station for '#{from}'", response
        end
    end

    def test_bad_to_station
      map = {}
      fuzzy = DummyFuzzy.new
      sender = '3528675309'
      from = 'foo'
      to = 'bar'
      fuzzy.reject to
      body = "save #{from} / #{to}"
      intent = SaveFavorite.new(
        sender: sender,
        body: body,
        map: map,
        fuzzy: fuzzy
      )

      intent.call
        .or { flunk }
        .fmap do |response|
          assert_equal "Could not find station for '#{to}'", response
        end
    end
  end
end
