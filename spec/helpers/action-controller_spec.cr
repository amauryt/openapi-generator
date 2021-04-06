require "json"
require "file_utils"
require "action-controller"
require "../spec_helper"
require "../../src/openapi-generator/helpers/action-controller"

class Payload
  include JSON::Serializable
  extend OpenAPI::Generator::Serializable

  def initialize(@hello : String = "world")
  end
end

class HelloPayloadActionController < ActionController::Base
  include ::OpenAPI::Generator::Controller
  include ::OpenAPI::Generator::Helpers::ActionController

  base "/hello"

  @[OpenAPI(
    <<-YAML
      summary: Sends a hello payload
      responses:
        200:
          description: Overriden
    YAML
  )]
  def create
    mandatory = query_params mandatory : String, "A mandatory query parameter"
    optional = query_params optional : String?, "An optional query parameter"

    body_as Payload?, description: "A Hello payload."

    payload = Payload.new(hello: (!!mandatory).to_s)
    respond_with 200, description: "Hello" do
      json payload, type: Payload
      xml "<hello></hello>", type: String
    end
    respond_with 201, description: "Not Overriden" do
      text "Good morning.", type: String
    end
    respond_with 400 do
      text "Ouch.", schema: String.to_openapi_schema
    end
  end
end

require "../../src/openapi-generator/providers/action-controller.cr"

OpenAPI::Generator::Helpers::ActionController.bootstrap

describe OpenAPI::Generator::Helpers::ActionController do
  after_all {
    FileUtils.rm "openapi_test.yaml"
  }

  it "should infer the status codes and contents of the response body" do
    options = {
      output: Path[Dir.current] / "openapi_test.yaml",
    }
    base_document = {
      info:       {title: "Test", version: "0.0.1"},
      components: NamedTuple.new,
    }

    OpenAPI::Generator.generate(
      OpenAPI::Generator::RoutesProvider::ActionController.new,
      options: options,
      base_document: base_document
    )

    openapi_file_contents = File.read "openapi_test.yaml"
    openapi_file_contents.should eq <<-YAML
    ---
    openapi: 3.0.1
    info:
      title: Test
      version: 0.0.1
    paths:
      /hello:
        post:
          summary: Sends a hello payload
          parameters:
          - name: mandatory
            in: query
            description: A mandatory query parameter
            required: true
            schema:
              type: string
          - name: optional
            in: query
            description: An optional query parameter
            required: false
            schema:
              type: string
          requestBody:
            description: A Hello payload.
            content:
              application/json:
                schema:
                  allOf:
                  - $ref: '#/components/schemas/Payload'
            required: false
          responses:
            "200":
              description: Hello
              content:
                application/json:
                  schema:
                    allOf:
                    - $ref: '#/components/schemas/Payload'
                application/xml:
                  schema:
                    type: string
            "201":
              description: Not Overriden
              content:
                text/plain:
                  schema:
                    type: string
            "400":
              description: Bad Request
              content:
                text/plain:
                  schema:
                    type: string
    components:
      schemas:
        Model:
          required:
          - string
          - inner_schema
          - cast
          type: object
          properties:
            string:
              type: string
            opt_string:
              type: string
              readOnly: true
            inner_schema:
              $ref: '#/components/schemas/Model_InnerModel'
            cast:
              type: string
              example: "1"
        Model_InnerModel:
          required:
          - array_of_int
          type: object
          properties:
            array_of_int:
              type: array
              items:
                type: integer
              writeOnly: true
        Model_ComplexModel:
          required:
          - union_types
          - free_form
          - array_of_hash
          type: object
          properties:
            union_types:
              oneOf:
              - type: object
                additionalProperties:
                  $ref: '#/components/schemas/Model_InnerModel'
              - type: integer
              - type: string
            free_form:
              type: object
              additionalProperties: true
            array_of_hash:
              type: array
              items:
                type: object
                additionalProperties:
                  oneOf:
                  - type: integer
                  - type: string
        Payload:
          required:
          - hello
          type: object
          properties:
            hello:
              type: string
      responses: {}
      parameters: {}
      examples: {}
      requestBodies: {}
      headers: {}
      securitySchemes: {}
      links: {}
      callbacks: {}

    YAML
  end

  it "should implement the helper methods" do
    res = HelloPayloadActionController.context(method: "GET", route: "/hello?mandatory", headers: {"Content-Type" => "application/json"}, &.create)
    res.status_code.should eq(200)
    res.output.to_s.should eq(Payload.new(hello: "true").to_json)
  end
end
