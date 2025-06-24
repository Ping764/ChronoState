# ChronoState
**A coroutine-aware, asynchronous-first state machine module for Roblox!**

---

## Documentation

### Creating a new state controller:
To start using the state machine, we have to first create the 'StateController' and pass a table with the indexed states.
```luau
-- Use 'ChronoState.new' to create a new state controller.
local StateController = ChronoState.new({
	-- Each state needs to have an 'Enter' and 'Exit' function, with the state controller as self.
	
	Idle = {
		Enter = function(self: ChronoState.StateController) print('Entered idle state.') end;
		Exit = function(self: ChronoState.StateController) print('Leaving idle state.') end;
	};
	
	Attack = {
		Enter = function(self: ChronoState.StateController) print('Entered attack state.') end;
		Exit = function(self: ChronoState.StateController) print('Leaving attack state.') end;
	};
})
```
Using ```ChronoState.new(StatesTable: {[any]: ModularState})``` we've now created a 'StateController'. With it, it's now possible to start using the states.

### Using and switching states:
When changing states, if a state is currently executing, ChronoState will wait for it to reach the 'idle' status (i.e., after it completes the 'Enter' coroutine). Once idle, it will run the 'Exit' coroutine for the current state and wait for it to finish. After that, the newly requested state will begin executing its 'Enter' coroutine.

Note that the ```:ChangeState(NewState: string, ...any)``` function is asynchronous and **does not yield**. Your code will continue running without waiting for the state change to complete.

Also be aware that if you call ```ChangeState``` again while a previous state change request is still pending, the new request will overwrite the previous one.
```luau
StateController:ChangeState('Attack')
task.wait(1)
StateController:ChangeState('Idle')
```

### Closing a state:
In case you want to 'Exit' the current state but you don't want to change to another state, you can use ':CloseState()' to just exit the current state.
```luau
StateController:CloseState()
```

---

### Requirements:

The module uses two external modules: Promise and Janitor.
 - [Janitor: https://github.com/howmanysmall/Janitor](https://github.com/howmanysmall/Janitor).
 - [Promise: https://github.com/evaera/roblox-lua-promise](https://github.com/evaera/roblox-lua-promise).

Be sure to include them in your project and **change the require path** in the ChronoState module if needed!

---

### Overview

**ChronoState** is a coroutine-safe state machine for Roblox written in **Luau**. Designed for systems like weapons, character states, or UI flows, it ensures that:

- Each **state transition is awaited** before continuing.
- States are structured as `Enter` and `Exit` functions.
- Coroutine yielding and cancellation are safely handled.
- Cleanup and resource management are built-in.

---

### Purpose

ChronoState is a simple, extensible state machine that you can customize for your specific use cases. It's especially useful for gameplay systems that require:

- Clean transitions
- Awaitable logic
- Resource lifecycle management

---

### Contributing

I plan to continue upgrading ChronoState into a more advanced, general-purpose solution.  
**I’d love to hear your ideas, feedback, or contributions!** Feel free to open an issue or pull request.
