require 'dry/monads/result'

class DummyStationList
  include Dry::Monads::Result::Mixin

  def call
    Success(Hash[[
      'GRAND CENTRAL',
      'SPUYTEN DUYVIL',
    ].map.with_index { |e, i| [e, i] }])
  end
end
