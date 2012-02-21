require 'active_support/core_ext/string/inflections'

require 'serf/messages/caught_exception_event'
require 'serf/util/null_object'

module Serf
module Util

  ##
  # Helper module to rescues exceptions from executing blocks of
  # code, and then logs+publishes the error event.
  #
  module WithErrorHandling

    ##
    # A block wrapper to handle errors when executing a block.
    #
    # Including classes may have the following instance variables
    # to override the default values:
    # * @error_event_class - ::Serf::Messages::CaughtExceptionEvent
    # * @logger - ::Serf::Util::NullObject.new
    # * @error_channel - ::Serf::Util::NullObject.new
    #
    def with_error_handling(context=nil)
      yield
    rescue => e
      eec = @error_event_class || ::Serf::Messages::CaughtExceptionEvent
      logger = @logger || ::Serf::Util::NullObject.new
      error_channel = @error_channel || ::Serf::Util::NullObject.new
      error_event = eec.new(
        context: context,
        error: e.class.to_s.tableize,
        message: e.message,
        backtrace: e.backtrace.join("\n"))

      # log the error to our logger, and to our error channel.
      logger.error error_event
      error_channel.publish error_event

      # We're done, so just return this error.
      return error_event
    end

  end

end
end
