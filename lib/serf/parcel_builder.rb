require 'hashie'
require 'optser'

module Serf

  ##
  # Builds Parcels as Hashie::Mash objects with headers and messages.
  #
  class ParcelBuilder
    attr_reader :mash_class

    def initialize(*args)
      opts = Optser.extract_options! args

      @mash_class = opts.get :mash_class, Hashie::Mash
    end

    def build(headers=nil, message=nil)
      # We want to make sure that our headers and message are Mashes.
      headers = mash_class.new(headers) unless headers.kind_of? mash_class
      message = mash_class.new(message) unless message.kind_of? mash_class
      mash_class.new headers: headers, message: message
    end

  end

end
