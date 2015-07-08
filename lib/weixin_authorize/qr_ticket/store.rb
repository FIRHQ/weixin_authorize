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
          raise NotImplementedError, "Redis is necessary"
        else
          RedisStore.new(client)
        end
      end

      def qrticket_expired? str
        raise NotImplementedError, "Subclasses must implement a `qrticket_expired?` method"
      end

      def create_qrticket scene_id, expire_seconds
        result = client.create_qr_scene(scene_id, expire_seconds).result

        # TODO: 这个 gem 包真他妈难用, 各种隐晦, 回头重写这套逻辑!!!!!!!
        unless result.is_ok?
          token_store.refresh_token
          result = client.create_qr_scene(scene_id, expire_seconds).result
        end

        client.qrticket            = result["ticket"]
        client.qrcode_url          = result["url"]
        client.qrticket_is_used    = '0'
        client.qrticket_expired_at = result["expire_seconds"].to_i + Time.now.to_i
      end
    end
  end
end
