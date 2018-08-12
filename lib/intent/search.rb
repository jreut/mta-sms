module Intent
  class Search
    def initialize(body:)
      @body = body
    end

    def call(response:)
      # the MTA Web site always expects this time zone
      tz = TZInfo::Timezone.get 'America/New_York'
      now = tz.utc_to_local Time.now.utc

      response['Content-Type'] = 'text/plain'
      origin, destination = @body.split(%r{[./]}).map(&:strip)
      TIMETABLE.(
        origin: origin, destination: destination,
        time: now,
      ).fmap do |timetable|
        TimetablePresenter.new(timetable: timetable, now: now).call
      end.value_or(&:itself)
    end
  end
end
