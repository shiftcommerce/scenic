module Scenic
  # Methods that are made available in migrations for managing Scenic views.
  module Statements
    module FunctionStatements
      # Create a new database view.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param version [Fixnum] The version number of the function, used to find the
      #   definition file in `db/functions`. This defaults to `1` if not provided.
      # @param sql_definition [String] The SQL query for the function. An error
      #   will be raised if `sql_definition` and `version` are both set,
      #   as they are mutually exclusive.
      # @return The database response from executing the create statement.
      #
      # @example Create from `db/functions/searches_v02.sql`
      #   create_function(:searches, version: 2)
      #
      # @example Create from provided SQL string
      #   create_function(:active_users, sql_definition: <<-SQL)
      #     SELECT * FROM users WHERE users.active = 't'
      #   SQL
      #
      def create_function(name, version: nil, sql_definition: nil)
        if version.present? && sql_definition.present?
          raise(
              ArgumentError,
              'sql_definition and version cannot both be set',
          )
        end

        if version.blank? && sql_definition.blank?
          version = 1
        end

        sql_definition ||= definition(name, version)

        Scenic.database.create_function(name, sql_definition)
      end

      # Drop a database function by name.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param revert_to_version [Fixnum] Used to reverse the `drop_function` command
      #   on `rake db:rollback`. The provided version will be passed as the
      #   `version` argument to {#create_function}.
      # @return The database response from executing the drop statement.
      #
      # @example Drop a function, rolling back to version 3 on rollback
      #   drop_function(:users_who_recently_logged_in, revert_to_version: 3)
      #
      def drop_function(name, revert_to_version: nil)
        Scenic.database.drop_function(name)
      end

      # Update a database function to a new version.
      #
      # The existing function is dropped and recreated using the supplied `version`
      # parameter.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param version [Fixnum] The version number of the function.
      # @param sql_definition [String] The SQL query for the function schema. An error
      #   will be raised if `sql_definition` and `version` are both set,
      #   as they are mutually exclusive.
      # @param revert_to_version [Fixnum] The version number to rollback to on
      #   `rake db rollback`
      # @return The database response from executing the create statement.
      #
      # @example
      #   update_function :engagement_reports, version: 3, revert_to_version: 2
      #
      def update_function(name, version: nil, sql_definition: nil, revert_to_version: nil)
        if version.blank? && sql_definition.blank?
          raise(
              ArgumentError,
              "sql_definition or version must be specified",
          )
        end

        if version.present? && sql_definition.present?
          raise(
              ArgumentError,
              "sql_definition and version cannot both be set",
          )
        end

        sql_definition ||= definition(name, version)

        Scenic.database.update_function(name, sql_definition)
      end

      # Update a database function to a new version using `CREATE OR REPLACE VIEW`.
      #
      # The existing function is replaced using the supplied `version`
      # parameter.
      #
      # Does not work with materialized functions due to lack of database support.
      #
      # @param name [String, Symbol] The name of the database function.
      # @param version [Fixnum] The version number of the function.
      # @param revert_to_version [Fixnum] The version number to rollback to on
      #   `rake db rollback`
      # @return The database response from executing the create statement.
      #
      # @example
      #   replace_function :engagement_reports, version: 3, revert_to_version: 2
      #
      def replace_function(name, version: nil, revert_to_version: nil)
        if version.blank?
          raise ArgumentError, "version is required"
        end

        sql_definition = definition(name, version)

        Scenic.database.replace_function(name, sql_definition)
      end

      private

      def definition(name, version)
        Scenic::Definition.new(name, version, :function).to_sql
      end
    end
  end
end
