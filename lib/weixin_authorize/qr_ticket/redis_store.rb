module WeixinAuthorize
  module QrTicket
    class RedisStore < Store
      QRTICKET   = "qrticket"
      QRCODE_URL = "qrcode_url"
      EXPIRED_AT = "expired_at"
      IS_USERD   = "is_used"

      def qrticket_expired? str
        weixin_redis.hvals("#{client.qrticket_redis_key}:#{str}").empty?
      end

      def create_qrticket scene_id, expire_seconds = 600
        super
        weixin_redis.hmset(
          "#{client.qrticket_redis_key}:#{client.qrticket}",
          QRTICKET,
          client.qrticket,
          QRCODE_URL,
          client.qrcode_url
          EXPIRED_AT,
          client.qrticket_expired_at,
          IS_USERD,
          client.qrticket_is_used
        )
        weixin_redis.expireat(
          "#{client.qrticket_redis_key}:#{client.qrticket}",
          client.qrticket_expired_at.to_i
        )
      end

      def get_qrticket str
        return nil if qrticket_expired?(str)

        client.qrticket            = str
        client.qrcode_url          = weixin_redis.hget("#{client.qrticket_redis_key}:#{str}", QRCODE_URL)
        client.qrticket_expired_at = weixin_redis.hget("#{client.qrticket_redis_key}:#{str}", EXPIRED_AT)
        client.qrticket_is_used    = weixin_redis.hget("#{client.qrticket_redis_key}:#{str}", IS_USERD)
      end

      def set_qrticket_used str
        return nil if qrticket_expired?(str)

        weixin_redis.hset("#{client.qrticket_redis_key}:#{str}", IS_USERD, '1')
      end

      def weixin_redis
        WeixinAuthorize.weixin_redis
      end
    end
  end
end
