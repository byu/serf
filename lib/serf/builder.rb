require 'serf/serfer'
require 'serf/runners/direct_runner'
require 'serf/runners/em_runner'
require 'serf/util/null_object'
require 'serf/util/route_set'

module Serf

  ##
  # A Serf Builder that processes the SerfUp DSL to build a rack-like
  # app to route and process received messages. This builder is
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
    def self.parse_file(config)
      cfgfile = ::File.read(config)
      builder = eval "::Serf::Builder.new {\n" + cfgfile + "\n}",
        TOPLEVEL_BINDING, config
      return builder
    end

    def initialize(app=nil, &block)
      # Configuration about the routes and apps to run.
      @use = []
      @route_maps = []
      @handlers = {}
      @message_parsers = {}
      @not_found = app || proc do
        raise ArgumentError, 'Handler Not Found'
      end

      # Default option in route_configs for background is 'false'
      @background = false

      # Factories to build objects that wire our Serf App together.
      # Note that these default implementing classes are also factories
      # of their own objects (i.e. - define a 'build' class method).
      @serfer_factory = ::Serf::Serfer
      @foreground_runner_factory = ::Serf::Runners::DirectRunner
      @background_runner_factory = ::Serf::Runners::EmRunner
      @route_set_factory = ::Serf::Util::RouteSet

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

    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    def routes(route_map)
      @route_maps << route_map
    end

    def handler(handler_name, handler)
      @handlers[handler_name] = handler
    end

    def message_parser(message_parser_name, message_parser)
      @message_parsers[message_parser_name] = message_parser
    end

    def not_found(app)
      @not_found = app
    end

    def background(run_in_background)
      @background = run_in_background
    end

    def serfer_factory(serfer_factory)
      @serfer_factory = serfer_factory
    end

    def foreground_runner_factory(foreground_runner_factory)
      @foreground_runner_factory = foreground_runner_factory
    end

    def background_runner_factory(background_runner_factory)
      @background_runner_factory = background_runner_factory
    end

    def route_set_factory(route_set_factory)
      @route_set_factory = route_set_factory
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
      bg_route_set = @route_set_factory.build
      fg_route_set = @route_set_factory.build

      @route_maps.each do |route_map|
        route_map.each do |matcher, route_configs|
          route_configs_iterator(route_configs).each do |route_config|
            # If the passed in route_config was a String, then we place
            # it in an route config as the 'target' field and leave all
            # other options as default.
            config = (route_config.is_a?(String) ?
              { target: route_config } :
              route_config)

            # Get the required handler.
            # Raises error if handler wasn't declared in config.
            target = config.fetch :target
            handler_name, action = handler_and_action target

            # Raises error if handler wasn't registered with builder.
            handler = @handlers.fetch handler_name

            # Lookup the parser if it was defined.
            # The Parser MAY be either an object or string.
            # If String, then we're going to look up in parser map.
            # Raises an error if a parser (string) was declared, but not
            # registered with the builder.
            parser = config[:message_parser]
            parser = @message_parsers.fetch(parser) if parser.is_a?(String)

            # We have the handler, action and parser.
            # Now we're going to add that route to either the background
            # or foreground route_set.
            background = config.fetch(:background) { @background }
            (background ? bg_route_set : fg_route_set).add_route(
              matcher: matcher,
              handler: handler,
              action: action,
              message_parser: parser)
          end
        end
      end

      # Get or make our foreground runner
      fg_runner = @foreground_runner_factory.build(
        results_channel: @results_channel,
        error_channel: @error_channel,
        logger: @logger)

      # Get or make our background runner
      bg_runner = @background_runner_factory.build(
        results_channel: @results_channel,
        error_channel: @error_channel,
        logger: @logger)

      # We create the route_sets dependent on built routes.
      route_sets = {}
      if fg_route_set.size > 0
        route_sets[fg_route_set] = fg_runner
      end
      if bg_route_set.size > 0
        route_sets[bg_route_set] = bg_runner
      end

      # By default, we go to the not_found app.
      app = @not_found

      # But if we have routes, then we'll build a serfer to handle it.
      if route_sets.size > 0
        app = @serfer_factory.build(
          route_sets: route_sets,
          not_found: app,
          error_channel: @error_channel,
          logger: @logger)
      end

      # We're going to inject middleware here.
      app = @use.reverse.inject(app) { |a,e| e[a] } if @use.size > 0

      return app
    end

    private

    ##
    # This handles route_configs that are Array, Hash or String.
    # We want to create a proper iterator to run over the route_configs.
    def route_configs_iterator(route_configs)
      case route_configs
      when String
        return Array(route_configs)
      when Hash
        return [route_configs]
      else
        return route_configs
      end
    end

    ##
    # Extracts the handler_name and action from the 'target' using
    # the shortcut convention similar to Rails routing.
    #
    #   'my_handler#my_method' => # my_method action.
    #   'my_handler#' => # action defaults to 'call' method.
    #   'my_handler'  => # action defaults to 'call' method.
    #   '#my_method'  => # some registered handler name with empty string.
    #
    # @param [String] target the handler and action description.
    # @return the splat handler and action.
    #
    def handler_and_action(target)
      handler, action = target.split '#', 2
      handler = handler.to_s.strip
      action = action.to_s.strip
      action = :call if action.size == 0
      return handler, action
    end
  end

end
