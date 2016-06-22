require 'spec_helper'

describe ActiveRecord::Type::TypedStore do
  let(:json_type) { ActiveRecord::Type::Serialized.new(ActiveRecord::Type::Text.new, ActiveRecord::Coders::JSON) }
  let(:yaml_type) do
    ActiveRecord::Type::Serialized.new(
      ActiveRecord::Type::Text.new,
      ActiveRecord::Store::IndifferentCoder.new(
        ActiveRecord::Coders::YAMLColumn.new(Hash)
      )
    )
  end

  context "with json store" do
    subject { described_class.new(json_type) }

    describe "#type_cast_from_user" do
      it "without key types", :aggregate_failures do
        expect(subject.type_cast_from_user([1, 2])).to eq [1, 2]
        expect(subject.type_cast_from_user('a' => 'b')).to eq('a' => 'b')
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.type_cast_from_user(date: '2016-06-22')).to eq('date' => date)
      end
    end

    describe "#type_cast_from_database" do
      it "without key types", :aggregate_failures do
        expect(subject.type_cast_from_database('[1,2]')).to eq [1, 2]
        expect(subject.type_cast_from_database('{"a":"b"}')).to eq('a' => 'b')
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.type_cast_from_database('{"date":"2016-06-22"}')).to eq('date' => date)
      end
    end

    describe "#type_cast_for_database" do
      it "without key types", :aggregate_failures do
        expect(subject.type_cast_for_database([1, 2])).to eq '[1,2]'
        expect(subject.type_cast_for_database('a' => 'b')).to eq '{"a":"b"}'
      end

      it "with type keys" do
        subject.add_typed_key('date', :date)

        date = ::Date.new(2016, 6, 22)
        expect(subject.type_cast_for_database(date: date)).to eq '{"date":"2016-06-22"}'
      end

      it "with type key with option" do
        subject.add_typed_key('val', :integer, limit: 1)

        expect { subject.type_cast_for_database(val: 1024) }.to raise_error(RangeError)
      end
    end

    describe ".create_from_type" do
      it "creates with valid types", :aggregate_failures do
        type = described_class.create_from_type(json_type, 'date', :date)
        new_type = described_class.create_from_type(type, 'val', :integer)

        date = ::Date.new(2016, 6, 22)

        expect(type.type_cast_from_user(date: '2016-06-22', val: '1.2')).to eq('date' => date, 'val' => '1.2')
        expect(new_type.type_cast_from_user(date: '2016-06-22', val: '1.2')).to eq('date' => date, 'val' => 1)
      end
    end
  end

  context "with yaml coder" do
    let(:subject) { described_class.new(yaml_type) }

    it "works", :aggregate_failures do
      subject.add_typed_key('date', :date)

      date = ::Date.new(2016, 6, 22)

      expect(subject.type_cast_from_user(date: '2016-06-22')).to eq('date' => date)
      expect(subject.type_cast_from_user('date' => '2016-06-22')).to eq('date' => date)
      expect(subject.type_cast_from_database("---\n:date: 2016-06-22\n")).to eq('date' => date)
      expect(subject.type_cast_from_database("---\ndate: 2016-06-22\n")).to eq('date' => date)
      expect(subject.type_cast_for_database(date: date)).to eq "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ndate: 2016-06-22\n"
      expect(subject.type_cast_for_database('date' => date)).to eq "--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess\ndate: 2016-06-22\n"
    end
  end
end
