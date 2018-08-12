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
      Maybe(@map[@sender])
        .bind do |query|
          case @body
          when 'in'
            opposite = 'out'
            search = "#{query[:from]} . #{query[:to]}"
          when 'out'
            opposite = 'in'
            search = "#{query[:to]} . #{query[:from]}"
          end

          Intent::Search.new(body: search, source: @source)
            .call
            .fmap do |response|
              response + "\nsend '#{opposite}' for other direction"
            end
        end
        .or { Success("No favorite saved for #{@sender}") }
    end
  end
end
