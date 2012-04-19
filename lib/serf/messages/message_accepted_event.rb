require 'serf/message'
require 'serf/util/uuidable'

module Serf
module Messages

  ##
  # This event signals that the serf process has accepted a message
  # for processing at a later time. These events are normally sent
  # in response to calling clients, which is a separate signal
  # than any errors given.
  #
  class MessageAcceptedEvent
    include Serf::Message
    include Serf::Util::Uuidable

    attr_accessor :message

    def initialize(options={})
      @message = options[:message]
      @uuid = options[:uuid]
    end

    def attributes
      {
        'message' => @message,
        'uuid' => (@uuid || create_coded_uuid)
      }
    end

    def to_s
      to_hash.to_s
    end

  end

end
end
