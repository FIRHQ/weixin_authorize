# encoding: utf-8

require "redis"
require "digest/md5"

module WeixinAuthorize

  class Client
    include Api::User
    include Api::Menu
    include Api::Custom
    include Api::Groups
    include Api::Qrcode
    include Api::Media
    include Api::Mass
    include Api::Oauth
    include Api::Template

    attr_accessor :app_id, :app_secret, :expired_at # Time.now + expires_in
    attr_accessor :access_token, :redis_key
    attr_accessor :qrticket, :qrcode_url, :qrticket_expired_at, :qrticket_redis_key
    attr_accessor :jsticket, :jsticket_expired_at, :jsticket_redis_key

    def initialize app_id, app_secret
      @app_id              = app_id
      @app_secret          = app_secret
      @redis_key           = "weixin_#{app_id}"
      @qrticket_redis_key  = "weixin_qr_code_#{app_id}"
      @jsticket_redis_key  = "weixin_js_sdk_#{app_id}"
      @qrticket_redis_key  = @jsticket_expired_at = @expired_at = Time.now.to_i
    end

    # return token
    def get_access_token
      token_store.access_token
    end

    # 检查appid和app_secret是否有效。
    def is_valid?
      token_store.valid?
    end

    def token_store
      Token::Store.init_with(self)
    end

    def qrticket_store
      QrTicket::Store.init_with(self)
    end

    def get_qrticket str
      qrticket_store.get_qrticket(str)
    end

    def set_qrticket scene_id = nil, scene_str = nil, expire_seconds = 600, limited = false
      qrticket_store.set_qrticket(scene_id, scene_str, expire_seconds, limited)
    end

    def jsticket_store
      JsTicket::Store.init_with(self)
    end

    def get_jsticket
      jsticket_store.jsticket
    end

    # 获取js sdk 签名包
    def get_jssign_package(url)
      timestamp = Time.now.to_i
      noncestr = SecureRandom.hex(16)
      str = "jsapi_ticket=#{get_jsticket}&noncestr=#{noncestr}&timestamp=#{timestamp}&url=#{url}";
      signature = Digest::SHA1.hexdigest(str)

      {
        "appId"     => app_id,    "nonceStr"  => noncestr,
        "timestamp" => timestamp, "url"       => url,
        "signature" => signature, "rawString" => str
      }
    end

    # 暴露出：http_get,http_post两个方法，方便第三方开发者扩展未开发的微信API。
    def http_get(url, headers={}, endpoint="plain")
      headers = headers.merge(access_token_param)
      WeixinAuthorize.http_get_without_token(url, headers, endpoint)
    end

    def http_post(url, payload={}, headers={}, endpoint="plain")
      headers = access_token_param.merge(headers)
      WeixinAuthorize.http_post_without_token(url, payload, headers, endpoint)
    end

    private

      def access_token_param
        { access_token: get_access_token }
      end

  end
end
