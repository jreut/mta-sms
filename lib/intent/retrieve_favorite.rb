require 'dry/monads/maybe'
require 'dry/monads/result'

require 'intent/search'

module Intent
  class RetrieveFavorite
    include Dry::Monads::Result::Mixin
    include Dry::Monads::Maybe::Mixin

    def initialize(body:, sender:, map:, source:)
      @body = body
      @map = map
      @sender = sender
      @source = source
    end

    def match?
      @body.start_with? 'in', 'out'
    end

    def call
      Dry::Monads::Maybe(@map[@sender])
        .or { Failure("No favorite saved for #{@sender}") }
        .bind do |query|
          case @body
          when 'in'
            search = "#{query[:from]} . #{query[:to]}"
          when 'out'
            search = "#{query[:to]} . #{query[:from]}"
          end

          Intent::Search.new(body: search, source: @source).call
        end
    end
  end
end
