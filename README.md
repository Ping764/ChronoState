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

Note that the ```:ChangeState(NewState: any, ...any)``` function is asynchronous and **does not yield**. Your code will continue running without waiting for the state change to complete.

Also be aware that if you call ```ChangeState``` again while a previous state change request is still pending, the new request will overwrite the previous one.
```luau
StateController:ChangeState('Attack')
task.wait(1)
StateController:ChangeState('Idle')
```

### Closing a state:
In case you want to 'Exit' the current state but you don't want to change to another state, you can use ':ExitState()' to just exit the current state.
```luau
StateController:ExitState()
```

### Cleanup and resource management:
When coding the 'Enter' and 'Exit' methods in the 'ModularState', the 'StateController' provides a ```StateCache``` and ```StateJanitor``` that you can use to help you manage the Instances, Connections, Variables and more.
(Obs: **After** exiting the state, both the ```StateCache``` and ```StateJanitor``` are cleaned, destroying any connection, or instance in the janitor, and clearing the cache.)
```lua
local RunService: RunService = game:GetService('RunService')

local ModularState = {}

function ModularState:Enter(ExampleString: string): ()
	self.StateCache.ExampleString = ExampleString
	self.StateCache.StartTick = tick()
	self.StateCache.PassedHeartbeat = 0
	self.StateJanitor:Add(RunService.Heartbeat:Connect(function(DeltaTime: number): ()
		self.StateCache.PassedHeartbeat += DeltaTime
	end), nil, 'Disconnect')
end

function ModularState:Exit(): ()
	print("Cached string: " self.StateCache.ExampleString)
	print("Time since entered state (Counting with heartbeat): ".. self.StateCache.PassedHeartbeat)
	print("Time since entered state (Counting with tick): ".. tick() - self.StateCache.StartTick)
end

return ModularState
```
Note that the **cache should be only used to store variables**, while the **janitor should be used to add instances, connections, and other** things you want to destroy after the state changes.
*(If you haven't used Janitor API before, check the "Requirements" section. The API is really easy and simple to use and understand)*

To run the above modular state it would look something like this:
```luau
local StateController = ChronoState.new({
	StateOne = require(script.ModularState) :: ChronoState.ModularState;
})

StateController:ChangeState('StateOne', 'Cool string!')
task.wait(1)
StateController:ExitState()
```
Any argument passed after 'NewState' in ```:ChangeState(NewState: any, ...any)``` will be sent to the 'Enter' method of the chosen state.

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
