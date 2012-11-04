require 'hashie'

require 'serf/util/options_extraction'
require 'serf/util/uuidable'

module Serf
module Middleware

  ##
  # Middleware to add uuids to the headers of the parcel hash.
  #
  class UuidTagger
    include Serf::Util::OptionsExtraction

    attr_reader :app
    attr_reader :uuidable

    ##
    # @param app the app
    #
    def initialize(app, *args)
      extract_options! args
      @app = app
      @uuidable = opts(:uuidable) { Serf::Util::Uuidable.new }
    end

    def call(parcel)
      # Makes sure our parcel has headers
      parcel[:headers] ||= {}

      # Tag headers with a UUID unless it already has one
      parcel[:headers][:uuid] ||= uuidable.create_coded_uuid

      # Pass on the given parcel with newly annotated headers
      app.call parcel
    end

  end

end
end
