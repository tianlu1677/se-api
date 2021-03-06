require "se/api/types/user"

module SE
  module API
    class Comment
      attr_reader :body, :link, :id, :post_id, :score, :type, :created_at, :author, :body_markdown, :edited, :post_type
      attr_reader :json

      def initialize(item_json)
        @json = Hash(item_json)
        @body = @json["body"]
        @body_markdown = @json["body_markdown"]
        @link = @json["link"]
        @edited = (@json["edited"] == "true")
        @post_id = @json["post_id"].to_i
        @post_type = @json["post_type"]
        @score = @json["score"].to_i
        @type = @json["post_type"]
        @id = @json["comment_id"].to_i
        @created_at = @json["creation_date"]
        @author = User.new(@json["owner"])
      end

      alias_method :user, :author
      alias_method :owner, :author
      alias_method :comment_id, :id
      alias_method :creation_date, :created_at
    end
  end
end
