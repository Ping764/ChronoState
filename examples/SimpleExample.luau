--!strict
--!optimize 2

-- IMPORTANT:
-- THIS IS A SIMPLE EXAMPLE JUST TO SHOWCASE THE MODULE USAGE.

-- OBS:
-- In this example, it's a single state only. But obviously in a real system more states could and should be implemented.

local ReplicatedFirst = game:GetService('ReplicatedFirst')
local UserInputService: UserInputService = game:GetService('UserInputService')

local ChronoState = require(ReplicatedFirst.Packages.ChronoState)

local TestState = ChronoState.new({
	-- This "EquipGun" function could be implemented as a modular state.
	-- It would look something like this:
	-- ['EquipGun'] = require(script.States.EquipGun --[[Path to the modular state]]) :: ChronoState.ModularState;
	['EquipGun'] = {
		Enter = function(self: ChronoState.StateController, GunName: string): ()
			self.StateCache.Gun = GunName
			self.StateCache.BulletsUsed = 0
			
			print('Equipping gun: '.. GunName)
			
			task.wait(1) -- Equipping animation timeout for example.
			
			-- Uses janitor to add the connection, so when it changes state the connection gets cleaned.
			self.StateJanitor:Add(UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessedEvent: boolean): ()
				if self.StateCache.IsUnequipping then return end
				if GameProcessedEvent then return end
				if Input.KeyCode ~= Enum.KeyCode.MouseLeftButton then return end
				
				print('Shot a bullet!')
				self.StateCache.BulletsUsed += 1
			end))
			
			print('Finished equipping the gun!')
		end,
		
		Exit = function(self: ChronoState.StateController): ()
			self.StateCache.IsUnequipping = true
			print('Unequipping gun: '.. self.StateCache.Gun)
			
			task.wait(1) -- Unequipping animation timeout for example.
			
			print('Finished unequipping the gun!')
		end,
	};
})

local GunOne: string = 'Awesome Gun'
local GunTwo: string = 'Awesome Gun 2'

TestState:ChangeState('EquipGun', GunOne) -- Equips the first gun
TestState:ChangeState('EquipGun', GunTwo) -- Equips the second gun after the first gun is unequipped

task.wait(2)

TestState:CloseState() -- Unequips the current gun
