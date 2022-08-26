package schema

#Blueprint: {
	#Env: [string]: string
	[string]: {
		tasks: [task=string]: {id: task, #TaskBuilder}
		results: [string]: description: string
		...
	}
}
