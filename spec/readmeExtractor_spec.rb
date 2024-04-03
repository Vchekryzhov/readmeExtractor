require "readmeExtractor"

RSpec.describe ReadmeExtractor do
  let(:extractor) { ReadmeExtractor.new }
  let(:from_directory) { "spec/fixtures/gems/" } # Ensure this directory contains test .gem files
  let(:to_directory) { "spec/fixtures/output/" }


  describe "#perform" do
    it "extracts readme.md from gem files" do
      expect { extractor.perform(from_directory, to_directory) }.not_to raise_error
    end
  end

  describe "#gem_list_prepare" do
    context "when gem files are present" do
      it "extracts and returns a hash of gem names and versions" do
        expect(extractor.gem_list_prepare(from_directory)).to eq({"platform"=> {version: '10.1.1', gem_path: 'platform-10.1.1-java.gem'}, "complex-version"=>{:version=>"2.2.2.2", :gem_path=>"complex-version-2.2.2.2.gem"}, "version"=>{:version=>"10.1.1", :gem_path=>"version-10.1.1.gem"}, "with_md_readme"=>{:version=>"1.0.0", :gem_path=>"with_md_readme-1.0.0.gem"}, "with_metadata"=>{:version=>"1.0.0", :gem_path=>"with_metadata-1.0.0.gem"}, "with_rdoc_and_md_readme"=>{:version=>"1.0.0", :gem_path=>"with_rdoc_and_md_readme-1.0.0.gem"}, "with_rdoc_readme"=>{:version=>"1.0.0", :gem_path=>"with_rdoc_readme-1.0.0.gem"}})
      end
    end

    context "when gem file names do not match the expected format" do
      it "raises GemFileNameError" do
        expect do
          extractor.gem_list_prepare("spec/fixtures/broken_gems")
        end.to raise_error(ReadmeExtractor::GemFileNameError, "badname.gem does not match the expected format.")
      end
    end
    context "When from is not fodler" do
      it "raises FromPathError" do
        expect do
          extractor.gem_list_prepare("spec/fixtures/broken_gems__")
        end.to raise_error(ReadmeExtractor::FromPathError, "Is not a folder")
      end
    end
  end

  describe "#extract_from_gem_file" do
    context "when the gem contains a README file" do
      it "finds and reads the md README file" do
        gem_path = "spec/fixtures/gems/with_md_readme-1.0.0.gem" # Ensure this path is correct
        expect(extractor.extract_from_gem_file(gem_path)[:readme]).to eq("## md readme\n")
      end
      it "finds and reads the rdoc README file" do
        gem_path = "spec/fixtures/gems/with_rdoc_readme-1.0.0.gem" # Ensure this path is correct
        expect(extractor.extract_from_gem_file(gem_path)[:readme]).to eq("# Rdoc Header\n")
      end

      it "return md file if md and rdoc exists in gem" do
        gem_path = "spec/fixtures/gems/with_rdoc_and_md_readme-1.0.0.gem" # Ensure this path is correct
        expect(extractor.extract_from_gem_file(gem_path)[:readme]).to eq("## md readme\n")
      end
    end

    context "when the gem does not contain a README file" do
      it "outputs 'README.MD not found in the gem.'" do
        gem_path = "spec/fixtures/broken_gems/without_readme-1.0.0.gem" # Ensure this gem does not contain a README
        expect do
          extractor.extract_from_gem_file(gem_path)
        end.to output("spec/fixtures/broken_gems/without_readme-1.0.0.gem unable to find readme file\n").to_stdout
      end
    end
    context "when the gem does not contain a data.tar.gz file" do
      it "outputs 'README.MD not found in the gem.'" do
        gem_path = "spec/fixtures/broken_gems/without_data_tar_gz-1.0.0.gem" # Ensure this gem does not contain a README
        expect do
          extractor.extract_from_gem_file(gem_path)
        end.to output("spec/fixtures/broken_gems/without_data_tar_gz-1.0.0.gem doesnt have data.tar.gz file\n").to_stdout
      end
    end

    context "when the gem file is corrupted or not a valid gzip file" do
      it "prints an error message" do
        gem_path = "spec/fixtures/broken_gems/invalid_data_tar_gz-1.0.0.gem" # Ensure this is a corrupted or invalid file
        expect { extractor.extract_from_gem_file(gem_path) }.to output("Error reading gem file: spec/fixtures/broken_gems/invalid_data_tar_gz-1.0.0.gem, not in gzip format\n" ).to_stdout
      end
    end
  end
end
