serf
====

Serf is a library that scaffolds distributed systems that are architected using
Event-Driven Service Oriented Architecture design in combinations with
the Command Query Responsibility Separation pattern.

Philosophy
==========

The underlying idea of Serf is to define a standard Ruby code interface
that standalone gems can follow to create a business verticals services.
These gems are intended to run as standalone processes in a distributed
manner.

Fundamentally, a service creates an abstraction of:
1. Messages
2. Handlers/Commands

Messages are the representation of data, documents, etc that are
marshalled from client to service, which represents the business
level interaction of the service.

Messages may be command requests that a service must handle.
Messages may be events that a service emits.
Messages may be documents that represent state or business data.

Handlers are the code that is executed over Messages.
Handlers may process Command Messages.
Handlers may process observed Events that 3rd party services emit.

Serf App and Channels
=====================

A Serf App is a Rack-like application that accepts an ENV hash as input.
This ENV hash is simply the hash representation of a message to be processed.

The Serf App, as configured by DSL, will:
1. route the ENV to the proper Endpoint
2. The endpoint will create a handler instance.
  a. The handler's build class method will be given an ENV, which
    may be handled as fit. The Command class will help by parsing it
    into a Message object as registered by the implementing subclass.
3. Push the handler's results to a response channel.
  a. Raised errors are caught and pushed to an error channel.
  b. These channels are normally message queuing channels.
  c. We only require the channel instance to respond to the 'push'
    method and accept a message (or message hash) as the argument.
4. return the handler's results to the caller if it is blocking mode.
  a. In non-blocking mode, an MessageAcceptedEvent is returned instead
    because the message will be run by the EventMachine deferred threadpool
    by default.

Not implemented as yet:
1. Create a message queue listener or web endpoint to accept messages
  and run them through the built Serf App.
2. Message Queue channels to route responses to pub/sub locations.

Service Libraries
=================

1. Service Libraries SHOULD implement messages as just hashes with
  defined schemas (JSON Schema).
  a. Required by all messages is the 'kind' field.
  b. By default, Serf Commands will read in hashes and turn them into
    more convenient Hashie::Mash objects.
2. Serialization of the messages SHOULD BE Json or MessagePack (I hate XML).
  a. Serf Builder will create Serf Apps that expect a HASH ENV as input
3. Handlers MUST implement the 'build' class method, which
  MUST receive the ENV Hash as the first parameter, followed by supplemental
  arguments as declared in the DSL.
4. Handler methods SHOULD return zero or more messages.
  a. Raised errors are caught and pushed to error channels.
  b. Returned messages MUST be Hash based objects for Serialization.
5. Handler methods SHOULD handle catch their business logic exceptions and
  return them as specialized messages that can be forwarded down error channels.
  Uncaught exceptions that are then caught by Serf are pushed as
  generic CaughtExceptionEvents, and are harder to deal with.


