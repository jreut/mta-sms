require 'dry/monads/result'

module Intent
  class SaveFavorite
    include Dry::Monads::Result::Mixin

    def initialize(sender:, body:, map:, fuzzy:)
      @sender = sender
      @body = body
      @map = map
      @fuzzy = fuzzy
    end

    def match?
      @body.start_with? 'save', '+'
    end

    def call
      %r{(save|\+)\s+(?<from>[^/]+)/(?<to>[^/]+)}.match(@body) do |m|
        @fuzzy.(m[:from].strip)
          .or { Failure(fuzzy_failure(m[:from].strip)) }
          .bind do |from|
            @fuzzy.(m[:to].strip)
              .or { Failure(fuzzy_failure(m[:to].strip)) }
              .bind do |to|
                @map[@sender] = { from: from, to: to }
                Success(happy(from, to))
              end
          end
      end
    end

    private

    def happy(from, to)
      "Saved favorite: #{from} -> #{to}"
    end

    def fuzzy_failure(string)
      "Could not find station for '#{string}'"
    end
  end
end
