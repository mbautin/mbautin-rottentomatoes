require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec', 'setup', 'spec_helper.rb'))

describe Rotten do

  it "set a specified API key" do
    old_key = Rotten.api_key
    key = "000000000"
    Rotten.api_key = key
    Rotten.api_key.should == key
    Rotten.api_key = old_key
  end

  it "should return a base API url" do
    Rotten.base_api_url.should == "http://api.rottentomatoes.com/api/public/v1.0/"
  end

  it "should return a URL as a successful response object" do
    response = Rotten.get_url("http://example.com")
    response.code.to_i.should == 200
  end

  it "should return a website URL that doesn't exist as a 404" do
    response = Rotten.get_url("http://fakeurlisfakeforsure.com")
    response.code.to_i.should == 404
  end

  it "should raise an exception if the API key is not set" do
    old_key = Rotten.api_key
    lambda {
      Rotten.api_key = ""
      Rotten.api_call("movies", :title => "Fight Club")
    }.should raise_error(ArgumentError)
    Rotten.api_key = old_key
  end

  it "should return an array of results when searching by title" do
    movies = Rotten.api_call("movies", :title => "Fight Club")
    movies.should be_a_kind_of Array
    movies.length.should have_at_least(3).things
    movies.each do |movie|
      movie.should be_a_kind_of Hash
    end
  end

  it "should return a hash when searching by id" do
    movies = Rotten.api_call("movies", :id => 12132)
    movies.should be_a_kind_of Hash
  end

  it "should raise an exception for a failed API call" do
    lambda {
      movies = Rotten.api_call("unknown", :title => "Fight Club")
    }.should raise_error(ArgumentError)
  end

  it "should return nil for a search that returns no results when searching by title" do
    movies = Rotten.api_call("movies", :title => "xxxxxxx")
    movies.should == nil
  end

  describe "data_to_object" do

    it "should create an object from a nested data structure" do
      data = {
        :one => [
          'a', 'b', 'c'
        ],
        :two => 'd'
      }
      test_object = Rotten.data_to_object(data)
      test_object.one.should == ['a', 'b', 'c']
      test_object.two.should == 'd'
    end

    it "should include raw_data that returns the original data" do
      data = {
        :one => ['a', 'b', 'c']
      }
      test_object = Rotten.data_to_object(data)
      test_object.raw_data.should == data
    end

  end

end
