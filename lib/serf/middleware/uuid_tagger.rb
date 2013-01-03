require 'hashie'
require 'optser'

require 'serf/util/uuidable'

module Serf
module Middleware

  ##
  # Middleware to add the uuid to the parcel hash if not already present.
  #
  class UuidTagger
    attr_reader :app
    attr_reader :uuidable

    ##
    # @param app the app
    #
    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app
      @uuidable = opts.get(:uuidable) { Serf::Util::Uuidable.new }
    end

    def call(parcel)
      # Duplicate the parcel
      parcel = parcel.dup

      # Tag with a UUID unless it already has one
      parcel[:uuid] ||= uuidable.create_coded_uuid

      # Pass on the given parcel with the uuid
      app.call parcel
    end

  end

end
end
