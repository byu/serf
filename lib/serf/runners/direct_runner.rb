require 'serf/util/with_error_handling'

module Serf
module Runners

  ##
  # Direct runner drives the execution of a handler for given messages.
  # This class deals with error handling and publishing handler results
  # to proper error or results channels.
  #
  class DirectRunner
    include ::Serf::Util::WithErrorHandling

    def initialize(options={})
      # Mandatory, we want both results and error channels.
      @results_channel = options.fetch(:results_channel)
      @error_channel = options.fetch(:error_channel)

      # Optional overrides for error handling
      @error_event_class = options[:error_event_class]
      @logger = options[:logger]
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
  end

end
end
