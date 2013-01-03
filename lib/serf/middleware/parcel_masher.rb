require 'hashie'
require 'optser'

module Serf
module Middleware

  ##
  # Middleware to coerce the parcel to Hashie::Mash.
  #
  class ParcelMasher
    attr_reader :app
    attr_reader :masher_class

    ##
    # @param app the app
    #
    def initialize(app, *args)
      opts = Optser.extract_options! args
      @app = app
      @masher_class = opts.get :masher_class, Hashie::Mash
    end

    ##
    # Coerces the parcel into a Hashie::Mash, makes sure that
    # the message field is set, and then passes it along the chain.
    def call(parcel)
      mashed_parcel = masher_class.new parcel
      mashed_parcel[:message] ||= {}
      app.call mashed_parcel
    end

  end

end
end
