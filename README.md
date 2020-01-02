# AsyncCable

Very simple but functional websocket server for Rack async application.

* Works on Fibers via [async](https://github.com/socketry/async).
* Threadsafe
* Supports broadcasting.
* Works with [Falcon web server](https://github.com/socketry/falcon).
* Supports authorization with cookies/header.

Intended to use with [Falcon web server](https://github.com/socketry/falcon) or other web server based on.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'async_cable'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install async_cable

## Usage

```ruby
# config.ru
require_relative 'lib/main_cable' 
app = RackBuilder.new do
  use Rack::Session::Cookie, key: 'test.app', secret: ENV['RACK_SECRET']
  map '/cable' do
    run AsyncCable::Server.new(connection_class: MainCable)
  end
end
run app


# lib/main_cable.rb
class ChatCable < AsyncCable::Connection
  identified_as :main
  attr_reader :current_user

  def on_open
    @current_user = User.find_by id: request.session['user_id']
    reject_unauthorized if current_user.nil?
    stream_for request.params['room_name']
    
    logger.info { "User##{current_user.id} has joined to #{channel_name}/#{stream_name}." }
    self.class.broadcast(stream_name, message: "#{current_user.username} has joined.")
    transmit(message: "Welcome #{current_user.username}.")
  end

  def on_data(data)
    self.class.broadcast(stream_name, message: data[:message].to_s, by_who: current_user.username)
  end

  def on_close
    return if identifier.nil?

    logger.info { "User##{current_user.id} has left #{channel_name}/#{stream_name}." }
    self.class.broadcast(stream_name, message: "#{current_user.username} has left.")
  end
end
```

example of JS code for connecting with websocket server 
```js
  var socket = new WebSocket("ws://localhost:9292/cable");
  socket.onopen = function(_event) { 
    console.log("WebSocket connected"); 
  };
  socket.onerror = function(error) { 
    console.log("WebSocket error", error); 
  };
  socket.onclose = function(event) { 
    console.log("WebSocket closed", event.wasClean, event.code, event.reason);
  };
  socket.onmessage = function(event) { 
    console.log("WebSocket data received", JSON.parse(event.data)); 
  };

  var transmit = function (data) {
    socket.send( JSON.generate(data) );
  };
  var close = function (code, reason) {
    socket.close(code || 1000, reason);
  };
```

## Development

will use [Semver](https://semver.org) from version `1.0.0`

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/senid231/async_cable. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/async_cable/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AsyncCable project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/async_cable/blob/master/CODE_OF_CONDUCT.md).
