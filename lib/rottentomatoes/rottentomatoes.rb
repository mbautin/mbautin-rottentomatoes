module RottenTomatoes

  class Rotten

    require 'net/http'
    require 'uri'
    require 'cgi'
    require 'json'
    require 'deepopenstruct'

    @@api_key = ""
    @@api_response = {}

    REQUEST_SLEEP_SEC = ENV['ROTTENTOMATOES_REQUEST_SLEEP_SEC'].to_f || 0

    TYPE_TO_SECTION = {
      :box_office => 'movies',
      :in_theaters => 'movies',
      :opening => 'movies',
      :top_rentals => 'dvds',
      :current_releases => 'dvds',
      :new_releases => 'dvds'
    }

    def self.api_key
      @@api_key
    end

    def self.api_key=(key)
      @@api_key = key
    end

    def self.base_api_url
      "http://api.rottentomatoes.com/api/public/v1.0/"
    end

    def self.api_call(method, options)
      raise ArgumentError, "Rotten.api_key must be set before you can use the API" if(@@api_key.nil? || @@api_key.empty?)
      raise ArgumentError, "You must specify 'movies', 'movie_alias', 'lists' or 'direct' as the method" if (method != "movies" && method != "direct" && method != "lists" && method != "movie_alias")

      url = (method == "direct") ? options : base_api_url + method

      if (method == "movies" && !options[:id].nil?)
        url += "/" + options[:id].to_s
      end

      if (method == "lists")
        type = options[:type]
        section = options[:section] || TYPE_TO_SECTION[type] || 'movies'
        url += "/#{section}/#{type}"
      end

      url += ".json" if (url[-5, 5] != ".json")
      url += "?apikey=" + @@api_key
      url += "&q=" + CGI::escape(options[:title].to_s) if (method == "movies" && !options[:title].nil? && options[:id].nil?)
      url += "&type=imdb&id=%07d" % options[:imdb].to_i if (method == "movie_alias")

      response = get_url(url)
      return nil if(response.code.to_i != 200)
      body = JSON(response.body)

      if (body["total"] == 0 && body["title"].nil?)
        return nil
      else
        return body["movies"] if !body["movies"].nil?
        return body
      end
    end

    def self.process_results(results, options)
      results.flatten!
      results.compact!

      unless (options[:limit].nil?)
        raise ArgumentError, "Limit must be an integer greater than 0" if (!options[:limit].is_a?(Fixnum) || !(options[:limit] > 0))
        results = results.slice(0, options[:limit])
      end

      results.map!{|m| RottenMovie.new(m, options[:expand_results])}

      if (results.length == 1)
        return results[0]
      else
        return results
      end
    end

    def self.get_url(uri_str, limit = 10)
      return false if limit == 0
      uri = URI.parse(uri_str)
      begin
        response = Net::HTTP.start(uri.host, uri.port) do |http|
          http.get((uri.path.empty? ? '/' : uri.path) + (uri.query ? '?' + uri.query : ''))
        end
        sleep(REQUEST_SLEEP_SEC) if REQUEST_SLEEP_SEC != 0
      rescue SocketError, Errno::ENETDOWN
        response = Net::HTTPBadRequest.new( '404', 404, "Not Found" )
        return response
      end
      case response
        when Net::HTTPSuccess     then response
        when Net::HTTPRedirection then get_url(response['location'], limit - 1)
        when Net::HTTPForbidden   then get_url(uri_str, limit - 1)
      else
        Net::HTTPBadRequest.new( '404', 404, "Not Found" )
      end
    end

    def self.data_to_object(data)
      object = DeepOpenStruct.load(data)
      object.raw_data = data
      return object
    end

  end

end
