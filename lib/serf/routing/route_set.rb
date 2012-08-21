require 'serf/routing/regexp_matcher'
require 'serf/util/options_extraction'

module Serf
module Routing

  ##
  # RouteSet resolves a list of matched routes to execute based on
  # criteria from associated 'matcher' objects.
  #
  class RouteSet
    include Serf::Util::OptionsExtraction

    attr_reader :routes
    attr_reader :matchers
    attr_reader :regexp_matcher_factory

    def initialize(*args, &block)
      extract_options! args
      @routes = {}
      @matchers = []
      @regexp_matcher_factory = opts(
        :regexp_matcher_factory,
        ::Serf::Routing::RegexpMatcher)
    end

    ##
    # Connects a matcher (String or an Object implementing ===) to routes.
    #
    def add(matcher, route)
      # Maybe we have an non-String matcher. Handle the Regexp case.
      # We only keep track of matchers if it isn't a string because
      # string matchers are just pulled out of routes by key lookup.
      matcher = regexp_matcher_factory.build matcher if matcher.kind_of? Regexp
      matchers << matcher unless matcher.is_a? String

      # We add the (matcher+routes) into our routes
      routes[matcher] ||= []
      routes[matcher].push route
    end

    ##
    # @param [Hash] message The input message to match for routes.
    # @return [Array] List of routes that matched.
    #
    def resolve(headers, message)
      resolved_routes = []
      resolved_routes.concat routes.fetch(message[:kind]) { [] }
      matchers.each do |matcher|
        resolved_routes.concat routes[matcher] if matcher === message
      end
      return resolved_routes
    end

    ##
    # Default factory method.
    #
    def self.build(*args, &block)
      new *args, &block
    end
  end

end
end
