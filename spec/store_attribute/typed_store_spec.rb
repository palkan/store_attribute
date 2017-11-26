require 'spec_helper'

describe ActiveRecord::Type::TypedStore do
  let(:json_type) { ActiveRecord::Type::Serialized.new(ActiveRecord::Type::Text.new, ActiveRecord::Coders::JSON) }

  context "with json store" do
    subject { described_class.new(json_type) }

    describe "#cast" do
      it "without key types", :aggregate_failures do
        expect(subject.cast([1, 2])).to eq [1, 2]
        expect(subject.cast('a' => 'b')).to eq('a' => 'b')
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.cast(date: '2016-06-22')).to eq('date' => date)
      end
    end

    describe "#deserialize" do
      it "without key types", :aggregate_failures do
        expect(subject.deserialize('[1,2]')).to eq [1, 2]
        expect(subject.deserialize('{"a":"b"}')).to eq('a' => 'b')
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.deserialize('{"date":"2016-06-22"}')).to eq('date' => date)
      end
    end

    describe "#serialize" do
      it "without key types", :aggregate_failures do
        expect(subject.serialize([1, 2])).to eq '[1,2]'
        expect(subject.serialize('a' => 'b')).to eq '{"a":"b"}'
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.serialize(date: date)).to eq '{"date":"2016-06-22"}'
      end

      it "with type key with option" do
        subject.add_typed_key('val', :integer, limit: 1)

        expect { subject.serialize(val: 1024) }.to raise_error(RangeError)
      end
    end

    describe ".create_from_type" do
      it "creates with valid types", :aggregate_failures do
        type = described_class.create_from_type(json_type, 'date', :date)
        new_type = described_class.create_from_type(type, 'val', :integer)

        date = ::Date.new(2016, 6, 22)

        expect(type.cast(date: '2016-06-22', val: '1.2')).to eq('date' => date, 'val' => '1.2')
        expect(new_type.cast(date: '2016-06-22', val: '1.2')).to eq('date' => date, 'val' => 1)
      end
    end
  end

  context "with yaml coder" do
    if RAILS_5_1
      let(:yaml_type) do
        ActiveRecord::Type::Serialized.new(
          ActiveRecord::Type::Text.new,
          ActiveRecord::Store::IndifferentCoder.new(
            'test',
            ActiveRecord::Coders::YAMLColumn.new('test', Hash)
          )
        )
      end
    else
      let(:yaml_type) do
        ActiveRecord::Type::Serialized.new(
          ActiveRecord::Type::Text.new,
          ActiveRecord::Store::IndifferentCoder.new(
            ActiveRecord::Coders::YAMLColumn.new(Hash)
          )
        )
      end
    end

    let(:subject) { described_class.new(yaml_type) }

    it "works", :aggregate_failures do
      subject.add_typed_key('date', :date)

      date = ::Date.new(2016, 6, 22)

      expect(subject.cast(date: '2016-06-22')).to eq('date' => date)
      expect(subject.cast('date' => '2016-06-22')).to eq('date' => date)
      expect(subject.deserialize("---\n:date: 2016-06-22\n")).to eq('date' => date)
      expect(subject.deserialize("---\ndate: 2016-06-22\n")).to eq('date' => date)
      expect(subject.serialize(date: date)).to eq "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ndate: 2016-06-22\n"
      expect(subject.serialize('date' => date)).to eq "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ndate: 2016-06-22\n"
    end
  end
end
