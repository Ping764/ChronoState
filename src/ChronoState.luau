--!strict
--!optimize 2

--	ChronoState:
--		Made by: Ping764, aka ItsPing764.
--		Github: https://github.com/Ping764/ChronoState

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ReplicatedFirst = game:GetService('ReplicatedFirst')

local Promise = require(ReplicatedFirst.Packages.Promise)
local Janitor = require(ReplicatedFirst.Packages.Janitor)

export type ModularState = {
	Enter: (self: StateController) -> (),
	Exit: (self: StateController) -> (),
}

export type ChronoState = {
	__index: ChronoState,
	
	new: (States: {[string]: ModularState}) -> StateController,
	
	ChangeState: (self: StateController, NewState: string) -> (),
	GetCurrentState: (self: StateController) -> string,
	CloseState: (self: StateController) -> (),
	
	Destroy: (self: StateController) -> (),
}

export type StateController = typeof(setmetatable(
	{} :: {
		States: {[string]: ModularState},
		
		StateStatus: StateStatuses,
		CurrentState: 'None' | string,
		
		YieldedThread: thread?,
		
		StateJanitor: Janitor.Janitor,
		StateCache: {},
	},
	{} :: ChronoState
))

type StateStatuses = 'None' | 'Idle' | 'Calling' | 'Transitioning'

local StateStatuses = {
	None = 'None' :: StateStatuses,
	Idle = 'Idle' :: StateStatuses,
	Calling = 'Calling' :: StateStatuses,
	Transitioning = 'Transitioning' :: StateStatuses,
}

local function SpawnWithPromise(Function: (...any) -> (...any), ...): Promise.Promise
	local Args: {any} = {...}
	return Promise.new(function(Resolve, Reject): ()
		local Success: boolean, CallBack: any? = pcall(Function, unpack(Args))
		
		if Success then
			Resolve(CallBack)
		else
			Reject(CallBack)
		end
	end)
		:catch(function(Error: string): ()
			Error = Error or 'Callback was nil'
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

local function TransitionCurrentState(self: StateController): ()
	OverwriteYieldedThread(self)
	
	self.StateStatus = StateStatuses.Transitioning
	SpawnWithPromise(self.States[self.CurrentState].Enter, self):await()
	self.StateStatus = StateStatuses.Idle
end

local function CallCurrentState(self: StateController): ()
	self.StateStatus = StateStatuses.Calling
	SpawnWithPromise(self.States[self.CurrentState].Exit, self):await()
	self.StateStatus = StateStatuses.Idle
	CallYieldedThread(self)
end

local function ChangeState(self: StateController, NewState: string): ()
	if (self.StateStatus ~= StateStatuses.None) and (self.StateStatus ~= StateStatuses.Idle) then
		TransitionCurrentState(self)
	end
	
	CleanupState(self)

	self.CurrentState = NewState
	
	CallCurrentState(self)
end

local function CloseState(self: StateController): ()
	if (self.StateStatus ~= StateStatuses.None) and (self.StateStatus ~= StateStatuses.Idle) then
		TransitionCurrentState(self)
	end
	
	CleanupState(self)
	
	self.StateStatus = StateStatuses.None
end

local ChronoState: ChronoState = {} :: ChronoState
ChronoState.__index = ChronoState

function ChronoState.new(States: {[string]: ModularState}): StateController
	local self: StateController = setmetatable({
		States = States,
		
		StateStatus = StateStatuses.None,
		CurrentState = 'None',
		
		YieldedThread = nil,
		
		StateJanitor = Janitor.new(),
		StateCache = {}
	}, ChronoState)
	return self
end

function ChronoState:ChangeState(NewState: string): ()
	if not self.States[NewState] then
		return error(string.format("%s is not in the states list!", NewState))
	end
	
	task.spawn(ChangeState, self, NewState)
end

function ChronoState:CloseState(): ()
	if self.CurrentState == 'None' or self.StateStatus == StateStatuses.None then
		return
	end
	
	task.spawn(CloseState, self)
end

function ChronoState:GetCurrentState(): string
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
