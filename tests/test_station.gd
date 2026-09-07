extends GutTest


func test_stores_its_fields():
	var station := Station.new("A", Vector2i(0, 3), "red", Station.Role.SOURCE)
	assert_eq(station.id, "A")
	assert_eq(station.cell, Vector2i(0, 3))
	assert_eq(station.color, "red")
	assert_eq(station.role, Station.Role.SOURCE)


func test_is_source_and_is_destination():
	var source := Station.new("A", Vector2i(0, 0), "red", Station.Role.SOURCE)
	var destination := Station.new("B", Vector2i(9, 9), "red", Station.Role.DESTINATION)
	assert_true(source.is_source())
	assert_false(source.is_destination())
	assert_true(destination.is_destination())
	assert_false(destination.is_source())
