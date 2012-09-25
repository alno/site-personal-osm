Sequel.migration do

  change do
    create_table :map_errors do
      column :id, 'bigserial', :primary_key => true

      column :source, 'text', :null => false
      column :source_id, 'text', :null => false

      unique [:source, :source_id]

      column :types, 'text[]', :null => false
      column :text, 'text'
      column :url, 'text'
      column :geometry, 'GEOGRAPHY(Geometry,4326)', :null => false
      column :objects, 'text[]'
      column :params, 'HSTORE'

      column :created_at, 'TIMESTAMP', :null => false
      column :updated_at, 'TIMESTAMP', :null => false
      column :deleted_at, 'TIMESTAMP'

      spatial_index :geometry, :where => 'deleted_at IS NULL'
    end
  end

end
