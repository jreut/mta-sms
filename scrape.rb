#!/usr/bin/env ruby

require 'net/http'
require 'nokogiri'

class Scrape
  def get
    uri = URI('http://as0.mta.info/mnr/schedules/sched_form.cfm')
    body = Net::HTTP.get(uri)
    doc = Nokogiri::HTML(body)
    xpath = '//*[@id="Vorig_station"]'
    doc.xpath(xpath+'/option').each_with_object({}){|option, hash| hash[option.text]=option['value'].to_i}
  end

  def post(from: 1, to: 14, time: Time.now)
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
      .drop(1)
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

  def call(origin:, destination:, time: DateTime.now)
    hash = get
    origin_id = hash[origin.upcase]
    destination_id = hash[destination.upcase]
    if origin_id.nil? or destination_id.nil?
      nil
    else
      response = post from: origin_id, to: destination_id, time: time
      times = table response.body
      {
        from: origin.upcase,
        to: destination.upcase,
        times: times,
      }
    end
  end
end
