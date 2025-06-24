# ChronoState
**A coroutine-aware, asynchronous-first state machine module for Roblox!**

---

## API

### Creating a new state controller.
For us to start using this state machine, we've first gotta create the controll and give it the necessary states.
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

---

### Overview

**ChronoState** is a coroutine-safe state machine for Roblox written in **Luau**. Designed for systems like weapons, character states, or UI flows, it ensures that:

- Each **state transition is awaited** before continuing.
- States are structured as `Enter` and `Exit` functions.
- Coroutine yielding and cancellation are safely handled.
- Cleanup and resource management are built-in.

---

### Requirements:

The module uses two external modules: Promise and Janitor.
 - [Janitor: https://github.com/howmanysmall/Janitor](https://github.com/howmanysmall/Janitor).
 - [Promise: https://github.com/evaera/roblox-lua-promise](https://github.com/evaera/roblox-lua-promise).

Be sure to include them in your project and **change the require path** in the ChronoState module if needed!

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
