require 'active_support/core_ext/hash/keys'

require 'serf/error'
require 'serf/util/with_error_handling'

module Serf

  class Serfer
    include ::Serf::Util::WithErrorHandling

    def initialize(*args)
      extract_options! args

      # Map of Runners to Registries
      @registries = opts :registries, {}

      # Additional serf infrastructure options to pass to Endpoints#build.
      @serf_options = opts :serf_options, {}

      # Options for handling the requests
      @not_found = opts :not_found, lambda { |env|
        raise ArgumentError, 'Handler Not Found'
      }
    end

    ##
    # Rack-like call to run a set of handlers for a message
    #
    def call(env)
      # We normalize by symbolizing the env keys
      env = env.symbolize_keys

      # Call the processor
      matched, results = process_request env

      # If we don't have any handlers, do the not_found call.
      # NOTE: Purposefully not wrapping this in exception handling.
      return @not_found.call env unless matched > 0

      return results
    rescue => e
      e.extend(::Serf::Error)
      raise e
    end

    def self.build(options={})
      self.new options
    end

    protected

    ##
    # Do the work of processing the env.
    # 1. Match our endpoints to run, keep associated with their runner.
    # 2. Turn endpoints into actual handlers that can be called by runners.
    # 3. Call runner to process the endpoints
    # 4. Return results
    #
    # NOTES:
    # * Any error in matching will be raised to the caller, not absorbed by
    #   the error handler.
    # * Any error in Handler creation from endpoint will be caught by the
    #   error handler, (1) pushed to the error channel and (2)
    #   an error event will included in the results pass back to caller.
    #   (a) There may be successul handlers created that can complete.
    # * If the runner raises an error, it will be caught and the error
    #   event will be appended to the results. This is so one
    #   runner failure will not affect another runner's run.
    #   Each runner SHOULD do their own error handling so errors in
    #   one handler will not affect another in the list of handlers the runner
    #   is to process.
    # * RUNNERS MUST push errors they catch to the error channel.
    #
    def process_request(env)
      # This will be the work we need to do.
      # This is a hash of runners to handlers to run.
      tasks = {}

      # We're going to concat all the results
      results = []

      # Figure out which endpoints to run.
      matches = match_endpoints env

      # Now we go head and create our Tasks (Units of Work)
      # for each of the matched endpoints (with their runners).
      matches.each do |runner, endpoints|
        # We create the unit of work
        handlers = endpoints.map{ |endpoint|
          # We try to build the endpoint. Any errors here will
          # be caught and returned to the caller.
          # This is so individual building of tasks do not affect other tasks.
          ok, obj = with_error_handling(env) do
            endpoint.build env.dup, @serf_options
          end
          # The return of this if/else statement will be result of map item.
          if ok
            obj
          else
            results << obj
            nil
          end
        }.
        select{ |h| !h.nil? }

        # No we enqueue the units of work into our task queue
        # List could be empty because all build calls could have error out.
        tasks[runner] = handlers if handlers.size > 0
      end

      # We call the runners with the handlers they need to execute.
      # Errors raised by the runner are pushed to the error channel.
      # Errors here are also passed back the caller of the SerfApp.
      #
      tasks.each do |runner, handlers|
        ok, run_result = with_error_handling(env) do
          runner.call handlers, env
        end
        # We need to coerce the runner's results (nil, Hash, Array, Object)
        # into an Array of messages.
        # now we concat this run's results to our total results list.
        run_result = run_result.is_a?(Hash) ? [run_result] : Array(run_result)
        results.concat run_result
      end

      return matches.size, results
    end

    ##
    # Figure out which endpoints to run
    #
    def match_endpoints(env)
      matches = {}

      @registries.each do |runner, registry|
        endpoints = registry.match env
        matches[runner] = endpoints if endpoints.size > 0
      end

      return matches
    end

  end

end
