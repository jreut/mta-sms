require 'dry/monads/result'
require 'nokogiri'

require 'http'

class StationList
  def initialize(logger:)
  end

  def call
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
end
