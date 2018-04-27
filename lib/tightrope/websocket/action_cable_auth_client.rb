require 'http'

module Tightrope
  module WebSocket
    class ActionCableAuthClient < ::Tightrope::WebSocket::ActionCableClient
      def self.connect(args)
        local_args = prepare_args(args)
        uri = URI.parse(local_args[:uri])

        host = uri.host
        port = uri.port

        if args[:auth_uri]
          auth_uri = URI.parse(local_args[:auth_uri])
          host = auth_uri.host
          port = auth_uri.port
          local_args[:ssl] = true if auth_uri.scheme == 'https'
        else
          auth_path = local_args[:auth_path].sub(/^\//, '') if local_args[:auth_path]
          local_args[:auth_uri] = (args[:ssl] ? 'https' : 'http') + "://#{host}"
          local_args[:auth_uri] << ":#{port}" if port
          local_args[:auth_uri] << "/#{auth_path}" if auth_path
        end

        local_args.delete(:auth_path)

        check_arg(local_args, :user)
        check_arg(local_args, :password)
        local_args[:headers] = login(local_args)

        super(local_args)
      end

      def self.login(args)
        res = HTTP.post(args[:auth_uri], json: {email: args[:user], password: args[:password]})
        raise Tightrope::LoginError.new("Login failed for user #{args[:user]}") if res.code != 200

        {'access-token' => res.headers['access-token'],
         'expiry'       => res.headers['expiry'],
         'uid'          => res.headers['uid'],
         'client'       => res.headers['client'],
         'token-type'   => 'Bearer'}
      end

      def self.check_arg(args, key)
        raise ArgumentError.new("Argument ':#{key.to_s}' is missing") unless args[key]
      end
    end
  end
end
