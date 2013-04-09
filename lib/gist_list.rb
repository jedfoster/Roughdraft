class GistList
  attr_reader :list, :from_redis

  def initialize(user_id, page = 1)
    @user_id = user_id
    @from_redis = 'True'
    @page = page
    @list = REDIS.get("gist-list: #{user_id}, pg: #{page}")


    if ! @list
      @from_redis = 'False'

      @list = fetch
    else
      @list = JSON.parse(@list)
    end
  end

  def listify
    gists = Array.new

    @list['list'].each do |gist|
      gists << {
        :id => gist["id"],
        :description => gist["description"] || false,
        :created_at => gist["created_at"],
        :created_at_rendered => Time.parse(gist['created_at']).strftime("%b %-d, %Y")
      }
    end
    
    hash = {
      "list" => gists,
      "page_count" => @list["page_count"],
      "links" => {
        "next" => @list["links"]["next"],
        "prev" => @list["links"]["prev"],
      }
    }
    
    hash
  end


private
  def fetch
    begin
      gists = Array.new

      github_response = Github::Gists.new.list(user: @user_id, client_id: Roughdraft.gh_config['client_id'], client_secret: Roughdraft.gh_config['client_secret']).page(@page)

      github_response.each do |gist|
        gist.files.each do |key, file|
          if Gist.is_allowed file.language.to_s
            gists << gist.to_hash
            break
          end
        end
      end

      hash = {
        "list" => gists,
        "page_count" => github_response.count_pages,
        "links" => {
          "next" => github_response.links.next ? github_response.links.next.scan(/&page=(\d)/).first.first : nil,
          "prev" => github_response.links.prev ? github_response.links.prev.scan(/&page=(\d)/).first.first : nil,
        }
      }

      REDIS.setex("gist-list: #{@user_id}, pg: #{@page}", 60, hash.to_json)
      hash

    rescue Github::Error::NotFound
      false
    end
  end


end