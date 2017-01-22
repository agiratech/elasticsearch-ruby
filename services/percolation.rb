require 'typhoeus/adapters/faraday'
require 'elasticsearch'
require 'pry'
module Services
  class Percolation

    def initialize(cfg)
      @cfg = cfg
      transport_configuration = lambda do |f|
        f.response :logger
        f.adapter  :typhoeus
      end
      transport = Elasticsearch::Transport::Transport::HTTP::Faraday.new hosts: [
        { host: @cfg['elastic']['url'], port: @cfg['elastic']['port'] } ], &transport_configuration
      @server = Elasticsearch::Client.new log: true, transport: transport
    end

    def re_index
      index_name = "percolator-index"
      delete_index(index_name)
      create_index(index_name)
      ds = ['foo', 'bar']
      ds.map do |i|
        index(i, index_name)
      end
    end

    def delete_index(index_name)
      if @server.indices.exists? index: index_name
        @server.indices.delete index: index_name
      end
    end

    def create_index(index_name)
      @server.indices.create index: index_name, body: {
        mappings: {
          doctype: {
            properties: {
              message: {
                type: "text"
              }
            }
          },
          queries: {
            properties: {
              query: {
                type: "percolator"
              }
            }
          }
        }
      }
    end

    def index(ds, index_name)
      query = { query: { match: { message: "#{ds}" } } }
      begin
        r = @server.index index: index_name, type: 'queries', id: ds, body: query
        puts 'Indexing result:'
        puts r.inspect
      rescue Faraday::Error::ResourceNotFound,
          Faraday::Error::ClientError,
          Faraday::Error::ConnectionFailed => e
        puts "Connection failed: #{e}"
        false
      end
    end

    def list_document(index_name='percolator-index')
      sleep 2
      doc = { query: { percolate: { field: "query", document_type: "doctype",document: {message: 'message foo bar'} } } }
      data = @server.search index: index_name, type: 'queries', body: doc
      puts "final result"
      puts data
    end

  end
end