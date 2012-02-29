require 'serf/util/with_error_handling'

module Serf
module Runners

  ##
  # Direct runner drives the execution of a handler for given messages.
  # This class deals with error handling and publishing handler results
  # to proper error or results channels.
  #
  # NOTES:
  # * Results returned from handlers are published to response channel.
  # * Errors raised by handlers are published to error channel, not response.
  #
  class Direct
    include ::Serf::Util::WithErrorHandling

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
        publish_results run_result if ok
      end
      return results
    end

    def self.build(options={})
      self.new options
    end

    protected

    ##
    # Loop over the results and publish them to the results channel.
    # Any error in publishing individual messages will result in
    # a log event and an error channel event.
    def publish_results(results)
      response_channel = opts! :response_channel
      results.each do |message|
        with_error_handling(message) do
          response_channel.publish message
        end
      end
      return nil
    end

  end

end
end
