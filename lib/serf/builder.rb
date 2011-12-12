require 'serf/serfer'

module Serf

  ##
  # A Serf Builder that processes the SerfUp DSL to build a rack-like
  # app to route and process received messages. This builder is
  # implemented with lots of code from Rack::Builder.
  #
  #   builder = Serf::Builder.parse_file 'examples/config.su'
  #   builder.to_app
  #
  # or
  #
  #   builder = Serf::Builder.new do
  #     ... A SerfUp Config block here. See the examples/config.su
  #   end
  #   builder.to_app
  #
  class Builder
    def self.parse_file(config)
      cfgfile = ::File.read(config)
      builder = eval "::Serf::Builder.new {\n" + cfgfile + "\n}",
        TOPLEVEL_BINDING, config
      return builder
    end

    def initialize(options={}, &block)
      @use = []
      @manifest = {}
      @config = {}
      @not_found = options[:not_found]
      @serfer_class = options.fetch(:serfer_class) { ::Serf::Serfer }
      @serfer_options = options[:serfer_options] || {}
      instance_eval(&block) if block_given?
    end

    def self.app(default_app=nil, &block)
      self.new(default_app, &block).to_app
    end

    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    def register(manifest)
      @manifest.merge! manifest
    end

    def config(handler, *args, &block)
      @config[handler] = [args, block]
    end

    def not_found(app)
      @not_found = app
    end

    def to_app
      app = generate_routes
      return @use.reverse.inject(app) { |a,e| e[a] }
    end

    private

    def generate_routes
      kinds = {}
      handlers = {}
      async_handlers = {}

      @manifest.each do |kind, options|
        # Instantiate our handler with any possible configuration.
        handler_str = options.fetch(:handler)
        handler_class = handler_str.camelize.constantize
        args, block = @config.fetch(handler_str) { [[], nil] }
        handler = handler_class.new *args, &block

        # Then put it into the proper map of handlers for either
        # synchronous or asynchronous processing.
        async = options.fetch(:async) { true }
        (async ? async_handlers : handlers)[kind] = handler

        # Get the implementing message serialization class.
        # For a given message kind, we may have a different (or nil)
        # implementing class. If nil, then we're not going to try to
        # create a message class to validate before passing to handler.
        message_class = options.fetch(:message_class) { kind }
        kinds[kind] = message_class && message_class.camelize.constantize
      end

      # We create the serfer class to handle all the messages.
      return @serfer_class.new(
        @serfer_options.merge(
          kinds: kinds,
          handlers: handlers,
          async_handlers: async_handlers,
          not_found: @not_found))
    end

  end

end
