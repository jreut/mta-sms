require 'fuzzy_match'
require 'dry/monads/maybe'

class Fuzzy
  def initialize(strings:)
    @fuzzy = FuzzyMatch.new strings
  end

  def call(needle)
    Dry::Monads::Maybe(@fuzzy.find(needle))
  end
end
