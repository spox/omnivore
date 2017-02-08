require "json"
require "option_parser"
require "logger"
require "secure_random"
require "crogo"
require "./omnivore/macros"
require "./omnivore/utils"
require "./omnivore/*"

module Omnivore

  @@startup_waiter : Channel::Buffered(Bool) = Channel(Bool).new(1)
  @@application : Omnivore::Application | Nil
  @@logger = ::Logger.new(STDOUT)

  # @return [Logger] default application logger
  def self.logger
    @@logger
  end

  # @return [Application] currently running application instance
  def self.application : Application
    app = @@application
    if(app.nil?)
      raise Error::NoApplication.new("Application has not been initialized!")
    else
      app
    end
  end

  # @return [Bool] application is running
  def self.wait_for_startup : Bool
    if(@@application.nil?)
      !!@@startup_waiter.receive?
    else
      true
    end
  end

  # Start the application
  #
  # @param options [Hash(String, String | Bool)]
  # @return [Nil]
  def self.run!(options : Hash(String, String | Bool))
    config_path = options.fetch("config", nil).to_s
    configuration = Configuration.new(config_path.empty? ? nil : config_path)
    logger_conf = configuration.get("logger", type: :hash)
    if(logger_conf)
      logger_conf = configuration.hashify(logger_conf.as(Hash(String, JSON::Type)))
    else
      logger_conf = {} of String => String
    end
    configure_logger(options, logger_conf)
    logger.info "Configuration loading and logger setup complete"
    application = build_application(configuration)
    @@application = application
    @@startup_waiter.send(true)
    Signal::INT.trap do
      application.halt!
      @@application = nil
    end
    begin
      logger.info "Core initialization complete. Starting application consumption."
      application.consume!
      logger.info "Application consumption is complete. Shutting down."
      nil
    rescue error
      logger.fatal "Unexpected error encountered during consumption! #{error.class}: #{error.message}"
      logger.debug "#{error.class}: #{error.message}\n#{error.backtrace.join("\n")}"
      raise error
    end
  end

  # Halt the application
  #
  # @return [Nil]
  def self.halt!
    application.halt!
    @@application = nil
  end

  # Build new application type based on configuration
  #
  # @param conf [Configuration]
  # @return [Application]
  def self.build_application(conf : Configuration) : Application
    app_type = conf.get("application") || "default"
    klass = Application.applications[app_type.to_s]
    klass.new(conf)
  end

  # Configure application logger based on settings/configuration
  #
  # @param cli [Hash(String, String | Bool)] CLI options
  # @param config [Hash(String, String)] logger configuration options
  # @return [Logger]
  def self.configure_logger(cli : Hash(String, String | Bool), config : Hash(String, String))
    path = cli.fetch("log_path", config["path"]?)
    if(path)
      @@logger = ::Logger.new(File.open(path.to_s, "a+"))
    end
    level = cli.fetch("verbosity", config["verbosity"]?)
    if(level)
      case level.to_s
      when "debug"
        @@logger.level = Logger::DEBUG
      when "info"
        @@logger.level = Logger::INFO
      when "warn"
        @@logger.level = Logger::WARN
      when "error"
        @@logger.level = Logger::ERROR
      when "fatal"
        @@logger.level = Logger::FATAL
      end
    end
    @@logger.progname = config.fetch("name", "omnivore").to_s
    @@logger
  end

end

cli_options = {} of String => String | Bool

begin
  OptionParser.parse! do |parser|
    parser.banner = "Usage: omnivore [arguments]"
    parser.on("-v", "--version", "Print current version") do
      cli_options["version"] = true
    end
    parser.on("-c PATH", "--config=PATH", "Path to configuration file") do |path|
      cli_options["config"] = path
    end
    parser.on("-V LEVEL", "--verbosity=LEVEL", "Set logging output level") do |level|
      cli_options["verbosity"] = level
    end
    parser.on("-l PATH", "--log-to=PATH", "Path to log file") do |path|
      cli_options["log_path"] = path
    end
    parser.on("-d", "--debug", "Enable debug output") do
      cli_options["debug"] = true
    end
    parser.on("-h", "--help", "Display this help message") do
      cli_options["help"] = true
      puts parser
    end
  end
rescue error
  puts "Option parsing error - #{error.message}"
  exit -1
end

if(cli_options["help"]?)
  exit 0
elsif(cli_options["version"]?)
  puts "Version: 1.0.0"
  exit 0
end

unless(ENV["OMNIVORE_SPEC"]?)
  begin
    Omnivore.run!(cli_options)
  rescue error
    puts "Unexpected error encountered! #{error.message}"
    exit -1
  end
end
