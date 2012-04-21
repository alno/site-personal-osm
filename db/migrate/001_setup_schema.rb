Sequel.migration do

  change do
    create_table :osm_errors do
      column :id, 'bigserial', :primary_key => true

      column :source, 'varchar(50)', :null => false
      column :source_id, 'varchar(255)', :null => false

      unique [:source, :source_id]

      column :type, 'varchar(50)', :null => false
      column :text, 'text'
      column :geometry, 'GEOGRAPHY(Geometry,4326)'
      column :objects, 'VARCHAR(50)[]'
    end
  end

end
