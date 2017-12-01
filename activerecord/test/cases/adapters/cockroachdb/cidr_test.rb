# FILE(NOT DONE)
# frozen_string_literal: true

require "cases/helper"
require "ipaddr"
require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    # FIXME(joey): It seems excessive that this test needs to inherit
    # the postgres adapater. It appears that the test is a "monkeypatch"
    # to the CockroachDBAdapter class. Why?
    class CockroachDBAdapter < PostgreSQLAdapter
      class CidrTest < ActiveRecord::CockroachDBTestCase
        test "type casting IPAddr for database" do
          type = OID::Cidr.new
          ip = IPAddr.new("255.0.0.0/8")
          ip2 = IPAddr.new("127.0.0.1")

          assert_equal "255.0.0.0/8", type.serialize(ip)
          assert_equal "127.0.0.1/32", type.serialize(ip2)
        end

        test "casting does nothing with non-IPAddr objects" do
          type = OID::Cidr.new

          assert_equal "foo", type.serialize("foo")
        end
      end
    end
  end
end
