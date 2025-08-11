class_name PhraseItem
extends FilterableListItem

func is_valid() -> bool:
	var fills: Array = PracticeDB.extract_fills(text)

	if fills.is_empty():
		return true

	for fill in fills:
		if fill not in PracticeDB.fills:
			return false

		var fill_item: FillItem = FillItem.new()
		fill_item.words = PracticeDB.fills[fill].words
		fill_item.phrases = PracticeDB.fills[fill].phrases
		if not fill_item.is_valid():
			return false

	return true
