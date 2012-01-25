require 'serf/util/route_endpoint'
require 'serf/util/regexp_matcher'

module Serf
module Util

  ##
  # RouteSets hold routing information for ENV hashes to matched endpoints.
  #
  class RouteSet

    def initialize(options={})
      @routes = {}
      @matchers = []
      @regexp_matcher_factory = options.fetch(:regexp_matcher_factory) {
        ::Serf::Util::RegexpMatcher
      }
      @route_endpoint_factory = options.fetch(:route_endpoint_factory) {
        ::Serf::Util::RouteEndpoint
      }
    end

    ##
    # Connects a matcher (String or an Object implementing ===) to an endpoint.
    #
    # @option opts [Obj, String] :matcher Matches ENV Hashes to endpoints.
    #   Note that String and Regexp values are set up to match the
    #   :kind key from ENV Hashes.
    # @option opts [Obj] :handler Receiver of the action.
    # @option opts [Symbol, String] :action Method to call on handler.
    # @option opts [#parse] :message_parser Translates ENV Hash to Message Obj.
    #
    def add_route(options={})
      # We create our endpoint representation.
      endpoint = @route_endpoint_factory.build(
        handler: options.fetch(:handler),
        action: options.fetch(:action),
        message_parser: options[:message_parser])

      # Maybe we have an non-String matcher. Handle the Regexp case.
      # We only keep track of matchers if it isn't a string because
      # string matchers are just pulled out of routes by key lookup.
      matcher = options.fetch :matcher
      matcher = @regexp_matcher_factory.build matcher if matcher.kind_of? Regexp
      @matchers << matcher unless matcher.is_a? String

      # We add the route (matcher+endpoint) into our routes
      @routes[matcher] ||= []
      @routes[matcher] << endpoint
    end

    ##
    # @param [Hash] env The input message environment to match for routes.
    # @return [Array] List of endpoints that matched.
    #
    def match_routes(env={})
      kind = env[:kind]
      routes = []
      routes.concat Array(@routes[kind])
      @matchers.each do |matcher|
        routes.concat Array(@routes[matcher]) if matcher === env
      end
      return routes
    end

    ##
    # @return [Integer] Number of routes this RouteSet tracks.
    #
    def size
      return @routes.size
    end

    ##
    # Default factory method.
    #
    def self.build(options={})
      self.new options
    end
  end

end
end
