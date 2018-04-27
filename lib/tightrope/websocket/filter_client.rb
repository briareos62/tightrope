require 'json'

module Tightrope
  module WebSocket
    # https://tools.ietf.org/html/rfc6455

    class FilterClient < ::WebSocket::EventMachine::Client
      #
      # Websocket client for filtering frames send by websocket events.
      # You can customize the methods
      #    filter_text, filter_binary, filter_ping, filter_pong and filter_close
      #
      def initialize(args)
        create_methods
        super(args)
      end

      [:text, :binary, :ping, :pong, :close].each do |type|
        define_method("filter_#{type.to_s}") { |arg| false }
      end

      def args
        instance_variable_get("@args")
      end

      def error(method, code, message = '')
        e = {method: method, code: code}
        e[:message] = message if message && message != ''
        trigger_onerror(e.to_json)
      end

      private

      def create_method(name, &block)
        self.class.send(:define_method, name, &block)
      end

      def create_methods
        [:onopen, :onping, :onpong, :onerror, :onmessage, :onclose].each do |event|
          create_method("trigger_#{event}".to_sym) do |data,type=nil|
            ivar = instance_variable_get("@#{event}")
            ivar.call(data,type) if ivar
          end
        end

        create_method(:handle_open) do |data|
          frame_super = instance_variable_get("@frame")
          frame_super << data
          instance_variable_set("@frame", frame_super)
          while frame = frame_super.next
            state = instance_variable_get("@state")
            if state == :open
              case frame.type
              when :close
                state = :closing
                instance_variable_set("@state", :closing)
                close
                trigger_onclose(frame.code, frame.data) unless filter_close(frame)
              when :ping
                pong(frame.to_s)
                trigger_onping(frame.to_s) unless filter_ping(frame)
              when :pong
                trigger_onpong(frame.to_s) unless filter_pong(frame)
              when :text
                trigger_onmessage(frame.to_s, :text) unless filter_text(frame)
              when :binary
                trigger_onmessage(frame.to_s, :binary) unless filter_binary(frame)
              end
            else
              break
            end
          end

          if frame_super.error?
            error_code = case error
              when :invalid_payload_encoding then 1007
              else 1002
            end
            trigger_onerror(error.to_s)
            close(error_code)
            unbind
          end
        end
      end
    end
  end
end
