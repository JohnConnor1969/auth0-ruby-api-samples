require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'sinatra/json'
require 'jwt'
require_relative 'jwt/json_web_token'

SCOPES = {
    '/api/private'    => nil,
    '/api/private-scoped' => ['read:messages']
}

def authenticate!
  # Extract <token> from the 'Bearer <token>' value of the Authorization header
  supplied_token = String(request.env['HTTP_AUTHORIZATION']).slice(7..-1)

  @auth_payload, @auth_header = JsonWebToken.verify(supplied_token)

  halt 403, json(error: 'Forbidden', message: 'Insufficient scope') unless scope_included

rescue JWT::DecodeError => e
  halt 401, json(error: e.class, message: e.message)
end

def scope_included
  if SCOPES[request.env['PATH_INFO']] == nil
    true
  else
    # The intersection of the scopes included in the given JWT and the ones in the SCOPES hash needed to access
    # the PATH_INFO, should contain at least one element
    (String(@auth_payload['scope']).split(' ') & (SCOPES[request.env['PATH_INFO']])).any?
  end
end

configure do
  set :bind, '0.0.0.0'
  set :port, '3010'
  set :auth0_domain,  ENV['AUTH0_DOMAIN'] || 'testdomain'
  set :auth0_api_audience,  ENV['AUTH0_API_AUDIENCE'] || 'testissuer'
end

get '/api/public' do
  json( message: 'All good. You don\'t need to be authenticated to call this.' )
end

get '/api/private' do
  authenticate!
  json( message: 'All good. You only get this message if you\'re authenticated.' )
end

get '/api/private-scoped' do
  authenticate!
  json( message: 'All good. You only get this message if you\'re authenticated and have a scope of read:messages.' )
end
