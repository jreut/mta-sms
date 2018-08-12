class TimetablePresenter
  def initialize(timetable:, now:)
    @timetable = timetable
    @now = now
  end

  def call
    times = @timetable[:times]
      .sort_by { |t| t[:start] }
      .map do |time|
        "#{time[:start].strftime('%H:%M')} -> #{time[:stop].strftime('%H:%M')}\n"
      end
    ([
      "#{@timetable[:from]} -> #{@timetable[:to]}\n",
      @now.strftime("around %H:%M on %a %e %b\n")
    ] + times).join
  end
end
