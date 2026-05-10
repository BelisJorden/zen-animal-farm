extends Node

# Farm / world
signal animal_placed(animal: Node)
signal animal_removed(animal: Node)
signal tile_selected(tile_pos: Vector2i)
signal farm_unlocked(farm_id: String)

# Animals
signal animal_combined(result_animal: Node)
signal animal_trained(animal: Node)
signal animal_sent_to_spa(animal: Node)
signal animal_returned_from_spa(animal: Node)

# Resources
signal coins_earned(amount: int)
signal coins_changed(new_amount: int)
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
