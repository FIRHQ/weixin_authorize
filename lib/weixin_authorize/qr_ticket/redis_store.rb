module WeixinAuthorize
  module QrTicket
    class RedisStore < Store

      def qrticket_expired? str
        weixin_redis.get("#{client.qrticket_redis_key}:#{str}").nil?
      end

      def set_qrticket scene_id, scene_str = nil, expire_seconds = 600, limited = false
        super
        weixin_redis.setex(
          "#{client.qrticket_redis_key}:#{client.qrticket}",
          expire_seconds.to_i,
          client.qrcode_url
        )
      end

      def get_qrticket str
        return nil unless super(str)

        client.qrticket            = str
        client.qrcode_url          = weixin_redis.get("#{client.qrticket_redis_key}:#{str}")
        client.qrticket_expired_at = weixin_redis.ttl("#{client.qrticket_redis_key}:#{str}") + Time.now.to_i
        client
      end

      def weixin_redis
        WeixinAuthorize.weixin_redis
      end
    end
  end
end
