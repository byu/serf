require 'base64'
require 'hashie'
require 'optser'
require 'uuidtools'

module Serf
module Util

  ##
  # Helper module to for various UUID tasks.
  #
  # 1. Primarily to create and parse 'coded' UUIDs, which are just
  #   base64 encoded UUIDs without trailing '='.
  #
  class Uuidable
    attr_reader :uuid_tool

    def initialize(*args)
      opts = Optser.extract_options! args
      @uuid_tool = opts.get :uuid_tool, UUIDTools::UUID
    end

    ##
    # Creates a Timestamp UUID, base64 encoded.
    #
    # NOTE: UUIDTools TimeStamp code creates a UTC based timestamp UUID.
    #
    def create_coded_uuid
      # All raw UUIDs are 16 bytes long. Base64 lengthens the string to
      # 24 bytes long. We chomp off the last two equal signs '==' to
      # trim the string length to 22 bytes. This gives us an overhead
      # of an extra 6 bytes over raw UUID, but with the readability
      # benefit. And saves us 14 bytes of size from the 'standard'
      # string hex representation of UUIDs.
      Base64.urlsafe_encode64(uuid_tool.timestamp_create.raw).chomp('==')
    end

    ##
    # @param coded_uuid a coded uuid to parse.
    #
    def parse_coded_uuid(coded_uuid)
      uuid_tool.parse_raw Base64.urlsafe_decode64("#{coded_uuid}==")
    end

    ##
    # Parses a coded_uuid and returns a time object for the Timestamped UUID.
    #
    # @param coded_uuid the coded uuid from which to get a time.
    #
    # @return ruby time object for which the coded_uuid was timestamped.
    #
    def coded_uuid_time(coded_uuid)
      uuid = parse_coded_uuid coded_uuid
      uuid.timestamp.utc
    end

    ##
    # Create a new set of uuids.
    #
    def create_uuids(parent=nil)
      parent ||= {}
      Hashie::Mash.new(
        uuid: create_coded_uuid,
        parent_uuid: parent[:uuid],
        origin_uuid: (
          parent[:origin_uuid] ||
          parent[:parent_uuid] ||
          parent[:uuid]))
    end

  end

end
end
