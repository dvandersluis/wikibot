module Curl
  class Easy
    # Wrapper method for curl methods that raises an exception unless a response of 200 is received
    def do(method, url, data = [])
      self.url = url
      self.send(method, *data)
      raise WikiBot::CurbError, response_code.to_s unless response_code == 200
    end
  end
end
