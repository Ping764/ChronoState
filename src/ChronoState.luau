--!strict
--!optimize 2

--	ChronoState:
--		Made by: Ping764, aka ItsPing764.
--		Github: https://github.com/Ping764/ChronoState

local Promise = require(script.Packages.Promise)
local Janitor = require(script.Packages.Janitor)

local StateStatuses = {
	None = 'None' :: StateStatuses,
	Idle = 'Idle' :: StateStatuses,
	Calling = 'Calling' :: StateStatuses,
	Transitioning = 'Transitioning' :: StateStatuses,
}

local StateEnums = {
	None = newproxy(false),
}

export type ModularState = {
	Enter: (self: StateController, ...any) -> (),
	Exit: (self: StateController) -> (),
}

export type ChronoState = {
	__index: ChronoState,
	
	new: (States: {[any]: ModularState}) -> StateController,
	
	ChangeState: (self: StateController, NewState: string, ...any) -> (),
	GetCurrentState: (self: StateController) -> string,
	ExitState: (self: StateController) -> (),
	
	Destroy: (self: StateController) -> (),
}

export type StateController = typeof(setmetatable(
	{} :: {
		States: {[any]: ModularState},
		
		StateStatus: StateStatuses,
		CurrentState: typeof(StateEnums.None) | any,
		
		YieldedThread: thread?,
		
		StateJanitor: Janitor.Janitor,
		StateCache: {[any]: any},
	},
	{} :: ChronoState
))

type StateStatuses = 'None' | 'Idle' | 'Calling' | 'Transitioning'

local function ErrorCallback(Error: string): string
	return Error or 'Callback was nil'
end

local function SpawnWithPromise(Function: (...any) -> (...any), ...): Promise.Promise
	local Args: {any} = {...}
	return Promise.new(function(Resolve, Reject): ()
		local Success: boolean, CallBack: any? = xpcall(Function, ErrorCallback, unpack(Args))
		
		if Success then
			Resolve(CallBack)
		else
			Reject(CallBack)
		end
	end)
		:catch(function(Error: string): ()
			warn(string.format('Catched the following error: %s', Error))
		end)
end

local function CleanupState(self: StateController): ()
	self.StateJanitor:Cleanup()
	table.clear(self.StateCache)
end

local function CallYieldedThread(self: StateController): ()
	local YieldedThread = self.YieldedThread
	if not YieldedThread then return end
	task.spawn(YieldedThread)
	self.YieldedThread = nil
end

local function OverwriteYieldedThread(self: StateController): ()
	local YieldedThread = self.YieldedThread
	if YieldedThread and coroutine.status(YieldedThread) ~= 'dead' then
		pcall(coroutine.close, YieldedThread)
	end
	local CurrentThread = coroutine.running()
	self.YieldedThread = CurrentThread
	coroutine.yield(CurrentThread)
	if self.YieldedThread == CurrentThread then
		self.YieldedThread = nil
	end
end

local function ExitCurrentState(self: StateController): ()
	self.StateStatus = StateStatuses.Transitioning
	SpawnWithPromise(self.States[self.CurrentState].Exit, self):await()
	self.StateStatus = StateStatuses.Idle
end

local function TransitionCurrentState(self: StateController): ()
	if (self.StateStatus ~= StateStatuses.None) and (self.StateStatus ~= StateStatuses.Idle) then
		OverwriteYieldedThread(self)
	end
	if self.CurrentState and (self.CurrentState ~= StateEnums.None) then
		ExitCurrentState(self)
	end
end

local function CallCurrentState(self: StateController, ...): ()
	self.StateStatus = StateStatuses.Calling
	SpawnWithPromise(self.States[self.CurrentState].Enter, self, ...):await()
	self.StateStatus = StateStatuses.Idle
	CallYieldedThread(self)
end

local function ChangeState(self: StateController, NewState: any, ...): ()
	TransitionCurrentState(self)
	CleanupState(self)

	self.CurrentState = NewState
	
	CallCurrentState(self, ...)
end

local function ExitState(self: StateController): ()
	TransitionCurrentState(self)
	CleanupState(self)
	
	self.StateStatus = StateStatuses.None
	self.CurrentState = StateEnums.None
end

local ChronoState: ChronoState = {} :: ChronoState
ChronoState.__index = ChronoState

function ChronoState.new(States: {[any]: ModularState}): StateController
	local self: StateController = setmetatable({
		States = States,
		
		StateStatus = StateStatuses.None,
		CurrentState = StateEnums.None,
		
		YieldedThread = nil,
		
		StateJanitor = Janitor.new(),
		StateCache = {}
	}, ChronoState)
	return self
end

function ChronoState:ChangeState(NewState: any, ...): ()
	if not self.States[NewState] then
		return error(string.format("%s is not in the states list!", NewState))
	end
	
	task.spawn(ChangeState, self, NewState, ...)
end

function ChronoState:ExitState(): ()
	if self.CurrentState == StateEnums.None or self.StateStatus == StateStatuses.None then
		return
	end
	
	task.spawn(ExitState, self)
end

function ChronoState:GetCurrentState(): any
	return self.CurrentState
end

function ChronoState:Destroy(): ()
	self.StateJanitor:Destroy()
	
	if self.YieldedThread and coroutine.status(self.YieldedThread) ~= 'dead' then
		pcall(coroutine.close, self.YieldedThread)
	end
	
	table.clear(self :: never)
	setmetatable(self :: any, nil)
end

return ChronoState
