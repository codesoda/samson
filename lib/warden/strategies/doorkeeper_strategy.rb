# frozen_string_literal: true
require "warden/strategies/doorkeeper"

# Strategy that allows login via OAuth baerer token
class Warden::Strategies::Doorkeeper < ::Warden::Strategies::Base
  KEY = :doorkeeper

  def valid?
    request.authorization.to_s.start_with?("Bearer ")
  end

  def authenticate!
    if !request.path.start_with?('/api/')
      custom! [400, {}, ["Only api can be used with OAuth tokens"]]
    else
      token = ::Doorkeeper::OAuth::Token.authenticate(request, :from_bearer_authorization)
      requested_scope = request.env.fetch('requested_oauth_scope')

      if !token
        halt_json "Unable to find OAuth token"
      elsif !token.accessible?
        halt_json "OAuth token is expired"
      elsif !token.scopes.acceptable?('default') && !token.acceptable?(requested_scope)
        halt_json "OAuth token does not have scope #{requested_scope}"
      elsif !(user = User.find_by_id(token.resource_owner_id))
        halt_json "OAuth token belongs to deleted user #{token.resource_owner_id}"
      else
        request.session_options[:skip] = true # do not store user in session
        success! user
      end
    end
  end

  private

  def request
    ActionDispatch::Request.new(super.env)
  end

  def halt_json(message)
    custom! [400, {'Content-Type': 'application/json'}, [message]]
  end
end

Warden::Strategies.add(Warden::Strategies::Doorkeeper::KEY, Warden::Strategies::Doorkeeper)
