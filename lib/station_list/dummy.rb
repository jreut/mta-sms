require 'dry/monads/result'

module StationList
  class Dummy
    include Dry::Monads::Result::Mixin

    def call
      Success(Hash[[
        'GRAND CENTRAL',
        'SPUYTEN DUYVIL',
      ].map.with_index { |e, i| [e, i] }])
    end
  end
end
