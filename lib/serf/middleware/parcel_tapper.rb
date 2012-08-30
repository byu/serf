require 'serf/util/null_object'
require 'serf/util/options_extraction'
require 'serf/util/protected_call'

module Serf
module Middleware

  ##
  # ParcelTapper pushes the received requests and generated responses
  # onto respective Messaging Channels for further processing. Examples
  # include audit logging requests, and pushing response events to
  # event handlers (other Serf Apps).
  class ParcelTapper
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall

    attr_reader :app
    attr_reader :logger
    attr_reader :request_channel
    attr_reader :response_channel

    def initialize(app, *args)
      extract_options! args

      @app = app
      @logger = opts(:logger) { Serf::Util::NullObject.new }
      @request_channel = opts(:request_channel) { Serf::Util::NullObject.new }
      @response_channel = opts(:response_channel) { Serf::Util::NullObject.new }
    end

    def call(header, message)
      push_request_channel [header, message]
      response_parcels = app.call header, message
      push_response_channel response_parcels
      return response_parcels
    end

    private

    def push_request_channel(parcel)
      request_channel.push parcel
    rescue => e
      logger.error e
    end

    def push_response_channel(parcels)
      parcels.each do |parcel|
        ok, err = pcall do
          response_channel.push parcel
        end
        logger.error err unless ok
      end
    end

  end

end
end
