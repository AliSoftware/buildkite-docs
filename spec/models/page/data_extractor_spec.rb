require 'rails_helper'

RSpec.describe Page::DataExtractor do
  describe "page title and description fields" do
    it "extracts data from basic markdown" do
      md = <<~MD
        # Page title

        Some description
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => "Page title",
        "sections" => [],
        "shortDescription" => "Some description",
        "textContent" => "Some description"
      })
    end

    it "Takes the first page title only" do
      md = <<~MD
        # Page title

        # Another page title? Weird!

        Some description
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => "Page title",
        "sections" => [],
        "shortDescription" => "Some description",
        "textContent" => "Some description"
      })
    end

    it "ignores h3s outside of sections" do
      md = <<~MD
        ### Meow

        Sub section text
      MD

      expect(Page::DataExtractor.extract(md)).to include({
        "sections" => []
      })
    end

    it "extracts sections from secondary headings" do
      md = <<~MD
        # Page title

        Some description

        And some more description here

        ## Here's a second heading

        More text goes here!

        ### Meow

        Sub section text

        ## Here's another!

        Yet more text goes in this section
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => "Page title",
        "sections" => [
          {
            id: "heres-a-second-heading",
            header: "Here's a second heading",
            subsections: [
              { id: "meow", header: "Meow" },
            ]
          },
          { id: "heres-another", header: "Here's another!", subsections: [] },
        ],
        "shortDescription" => "Some description",
        "textContent" => <<~MD.strip
          Some description

          And some more description here
        MD
      })
    end

    it "ignores raw HTML tags in the description" do
      md = <<~MD
        # Page title

        Some description

        <img src="https://placekitten.com/320/240" />

        More text goes here
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => "Page title",
        "sections" => [],
        "shortDescription" => "Some description",
        "textContent" => <<~MD.strip
          Some description

          More text goes here
        MD
      })
    end

    it "supports {: code-filename=\"file.md\"} filenames for code blocks" do
      md = <<~MD
        ```json
        { "key": "value" }
        ```
        {: codeblock-file="file.json"}
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => nil,
        "sections" => [],
        "shortDescription" => "",
        "textContent" => <<~MD.strip
          <figure class="highlight-figure"><figcaption>file.json</figcaption>

          ``` json
          { "key": "value" }
          ```

          </figure>
        MD
      })
    end
  end

  describe "attributes" do
    it "extracts content from HTML table elements" do
      md = <<~MD
        <table data-attributes data-attributes-required>
          <tr>
            <td><code>command</code></td>
            <td>
              <img src="https://placekitten.com/480/272" />
              <img src="https://placekitten.com/640/480" />
            </td>
          </tr>
        </table>

        <table data-attributes>
          <tr>
            <td><code>another-thing</code></td>
            <td>
              <img src="https://placekitten.com/480/272" />
              <img src="https://placekitten.com/640/480" />
            </td>
          </tr>
        </table>
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [
          {
            "isRequired" => true,
            "name" => "command",
            "textContent" => <<~MD.strip
              <div><img src="https://placekitten.com/480/272">
                    <img src="https://placekitten.com/640/480"></div>
            MD
          },
          {
            "isRequired" => false,
            "name" => "another-thing",
            "textContent" => <<~MD.strip
              <div><img src="https://placekitten.com/480/272">
                    <img src="https://placekitten.com/640/480"></div>
            MD
          }
        ],
        "name" => nil,
        "sections" => [],
        "shortDescription" => nil,
        "textContent" => ""
      })
    end

    it "ignores tables which do not have data-attributes" do
      md = <<~MD
        <table>
          <tr>
            <td><code>another-thing</code></td>
            <td>
              <img src="https://placekitten.com/480/272" />
              <img src="https://placekitten.com/640/480" />
            </td>
          </tr>
        </table>
      MD

      expect(Page::DataExtractor.extract(md)).to eql({
        "attributes" => [],
        "name" => nil,
        "sections" => [],
        "shortDescription" => nil,
        "textContent" => ""
      })
    end
  end
end
