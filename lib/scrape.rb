#!/usr/bin/env ruby

require 'net/http'

require 'nokogiri'

require 'prefix_checker'

class Scrape
  def call(origin:, destination:, time:)
    hash = get
    checker = PrefixChecker.new dictionary: hash.keys
    corrected_origin = checker.correct(origin.upcase).first
    corrected_destination = checker.correct(destination.upcase).first
    origin_id = hash[corrected_origin]
    destination_id = hash[corrected_destination]
    if origin_id.nil? or destination_id.nil?
      nil
    else
      response = post from: origin_id, to: destination_id, time: time
      times = table response.body
      {
        from: corrected_origin,
        to: corrected_destination,
        times: times,
      }
    end
  end

  private

  def get
    return @dict if instance_variable_defined? :@dict
    uri = URI('http://as0.mta.info/mnr/schedules/sched_form.cfm')
    body = Net::HTTP.get(uri)
    doc = Nokogiri::HTML(body)
    xpath = '//*[@id="Vorig_station"]'
    @dict = doc
      .xpath(xpath+'/option')
      .each_with_object({}) do |option, hash|
        hash[option.text] = option['value']
      end
    @dict
  end

  def post(from:, to:, time:)
    uri = URI('http://as0.mta.info/mnr/schedules/sched_results.cfm?n=y')
    headers = {
      'Content-Type' => 'application/x-www-form-urlencoded',
    }
    params = {
      'orig_id' => from,
      'dest_id' => to,
      'Filter_id' => 1,
      'traveldate' => time.strftime('%m-%d-%Y'),
      'Time_id' => time.strftime('%I:%M'),
      'SelAMPM1' => time.strftime('%p'),
      'cmdschedule' => 'see+schedule'
    }
    data = URI.encode_www_form(params)
    Net::HTTP.post(uri, data, headers)
  end

  def table(body)
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
