module Serf
module Errors

  class NotFound < RuntimeError
    attr_reader :request_headers, :request_message

    def initialize(parcel_pair=[])
      @request_headers, @request_message = parcel_pair
    end

    def to_s
      "NotFound kind:#{request_message['kind']} uuid:#{request_headers['uuid']}"
    end

  end

end
end
