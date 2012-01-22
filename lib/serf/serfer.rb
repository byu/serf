require 'serf/error'
require 'serf/util/with_error_handling'

module Serf

  class Serfer
    include ::Serf::Util::WithErrorHandling

    def initialize(options={})
      # Manditory, needs a runner.
      @runner = options.fetch(:runner)

      # Optional overrides for WithErrorHandling
      @error_channel = options[:error_channel]
      @error_event_class = options[:error_event_class]
      @logger = options[:logger]

      # Options for handling the requests
      @handlers = options[:handlers] || {}
      @not_found = options[:not_found] || proc do
        raise ArgumentError, 'Handler Not Found'
      end
    end

    ##
    # Rack-like call to handle a message
    #
    def call(env)
      # We normalize by symbolizing the env keys
      params = env.symbolize_keys

      # Pull the kind out of the env.
      kind = params[:kind]
      handlers = Array(@handlers[kind])

      # If we don't have any handlers, do the not_found call.
      # NOTE: Purposefully not wrapping this in exception handling.
      @not_found.call env if handlers.size == 0

      # We're going to run each handler via runner.
      results = []
      handlers.each do |handler|
        results.concat Array(with_error_handling(params) do
          @runner.run(handler, params)
        end)
      end
      return results
    rescue => e
      e.extend(::Serf::Error)
      raise e
    end
  end

end
