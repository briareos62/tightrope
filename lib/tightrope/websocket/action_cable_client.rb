require 'cgi'
require 'json'

module Tightrope
  module WebSocket
    class ActionCableClient < Tightrope::WebSocket::FilterClient
      attr_reader :channel

      def initialize(args)
        @channel = args[:channel] if args[:channel]
        @channel_subscribed = false
        super(args)
      end

      def channel_subscribed?
        @channel_subscribed
      end

      # Connect to an ActionCable websocket server
      # @param args [Hash] The request arguments
      # @option args [String] :host The host IP/DNS name
      # @option args [Integer] :port The port to connect too(default = 80)
      # @option args [String] :uri Full URI for server(optional - use instead of host/port combination)
      # @option args [Integer] :version Version of protocol to use(default = 13)
      # @option args [Hash] :headers HTTP headers to use in the handshake
      # @option args [Boolean] :ssl Force SSL/TLS connection
      def self.connect(args = {})
        super(prepare_args(args))
      end

      def self.prepare_args(args = {})
        host = nil
        port = nil
        cable_path = nil
        query = nil

        if args[:uri]
          uri = URI.parse(args[:uri])
          host = uri.host
          port = uri.port
          args[:ssl] = true if uri.scheme == 'wss'
        else
          host = args[:host] if args[:host]
          port = args[:port] if args[:port]
          cable_path = args[:cable_path].sub(/^\//, '') if args[:cable_path]

          args[:uri] = (args[:ssl] ? 'wss' : 'ws') + '://' + host
          args[:uri] << ":#{port}" if port
          args[:uri] << "/#{cable_path}" if cable_path
          if args[:query]
            args[:uri] << '?'
            args[:query].each {|k,v| args[:uri] << ::CGI::escape(k.to_s) + '=' + ::CGI::escape(v.to_s) + '&'}
            args[:uri].sub!(/&$/, '')
          end

          [:host, :port, :cable_path, :query].each {|k| args.delete(k) }
        end

        args
      end

      def subscribe_to_channel(channel = nil, options = {})
        if channel_subscribed?
          error(__method__, Tightrope::ERROR_CHANNEL_ALREADY_SUBSCRIBED)
          return false
        end

        if @channel.nil? && channel.nil?
          error(__method__, Tightrope::ERROR_PARAM_CHANNEL_MISSING)
          return false
        end

        if @channel && channel && @channel != channel
          error(__method__, Tightrope::ERROR_PARAM_CHANNEL_NOT_UNIQUE)
          return false
        end

        @channel = channel if @channel.nil? && channel

        send_message(command: 'subscribe', channel: @channel, opts: options)
      end

      def send_message(options = {})
        channel = options[:channel]
        unless channel
          error(__method__, Tightrope::ERROR_PARAM_CHANNEL_MISSING)
          return false
        end

        identifier = {channel: channel}
        identifier.merge!(options[:opts]) if options[:opts]
        msg = {command: options[:command] || 'message', identifier: identifier.to_json}

        if options[:message] || options[:action]
          unless options[:message]
            error(__method__, Tightrope::ERROR_PARAM_MESSAGE_MISSING)
            return false
          end
          unless options[:action]
            error(__method__, Tightrope::ERROR_PARAM_ACTION_MISSING)
            return false
          end
          msg[:data] = {message: options[:message], action: options[:action]}.to_json
        end

        send(msg.to_json, type: options['type'] || 'text')
      end

      def send_to_channel(options = {})
        unless channel_subscribed?
          error(__method__, Tightrope::ERROR_CLIENT_HAS_NOTSUBSCRIBED)
          return false
        end

        send_message(options.merge(channel: @channel))
      end

      def trigger_onsubscription(channel)
        @onsubscription.call(channel) if @onsubscription
      end

      #
      # is called when the subscription confirmation is sent
      #
      def onsubscription(&blk)
        @onsubscription = blk
      end

      #
      # triggers event 'onsubscribtion' when subscription confirmation is sent
      #
      def filter_text(frame)
        unless channel_subscribed?
          confirmation = JSON.parse(frame.to_s)
          if confirmation['type'] == 'confirm_subscription'
            identifier = JSON.parse(confirmation['identifier'])
            @channel_subscribed = @channel && identifier['channel'] == @channel
            trigger_onsubscription(identifier['channel']) if @channel_subscribed
            return @channel_subscribed
          end
        end
        false
      end

    end
  end # ActionCableClient

end
