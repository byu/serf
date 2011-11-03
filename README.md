serf
====

Serf is a library that scaffolds distributed systems that are architected using
Event-Driven Service Oriented Architecture design in combinations with
the Command Query Responsibility Separation pattern.

Fundamentally, serf is a server process that receives commands and
emits events. The actual business logic is set up using `Serf's Up`
configuration files similar to rackup files.

An application developer writes Handler code that knows how to
process commands and events. This handler code is wired up in the
afore mentioned serfup file.

Handler code is essentally an object that responds to 'call' as with
other Rack based applications. The primary difference is that
the 'env' passed to the Handler object is NOT rack env conformant.

The message passed to the Handler objects' call methods are a
hash, which has a `kind` keyed element whose value is the type
of command (or event). A Handler SHOULD verify that this value is
what it expects in case of misrouting due to bad serfup configuration.

The serf library provides a very basic event service bus using
Redis' pubsub capabilities. We hope to implement more advanced topologies
using ZeroMQ in the future.

View the `examples/config.su` file for an example of a serfup configuration.

Besides Handlers, we have `Receivers` that expose points of entry for
command and event messages. We implement two types:

1. RedisPubsubReceiver - For pubsub event messages.
2. MsgpackReceiver - For msgpack rpc receipt of command messages.

Middleware
==========

Serf::Middleware::EmRunner
--------------------------

The EmRunner middleware is a mechanism to take a received message
(from RedisPubsubReceiver or MsgpackReceiver) and have the subsequent
app chain to be processed in the EventMachine deferred thread pool.
This is handy for async messages that come in through the PubSub
channel. And it is helpful in the CQRS model of processing when
accepting commands through Msgpack RPC.

Serf::Middleware::CelluloidRunner
---------------------------------

`celluloid` is a soft dependency.

But this middleware functions the same as the EmRunner, but with
actors and fibers instead.

NOTE: The limitation of this is that only 1 actor will be generated
per 'use Serf::Middleware::CelluloidRunner' definition. Thus messages
to any handler within a single 'group' will be processed serially.

This might be helpful in special cases where you want non-blocking
receipt of messages but also want ordered processing based on
received messages.

Airbrake
--------

You can use Airbrake's middleware to catch exceptions.

    # example.su
    require 'rack'
    require 'airbrake'

    Airbrake.configure do |config|
      config.api_key = 'my_api_key'
    end

    group :my_commands do
      use Airbrake::Rack
      handle 'my_command', MyCommand.new
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

