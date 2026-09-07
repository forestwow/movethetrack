extends GutTest


func test_stores_its_fields():
	var train := Train.new("train_1", "A", "B", "red")
	assert_eq(train.id, "train_1")
	assert_eq(train.start_station_id, "A")
	assert_eq(train.target_station_id, "B")
	assert_eq(train.color, "red")
