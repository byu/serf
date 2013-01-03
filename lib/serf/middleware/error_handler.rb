require 'hashie'
require 'optser'

require 'serf/parcel_factory'
require 'serf/util/error_handling'

module Serf
module Middleware

  ##
  # Middleware to catch raised exceptions and return an error parcel
  # instead.
  #
  class ErrorHandler
    include Serf::Util::ErrorHandling

    attr_reader :app
    attr_reader :parcel_factory

    ##
    # @param app the app
    #
    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app

      # Tunable knobs
      @parcel_factory = opts.get(:parcel_factory) { Serf::ParcelFactory.new }
    end

    def call(parcel)
      # Attempt to execute the app, catching errors
      response_parcel, error_message = with_error_handling do
        app.call parcel
      end

      # Return on success
      return response_parcel if response_parcel

      # We got an error message, so build out and return the error parcel
      return parcel_factory.create(
        kind: 'serf/events/caught_error',
        parent: parcel,
        message: error_message)
    end

  end

end
end
