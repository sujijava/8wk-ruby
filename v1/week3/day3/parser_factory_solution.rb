# Solution for Parser Factory Challenge
# Write your solution here

class Parser
  def parse(data)
    raise NotImplementedError
  end
end

class JSONParser < Parser
  def parse(data)
    JSON.parse(data, symbolize_names: true)
  end
end

class CSVParser < Parser
  def parse(data)
    rows = CSV.parse(data, headers: true)
    rows.map { |row| row.to_h.transform_keys(&:to_sym) }
  end
end

class ParserFactory
  @parsers = {
    "csv": CSVParser.new,
    "json": JSONParser.new,
  }

  def self.create_parser(file_name)
    extension = file_name.split('.').last

    parser_class = @parsers[extension]
    raise ArgumentError, "Unknown extension: #{extension}" unless parser_class
    
    parser_class
  end
end