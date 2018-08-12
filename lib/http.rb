require 'net/http'

require 'dry/monads/result'

class Http
  class << self
    include Dry::Monads::Result::Mixin

    def get(*args)
      response = Net::HTTP.get_response(*args)
      case response
      when Net::HTTPSuccess
        Success response
      else
        Failure response
      end
    end

    def post(*args)
      response = Net::HTTP.post(*args)
      case response
      when Net::HTTPSuccess
        Success response
      else
        Failure response
      end
    end
  end
end
