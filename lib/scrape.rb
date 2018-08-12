#!/usr/bin/env ruby

require 'nokogiri'
require 'dry/monads/result'

require 'prefix_checker'
require 'http'

class Scrape
  include Dry::Monads::Result::Mixin

  def initialize(logger:)
    @logger = logger
  end

  def call(origin:, destination:, time:)
    retrieve_station_list.bind do |hash|
      checker = PrefixChecker.new dictionary: hash.keys
      checker.(origin.upcase).bind do |origin_|
        checker.(destination.upcase).bind do |destination_|
          @logger.debug { "from: #{origin} → #{hash[origin_]}, to: #{destination} → #{hash[destination_]}" }
          retrieve_schedule(from: hash[origin_], to: hash[destination_], time: time)
            .fmap do |times|
              {
                from: origin_,
                to: destination_,
                times: times,
              }
            end
        end.or { Failure("Could not find station for '#{destination}'") }
      end.or { Failure("Could not find station for '#{origin}'") }
    end
  end

  private

  def retrieve_station_list
    return Success(@dict) if instance_variable_defined? :@dict
    uri = URI('http://as0.mta.info/mnr/schedules/sched_form.cfm')
    Http.get(uri).fmap do |response|
      Nokogiri::HTML(response.body)
        .xpath('//*[@id="Vorig_station"]/option')
        .each_with_object({}) do |option, hash|
          hash[option.text] = option['value']
        end
    end.fmap do |response|
      @dict = response
    end.or do |response|
      @logger.error { response.inspect }
      Failure('Error fetching station list')
    end
  end

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
