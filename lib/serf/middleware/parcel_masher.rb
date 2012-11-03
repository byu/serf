require 'hashie'

require 'serf/util/options_extraction'

module Serf
module Middleware

  ##
  # Middleware to add uuids to the headers of the parcel hash.
  #
  class ParcelMasher
    include Serf::Util::OptionsExtraction

    attr_reader :app
    attr_reader :masher_class

    ##
    # @param app the app
    #
    def initialize(app, *args)
      extract_options! args
      @app = app
      @masher_class = opts :masher_class, Hashie::Mash
    end

    ##
    # Coerces the parcel into a Hashie::Mash, makes sure that
    # the headers and message are set, and then passes it along the chain.
    def call(parcel)
      mashed_parcel = masher_class.new parcel
      mashed_parcel[:headers] ||= {}
      mashed_parcel[:message] ||= {}
      app.call mashed_parcel
    end

  end

end
end
