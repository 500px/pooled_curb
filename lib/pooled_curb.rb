require 'active_support'
require 'connection_pool'
require 'curb'

# A Curb-based client which uses the "connection_pool" gem to allow high-performance
# HTTP requests in a multi-threaded environment.
#
# Based on: https://github.com/karmi/tire-contrib/blob/master/lib/tire/http/clients/pooled_curb.rb
#
# Example:
# --------
#
#     require 'api/pooled_curb'
#

class PooledCurb
  cattr_accessor :pool_size, :pool_timeout, :read_timeout, :write_timeout

  POOL_SIZE = 1
  POOL_TIMEOUT = 5.0 # seconds
  READ_TIMEOUT = 5 # seconds
  WRITE_TIMEOUT = 30 # seconds

  RETRIES = 3
  RETRY_WAIT = 0.2 # second

  def self.configure
    yield self

    self
  end

  def self.reset!
    [:pool_size, :pool_timeout, :read_timeout, :write_timeout].each do |attr_name|
      send("#{attr_name}=", nil)
    end

    @pool = nil

    self
  end

  def self.connection_pool
    @pool ||= ConnectionPool.new(connection_pool_opts) do |config|
      Curl::Easy.new
    end
  end

  def self.disconnect!
    if @pool
      @pool.shutdown { |client| client.close }
      @pool = nil
    end
  end

  def self.with_client(&block)
    connection_pool.with(&block)
  end

  def self.head(url, headers: {})
    perform_with_retry(:head, url, timeout: _read_timeout, headers: headers)
  end

  def self.get(url, headers: {})
    perform_with_retry(:get, url, timeout: _read_timeout, headers: headers)
  end

  def self.post(url, data, headers: {})
    perform_with_retry(:post, url, post_body: to_post_data(data), timeout: _write_timeout, headers: headers)
  end

  def self.multipart_form_post(url, data, headers: {})
    perform_with_retry(:post, url, post_body: to_post_data(data), multipart_form_post: true, timeout: _write_timeout, headers: headers)
  end

  def self.put(url, data, headers: {})

    perform_with_retry(:put, url, post_body: data, timeout: _write_timeout, headers: headers)
  end

  def self.delete(url, headers: {})
    perform_with_retry(:delete, url, timeout: _write_timeout, headers: headers)
  end

  class Response
    attr_reader :body, :status, :header_str

    def initialize(status, header_str, body)
      @body = body
      @header_str = header_str
      @status = status
    end

    def success?
      status <= 299
    end

    def failure?
      status >= 400
    end

    def headers
      return @headers if @headers

      headers = @header_str.split("\r\n")
      headers.shift  # Remove HTTP response line ("200 OK")
      headers = headers.reject { |h| h.nil? || h.empty? }.map { |h| h.split(/:/, 2).map(&:strip) }
      @headers = Hash[headers]
    end
  end

  private

  def self.perform_with_retry(verb, url, headers: {}, **opts)
    RETRIES.times do |tries|
      Kernel.sleep(RETRY_WAIT) if tries > 0
      can_retry = tries + 1 < RETRIES

      begin
        response = perform(verb, url, headers: headers, **opts)
        final_response = response.success? || (response.failure? && response.status < 500)

        return response if !can_retry || final_response
      rescue Curl::Err::CurlError => ex
        raise unless can_retry
      end
    end
  end

  def self.to_post_data(data)
    if data.kind_of?(Hash)
      data.map { |k, v| Curl::PostField.content(k, v) }
    else
      data
    end
  end

  def self.perform(verb, url, **opts)
    with_client do |client|
      client.url = url

      opts.each do |attr, value|
        client.send("#{attr}=", value)
      end

      begin
        if [:put, :post].include?(verb)
          client.send("http_#{verb}", opts[:post_body])
        else
          client.send("http_#{verb}")
        end
        response = Response.new(client.response_code, client.header_str, client.body_str)
      rescue Curl::Err::CurlError
        # Reset the connection to prevent sending requests to the same broken handler
        client.close
        raise
      end
    end
  end

  def self._read_timeout
    read_timeout || READ_TIMEOUT
  end

  def self._write_timeout
    write_timeout || WRITE_TIMEOUT
  end

  def self.connection_pool_opts
    {
      size: pool_size || POOL_SIZE,
      timeout: pool_timeout || POOL_TIMEOUT
    }
  end
end
