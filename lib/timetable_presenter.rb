require 'tzinfo'

class TimetablePresenter
  def initialize(timetable:, time:)
    @timetable = timetable
    @time = time
  end

  def call
    times = @timetable[:times]
      .reject { |t| t[:start] < @time }
      .sort_by { |t| t[:start] }
      .map do |time|
        "#{format_from_utc(time[:start], '%H:%M')} -> #{format_from_utc(time[:stop], '%H:%M')}\n"
      end
    ([
      "#{@timetable[:from]} -> #{@timetable[:to]}\n",
      format_from_utc(@time, "around %H:%M on %a %e %b\n")
    ] + times).join
  end

  private

  def format_from_utc(time, format)
    # the MTA always expects this zone
    @tz ||= TZInfo::Timezone.get 'America/New_York'
    @tz.utc_to_local(time.utc).strftime(format)
  end
end
