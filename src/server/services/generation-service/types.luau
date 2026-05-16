export type Room = Model & {
	Nodes: {
		EntitySpawns: Folder,
		Barricade: Folder,
		Path: Folder,
		Room: Folder,
	},
	Collision: {
		Barrier: Folder,
		Entity: Folder,
	},
	Static: Folder,
	Root: BasePart,
}

return {}
