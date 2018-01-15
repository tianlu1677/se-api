require "se/api/version"
require "se/api/types/answer"
require "se/api/types/question"
require "se/api/types/comment"
require "se/api/types/user"
require "se/api/types/post"

require "net/http"
require "json"
require "uri"
require "time"
require "logger"

module SE
  module API
    class Client
      API_VERSION = 2.2

      attr_reader :quota, :quota_used
      attr_accessor :params

      def initialize(key = "", **params)
        @key = key
        @params = params.merge({filter: '!*1_).BnZb8pdvWlZpJYNyauMekouxK9-RzUNUrwiB'})
        @quota = nil
        @quota_used = 0
        @backoff = Time.now
        @logger_raw = Logger.new 'api_raw.log'
        @logger_json = Logger.new 'api_json.log'
      end

      def posts(*ids, **params)
        objectify Post, ids, **params
      end

      def post(id, **params)
        posts(id, **params).first
      end

      def questions(*ids, **params)
        objectify Question, ids, **params
      end

      def question(id, **params)
        questions(id, **params).first
      end

      def answers(*ids, **params)
        objectify Answer, ids, **params
      end

      def answer(id, **params)
        answers(id, **params).first
      end

      def comments(*ids, **params)
        objectify Comment, ids, **params
      end

      def comment(id, **params)
        comments(id, **params).first
      end

      def users(*ids, **params)
        objectify User, ids, **params
      end

      def user(id, **params)
        users(id, **params).first
      end

      private

      def objectify(type, ids = "", uri: nil, **params)
        return if ids == ""
        uri = "#{type.to_s.split('::').last.downcase}s" if uri.nil?
        json("#{uri}/#{Array(ids).join(';')}", **params).map do |i|
          type.new(i)
        end
      end

      def json(uri, **params)
        params = @params.merge(params)
        throw "No site specified" if params[:site].nil?
        backoff_for = @backoff-Time.now
        backoff_for = 0 if backoff_for <= 0
        if backoff_for > 0
          puts "Backing off for #{backoff_for}"
          sleep backoff_for+2
          puts "Finished backing off!"
        end
        params = @params.merge(params).merge({key: @key}).map { |k,v| "#{k}=#{v}" }.join('&')
        puts "Posting to https://api.stackexchange.com/#{API_VERSION}/#{uri}?#{params}"
        begin
          resp_raw  = Net::HTTP.get_response(URI("https://api.stackexchange.com/#{API_VERSION}/#{uri}?#{params}")).body
        rescue Net::OpenTimeout, SocketError => e
          puts "Got timeout on API request (#{e}). Retrying..."
          sleep 0.3
          retry
        end
        @logger_raw.info "https://api.stackexchange.com/#{API_VERSION}/#{uri}?#{params} => #{resp_raw}"
        resp = JSON.parse(resp_raw)
        @backoff = Time.now + resp["backoff"].to_i
        @logger_json.info "https://api.stackexchange.com/#{API_VERSION}/#{uri}?#{params} => #{resp}"
        @quota = resp["quota_remaining"]
        @quota_used += 1
        resp["items"]
      end
    end
  end
end
