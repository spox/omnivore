macro snake_case(string)
  {{string}}.split("::").map do |part|
    part.gsub(/([a-z])([A-Z])/, "\1_\2").gsub("-", "_").downcase
  end.join("_")
end
