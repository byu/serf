require 'serf/util/null_object'
require 'serf/util/options_extraction'
require 'serf/util/protected_call'

module Serf
module Util

  ##
  # Helper module to rescues exceptions from executing blocks of
  # code, and then logs+pushes the error event.
  #
  # Including classes may have the following instance variables
  # to override the default values:
  # * @logger - ::Serf::Util::NullObject.new
  # * @error_channel - ::Serf::Util::NullObject.new
  module ErrorHandling
    include Serf::Util::OptionsExtraction
    include Serf::Util::ProtectedCall

    ##
    # A block wrapper to handle errors when executing a block.
    #
    def with_error_handling(context=nil, *args, &block)
      ok, results = pcall *args, &block
      return ok, (ok ? results : handle_error(results, context))
    end

    ##
    # Including classes may override this method to do alternate error
    # handling. By default, this method will create a new caught exception
    # event and publish it to the error channel. This method will also
    # log the exception itself to the logger.
    #
    def handle_error(e, context=nil)
      logger = opts(:logger){ ::Serf::Util::NullObject.new }
      error_channel = opts(:error_channel) { ::Serf::Util::NullObject.new }
      error_event = {
        kind: 'serf/messages/caught_exception_event',
        error: e.class.to_s,
        message: e.message,
        context: context,
        process_env: ENV.to_hash,
        backtrace: e.backtrace.join("\n")
      }

      # log the error to our logger
      logger.error e

      # log the error event to our error channel.
      begin
        error_channel.push error_event
      rescue => e1
        logger.error e1
      end

      # We're done, so just return this error.
      return error_event
    end

  end

end
end
