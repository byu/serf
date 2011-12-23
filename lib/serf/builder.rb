require 'serf/serfer'
require 'serf/runners/direct_runner'
require 'serf/runners/em_runner'
require 'serf/util/null_object'

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

    def initialize(app=nil, &block)
      # Configuration about the routes and apps to run.
      @manifest = {}
      @config = {}
      @not_found = app

      # Implementing classes of our app
      # NOTE: runner_class and async_runner_class are only used if actual
      #   runner instances are omitted in the configuration.
      @serfer_class = ::Serf::Serfer
      @serfer_options = {}
      @runner_class = ::Serf::Runners::DirectRunner
      @async_runner_class = ::Serf::Runners::EmRunner

      # Utility and messaging channels for our Runners
      # NOTE: these are only used if the builder needs to instantiage runners.
      @results_channel = ::Serf::Util::NullObject.new
      @error_channel = ::Serf::Util::NullObject.new
      @logger = ::Serf::Util::NullObject.new

      # configure based on a given block.
      instance_eval(&block) if block_given?
    end

    def self.app(default_app=nil, &block)
      self.new(default_app, &block).to_app
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

    def serfer_class(serfer_class)
      @serfer_class = serfer_class
    end

    def serfer_class(serfer_options)
      @serfer_options = serfer_options
    end

    def runner(runner)
      @runner = runner
    end

    def async_runner(runner)
      @async_runner = runner
    end

    def results_channel(results_channel)
      @results_channel = results_channel
    end

    def error_channel(error_channel)
      @error_channel = error_channel
    end

    def logger(logger)
      @logger = logger
    end

    def to_app
      # Our async and sync messages & handlers.
      kinds = {}
      handlers = {}
      async_kinds = {}
      async_handlers = {}

      # Iterate our manifests to build out handlers and message classes
      @manifest.each do |kind, options|
        # Instantiate our handler with any possible configuration.
        handler_str = options.fetch(:handler)
        handler_class = handler_str.camelize.constantize
        args, block = @config.fetch(handler_str) { [[], nil] }
        handler = handler_class.new *args, &block

        # Get the implementing message serialization class.
        # For a given message kind, we may have a different (or nil)
        # implementing class. If nil, then we're not going to try to
        # create a message class to validate before passing to handler.
        message_class = options.fetch(:message_class) { kind }
        message_class = message_class && message_class.camelize.constantize

        # Put handlers and kinds into the proper map of handlers for either
        # synchronous or asynchronous processing.
        async = options.fetch(:async) { true }
        if async
          async_kinds[kind] = message_class if message_class
          async_handlers[kind] = handler
        else
          kinds[kind] = message_class if message_class
          handlers[kind] = handler
        end
      end

      # Get or make our runner
      runner = @runner || @runner_class.new(
        results_channel: @results_channel,
        error_channel: @error_channel,
        logger: @logger)

      # By default, we go to the not_found app.
      app = @not_found

      # If we have synchronous handlers, insert before not_found app.
      if handlers.size > 0
        # create the serfer class to run synchronous handlers
        app = @serfer_class.new(
          @serfer_options.merge(
            kinds: kinds,
            handlers: handlers,
            runner: runner,
            not_found: app))
      end

      # If we have async handlers, insert before current app stack.
      if async_handlers.size > 0
        # Get or make our async wrapper
        async_runner = @async_runner || @async_runner_class.new(
          runner: runner,
          logger: @logger)
        # create the serfer class to run async handlers
        app = @serfer_class.new(
          @serfer_options.merge(
            kinds: async_kinds,
            handlers: async_handlers,
            runner: async_runner,
            not_found: app))
      end

      return app
    end
  end

end
