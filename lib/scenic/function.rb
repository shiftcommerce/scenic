module Scenic
  # The in-memory representation of a function definition.
  #
  # **This object is used internally by adapters and the schema dumper and is
  # not intended to be used by application code. It is documented here for
  # use by adapter gems.**
  #
  # @api extension
  class Function

    # The name of the function
    # @return [String]
    #
    # @example "hello_world"
    attr_reader :name

    # The SQL schema for the query that defines the view
    # @return [String]
    #
    # @example
    #   "CREATE OR REPLACE FUNCTION hello()
    #       RETURNS VARCHAR AS
    #    $$
    #    BEGIN
    #      RETURN 'hello';
    #    END
    #    $$ LANGUAGE plpgsql;"
    attr_reader :definition

    # Returns a new instance of Function.
    #
    # @param name [String] The name of the function.
    # @param definition [String] The code/definition of the function.
    def initialize(name:, definition:)
      @name = name
      @definition = definition
    end

    # @api private
    def ==(other)
      name == other.name &&
        definition == other.definition
    end


    # @api private
    def to_schema
      safe_to_symbolize_name = name.include?(".") ? "'#{name}'" : name

      <<-DEFINITION
  create_function :#{safe_to_symbolize_name}, sql_definition: <<-\SQL
    #{definition.indent(2)}
   SQL

      DEFINITION
    end
  end
end
