require 'hashie'
require 'optser'

require 'serf/util/uuidable'

module Serf

  ##
  # Creates Parcels as Hashie::Mash objects with headers and messages.
  #
  class ParcelFactory
    attr_reader :mash_class
    attr_reader :uuidable

    def initialize(*args)
      opts = Optser.extract_options! args

      @mash_class = opts.get :mash_class, Hashie::Mash
      @uuidable = opts.get(:uuidable) { Serf::Util::Uuidable.new }
    end

    def create(*args)
      opts = Optser.extract_options! args

      # Get parameters
      kind = opts.get :kind
      parent = opts.get :parent, {}
      headers = opts.get :headers, {}
      message = opts.get :message, {}

      # Coerce to mashes.
      parent = mash_class.new(parent) unless parent.kind_of? mash_class
      headers = mash_class.new(headers) unless headers.kind_of? mash_class

      # Create a new headers object w/ uuids set from the parent and kind.
      headers = headers.merge uuidable.create_uuids(parent.headers)
      headers.kind = kind

      # Return a final parcel, coerced as a mash.
      mash_class.new headers: headers, message: message
    end

  end

end
