require 'hashie'

require 'serf/error'
require 'serf/parcel'
require 'serf/util/error_handling'
require 'serf/util/uuidable'

module Serf
module Middleware

  ##
  # Middleware to catch raised exceptions and return an error parcel
  # instead.
  #
  class ErrorHandler
    include Serf::Util::ErrorHandling
    include Serf::Util::OptionsExtraction

    attr_reader :parcel_builder
    attr_reader :uuidable

    ##
    # @param app the app
    #
    def initialize(app, *args)
      extract_options! args
      @app = app

      # Tunable knobs
      @parcel_builder = opts(
        :parcel_builder,
        Serf::Parcel)
      @uuidable = opts :uuidable, Serf::Util::Uuidable
    end

    def call(headers, message)
      # Attempt to execute the app, catching errors
      parcel, error_message = with_error_handling do
        @app.call headers, message
      end

      # Return on success
      return parcel if parcel

      # We got an error message instead, so build out the headers
      # and return the parcel.
      error_headers = uuidable.create_uuids headers
      return parcel_builder.build error_headers, error_message
    end

  end

end
end
