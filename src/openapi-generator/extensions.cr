# :nodoc:
# Define a `self.to_openapi_schema` method for the Array class.
class Array(T)
  # Converts an Array to an OpenAPI schema.
  def self.to_openapi_schema
    schema_items = nil

    {% begin %}
      {% array_types = T.union_types %}

      ::OpenAPI::Generator::Serializable::Utils.generate_schema(
        schema_items,
        types: {{array_types}},
      )
    {% end %}

    OpenAPI::Schema.new(
      type: "array",
      items: schema_items
    )
  end
end

# :nodoc:
# Define a `self.to_openapi_schema` method for the Tuple struct.
#
# OpenAPI 3.0 does not support tuples (3.1 does), so we serialize it into a fixed bounds array.
# see: https://github.com/OAI/OpenAPI-Specification/issues/1026
struct Tuple
  def self.to_openapi_schema
    schema_items = nil

    {% begin %}
      {% types = [] of Types %}
      {% for i in 0...T.size %}
        {% for t in T[i].union_types %}
          {% types << t %}
        {% end %}
      {% end %}

      ::OpenAPI::Generator::Serializable::Utils.generate_schema(
        schema_items,
        types: {{ types }},
      )
    {% end %}

    OpenAPI::Schema.new(
      type: "array",
      items: schema_items,
      min_items: {{ T.size }},
      max_items: {{ T.size }}
    )
  end
end

# :nodoc:
# Define a `self.to_openapi_schema` method for the Hash class.
class Hash(K, V)
  # Returns the OpenAPI schema associated with the Hash.
  def self.to_openapi_schema
    additional_properties = nil

    {% begin %}
      {% value_types = V.union_types %}

      ::OpenAPI::Generator::Serializable::Utils.generate_schema(
        additional_properties,
        types: {{value_types}},
      )
    {% end %}

    OpenAPI::Schema.new(
      type: "object",
      additional_properties: additional_properties
    )
  end
end

# :nodoc:
# Define a `self.to_openapi_schema` method for the NamedTuple struct.
struct NamedTuple
  # Returns the OpenAPI schema associated with the NamedTuple.
  def self.to_openapi_schema
    schema = OpenAPI::Schema.new(
      type: "object",
      properties: Hash(String, (OpenAPI::Schema | OpenAPI::Reference)).new,
      required: [] of String
    )

    {% begin %}
      {% for key, value in T %}
        {% types = value.union_types %}
        ::OpenAPI::Generator::Serializable::Utils.generate_schema(
          schema,
          types: {{types}},
          schema_key: {{key}}
        )
      {% end %}
    {% end %}

    if schema.required.try &.empty?
      schema.required = nil
    end

    schema
  end
end

# :nodoc:
class String
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      type: "string"
    )
  end
end

# :nodoc:
abstract struct Number
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      type: "number"
    )
  end
end

# :nodoc:
abstract struct Int
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      type: "integer"
    )
  end
end

# :nodoc:
struct Bool
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      type: "boolean"
    )
  end
end

# :nodoc:
# Define a `self.to_openapi_schema` method for the enum.
struct Enum
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      title: {{@type.name.id.stringify.split("::").join("_")}},
      type: "integer",
      enum: self.values.map(&.to_i64)
    )
  end
end

# Define a `self.to_openapi_schema` method for the Time struct.
struct Time
  # Converts a Time data to an OpenAPI date-time format.
  # https://swagger.io/docs/specification/data-models/data-types/
  # :nodoc:
  def self.to_openapi_schema
    OpenAPI::Schema.new(
      type: "string",
      format: "date-time"
    )
  end
end

module OpenAPI
  # :nodoc:
  # Used to declare path parameters.
  struct Operation
    setter parameters
  end

  # :nodoc:
  class Schema
    setter read_only
    setter write_only
    setter required
    setter description
  end

  # :nodoc:
  struct Response
    setter content
  end

  # :nodoc:
  struct Components
    setter schemas
  end
end
