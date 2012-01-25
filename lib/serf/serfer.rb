require 'serf/error'
require 'serf/util/with_error_handling'

module Serf

  class Serfer
    include ::Serf::Util::WithErrorHandling

    def initialize(options={})
      # Each route_set has a runner.
      @route_sets = options[:route_sets] || {}

      # Optional overrides for WithErrorHandling
      @error_channel = options[:error_channel]
      @error_event_class = options[:error_event_class]
      @logger = options[:logger]

      # Options for handling the requests
      @not_found = options[:not_found] || proc do
        raise ArgumentError, 'Handler Not Found'
      end
    end

    ##
    # Rack-like call to run set of handlers for a message
    #
    def call(env)
      # We normalize by symbolizing the env keys
      env = env.symbolize_keys

      # We're going to concat all the results
      matched_routes = false
      results = []
      @route_sets.each do |route_set, runner|
        with_error_handling(env) do
          endpoints = route_set.match_routes env
          if endpoints.size > 0
            matched_routes = true
            results.concat Array(runner.run(endpoints, env))
          end
        end
      end

      # If we don't have any handlers, do the not_found call.
      # NOTE: Purposefully not wrapping this in exception handling.
      return @not_found.call env unless matched_routes

      return results
    rescue => e
      e.extend(::Serf::Error)
      raise e
    end

    def self.build(options={})
      self.new options
    end

  end

end
