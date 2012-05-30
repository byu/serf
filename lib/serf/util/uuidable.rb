require 'base64'
require 'hashie'
require 'uuidtools'

module Serf
module Util

  ##
  # Helper module to for various UUID tasks.
  #
  # 1. Primarily to create and parse 'coded' UUIDs, which are just
  #   base64 encoded UUIDs without trailing '='.
  #
  module Uuidable

    ##
    # @see self.create_coded_uuid
    def create_coded_uuid
      Uuidable.create_coded_uuid
    end

    ##
    # @see self.parse_coded_uuid
    def parse_coded_uuid(coded_uuid)
      Uuidable.parse_coded_uuid coded_uuid
    end

    ##
    # @see self.create_uuids
    def create_uuids(parent={})
      Uuidable.create_uuids parent
    end

    ##
    # @see self.annotate_with_uuids!
    def annotate_with_uuids!(message, parent={})
      Uuidable.annotate_with_uuids! message, parent
    end

    ##
    # Creates a Timestamp UUID, base64 encoded.
    #
    # NOTE: UUIDTools TimeStamp code creates a UTC based timestamp UUID.
    #
    def self.create_coded_uuid
      # All raw UUIDs are 16 bytes long. Base64 lengthens the string to
      # 24 bytes long. We chomp off the last two equal signs '==' to
      # trim the string length to 22 bytes. This gives us an overhead
      # of an extra 6 bytes over raw UUID, but with the readability
      # benefit. And saves us 14 bytes of size from the 'standard'
      # string hex representation of UUIDs.
      Base64.urlsafe_encode64(UUIDTools::UUID.timestamp_create.raw).chomp('==')
    end

    ##
    # @param coded_uuid a coded uuid to parse.
    #
    def self.parse_coded_uuid(coded_uuid)
      UUIDTools::UUID.parse_raw Base64.urlsafe_decode64("#{coded_uuid}==")
    end

    ##
    # Create a new set of uuids.
    #
    def self.create_uuids(parent={})
      Hashie::Mash.new(
        uuid: create_coded_uuid,
        parent_uuid: parent[:uuid],
        origin_uuid: (
          parent[:origin_uuid] ||
          parent[:parent_uuid] ||
          parent[:uuid]))
    end

    ##
    # Set a message's UUIDs with new UUIDs based on the parent's UUIDs.
    #
    def self.annotate_with_uuids!(message, parent={})
      uuids = self.create_uuids parent
      message[:uuid] ||= uuids[:uuid]
      message[:parent_uuid] ||= uuids[:parent_uuid]
      message[:origin_uuid] ||= uuids[:origin_uuid]
      return nil
    end

  end

end
end
