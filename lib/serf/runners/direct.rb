require 'serf/runners/helper'
require 'serf/util/with_error_handling'

module Serf
module Runners

  ##
  # Direct runner drives the execution of a handler for given messages.
  # This class deals with error handling and pushing handler results
  # to proper error or results channels.
  #
  # NOTES:
  # * Results returned from handlers are pushed to response channel.
  # * Errors raised by handlers are pushed to error channel, not response.
  #
  class Direct
    include Serf::Util::WithErrorHandling
    include Serf::Runners::Helper

    def initialize(*args)
      extract_options! args
      opts! :response_channel
    end

    def call(handlers, context)
      results = []
      handlers.each do |handler|
        ok, run_result = with_error_handling(context) do
          handler.call
        end
        run_result = run_result.is_a?(Hash) ? [run_result] : Array(run_result)

        # We only post to the response channel if we didn't catch and error.
        # But we add both error and success results to the 'results' to
        # pass back to the caller of the runner. This may be a background
        # runner, which then the results are ignored. But it may have been
        # the Serfer, which means all results should go back to the user
        # as this was a foreground (synchronous) execution.
        results.concat run_result
        push_results run_result if ok
      end
      return results
    end

    def self.build(options={})
      self.new options
    end

  end

end
end
