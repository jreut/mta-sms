require 'tzinfo'

require 'timetable_presenter'

module Intent
  class Search
    SPLIT_PATTERN = %r{[./]}

    def initialize(body:, source:)
      @body = body
      @source = source
    end

    def match?
      @body.match? SPLIT_PATTERN
    end

    def call
      # the MTA Web site always expects this time zone
      tz = TZInfo::Timezone.get 'America/New_York'
      now = tz.utc_to_local Time.now.utc

      origin, destination = @body.split(SPLIT_PATTERN).map(&:strip)
      @source.(
        origin: origin,
        destination: destination,
        time: now,
      ).fmap do |timetable|
        TimetablePresenter.new(timetable: timetable, now: now).call
      end
    end
  end
end