Example With GirlFriday
=======================

    # Require our libraries
    require 'log4r'
    require 'json'

    require 'serf/builder'
    require 'serf/command'
    require 'serf/middleware/uuid_tagger'
    require 'serf/util/options_extraction'

    # create a simple logger for this example
    outputter = Log4r::FileOutputter.new(
      'fileOutputter',
      filename: 'log.txt')
    ['tick',
      'serf',
      'hndl',
      'resp',
      'errr'].each do |name|
      logger = Log4r::Logger.new name
      logger.outputters = outputter
    end

    # Helper class for this example to receive result or error messages
    # and pipe it into our logger.
    class MyChannel
      def initialize(logger, error=false)
        @logger = logger
        @error = error
      end
      def push(message)
        if @error
          @logger.fatal "#{message}"
        else
          @logger.debug "#{message}"
        end
      end
    end

    # my_lib/my_validator.rb
    class MyValidator

      def self.validate!(data)
        raise 'Data is nil' if data[:data].nil?
      end

    end

    # my_lib/my_overloaded_command.rb
    class MyOverloadedCommand
      include Serf::Command

      self.request_validator = MyValidator

      def initialize(*args)
        super
        raise "Constructor Error: #{opts(:name)}" if opts :raises_in_new
      end

      def call
        # Set our logger
        logger = ::Log4r::Logger['hndl']

        # Just our name to sort things out
        name = opts! :name
        logger.info "#{name}: #{request.to_json}"

        raise "Forcing Error in #{name}" if opts(:raises, false)

        # Do work Here...
        # And return 0 or more messages as result. Nil is valid response.
        return { kind: "#{name}_result", input: request.to_hash }
      end

      def inspect
        "MyOverloadedCommand: #{opts(:name,'notnamed')}, #{request.to_json}"
      end

    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # Include some middleware
      use Serf::Middleware::UuidTagger

      # Create response and error channels for the handler result messages.
      response_channel MyChannel.new(::Log4r::Logger['resp'])
      error_channel MyChannel.new(::Log4r::Logger['errr'], true)

      # We pass in a logger to our Serf code: Serfer and Runners.
      logger ::Log4r::Logger['serf']

      runner :direct

      match 'my_message'
      run MyOverloadedCommand, name: 'my_message_command'

      match 'raise_error_message'
      run MyOverloadedCommand, name: 'foreground_raises_error', raises: true
      run MyOverloadedCommand, name: 'constructor_error', raises_in_new: true

      match 'other_message'
      run MyOverloadedCommand, name: 'foreground_other_message'

      runner :girl_friday

      # This message kind is handled by multiple handlers.
      match 'other_message'
      run MyOverloadedCommand, name: 'background_other_message'
      run MyOverloadedCommand, name: 'background_raises error', raises: true

      match /^events\/.*$/
      run MyOverloadedCommand, name: 'regexp_matched_command'

      # Optionally define a not found handler...
      # Defaults to raising an ArgumentError, 'Not Found'.
      #not_found lambda {|x| puts x}
    end
    app = builder.to_app

    # Start event machine loop.
    logger = ::Log4r::Logger['tick']

    logger.info "Start Tick #{Thread.current.object_id}"

    # This will submit a 'my_message' message (as a hash) to the Serf App.
    # NOTE: We should get an error message pushed to the error channel
    #  because no 'data' field was put in my_message as required
    #  And the Result should have a CaughtExceptionEvent.
    logger.info "BEG MyMessage w/o Data"
    results = app.call 'kind' => 'my_message'
    logger.info "END MyMessage w/o Data: #{results.size} #{results.to_json}"

    # Here is good result
    logger.info "BEG MyMessage w/ Data"
    results = app.call 'kind' => 'my_message', 'data' => '1'
    logger.info "END MyMessage w/ Data: #{results.size} #{results.to_json}"

    # Here is a result that will raise an error in foreground
    # We should get two event messages in the results because we
    # mounted two commands to the raise_error_message kind.
    # Each shows errors being raised in two separate stages.
    # 1. Error in creating the instance of the command.
    # 2. Error when the command was executed by the foreground runner.
    logger.info "BEG RaisesErrorMessage"
    results = app.call 'kind' => 'raise_error_message', 'data' => '2'
    logger.info "END RaisesErrorMessage: #{results.size} #{results.to_json}"

    # This submission will be executed by THREE commands.
    #   One in the foreground, two in the background.
    #
    # The foreground results should be:
    # * MessageAcceptedEvent
    # * And return result of one command call
    #
    # The error channel should output an error from one background command.
    logger.info "BEG OtherMessage"
    results = app.call 'kind' => 'other_message', 'data' => '3'
    logger.info "END OtherMessage: #{results.size} #{results.to_json}"

    # This will match a regexp call
    logger.info "BEG Regexp"
    results = app.call 'kind' => 'events/my_event', 'data' => '4'
    logger.info "END Regexp Results: #{results.size} #{results.to_json}"

    begin
      # Here, we're going to submit a message that we don't handle.
      # By default, an exception will be raised.
      app.call 'kind' => 'unhandled_message_kind'
    rescue => e
      logger.warn "Caught in Tick: #{e.inspect}"
    end
    logger.info "End Tick #{Thread.current.object_id}"


