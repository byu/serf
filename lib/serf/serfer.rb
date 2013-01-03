require 'optser'

require 'serf/parcel_factory'

module Serf

  ##
  # Class to drive the Interactor execution.
  #
  class Serfer
    attr_reader :interactor
    attr_reader :parcel_factory

    def initialize(interactor, *args)
      opts = Optser.extract_options! args

      # How to and when to handle requests
      @interactor = interactor

      # Tunable knobs
      @parcel_factory = opts.get(:parcel_factory) { Serf::ParcelFactory.new }
    end

    ##
    # Rack-like call to run the Interactor's use-case.
    #
    def call(parcel)
      # 1. Execute interactor
      response_kind, response_message = interactor.call parcel

      # 2. Return a new response parcel with:
      #   a. uuids set from parent parcel
      #   b. kind set to response kind
      #   c. the message set to response_message
      return parcel_factory.create(
        parent: parcel,
        kind: response_kind,
        message: response_message)
    end

  end

end
