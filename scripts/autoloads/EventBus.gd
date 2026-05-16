extends Node

# Farm / world
signal animal_placed(animal: Node)
signal animal_removed(animal: Node)
signal farm_data_loaded(placed_animals: Array)
signal tile_selected(col: int, row: int, world_pos: Vector3)
signal tile_deselected()
signal tile_tapped(col: int, row: int, world_pos: Vector3)
signal farm_unlocked(farm_id: String)

# Animals
signal animal_combined(result_animal: Node)
signal animal_trained(animal: Node)
signal animal_sent_to_spa(animal: Node)
signal animal_returned_from_spa(animal: Node)

# Resources
signal coins_earned(amount: int)
signal coins_changed(new_amount: int)
signal coins_per_second_changed(cps: float)
signal coins_collected(amount: int, world_pos: Vector3)
signal spirit_shard_collected(amount: int)

# Hatchery
signal egg_tapped(progress: int)
signal egg_hatched(animal_data: Dictionary)

# Quests
signal quest_progress_updated(quest_id: String, current: int, target: int)
signal quest_completed(quest_id: String)

# Inventory
signal inventory_changed

# UI
signal tab_changed(tab_name: String)
signal placing_mode_entered(animal_data: Dictionary)
signal placing_mode_exited()
signal notification_requested(message: String)

# Golden animal
signal golden_animal_spawned(animal_node: Node, farm_id: String)
signal golden_animal_collected(amount_coins: int, amount_shards: int)
signal golden_animal_expired()
