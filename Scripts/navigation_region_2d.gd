extends NavigationRegion2D

func _ready():
	# Wait for all walls and blocks to exist in the tree
	await get_tree().process_frame
	setup_navigation()

func setup_navigation():
	if navigation_polygon == null:
		print("Error: Please assign a 'New NavigationPolygon' in the Inspector first!")
		return
	
	# Clear old paths
	navigation_polygon.clear()
	
	# Tell it to look for walls (StaticBodys/TileMaps)
	navigation_polygon.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	navigation_polygon.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	# This is the "Safe" way to bake in Godot 4
	NavigationServer2D.bake_from_source_geometry_data(navigation_polygon, NavigationMeshSourceGeometryData2D.new())
	
	# Force the region to update with the new map
	navigation_polygon = navigation_polygon 
	
	print("Navigation Mesh baked and ready!")
