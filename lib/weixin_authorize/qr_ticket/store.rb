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
        res = client.create_qr_scene(scene_id, expire_seconds)

        # TODO: 这个 gem 包真他妈难用, 各种隐晦, 回头重写这套逻辑!!!!!!!
        unless res.is_ok?
          client.token_store.refresh_token
          res = client.create_qr_scene(scene_id, expire_seconds)
        end

        client.qrticket            = res.result["ticket"]
        client.qrcode_url          = res.result["url"]
        client.qrticket_is_used    = '0'
        client.qrticket_expired_at = res.result["expire_seconds"].to_i + Time.now.to_i
      end
    end
  end
end
