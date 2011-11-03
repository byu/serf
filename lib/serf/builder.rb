require 'rack'

module Serf

  ##
  # A Serf Builder that processes the SerfUp DSL to set up a new
  # serf server processing.
  #
  #   builder = Serf::Builder.parse_file 'examples/config.su'
  #   builder.run       # spins of daemon threads for each receiver
  #   EventMachine::run # Most likely do this because of EmRunner middleware.
  #
  # or
  #
  #   builder = Serf::Builder.new do
  #     ... A SerfUp Config block here. See the examples/config.su
  #   end
  #   builder.run
  #   EventMachine::run
  #
  class Builder
    def self.parse_file(config)
      cfgfile = ::File.read(config)
      builder = eval "::Serf::Builder.new {\n" + cfgfile + "\n}",
        TOPLEVEL_BINDING, config
      return builder
    end

    def initialize(&block)
      @already_run = false
      @groups = {}
      @receivers = []

      reset_current_group
      instance_eval(&block) if block_given?
    end

    def group(name, &block)
      raise 'Already inside group' if @current_group_name
      @current_group_name = name
      instance_eval(&block) if block_given?
      commit_current_group
      reset_current_group
    end

    def use(middleware, *args, &block)
      @use << proc { |app| middleware.new(app, *args, &block) }
    end

    def handle(kind, app=nil, &block)
      raise 'Not inside group' unless @current_group_name
      if app
        @handlers[kind.to_s] = app
      elsif block_given?
        @handlers[kind.to_s] = ::Rack::Builder.new(block).to_app
      end
    end

    def not_found(app)
      raise 'not_found already declared for this group' if @not_found
      @not_found = app
    end

    def bind(group, receiver, *args)
      app = @groups[group]
      @receivers << receiver.new(app, *args)
    end

    def run
      raise 'Already run' if @already_run
      @already_run = true
      @receivers.each do |receiver|
        Thread.new {
          receiver.run
        }
      end
    end

    private

    def reset_current_group
      @current_group_name = nil
      @not_found = nil
      @handlers = {}
      @use = []
    end

    def commit_current_group
      app = ::Serf::Middleware::KindMapper.new(
        map: @handlers,
        not_found: @not_found)
      app = @use.reverse.inject(app) { |a,e| e[a] } if @use.size > 0
      @groups[@current_group_name] = app
    end

  end

end
