require "lucky"
require "./base"

# Provides the list of declared routes.
class OpenAPI::Generator::RoutesProvider::Lucky < OpenAPI::Generator::RoutesProvider::Base
  # Return a list of routes mapped with the action classes.
  def route_mappings : Array(RouteMapping)
    routes = [] of RouteMapping
    # In the following we `reverse` and `uniq` Lucky routes to filter
    # out HEAD routes that are automatically generated for GET routes.
    ::Lucky.router.list_routes.reverse.uniq(&.last).each do |route|
      # A route is a `Tuple` as follows: `{path, method, action}`
      paths, path_params = route[0]
        # Split on /
        .split("/")
        # Reformat positional parameters from ":xxx" or "?:xxx" to "{xxx}"
        .reduce({[] of String, [] of String}) { |acc, segment|
          path_array, params = acc
          if segment.starts_with?(':') || segment.starts_with?('?')
            param = segment.gsub(/^[?:]+/, "")
            path_array << "{#{param}}"
            params << param
            acc
          else
            path_array << segment
            acc
          end
        }
      routes << {route[1].to_s, paths.join("/"), route[2].to_s, path_params}
    end
    routes
  end
end
