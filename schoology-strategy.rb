require 'json'

module OmniAuth
  module Strategies
    class Schoology < OmniAuth::Strategies::OAuth
      # Give your strategy a name.
      option :name, 'schoology'

      # This is where you pass the options you would pass when
      # initializing your consumer from the OAuth gem.
      option :client_options, {
                                :http_method => 'get',
                                :site => 'https://api.schoology.com/v1',
                                :authorize_url => 'https://www.schoology.com/oauth/authorize'
                              }

      # These are called after authentication has succeeded. If
      # possible, you should try to set the UID without making
      # additional calls (if the user id is returned with the token
      # or as a URI parameter). This may not be possible with all
      # providers.

      def provider
        'schoology'
      end

      uid { @uid ||= JSON.parse(access_token.get('/app-user-info').body)['api_uid'] }

      info do
        {
            :name => raw_info['name_display'],
            :email => raw_info['primary_email'],
            :image => raw_info['picture_url']
        }
      end

      credentials do
        {
            :token => access_token.token,
            :secret => access_token.secret
        }
      end

      def raw_info
        @raw_info ||= JSON.parse(access_token.get("/users/#{uid}").body)
      end
    end
  end
end