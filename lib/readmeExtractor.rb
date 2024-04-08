# frozen_string_literal: true

require_relative 'readmeExtractor/version'
require 'rubygems/package'
require 'zlib'
require 'fileutils'
require 'pathname'
require 'rdoc'
require 'stringio'
class ReadmeExtractor
  class Error < StandardError; end
  class GemFileNameError < StandardError; end
  class GemContentError < StandardError; end
  class FromPathError < StandardError; end

  def perform(from, to)
    gem_list = gem_list_prepare(from)
    gem_list.each_value do |gem_info|
      puts "Extracting #{gem_info[:gem_path]}..."
      extract_from_gem_file(gem_info[:gem_path], to, gem_info[:version])
    end
  end

  def gem_list_prepare(from)
    raise FromPathError, 'Is not a folder' unless File.directory? from

    gem_paths = Dir[Pathname(from).join('*')]
    gems = {}
    gem_paths.each do |gem_path|
      basename = File.basename gem_path
      match = basename.match(/(?<name>.*?)-(?<version>\d+(?:\.\d+)*).*?.gem/)
      raise GemFileNameError, "#{basename} does not match the expected format." unless match && match[:name] && match[:version]

      name = match[:name]
      version = match[:version]
      gems[name] ||= { version:, gem_path: }
      if Gem::Version.new(version) > Gem::Version.new(gems[name][:version])
        gems[name] = { version:, gem_path: }
      end
    end
    gems
  end

  def extract_from_gem_file(gem_path, to, version)
    output_folder = Pathname(to).join(File.basename(gem_path))
    readme_file = output_folder.join('readme.md').to_s
    metadata_file = output_folder.join('metadata.gz').to_s
    version_file = output_folder.join('version').to_s
    FileUtils.mkdir_p(output_folder)
    File.write(version_file, version)
    magic = File.binread(gem_path, 2)
    is_gzipped = magic == "\x1F\x8B"
    File.open(gem_path, 'rb') do |file|
      file = Zlib::GzipReader.new(file) if is_gzipped

      Gem::Package::TarReader.new(file) do |tar|
        tar.each do |entry|
          case entry.full_name.downcase
          when 'metadata.gz'
            File.binwrite(metadata_file, entry.read)
          when 'data.tar.gz'
            data_tar_io = StringIO.new(entry.read)
            Zlib::GzipReader.wrap(data_tar_io) do |data_gz|
              Gem::Package::TarReader.new(data_gz) do |data_tar|
                data_tar.each do |data_entry|
                  case data_entry.full_name.downcase
                  when 'readme.md'
                    File.write(readme_file, data_entry.read)
                  when 'readme.rdoc'
                    next if File.exist? readme_file

                    File.write(readme_file, RDoc::Markup::ToMarkdown.new.convert(data_entry.read))
                  end
                end
                raise GemContentError, "#{gem_path} unable to find readme file" unless File.exist? readme_file
              end
            end
          end
        end
        raise GemContentError, "#{gem_path} doesnt have data.tar.gz file" unless File.exist? metadata_file
      end
    end
  rescue Zlib::GzipFile::Error => e
    puts "Error reading gem file: #{gem_path}, #{e.message}"
  rescue GemContentError => e
    puts e.message
    # rubocop :disable Lint/DuplicateBranch
  rescue GemFileNameError => e
    puts e.message
  end
  # rubocop:enable Lint/DuplicateBranch
end
