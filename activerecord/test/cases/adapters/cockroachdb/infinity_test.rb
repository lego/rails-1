# frozen_string_literal: true

require "cases/helper"

class CockroachdbInfinityTest < ActiveRecord::CockroachDBTestCase
  include InTimeZone

  class CockroachdbInfinity < ActiveRecord::Base
  end

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.create_table(:cockroachdb_infinities) do |t|
      t.float :float
      t.datetime :datetime
    end
  end

  teardown do
    @connection.drop_table "cockroachdb_infinities", if_exists: true
  end

  test "type casting infinity on a float column" do
    record = CockroachdbInfinity.create!(float: Float::INFINITY)
    record.reload
    assert_equal Float::INFINITY, record.float
  end

  test "type casting string on a float column" do
    record = CockroachdbInfinity.new(float: "Infinity")
    assert_equal Float::INFINITY, record.float
    record = CockroachdbInfinity.new(float: "-Infinity")
    assert_equal(-Float::INFINITY, record.float)
    record = CockroachdbInfinity.new(float: "NaN")
    assert record.float.nan?, "Expected #{record.float} to be NaN"
  end

  test "update_all with infinity on a float column" do
    record = CockroachdbInfinity.create!
    CockroachdbInfinity.update_all(float: Float::INFINITY)
    record.reload
    assert_equal Float::INFINITY, record.float
  end

  test "type casting infinity on a datetime column" do
    record = CockroachdbInfinity.create!(datetime: Float::INFINITY)
    record.reload
    assert_equal Float::INFINITY, record.datetime
  end

  test "update_all with infinity on a datetime column" do
    record = CockroachdbInfinity.create!
    CockroachdbInfinity.update_all(datetime: Float::INFINITY)
    record.reload
    assert_equal Float::INFINITY, record.datetime
  end

  test "assigning 'infinity' on a datetime column with TZ aware attributes" do
    begin
      in_time_zone "Pacific Time (US & Canada)" do
        record = CockroachdbInfinity.create!(datetime: "infinity")
        assert_equal Float::INFINITY, record.datetime
        assert_equal record.datetime, record.reload.datetime
      end
    ensure
      # setting time_zone_aware_attributes causes the types to change.
      # There is no way to do this automatically since it can be set on a superclass
      CockroachdbInfinity.reset_column_information
    end
  end
end
