require 'ice_nine'
require 'optser'

module Serf
module Middleware

  ##
  # Middleware to add uuids to freeze the parcel.
  #
  class ParcelFreezer
    attr_reader :app
    attr_reader :freezer

    ##
    # @param app the app
    #
    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app
      @freezer = opts.get :freezer, IceNine
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
