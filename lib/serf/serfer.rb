require 'eventmachine'

require 'serf/util/null_object'

module Serf

  ##
  # The Serfer is a rack app endpoint that:
  class Serfer

    def initialize(options={})
      # Options for handling the requests
      @kinds = options[:kinds] || {}
      @handlers = options[:handlers] || {}
      @async_handlers = options[:async_handlers] || {}
      @not_found = options[:not_found]

      # Other processing aspects
      @em = options.fetch(:event_machine) { ::EM }
      @logger = options.fetch(:logger) { ::Serf::Util::NullObject.new }
    end

    ##
    # Rack-like call to handle a message
    #
    def call(env)
      kind = env['kind']

      # Do a message_class validation if we have it listed.
      # And use the message attributes instead of raw env when passing
      # to message handler.
      message_class = @kinds[kind]
      if message_class
        message = message_class.new env
        raise message.errors.full_messages.join('. ') unless message.valid?
        params = message.attributes
      else
        params = env.stringify_keys
      end

      # Run an asynchronous handler if we have it. 
      handler = @async_handlers[kind]
      if handler
        @em.defer(proc do
          begin
            handler.call params
          rescue => e
            @logger.error e
          end
        end)
        return [
          202,
          {
            'Content-Type' => 'text/plain'
          },
          ['Accepted']
        ]
      end

      # Run a synchronous handler if we have it. 
      handler = @handlers[kind]
      return handler.call(params) if handler

      # run a not found
      return @not_found.call(params) if @not_found

      # we can't handle this kind.
      return [
        404,
        {
          'Content-Type' => 'text/plain',
          'X-Cascade' => 'pass'
        },
        ['Not Found']
      ]
    end
  end
end
