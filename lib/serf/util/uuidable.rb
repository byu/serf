require 'base64'
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
    # Creates a Random UUID, base64 encoded.
    #
    def create_coded_uuid
      # All raw UUIDs are 16 bytes long. Base64 lengthens the string to
      # 24 bytes long. We chomp off the last two equal signs '==' to
      # trim the string length to 22 bytes. This gives us an overhead
      # of an extra 6 bytes over raw UUID, but with the readability
      # benefit. And saves us 14 bytes of size from the 'standard'
      # string hex representation of UUIDs.
      Base64.urlsafe_encode64(UUIDTools::UUID.random_create.raw).chomp('==')
    end

    ##
    # @param coded_uuid a coded uuid to parse.
    #
    def parse_coded_uuid(coded_uuid)
      UUIDTools::UUID.parse_raw Base64.urlsafe_decode64("#{coded_uuid}==")
    end

  end

end
end
