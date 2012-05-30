require 'serf/routing/route'
require 'serf/routing/route_set'
require 'serf/serfer'
require 'serf/util/null_object'
require 'serf/util/options_extraction'

module Serf

  ##
  # A Serf Builder that processes the SerfUp DSL to build a rack-like
  # app to handlers that process received messages. This builder is
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

    attr_reader :serfer_factory
    attr_reader :route_set_factory
    attr_reader :route_factory

    def self.parse_file(config)
      cfgfile = ::File.read(config)
      builder = eval "Serf::Builder.new {\n" + cfgfile + "\n}",
        TOPLEVEL_BINDING, config
      return builder
    end

    def self.app(*args, &block)
      new(*args, &block).to_app
    end

    def initialize(*args, &block)
      extract_options! args

      # Our factories
      @serfer_factory = opts :serfer_factory, Serf::Serfer
      @route_set_factory = opts :route_set_factory, Serf::Routing::RouteSet
      @route_factory = opts :route_factory, Serf::Routing::Route

      # List of middleware to be executed (non-built form)
      @use = []

      # A list of "mounted", non-built, command handlers with their
      # matcher and policies.
      @runs = []

      # List of default policies to be run (non-built form)
      @default_policies = []

      # The current matcher
      @matcher = nil

      # Current policies to be run (PRE-built)
      @policies = []

      # configure based on a given block.
      instance_eval(&block) if block_given?
    end

    ##
    # Append a policy to default policy chain. The default
    # policy chain is used by any route that does not define
    # at least one of its own policies.
    #
    # @param policy the policy factory to append
    # @param *args the arguments to pass to the factory
    # @param &block the block to pass to the factory
    def default_policy(policy, *args, &block)
      @default_policies << proc { policy.build(*args, &block) }
    end

    ##
    # Append a rack-like middleware
    #
    # @param the middleware class
    # @param *args the arguments to pass to middleware.new
    # @param &block the block to pass to middleware.new
    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    ##
    # Append a policy to the current match's policy chain.
    #
    # @param policy the policy factory to append
    # @param *args the arguments to pass to the factory
    # @param &block the block to pass to the factory
    def policy(policy, *args, &block)
      @policies << proc { policy.build(*args, &block) }
    end

    def response_channel(channel); @response_channel = channel; end
    def error_channel(channel); @error_channel = channel; end
    def logger(logger); @logger = logger; end

    ##
    # DSL Method to change our current context to use the given matcher.
    #
    def match(matcher)
      @matcher = matcher
      @policies = []
    end

    ##
    # @param command_factory the factory to invoke (in #to_app)
    # @param *args the rest of the args to pass to command_factory#build method
    # @param &block the block to pass to command_factory#build method
    def run(command_factory, *args, &block)
      raise 'No matcher defined yet' unless @matcher
      # Create a local duplicate of the matcher and policies "snapshotted"
      # at the time this method is called... so that snapshot is consistent
      # for when the proc is called.
      matcher = @matcher.dup
      policies = @policies.dup

      # This proc will be called in to_app when we actually go ahead and
      # instantiate all the objects. By this point, route_set and
      # default_policies passed to this proc will be ready, built.
      @runs << proc { |route_set, default_policies|
        route_set.add(
          matcher,
          route_factory.build(
            command: command_factory.build(*args, &block),
            policies: (policies.size > 0 ?
              policies.map{ |p| p.call } :
              default_policies)))
      }
    end

    ##
    # Create our app.
    #
    def to_app
      # Create the route_set to resolve routes
      route_set = route_set_factory.build
      # Build the default policies to be used if routes did not specify any.
      default_policies = @default_policies.map{ |p| p.call }
      # Add each route to the route_set
      for run in @runs
        run.call route_set, default_policies
      end
      # Create our serfer class
      app = serfer_factory.build(
        route_set: route_set,
        response_channel: (@response_channel || Serf::Util::NullObject.new),
        error_channel: (@error_channel || Serf::Util::NullObject.new),
        logger: (@logger || Serf::Util::NullObject.new))

      # We're going to inject middleware here.
      app = @use.reverse.inject(app) { |a,e| e[a] } if @use.size > 0

      return app
    end

  end
end
