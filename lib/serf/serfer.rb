require 'hashie'
require 'optser'

require 'serf/parcel_builder'
require 'serf/util/uuidable'

module Serf

  ##
  # Class to drive the Interactor execution.
  #
  class Serfer
    attr_reader :interactor
    attr_reader :parcel_builder
    attr_reader :uuidable

    def initialize(interactor, *args)
      opts = Optser.extract_options! args

      # How to and when to handle requests
      @interactor = interactor

      # Tunable knobs
      @parcel_builder = opts.get(:parcel_builder) { Serf::ParcelBuilder.new }
      @uuidable = opts.get(:uuidable) { Serf::Util::Uuidable.new }
    end

    ##
    # Rack-like call to run the Interactor's use-case.
    #
    def call(parcel)
      headers = parcel[:headers]
      message = parcel[:message]

      # 1. Execute interactor
      response_message, response_kind = interactor.call message

      # 2. Create the response headers
      response_headers = uuidable.create_uuids headers
      response_headers[:kind] = response_kind

      # 3. Return the response headers and message as a parcel
      return parcel_builder.build response_headers, response_message
    end

  end

end
