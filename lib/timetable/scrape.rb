#!/usr/bin/env ruby

require 'nokogiri'
require 'dry/monads/result'

require 'fuzzy'
require 'http'

module Timetable
  class Scrape
    include Dry::Monads::Result::Mixin

    def initialize(logger:, stations:)
      @logger = logger
      @stations = stations
      @haystack = Fuzzy.new strings: stations.keys
    end

    def call(origin:, destination:, time:)
        @haystack.(origin).bind do |origin_|
          @haystack.(destination).bind do |destination_|
            @logger.debug { "from: #{origin} → #{@stations[origin_]}, to: #{destination} → #{@stations[destination_]}" }
            retrieve_schedule(from: @stations[origin_], to: @stations[destination_], time: time)
              .fmap do |times|
                {
                  from: origin_,
                  to: destination_,
                  times: times,
                }
              end
          end
            .or { Failure("Could not find station for '#{destination}'") }
        end
          .or { Failure("Could not find station for '#{origin}'") }
          .or { |error| Success(error) }
    end

    private

    def retrieve_schedule(from:, to:, time:)
      uri = URI('http://as0.mta.info/mnr/schedules/sched_results.cfm?n=y')
      params = {
        'orig_id' => from,
        'dest_id' => to,
        'Filter_id' => 1,
        'traveldate' => time.strftime('%m-%d-%Y'),
        'Time_id' => time.strftime('%I:%M'),
        'SelAMPM1' => time.strftime('%p'),
        'cmdschedule' => 'see+schedule'
      }
      Http.post(uri, URI.encode_www_form(params))
        .fmap { |response| parse_table response.body }
        .or do |response|
          @logger.error { response.inspect }
          Failure('Error retreiving schedule')
        end
    end

    def parse_table(body)
      Nokogiri::HTML(body)
        .xpath('/html/body/div/div[3]/form[2]/div[3]/table[2]/tr')
        .drop(1) # the table's header is a <tr>
        .map do |tr|
          start, _, stop = tr.xpath('td')
          if start.nil? or stop.nil?
            nil
          else
            {
              start: Time.strptime(start.content.strip, '%I:%M %p'),
              stop: Time.strptime(stop.content.strip, '%I:%M %p'),
            }
          end
        end
        .compact
    end
  end
end
