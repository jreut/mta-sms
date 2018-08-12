require 'dry/monads/result'
require 'tzinfo'

require 'timetable_presenter'

module Intent
  class Search
    include Dry::Monads::Result::Mixin

    SPLIT_PATTERN = %r{[./]}

    def initialize(body:, source:)
      @body = body
      @source = source
    end

    def match?
      @body.match? SPLIT_PATTERN
    end

    def call(now: Time.now)
      # the MTA Web site always expects this time zone
      tz = TZInfo::Timezone.get 'America/New_York'
      local = tz.utc_to_local now.utc

      origin, destination = @body.split(SPLIT_PATTERN).map(&:strip)
      @source.(
        origin: origin,
        destination: destination,
        time: now,
      ).bind do |table_1|
        # if local is earlier 21:30 on the same day
        if (local.hour * 60 + local.min) < (21 * 60 + 30)
          Success(table_1)
        else
          @source.(
            origin: origin,
            destination: destination,
            # add 2½ hours
            time: now + (2 * 60 + 30),
          ).bind do |table_2|
            Success(
              table_1.merge(table_2) do |key, old, new|
                if key == :times
                  (old + new).uniq { |time| time[:start] }
                else
                  new
                end
              end
            )
          end
        end
      end.fmap do |timetable|
        TimetablePresenter.new(
          timetable: timetable,
          time: now,
        ).call
      end
    end
  end
end
