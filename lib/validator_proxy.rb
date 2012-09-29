require 'rack/proxy'
require 'rack/request'

class ValidatorProxy < Rack::Proxy

  def call(env)
    req = Rack::Request.new env
    url = req['url']
    callback = req['callback']

    rewrite_response(perform_request(rewrite_env(env, url)), callback)
  end

  def rewrite_env(env, url)
    req = Rack::Request.new env
    m = url.match(/^(?:http:\/\/)?([^\/\:]+)(?::(\d+))?(?:(\/[^?]+)(?:\?(.+))?)?$/)

    env["HTTP_HOST"] = m[1]
    env["SERVER_PORT"] = m[2] || '80'
    env["SCRIPT_NAME"] = m[3] || ''
    env["QUERY_STRING"] = ([m[4] || ''] + req.params.reject{|k,v| ['url','callback'].include? k }.map{|k,v| "#{k}=#{v}"}).join('&')
    env
  end

  def rewrite_response(response, callback)
    response[1]['Access-Control-Allow-Origin'] = '*'

    if callback
      response[2] = ["#{callback}(#{response[2].join})"]
      response[1]['Content-Type'] = 'application/javascript'
      response[1]['Content-Length'] = response[2].bytesize.to_s
    end

    response
  end

end
