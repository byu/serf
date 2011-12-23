require 'serf/error'

module Serf

  class Serfer

    def initialize(options={})
      # Manditory, needs a runner.
      @runner = options.fetch(:runner)

      # Options for handling the requests
      @kinds = options[:kinds] || {}
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
      handler = @handlers[kind]
      if handler
        # Do a message_class validation if we have it listed.
        # And use the message attributes instead of raw env when passing
        # to message handler.
        message_class = @kinds[kind]
        if message_class
          message = message_class.parse params
          unless message.valid?
            raise ArgumentError, message.errors.full_messages.join('. ')
          end
          params = message.attributes.symbolize_keys
        end

        # Let's run the handler
        return @runner.run(handler, params) if handler
      else
        # we can't handle this kind.
        return @not_found.call env
      end
    rescue => e
      e.extend(::Serf::Error)
      raise e
    end
  end

end
