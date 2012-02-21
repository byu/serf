require 'serf/message'
require 'serf/util/uuidable'

module Serf
module Messages

  ##
  # An event message to signal that the serf code caught an
  # exception during the processing of some message, which is
  # represented by the context field.
  #
  # Instances of this class are norminally published to an
  # error channel for out of band processing/notification.
  #
  class CaughtExceptionEvent
    include ::Serf::Message
    include ::Serf::Util::Uuidable

    attr_accessor :context
    attr_accessor :error
    attr_accessor :message
    attr_accessor :backtrace

    def initialize(options={})
      @context = options[:context]
      @error = options[:error]
      @message = options[:message]
      @backtrace = options[:backtrace]
      @uuid = options[:uuid]
    end

    def attributes
      {
        'context' => @context,
        'error' => @error,
        'message' => @message,
        'backtrace' => @backtrace,
        'uuid' => uuid
      }
    end

    def to_s
      to_hash.to_s
    end

  end

end
end
