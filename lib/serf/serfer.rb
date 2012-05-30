require 'hashie'

require 'serf/error'
require 'serf/errors/not_found'
require 'serf/util/error_handling'
require 'serf/util/null_object'

module Serf

  ##
  # Class to drive the command handler execution, error handling, etc
  # of received messages.
  class Serfer
    include Serf::Util::ErrorHandling

    attr_reader :route_set
    attr_reader :response_channel
    attr_reader :error_channel
    attr_reader :logger

    def initialize(*args)
      extract_options! args

      @route_set = opts! :route_set
      @response_channel = opts(:response_channel) { Serf::Util::NullObject }
      @error_channel = opts(:error_channel) { Serf::Util::NullObject }
      @logger = opts(:logger) { Serf::Util::NullObject }
    end

    ##
    # Rack-like call to run a set of handlers for a message
    #
    def call(env)
      env = Hashie::Mash.new env unless env.is_a? Hashie::Mash

      # We normalize by making the request a Hashie Mash
      message = Hashie::Mash.new env.message
      context = Hashie::Mash.new env.context

      # Resolve the routes that we want to run
      routes = route_set.resolve message, context

      # We raise an error if no routes were found.
      raise Serf::Errors::NotFound unless routes.size > 0

      # For each route, we're going to execute
      results = routes.map { |route|
        # 1. Check request+context with the policies (RAISE)
        # 2. Execute command (RETURNS Hash)
        ok, res = with_error_handling(
            message: message,
            options: context) do
          route.check_policies! message, context
          route.execute! message, context
        end
        # Return the run_results as result of this block.
        res
      }.flatten.select { |r| r }
      push_results results, context
      return results
    rescue => e
      e.extend(Serf::Error)
      raise e
    end

    def self.build(*args, &block)
      new *args, &block
    end

    private

    ##
    # Loop over the results and push them to the response channel.
    # Any error in pushing individual messages will result in
    # a log event and an error channel event.
    def push_results(results, context)
      results.each do |result|
        with_error_handling(result) do
          response_channel.push(
            message: result,
            context: context)
        end
      end
      return nil
    end

  end

end
