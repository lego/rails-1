# FILE(NOT DONE)
# frozen_string_literal: true

require "cases/helper"
require "support/schema_dumping_helper"

class CockroachdbMoneyTest < ActiveRecord::CockroachDBTestCase
  include SchemaDumpingHelper

  class CockroachdbMoney < ActiveRecord::Base; end

  setup do
    @connection = ActiveRecord::Base.connection
    @connection.execute("set lc_monetary = 'C'")
    @connection.create_table("cockroachdb_moneys", force: true) do |t|
      t.money "wealth"
      t.money "depth", default: "150.55"
    end
  end

  teardown do
    @connection.drop_table "cockroachdb_moneys", if_exists: true
  end

  def test_column
    column = CockroachdbMoney.columns_hash["wealth"]
    assert_equal :money, column.type
    assert_equal "money", column.sql_type
    assert_equal 2, column.scale
    assert_not column.array?

    type = CockroachdbMoney.type_for_attribute("wealth")
    assert_not type.binary?
  end

  def test_default
    assert_equal BigDecimal("150.55"), PostgresqlMoney.column_defaults["depth"]
    assert_equal BigDecimal("150.55"), PostgresqlMoney.new.depth
  end

  def test_money_values
    @connection.execute("INSERT INTO cockroachdb_moneys (id, wealth) VALUES (1, '567.89'::money)")
    @connection.execute("INSERT INTO cockroachdb_moneys (id, wealth) VALUES (2, '-567.89'::money)")

    first_money = CockroachdbMoney.find(1)
    second_money = CockroachdbMoney.find(2)
    assert_equal 567.89, first_money.wealth
    assert_equal(-567.89, second_money.wealth)
  end

  def test_money_type_cast
    type = CockroachdbMoney.type_for_attribute("wealth")
    assert_equal(12345678.12, type.cast("$12,345,678.12".dup))
    assert_equal(12345678.12, type.cast("$12.345.678,12".dup))
    assert_equal(-1.15, type.cast("-$1.15".dup))
    assert_equal(-2.25, type.cast("($2.25)".dup))
  end

  def test_schema_dumping
    output = dump_table_schema("cockroachdb_moneys")
    assert_match %r{t\.money\s+"wealth",\s+scale: 2$}, output
    assert_match %r{t\.money\s+"depth",\s+scale: 2,\s+default: "150\.55"$}, output
  end

  def test_create_and_update_money
    money = CockroachdbMoney.create(wealth: "987.65".dup)
    assert_equal 987.65, money.wealth

    new_value = BigDecimal("123.45")
    money.wealth = new_value
    money.save!
    money.reload
    assert_equal new_value, money.wealth
  end

  def test_update_all_with_money_string
    money = CockroachdbMoney.create!
    CockroachdbMoney.update_all(wealth: "987.65")
    money.reload

    assert_equal 987.65, money.wealth
  end

  def test_update_all_with_money_big_decimal
    money = CockroachdbMoney.create!
    CockroachdbMoney.update_all(wealth: "123.45".to_d)
    money.reload

    assert_equal 123.45, money.wealth
  end

  def test_update_all_with_money_numeric
    money = CockroachdbMoney.create!
    CockroachdbMoney.update_all(wealth: 123.45)
    money.reload

    assert_equal 123.45, money.wealth
  end
end
