# frozen_string_literal: true

ActiveRecord::Schema.define do

  enable_extension!("uuid-ossp", ActiveRecord::Base.connection)
  enable_extension!("pgcrypto",  ActiveRecord::Base.connection) if ActiveRecord::Base.connection.supports_pgcrypto_uuid?

  uuid_default = connection.supports_pgcrypto_uuid? ? {} : { default: "uuid_generate_v4()" }

  create_table :uuid_parents, id: :uuid, force: true, **uuid_default do |t|
    t.string :name
  end

  create_table :uuid_children, id: :uuid, force: true, **uuid_default do |t|
    t.string :name
    t.uuid :uuid_parent_id
  end

  create_table :defaults, force: true do |t|
    t.date :modified_date, default: -> { "CURRENT_DATE" }
    # FIXME(joey): Cockroach requires an explicit type cast, otherwise now() fails.
    # https://github.com/cockroachdb/cockroach/issues/20402
    t.date :modified_date_function, default: -> { "now()::DATE" }
    t.date :fixed_date, default: "2004-01-01"
    t.datetime :modified_time, default: -> { "CURRENT_TIMESTAMP" }
    t.datetime :modified_time_function, default: -> { "now()" }
    t.datetime :fixed_time, default: "2004-01-01 00:00:00.000000-00"
    t.column :char1, "char(1)", default: "Y"
    t.string :char2, limit: 50, default: "a varchar field"
    t.text :char3, default: "a text field"
    t.bigint :bigint_default, default: -> { "0::bigint" }
    t.text :multiline_default, default: "--- []

"
  end

  create_table :cockroachdb_times, force: true do |t|
    t.interval :time_interval
    # FIXME(joey): CockroachDB does not support precision on interval.
    # t.interval :scaled_time_interval, precision: 6
  end

  create_table :cockroachdb_oids, force: true do |t|
    t.oid :obj_id
  end

  drop_table "cockroachdb_timestamp_with_zones", if_exists: true
  drop_table "cockroachdb_partitioned_table", if_exists: true
  drop_table "cockroachdb_partitioned_table_parent", if_exists: true

  execute "DROP SEQUENCE IF EXISTS companies_nonstd_seq CASCADE"
  # FIXME(joey): CockroachDB does not support sequence dependancies.
  # https://github.com/cockroachdb/cockroach/issues/19723
  # execute "CREATE SEQUENCE companies_nonstd_seq START 101 OWNED BY companies.id"
  execute "CREATE SEQUENCE companies_nonstd_seq START 101"
  execute "ALTER TABLE companies ALTER COLUMN id SET DEFAULT nextval('companies_nonstd_seq')"
  execute "DROP SEQUENCE IF EXISTS companies_id_seq"

  # FIXME(joey): CockroachDB dos not support functions.
  # execute "DROP FUNCTION IF EXISTS partitioned_insert_trigger()"

  # FIXME(joey): I am quite confused where these sequences are being created.
  # %w(accounts_id_seq developers_id_seq projects_id_seq topics_id_seq customers_id_seq orders_id_seq).each do |seq_name|
  #   execute "SELECT setval('#{seq_name}', 100)"
  # end

  execute <<_SQL
  CREATE TABLE cockroachdb_timestamp_with_zones (
    id SERIAL PRIMARY KEY,
    time TIMESTAMP WITH TIME ZONE
  );
_SQL

#   begin
#     # FIXME(joey): I do not think CockroachDB supports anything similar to
#     # this.
#     execute <<_SQL
#     CREATE TABLE cockroachdb_partitioned_table_parent (
#       id SERIAL PRIMARY KEY,
#       number integer
#     );
#     CREATE TABLE cockroachdb_partitioned_table ( )
#       INHERITS (cockroachdb_partitioned_table_parent);
# _SQL
#     # FIXME(joey): CockroachDB does not support functions or triggers
#     # CREATE OR REPLACE FUNCTION partitioned_insert_trigger()
#     # RETURNS TRIGGER AS $$
#     # BEGIN
#     #   INSERT INTO cockroachdb_partitioned_table VALUES (NEW.*);
#     #   RETURN NULL;
#     # END;
#     # $$
#     # LANGUAGE plpgsql;
#     #
#     # CREATE TRIGGER insert_partitioning_trigger
#     #   BEFORE INSERT ON cockroachdb_partitioned_table_parent
#     #   FOR EACH ROW EXECUTE PROCEDURE partitioned_insert_trigger();
#   rescue ActiveRecord::StatementInvalid => e
#     if e.message.include?('language "plpgsql" does not exist')
#       execute "CREATE LANGUAGE 'plpgsql';"
#       retry
#     else
#       raise e
#     end
  # end

  # This table is to verify if the :limit option is being ignored for text and binary columns
  create_table :limitless_fields, force: true do |t|
    t.binary :binary, limit: 100_000
    t.text :text, limit: 100_000
  end

  create_table :bigint_array, force: true do |t|
    t.integer :big_int_data_points, limit: 8, array: true
    # FIXME(joey): For some reason ActiveRecord is throwing an error
    # when using an Array for a default value. Needs to be investigated.
    # t.decimal :decimal_array_default, array: true, default: [1.23, 3.45]
  end

  create_table :uuid_items, force: true, id: false do |t|
    t.uuid :uuid, primary_key: true, **uuid_default
    t.string :title
  end
end
