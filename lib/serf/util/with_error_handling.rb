require 'active_support/core_ext/string/inflections'

require 'serf/messages/caught_exception_event'
require 'serf/util/null_object'
require 'serf/util/with_options_extraction'

module Serf
module Util

  ##
  # Helper module to rescues exceptions from executing blocks of
  # code, and then logs+pushes the error event.
  #
  module WithErrorHandling
    include ::Serf::Util::WithOptionsExtraction

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
      return true, yield
    rescue => e
      eec = opts :error_event_class, ::Serf::Messages::CaughtExceptionEvent
      logger = opts :logger, ::Serf::Util::NullObject.new
      error_channel = opts :error_channel, ::Serf::Util::NullObject.new
      error_event = eec.new(
        context: context,
        error: e.class.to_s.tableize,
        message: e.message,
        backtrace: e.backtrace.join("\n"))

      # log the error to our logger, and to our error channel.
      logger.error error_event
      begin
        error_channel.push error_event
      rescue => e1
        logger.error("
          Failed pushing to ErrorChannel:
          #{e1.message}
          #{e1.backtrace.join('\n')}
        ")
      end

      # We're done, so just return this error.
      return false, error_event
    end

  end

end
end
