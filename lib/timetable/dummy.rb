require 'dry/monads/result'

module Timetable
  class Dummy
    include Dry::Monads::Result::Mixin

    def initialize(length: 10)
      @offsets = Array.new(length) { |i| i - length / 2 }
    end

    def call(origin:, destination:, time:)
      times = @offsets.map do |i|
        calculated = time + 60 * 15 * i
        {
          start: calculated,
          stop: calculated + 60 * 60,
        }
      end

      Success(
        from: origin.upcase,
        to: destination.upcase,
        times: times,
      )
    end
  end
end
