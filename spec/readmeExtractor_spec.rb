require 'readmeExtractor'

RSpec.describe ReadmeExtractor do
  let(:extractor) { ReadmeExtractor.new }
  let(:from_directory) { 'spec/fixtures/gems/' }
  let(:to_directory) { TO_DIRECTORY }

  describe '#perform' do
    it 'extracts readme.md from gem files' do
      expect { extractor.perform(from_directory, to_directory) }.not_to raise_error
    end
  end

  describe '#gem_list_prepare' do
    context 'when gem files are present' do
      # rubocop :disable Style/IpAddresses

      it 'extracts and returns a hash of gem names and versions' do
        expect(extractor.gem_list_prepare(from_directory)).to eq({ '3d_cache' => { version: '0.0.01', gem_path: 'spec/fixtures/gems/3d_cache-0.0.01a.gem' }, 'complex-version' => { version: '2.2.2.2', gem_path: 'spec/fixtures/gems/complex-version-2.2.2.2.gem' }, 'llo' => { version: '1.0.0', gem_path: 'spec/fixtures/gems/llo-1.0.0.pre.rc.0.gem' }, 'platform' => { version: '10.1.1', gem_path: 'spec/fixtures/gems/platform-10.1.1-java.gem' }, 'version' => { version: '10.1.1', gem_path: 'spec/fixtures/gems/version-10.1.1.gem' }, 'with_md_readme' => { version: '1.0.0', gem_path: 'spec/fixtures/gems/with_md_readme-1.0.0.gem' }, 'with_metadata' => { version: '1.0.0', gem_path: 'spec/fixtures/gems/with_metadata-1.0.0.gem' }, 'with_rdoc_and_md_readme' => { version: '1.0.0', gem_path: 'spec/fixtures/gems/with_rdoc_and_md_readme-1.0.0.gem' }, 'with_rdoc_readme' => { version: '1.0.0', gem_path: 'spec/fixtures/gems/with_rdoc_readme-1.0.0.gem' } })
      end
      # rubocop :enable Style/IpAddresses
    end

    context 'when gem file names do not match the expected format' do
      it 'raises GemFileNameError' do
        expect do
          extractor.gem_list_prepare('spec/fixtures/broken_gems')
        end.to raise_error(ReadmeExtractor::GemFileNameError, 'badname.gem does not match the expected format.')
      end
    end
    context 'When from is not fodler' do
      it 'raises FromPathError' do
        expect do
          extractor.gem_list_prepare('spec/fixtures/broken_gems__')
        end.to raise_error(ReadmeExtractor::FromPathError, 'Is not a folder')
      end
    end
  end

  describe '#extract_from_gem_file' do
    context 'when the gem contains a README file' do
      it 'finds and reads the md README file' do
        gem_name = 'with_md_readme-1.0.0.gem'
        gem_path = "spec/fixtures/gems/#{gem_name}"
        gem_version = '1.0.0'
        extractor.extract_from_gem_file(gem_path, to_directory, gem_version)
        expect(File.read(Pathname(to_directory).join(gem_name).join('readme.md').to_s)).to eq("## md readme\n")
        expect(File.read(Pathname(to_directory).join(gem_name).join('version').to_s)).to eq(gem_version)
      end
      it 'finds and reads the rdoc README file' do
        gem_name = 'with_rdoc_readme-1.0.0.gem'
        gem_path = "spec/fixtures/gems/#{gem_name}"
        gem_version = 'dummy-version'
        extractor.extract_from_gem_file(gem_path, to_directory, gem_version)
        expect(File.read(Pathname(to_directory).join(gem_name).join('readme.md').to_s)).to eq("# Rdoc Header\n")
        expect(File.read(Pathname(to_directory).join(gem_name).join('version').to_s)).to eq(gem_version)
      end

      it 'return md file if md and rdoc exists in gem' do
        gem_name = 'with_rdoc_and_md_readme-1.0.0.gem'
        gem_path = "spec/fixtures/gems/#{gem_name}"
        gem_version = '1.0.0'
        extractor.extract_from_gem_file(gem_path, to_directory, gem_version)
        expect(File.read(Pathname(to_directory).join('with_rdoc_and_md_readme-1.0.0.gem').join('readme.md').to_s)).to eq("## md readme\n")
        expect(File.read(Pathname(to_directory).join('with_rdoc_and_md_readme-1.0.0.gem').join('version').to_s)).to eq(gem_version)
      end
    end

    context 'when the gem does not contain a README file' do
      it "outputs 'README.MD not found in the gem.'" do
        gem_path = 'spec/fixtures/broken_gems/without_readme-1.0.0.gem'
        expect do
          extractor.extract_from_gem_file(gem_path, to_directory, '1.0.0')
        end.to output("spec/fixtures/broken_gems/without_readme-1.0.0.gem unable to find readme file\n").to_stdout
      end
    end
    context 'when the gem does not contain a data.tar.gz file' do
      it "outputs 'doesnt have data.tar.gz file'" do
        gem_path = 'spec/fixtures/broken_gems/without_data_tar_gz-1.0.0.gem'
        expect do
          extractor.extract_from_gem_file(gem_path, to_directory, '1.0.0')
        end.to output("spec/fixtures/broken_gems/without_data_tar_gz-1.0.0.gem doesnt have data.tar.gz file\n").to_stdout
      end
    end

    context 'when the gem contain a data.tar.gz file' do
      it "outputs 'README.MD not found in the gem.'" do
        gem_path = 'spec/fixtures/gems/with_metadata-1.0.0.gem'
        extractor.extract_from_gem_file(gem_path, to_directory, '1.0.0')
        expect(File).to exist(Pathname(to_directory).join('with_metadata-1.0.0.gem').join('metadata.gz').to_s)
      end
    end

    context 'when the gem file is corrupted or not a valid gzip file' do
      it 'prints an error message' do
        gem_path = 'spec/fixtures/broken_gems/invalid_data_tar_gz-1.0.0.gem'
        expect { extractor.extract_from_gem_file(gem_path, to_directory, '1.0.0') }.to output("Error reading gem file: spec/fixtures/broken_gems/invalid_data_tar_gz-1.0.0.gem, not in gzip format\n").to_stdout
      end
    end
  end
end
