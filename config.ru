require 'lib/validator_proxy.rb'

require 'rack/builder'

app = Rack::Builder.new do
  map '/proxy' do
    run ValidatorProxy.new
  end

  run lambda { |env| [200, {'Content-Type' => 'text/plain'}, 'OK'] }
end

run app
