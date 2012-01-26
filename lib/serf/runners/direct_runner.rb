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

    def run(endpoints, env)
      results = []
      endpoints.each do |ep|
        run_results = with_error_handling(env) do
          params = ep.message_parser ? ep.message_parser.parse(env) : env
          ep.handler.send(ep.action, params)
        end
        results.concat Array(run_results)
        publish_results run_results
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
