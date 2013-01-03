require 'hashie'
require 'optser'

require 'serf/util/uuidable'

module Serf

  ##
  # Creates Parcels as Hashie::Mash objects with headers and messages.
  #
  # The headers this factory sets are:
  # * kind
  # * uuid
  # * parent_uuid
  # * origin_uuid
  #
  # The message field:
  # * message
  #
  # The UUID fields are created using the uuidable processed from the parent
  # parcel.
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

      # Create a new parcel, with the header fields as base of object.
      # Merge in the new UUIDs, overwriting anything set in headers.
      # Merge in the kind and message, overwriting anything already set.
      parcel = mash_class.new(headers)
      parcel.merge! uuidable.create_uuids(parent)
      parcel.merge! kind: kind, message: message

      return parcel
    end

  end

end
