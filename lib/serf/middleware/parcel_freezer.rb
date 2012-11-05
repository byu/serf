require 'ice_nine'

require 'serf/util/options_extraction'

module Serf
module Middleware

  ##
  # Middleware to add uuids to the headers of the parcel hash.
  #
  class ParcelFreezer
    include Serf::Util::OptionsExtraction

    attr_reader :app
    attr_reader :freezer

    ##
    # @param app the app
    #
    def initialize(app, *args)
      extract_options! args
      @app = app
      @freezer = opts :freezer, IceNine
    end

    ##
    # Chains the call, but deep freezes the parcel.
    def call(parcel)
      freezer.deep_freeze parcel
      app.call parcel
    end

  end

end
end
