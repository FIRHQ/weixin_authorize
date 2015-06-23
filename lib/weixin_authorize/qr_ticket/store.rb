# encoding: utf-8

module WeixinAuthorize
  module QrTicket
    class Store

      attr_accessor :client

      def initialize(client)
        @client = client
      end

      def self.init_with(client)
        if WeixinAuthorize.weixin_redis.nil?
          ObjectStore.new(client)
        else
          RedisStore.new(client)
        end
      end

      def qrticket_expired? str
        raise NotImplementedError, "Subclasses must implement a qrticket_expired? method"
      end

      def get_qrticket str
        return nil if qrticket_expired?(str)
      end

      def set_qrticket scene_id = nil, scene_str = nil, expire_seconds = 600, limited = false
        if limited
          result = client.create_qr_limit_scene(scene_id, scene_str)
        else
          result = client.create_qr_scene(scene_id, expire_seconds)
        end

        client.qrticket   = result["ticket"]
        client.qrcode_url = result["url"]
        client.qrticket_expired_at = result["expire_seconds"] + Time.now.to_i
      end

    end
  end
end
