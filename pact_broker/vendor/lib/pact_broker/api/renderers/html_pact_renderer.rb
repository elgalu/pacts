require 'pact/consumer_contract'
require 'pact/reification'
# require 'redcarpet'
require 'kramdown'
require 'tilt/erubis'
require 'pact/doc/markdown/consumer_contract_renderer'
require 'pact_broker/api/pact_broker_urls'
require 'pact_broker/logging'

module PactBroker
  module Api
    module Renderers
      class HtmlPactRenderer

        class NotAPactError < StandardError; end

        include PactBroker::Logging

        def self.call pact
          new(pact).call
        end

        def initialize pact
          @json_content = pact.json_content
          @pact = pact
        end

        def call
          "<html>
            <head>#{head}</head>
            <body>
              #{pact_metadata}#{html}
            </body>
          </html>"
        end

        private

        def head
         "<link rel='stylesheet' type='text/css' href='/stylesheets/github.css'>
          <link rel='stylesheet' type='text/css' href='/stylesheets/pact.css'>
          <link rel='stylesheet' type='text/css' href='/stylesheets/github-json.css'>
          <script src='/javascripts/highlight.pack.js'></script>
          <script src='/javascripts/adrum.js'></script>
          <script>hljs.initHighlightingOnLoad();</script>"
        end

        def pact_metadata
          "<div class='pact-metadata'>
            <ul>
              <li>
                <span class='name'>#{@pact.consumer.name} version:</span>
                <span class='value'>#{@pact.consumer_version_number}</span>
              </li>
              <li>
                <span class='name'>Date published:</span>
                <span class='value'>#{published_date}</span>
              </li>
              <li>
                <a href=\"#{json_url}\">View in HAL Browser</a>
              </li>
            </ul>
          </div>"
        end

        def published_date
          @pact.updated_at.to_time.localtime.to_datetime.strftime("%a %d %b %Y, %l:%M%P %:z")
        end

        def json_url
          PactBroker::Api::PactBrokerUrls.hal_browser_url pact_url
        end

        def pact_url
          PactBroker::Api::PactBrokerUrls.pact_url '', @pact
        end

        def markdown
          Pact::Doc::Markdown::ConsumerContractRenderer.call consumer_contract
        rescue NotAPactError
          heading = "### A contract between #{@pact.consumer.name} and #{@pact.provider.name}"
          warning = "_Note: this contract could not be parsed to a Pact, showing raw content instead._"
          pretty_json = JSON.pretty_generate(@pact.content_hash)
          "#{heading}\n#{warning}\n```json\n#{pretty_json}\n```\n"
        end

        def html
          #== redcarpet ==#
          # opts = { fenced_code_blocks: true, lax_spacing: true }
          # Redcarpet::Markdown.new(Redcarpet::Render::HTML, opts).render(markdown)

          #== kramdown with rougue ==#
          opts = { syntax_highlighter: 'rouge' }

          #== kramdown ==#
          # opts = {}

          Kramdown::Document.new(markdown, opts).to_html.
            gsub('<code ', '<pre><code ').
            gsub('<code>', '<pre><code>').
            gsub('</code>', '</code></pre>')
        end

        def consumer_contract
          Pact::ConsumerContract.from_json(@json_content)
        rescue => e
          logger.warn "#{e.class} #{e.message} #{e.backtrace.join("\n")}"
          logger.warn "Could not parse the following content to a Pact, showing raw content instead: #{@json_content}"
          raise NotAPactError
        end

      end
    end
  end
end