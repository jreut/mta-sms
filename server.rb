require 'uri'
require_relative 'scrape'

class Server
  def call(env)
    params = Hash[URI.decode_www_form(env['QUERY_STRING'])]
    times = Scrape.new.call(origin: params['origin'], destination: params['destination'], time: Time.now)
    [
      200,
      {},
      times.map { |line| line + "\n" },
    ]
  end
end
