require 'serf/messages/caught_exception_event'
require 'serf/util/null_object'

module Serf
module Runners

  ##
  # Direct runner drives the execution of a handler for given messages.
  # This class deals with error handling and publishing handler results
  # to proper error or results channels.
  #
  class DirectRunner

    def initialize(options={})
      # Mandatory, we want both results and error channels.
      @results_channel = options.fetch(:results_channel)
      @error_channel = options.fetch(:error_channel)

      # For caught exceptions, we're going to publish an error event
      # over our error channel. This defines our error event message class.
      @error_event_class = options.fetch(:error_event_class) {
        ::Serf::Messages::CaughtExceptionEvent
      }

      # Our default logger
      @logger = options.fetch(:logger) { ::Serf::Util::NullObject.new }
    end

    def run(handler, params)
      with_error_handling(params) do
        results = handler.call params
        publish_results results
        return results
      end
    end

    protected

    ##
    # Loop over the results and publish them to the results channel.
    # Any error in publishing individual messages will result in
    # a log event and an error channel event.
    def publish_results(results)
      results = Array(results)
      results.each do |message|
        with_error_handling(message) do
          @results_channel.publish message
        end
      end
      return nil
    end

    ##
    # A block wrapper to handle errors when executing a block.
    #
    def with_error_handling(context=nil)
      yield
    rescue => e
      error_event = @error_event_class.new(
        context: context,
        error_message: e.inspect,
        error_backtrace: e.backtrace.join("\n"))

      # log the error to our logger, and to our error channel.
      @logger.error error_event
      @error_channel.publish error_event

      # We're done, so just return this error.
      return error_event
    end
  end

end
end
