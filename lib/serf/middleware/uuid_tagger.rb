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
      # Get local reference to the request parcel's headers.
      headers = parcel[:headers] || {}

      # Tag headers with a UUID unless it already has one
      headers[:uuid] ||= uuidable.create_coded_uuid

      # Ensures origin and parent UUIDs are set
      if headers[:origin_uuid].nil? && headers[:parent_uuid].nil?
        # Both origin and parent are blank.
        headers[:origin_uuid] = headers[:uuid]
        headers[:parent_uuid] = headers[:uuid]
      elsif headers[:origin_uuid] && headers[:parent_uuid].nil?
        # Origin is set, but parent is blank
        headers[:parent_uuid] = headers[:origin_uuid]
      elsif headers[:parent_uuid] && headers[:origin_uuid].nil?
        # Parent is set, but origin is blank
        headers[:origin_uuid] = headers[:parent_uuid]
      end

      # Reset the headers back into the parcel in case it was originally nil.
      parcel[:headers] = headers

      # Pass on the given parcel with newly annotated headers
      app.call parcel
    end

  end

end
end
