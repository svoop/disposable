require "test_helper"
require "disposable/twin/jsonb"

class JSONBTest < MiniTest::Spec
  Model = Struct.new(:id, :content)

  class Song < Disposable::Twin
    include JSONB
    include Sync

    property :id
    property :content, jsonb: true do
      property :title
      property :band do
        property :name

        property :label do
          property :location
        end
      end
    end
  end

  # puts Song.definitions.get(:content)[:nested].definitions.get(:band).inspect

  it "allows reading from existing hash" do
    model = Model.new(1, {})
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content={}>"

    song = Song.new(model)
    song.id.must_equal 1
    song.content.title.must_equal nil
    song.content.band.name.must_equal nil
    song.content.band.label.location.must_equal nil

    # model's hash hasn't changed.
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content={}>"
  end

  it "defaults to hash when value is nil" do
    model = Model.new(1)
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content=nil>"

    song = Song.new(model)
    song.id.must_equal 1
    song.content.title.must_equal nil
    song.content.band.name.must_equal nil
    song.content.band.label.location.must_equal nil

    # model's hash hasn't changed.
    model.inspect.must_equal "#<struct JSONBTest::Model id=1, content=nil>"
  end

  it "#sync writes to model" do
    model = Model.new

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    model.inspect.must_equal "#<struct JSONBTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}}}>"
  end

  it "doesn't erase existing, undeclared content" do
    model = Model.new(nil, {"artist"=>{}})

    song = Song.new(model)
    song.content.band.label.location = "San Francisco"

    song.sync

    model.inspect.must_equal "#<struct JSONBTest::Model id=nil, content={\"band\"=>{\"label\"=>{\"location\"=>\"San Francisco\"}},}>"
  end


  describe "features propagation" do
    module UUID
      def uuid
        "1224"
      end
    end

    class Hit < Disposable::Twin
      include JSONB
      feature UUID

      property :id
      property :content, jsonb: true do
        property :title
        property :band do
          property :name
        end
      end
    end

    it "includes features into all nested twins" do
      song = Hit.new(Model.new)
      song.uuid.must_equal "1224"
      song.content.uuid.must_equal "1224"
      song.content.band.uuid.must_equal "1224"
    end
  end
end

# fixme: make sure default hash is different for every invocation, and not created at compile time.