Example With EventMachine
=========================

    # Require our libraries
    require 'log4r'
    require 'json'

    require 'serf/builder'
    require 'serf/command'
    require 'serf/middleware/uuid_tagger'
    require 'serf/util/options_extraction'

    # create a simple logger for this example
    outputter = Log4r::FileOutputter.new(
      'fileOutputter',
      filename: 'log.txt')
    ['tick',
      'serf',
      'hndl',
      'resp',
      'errr'].each do |name|
      logger = Log4r::Logger.new name
      logger.outputters = outputter
    end

    # Helper class for this example to receive result or error messages
    # and pipe it into our logger.
    class MyChannel
      def initialize(logger, error=false)
        @logger = logger
        @error = error
      end
      def push(message)
        if @error
          @logger.fatal "#{message}"
        else
          @logger.debug "#{message}"
        end
      end
    end

    # my_lib/my_message.rb
    class MyValidator

      def self.validate!(data)
        raise 'Data Missing Error' if data[:data].nil?
      end

    end

    # my_lib/my_overloaded_command.rb
    class MyOverloadedCommand
      include Serf::Command

      self.request_validator = MyValidator

      def initialize(*args)
        super
        raise "Constructor Error: #{opts(:name)}" if opts :raises_in_new
      end

      def call
        # Set our logger
        logger = ::Log4r::Logger['hndl']

        # Just our name to sort things out
        name = opts! :name
        logger.info "#{name}: #{request.to_json}"

        raise "Forcing Error in #{name}" if opts(:raises, false)

        # Do work Here...
        # And return 0 or more messages as result. Nil is valid response.
        return { kind: "#{name}_result", input: request.to_hash }
      end

      def inspect
        "MyOverloadedCommand: #{opts(:name,'notnamed')}, #{request.to_json}"
      end

    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # Include some middleware
      use Serf::Middleware::UuidTagger

      # Create response and error channels for the handler result messages.
      response_channel MyChannel.new(::Log4r::Logger['resp'])
      error_channel MyChannel.new(::Log4r::Logger['errr'], true)

      # We pass in a logger to our Serf code: Serfer and Runners.
      logger ::Log4r::Logger['serf']

      runner :direct

      match 'my_message'
      run MyOverloadedCommand, name: 'my_message_command'

      match 'raise_error_message'
      run MyOverloadedCommand, name: 'foreground_raises_error', raises: true
      run MyOverloadedCommand, name: 'constructor_error', raises_in_new: true

      match 'other_message'
      run MyOverloadedCommand, name: 'foreground_other_message'

      runner :event_machine

      # This message kind is handled by multiple handlers.
      match 'other_message'
      run MyOverloadedCommand, name: 'background_other_message'
      run MyOverloadedCommand, name: 'background_raises error', raises: true

      match /^events\/.*$/
      run MyOverloadedCommand, name: 'regexp_matched_command'

      # Optionally define a not found handler...
      # Defaults to raising an ArgumentError, 'Not Found'.
      #not_found lambda {|x| puts x}
    end
    app = builder.to_app

    # Start event machine loop.
    logger = ::Log4r::Logger['tick']
    EM.run do
      # On the next tick
      EM.next_tick do
        logger.info "Start Tick #{Thread.current.object_id}"

        # This will submit a 'my_message' message (as a hash) to the Serf App.
        # NOTE: We should get an error message pushed to the error channel
        #  because no 'data' field was put in my_message as required
        #  And the Result should have a CaughtExceptionEvent.
        logger.info "BEG MyMessage w/o Data"
        results = app.call 'kind' => 'my_message'
        logger.info "END MyMessage w/o Data: #{results.size} #{results.to_json}"

        # Here is good result
        logger.info "BEG MyMessage w/ Data"
        results = app.call 'kind' => 'my_message', 'data' => '1'
        logger.info "END MyMessage w/ Data: #{results.size} #{results.to_json}"

        # Here is a result that will raise an error in foreground
        # We should get two event messages in the results because we
        # mounted two commands to the raise_error_message kind.
        # Each shows errors being raised in two separate stages.
        # 1. Error in creating the instance of the command.
        # 2. Error when the command was executed by the foreground runner.
        logger.info "BEG RaisesErrorMessage"
        results = app.call 'kind' => 'raise_error_message', 'data' => '2'
        logger.info "END RaisesErrorMessage: #{results.size} #{results.to_json}"

        # This submission will be executed by THREE commands.
        #   One in the foreground, two in the background.
        #
        # The foreground results should be:
        # * MessageAcceptedEvent
        # * And return result of one command call
        #
        # The error channel should output an error from one background command.
        logger.info "BEG OtherMessage"
        results = app.call 'kind' => 'other_message', 'data' => '3'
        logger.info "END OtherMessage: #{results.size} #{results.to_json}"

        # This will match a regexp call
        logger.info "BEG Regexp"
        results = app.call 'kind' => 'events/my_event', 'data' => '4'
        logger.info "END Regexp Results: #{results.size} #{results.to_json}"

        begin
          # Here, we're going to submit a message that we don't handle.
          # By default, an exception will be raised.
          app.call 'kind' => 'unhandled_message_kind'
        rescue => e
          logger.warn "Caught in Tick: #{e.inspect}"
        end
        logger.info "End Tick #{Thread.current.object_id}"
      end
      EM.add_timer 2 do
        EM.stop
      end
    end


Contributing to serf
====================

* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.


Copyright
=========

Copyright (c) 2011-2012 Benjamin Yu. See LICENSE.txt for further details.

