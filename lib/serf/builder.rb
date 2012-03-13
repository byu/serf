require 'serf/routing/endpoint'
require 'serf/routing/registry'
require 'serf/runners/direct'
require 'serf/serfer'
require 'serf/util/null_object'
require 'serf/util/options_extraction'

module Serf

  ##
  # A Serf Builder that processes the SerfUp DSL to build a rack-like
  # app to endpoint and process received messages. This builder is
  # implemented based on code from Rack::Builder.
  #
  #   builder = Serf::Builder.parse_file 'examples/config.su'
  #   builder.to_app
  #
  # or
  #
  #   builder = Serf::Builder.new do
  #     ... A SerfUp Config block here.
  #   end
  #   builder.to_app
  #
  class Builder
    include Serf::Util::OptionsExtraction

    def self.parse_file(config)
      cfgfile = ::File.read(config)
      builder = eval "::Serf::Builder.new {\n" + cfgfile + "\n}",
        TOPLEVEL_BINDING, config
      return builder
    end

    def initialize(*args, &block)
      extract_options! args

      # Configuration about the endpoints and apps to run.
      @use = []
      @not_found = opts :not_found, lambda { |env|
        raise ArgumentError, 'Endpoints Not Found'
      }

      # Utility and messaging channels that get passed as options
      # when building our Runners and Handlers.
      @response_channel = ::Serf::Util::NullObject.new
      @error_channel = ::Serf::Util::NullObject.new
      @logger = ::Serf::Util::NullObject.new

      # Set up the starting state for our DSL calls.
      @runner_matcher_endpoint_map = {}
      @runner_params = {}
      runner :direct
      @matcher = nil

      # configure based on a given block.
      instance_eval(&block) if block_given?
    end

    def self.app(default_app=nil, &block)
      self.new(default_app, &block).to_app
    end

    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    def not_found(app); @not_found = app; end

    def response_channel(channel); @response_channel = channel; end
    def error_channel(channel); @error_channel = channel; end
    def logger(logger); @logger = logger; end

    ##
    # DSL Method to change our current context to use the given matcher.
    #
    def match(matcher); @matcher = matcher; end

    ##
    # Mount and endpoint to the current context's Runner and Matcher.
    # Connected so the endpoint will pass serf_options to the handler's build.
    def run(*args, &block); mount true, *args, &block; end

    ##
    # Mount and endpoint to the current context's Runner and Matcher.
    # Unconnected so the endpoint will omit serf_options to the handler's build.
    def run_unconnected(*args, &block); mount false, *args, &block; end

    ##
    # The generic mount method used by run & run_unconnected to create an
    # endpoint to be associated with the current context's Runner and Matcher.
    def mount(connected, handler_factory, *args, &block)
      raise 'No matcher defined yet' unless @matcher
      @runner_matcher_endpoint_map[@runner_factory] ||= {}
      @runner_matcher_endpoint_map[@runner_factory][@matcher] ||= []
      @runner_matcher_endpoint_map[@runner_factory][@matcher] <<
        Serf::Routing::Endpoint.new(
          connected,
          handler_factory,
          *args,
          &block)
    end

    ##
    # DSL Method to change our current context to use the given runner.
    #
    def runner(type)
      @runner_factory = case type
      when :direct
        ::Serf::Runners::Direct
      when :event_machine
        begin
          require 'serf/runners/event_machine'
          Serf::Runners::EventMachine
        rescue NameError => e
          e.extend Serf::Error
          raise e
        end
      when :girl_friday
        begin
          require 'serf/runners/girl_friday'
          Serf::Runners::GirlFriday
        rescue NameError => e
          e.extend Serf::Error
          raise e
        end
      else
        raise 'No callable runner' unless type.respond_to? :build
        type
      end
    end

    def params(*args)
      @runner_params[@runner_factory] = args
    end

    ##
    # Returns a hash of our current serf infrastructure options
    # to be passed to Endpoint#build methods.
    def serf_options
      {
        response_channel: @error_channel,
        error_channel: @error_channel,
        logger: @logger
      }
    end

    ##
    # Create our app.
    #
    def to_app
      # By default, we go to the not_found app.
      app = @not_found

      registries = {}

      # Set additional options for all the mounts
      @runner_matcher_endpoint_map.each do |runner_factory, matcher_endpoints|

        # 1. Create a registry for our given hash of matchers to endpoints.
        # 2. Convert the hash of matcher to endpoints into a useable registry
        #   for lookups.
        registry = ::Serf::Routing::Registry.new
        matcher_endpoints.each do |matcher, endpoints|
          registry.add matcher, endpoints
        end

        # Ok, we'll create the runner and add it to our registries hash
        # if we actually have endpoints here.
        if registry.size > 0
          runner_params = @runner_params[runner_factory] ?
            @runner_params[runner_factory] :
            []
          runner_params << (runner_params.last.is_a?(Hash) ?
            runner_params.pop.merge(serf_options) :
            serf_options)
          runner = runner_factory.build *runner_params
          registries[runner] = registry
        end
      end

      if registries.size > 0
        app = Serf::Serfer.build(
          # The registries to match, and their runners to execute.
          registries: registries,
          # App if no endpoints were found.
          not_found: app,
          # Serf infrastructure options to pass to 'connected' Endpoints
          # to build a handler instance for each env hash received.
          serf_options: serf_options,
          # Options to use by serfer because it includes ErrorHandling.
          error_channel: @error_channel,
          logger: @logger)
      end

      # We're going to inject middleware here.
      app = @use.reverse.inject(app) { |a,e| e[a] } if @use.size > 0

      return app
    end
  end
end
