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
2. Handlers

Messages are the representation of data, documents, etc that are
marshalled from client to service, which represents the business
level interaction of the service.

Messages may be commands that a service must handle.
Messages may be events that a service emits.
Messages may be documents that represent state or business data.

Handlers are the code that is executed over Messages.
Handlers may process Command Messages.
Handlers may process observed Events that 3rd party services emit.

Services SHOULD declare a manifest to map messages to handlers, which
allows Serf to route messages and to determine blocking or non-blocking modes.

Serf App and Channels
=====================

A Serf App is a Rack-like application that accepts an ENV hash as input.
This ENV hash is simply the hash representation of a message to be processed.
The Serf App, as configured by registered manifests, will:
1. validate the message
2. route the message to the proper handler
3. run the handler in blocking or non-blocking mode.
4. publish the handler's results to results or error channels.
  a. These channels are normally message queuing channels.
  b. We only require the channel instance to respond to the 'publish'
    method and accept a message (or message hash) as the argument.
5. return the handler's results to the caller if it is blocking mode.
  a. In non-blocking mode, an MessageAcceptedEvent is returned instead
    because the message will be run by the EventMachine deferred threadpool
    by default.

Not implemented as yet:
1. Create a message queue listener or web endpoint to accept messages
  and run them through the built Serf App.
2. Message Queue channels to route responses to pub/sub locations.

Service Libraries
=================

1. Service Libraries SHOULD implement message classes that include the
  ::Serf::Message helper module.
  a. Barring that, they should conform to the idea that messages may be
    hashes that define at least one attribute: 'kind'.
2. Serialization of the messages SHOULD BE Json or MessagePack (I hate XML).
3. Service Libraries SHOULD implement handler classes that include the
  ::Serf::Handler helper module.
4. Handler methods MUST receive a message as an options hash, symbolized keys.
5. Handler methods MUST return zero or more messages.
6. Handler methods SHOULD handle catch their business logic exceptions and
  return them as specialized messages that can be forwarded down error channels.
  Uncaught exceptions that are then caught by Serf are published as
  generic Serf::CaughtExceptionEvents, and are harder to deal with.

Example
=======

    # Require our libraries
    require 'log4r'
    require 'serf/handler'
    require 'serf/message'
    require 'serf/builder'

    # create a simple logger for this example
    logger = Log4r::Logger.new 'my_logger'
    logger.outputters = Log4r::FileOutputter.new(
      'fileOutputter',
      filename: 'log.txt')

    # my_lib/my_handler.rb
    class MyHandler
      include Serf::Handler

      receives(
        'my_message',
        with: :submit_my_message)

      def initialize(options={})
        @logger = options[:logger]
      end

      def submit_my_message(message={})
        @logger.info "In Submit Match Result: #{message.inspect.to_s}"
        # Do work Here...
        # And return other messages as results of work, or nil for nothing.
        return nil
      end

    end

    # my_lib/my_message.rb
    class MyMessage
      include Serf::Message

      attr_accessor :data

      validates_presence_of :data

      def initialize(options={})
        @hi = options[:data] || 'some data here'
      end

    end

    # my_lib/manifest.rb
    MANIFEST = {
      'my_message' => {
        # Optional Definition of an implementation class.
        #message_class => 'other_name_space/my_other_message_implementation',
        # Declares which handler
        handler: 'my_handler',
        # Default is true to process in background.
        async: true
      }
    }

    # Helper class for this example to receive result or error messages
    # and pipe it into our logger.
    class MyChannel
      def initialize(name, logger)
        @name = name
        @logger = logger
      end
      def publish(message)
        @logger.info "#{@name} #{message}"
        #@logger.info message
      end
    end

    # Create a new builder for this serf app.
    builder = Serf::Builder.new do
      # Registers different service libary manifests.
      register MANIFEST
      # Can define arguments to pass to the 'my_handler' initialize method.
      config(
        'my_handler',
        logger: logger)
      # Create result and error channels for the handler result messages.
      error_channel MyChannel.new('errorchannel: ', logger)
      results_channel MyChannel.new('resultschannel: ', logger)
      # We pass in a logger to our Serf code: Serfer and Runners.
      logger logger
      # Optionally define a not found handler...
      # Defaults to raising an ArgumentError, 'Not Found'.
      #not_found lambda {|x| puts x}
    end
    app = builder.to_app

    # Start event machine loop.
    EM.run do
      # On the next tick
      EM.next_tick do
        logger.info "Start Tick #{Thread.current.object_id}"
        # This will submit a 'my_message' message (as a hash) to the Serf App.
        results = app.call('kind' => 'my_message')
        # Because we declared the 'my_message' kind to be handled async, we
        # should get a MessageAcceptedEvent as the results.
        logger.info "In Tick Results: #{results.inspect}"
        begin
          # Here, we're going to submit a message that we don't handle.
          # By default, an exception will be raised.
          app.call('kind' => 'unhandled_message_kind')
        rescue => e
          puts "Caught in Tick: #{e.inspect}"
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

Copyright (c) 2011 Benjamin Yu. See LICENSE.txt for further details.

