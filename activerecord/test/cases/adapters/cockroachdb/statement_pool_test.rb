# FILE(NOT DONE)
# frozen_string_literal: true

require "cases/helper"
require 'active_record/connection_adapters/postgresql_adapter'

module ActiveRecord
  module ConnectionAdapters
    # FIXME(joey): It seems excessive that this test needs to inherit
    # the postgres adapater. It appears that the test is a "monkeypatch"
    # to the CockroachDBAdapter class. Why?
    class CockroachDBAdapter < PostgreSQLAdapter
      class InactivePgConnection
        def query(*args)
          raise PG::Error
        end

        def status
          PG::CONNECTION_BAD
        end
      end

      class StatementPoolTest < ActiveRecord::CockroachDBTestCase
        if Process.respond_to?(:fork)
          def test_cache_is_per_pid
            cache = StatementPool.new nil, 10
            cache["foo"] = "bar"
            assert_equal "bar", cache["foo"]

            pid = fork {
              lookup = cache["foo"]
              exit!(!lookup)
            }

            Process.waitpid pid
            assert $?.success?, "process should exit successfully"
          end
        end

        def test_dealloc_does_not_raise_on_inactive_connection
          cache = StatementPool.new InactivePgConnection.new, 10
          cache["foo"] = "bar"
          assert_nothing_raised { cache.clear }
        end
      end
    end
  end
end
