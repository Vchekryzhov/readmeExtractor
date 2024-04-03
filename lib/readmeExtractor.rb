# frozen_string_literal: true

require_relative "readmeExtractor/version"
require "rubygems/package"
require "zlib"
require "fileutils"
require "pathname"
require "rdoc"
class ReadmeExtractor
  class Error < StandardError; end
  class GemFileNameError < StandardError; end
  class GemContentError < StandardError; end
  class FromPathError < StandardError; end

  def perform(from, to)
    gem_list = gem_list_prepare(from)
    gem_list.each do |gem_name, gem_info|
      gem_data = extract_from_gem_file(gem_info[:gem_path])
      FileUtils.mkdir_p("#{to}/#{gem_name}")
      File.write("#{to}/#{gem_name}/readme.md", gem_data[:readme])
      File.write("#{to}/#{gem_name}/metadata.yml", gem_data[:metadata])
      File.write("#{to}/#{gem_name}/version", gem_data[:version])
    end
  end

  def gem_list_prepare(from)
    raise FromPathError, 'Is not a folder' unless File.directory? from
    gem_paths = Dir["#{from}/*"]
    gems = {}
    gem_paths.each do |gem_path|
      basename = File.basename gem_path
      match = basename.match(/(?<name>.*?)-(?<version>\d+(?:\.\d+)*)(?:-(?<platform>[^.]+))?.gem/)
      unless match && match[:name] && match[:version]
        raise GemFileNameError, "#{basename} does not match the expected format."
      end
      name = match[:name]
      version = match[:version]
      gems[name] ||= { version:, gem_path:}
      if Gem::Version.new(version) > Gem::Version.new(gems[name][:version])
        gems[name] = { version:, gem_path:}
      end
    end
    gems
  end

  def extract_from_gem_file(gem_path)
    r = {
      readme: nil,
      metadata: nil
    }
    magic = File.binread(gem_path, 2)
    is_gzipped = magic == "\x1F\x8B"
    File.open(gem_path, "rb") do |file|
      file = Zlib::GzipReader.new(file) if is_gzipped

      Gem::Package::TarReader.new(file) do |tar|
        tar.each do |entry|
          case entry.full_name.downcase
          when 'metadata.gz'
              r['metadata.gz'] = entry.read
          when "data.tar.gz"
            data_tar_io = StringIO.new(entry.read)
            Zlib::GzipReader.wrap(data_tar_io) do |data_gz|
              Gem::Package::TarReader.new(data_gz) do |data_tar|
                data_tar.each do |data_entry|
                  case data_entry.full_name.downcase
                  when "readme.md"
                    r[:readme] = data_entry.read
                  when 'readme.rdoc'
                    next if r[:readme]
                    r[:readme] =  RDoc::Markup::ToMarkdown.new.convert(data_entry.read)
                  end
                end
                raise GemContentError, "#{gem_path} unable to find readme file" unless r[:readme]
              end
            end
          end
        end
        raise GemContentError, "#{gem_path} doesnt have data.tar.gz file" unless r[:readme] || r[:metadata]
      end
    end
    r
  rescue Zlib::GzipFile::Error => e
    puts "Error reading gem file: #{gem_path}, #{e.message}"
  rescue GemContentError => e
    puts e.message
  rescue GemFileNameError => e
    puts e.message
  end
end
