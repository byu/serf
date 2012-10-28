require 'serf/error'
require 'serf/util/protected_call'

module Serf
module Util

  ##
  # Helper module to rescues exceptions from executing blocks of
  # code, and then converts the exception to an "Error Message".
  #
  module ErrorHandling
    include Serf::Util::ProtectedCall

    ##
    # A block wrapper to handle errors when executing a block.
    #
    def with_error_handling(error_kind=Serf::Error, *args, &block)
      results, err = pcall *args, &block
      return results, handle_error(err, error_kind)
    end

    ##
    # Including classes may override this method to do alternate error
    # handling. By default, this method will create a new error event message.
    #
    def handle_error(e, error_kind)
      # no error was passed, so do nothing.
      return nil unless e

      # Get the nice string format of the error kind.
      unless error_kind.kind_of? String
        error_kind = error_kind.to_s
      end

      # Return a simple error event message
      return {
        kind: error_kind,
        error: e.class.to_s,
        message: e.message,
        process_env: ENV.to_hash,
        backtrace: e.backtrace.join("\n")
      }
    end

  end

end
end
