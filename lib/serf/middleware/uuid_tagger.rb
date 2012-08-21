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

    attr_reader :uuidable

    ##
    # @param app the app
    #
    def initialize(app, *args)
      extract_options! args
      @app = app
      @uuidable = opts :uuidable, Serf::Util::Uuidable
    end

    def call(headers, message)
      # Make a new header hash
      headers = Hashie::Mash.new headers

      # Tag headers with a UUID unless it already has one
      headers.uuid ||= uuidable.create_coded_uuid

      # Ensures origin and parent UUIDs are set
      if headers.origin_uuid.nil? && headers.parent_uuid.nil?
        # Both origin and parent are blank.
        headers.origin_uuid = headers.uuid
        headers.parent_uuid = headers.uuid
      elsif headers.origin_uuid && headers.parent_uuid.nil?
        # Origin is set, but parent is blank
        headers.parent_uuid = headers.origin_uuid
      elsif headers.parent_uuid && headers.origin_uuid.nil?
        # Parent is set, but origin is blank
        headers.origin_uuid = headers.parent_uuid
      end

      # Pass on the newly annotated deep copy of the original parcel.
      @app.call headers, message
    end

  end

end
end
