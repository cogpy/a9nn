------------------------------------------------------------------------
--[[ Environment ]]--
-- Base class for RL environments with Gym-like interface.
-- Provides standardized reset(), step(), and render() methods.
-- Includes several built-in test environments for RL development.
------------------------------------------------------------------------
local Environment, parent = torch.class('nn.Environment')

function Environment:__init(config)
   config = config or {}
   self.name = config.name or "Environment"
   self.observationDim = config.observationDim or 4
   self.actionDim = config.actionDim or 2
   self.maxSteps = config.maxSteps or 200
   self.currentStep = 0
   self.totalReward = 0
   self.done = false
   self.state = nil

   -- For seeding randomness
   self.seed = config.seed
   if self.seed then
      torch.manualSeed(self.seed)
   end
end

-- Reset environment to initial state
function Environment:reset()
   self.currentStep = 0
   self.totalReward = 0
   self.done = false
   self.state = torch.zeros(self.observationDim)
   return self.state:clone()
end

-- Take action and return (observation, reward, done, info)
function Environment:step(action)
   error("Environment:step() must be implemented by subclass")
end

-- Render environment state (for visualization)
function Environment:render(mode)
   mode = mode or "human"
   if mode == "human" then
      print(string.format("[%s] Step %d, State: %s, Done: %s",
         self.name, self.currentStep, tostring(self.state), tostring(self.done)))
   end
   return self.state:clone()
end

-- Close environment and cleanup
function Environment:close()
   self.state = nil
   self.done = true
end

-- Get observation space info
function Environment:getObservationSpace()
   return {
      shape = {self.observationDim},
      low = -math.huge,
      high = math.huge,
      dtype = "float"
   }
end

-- Get action space info
function Environment:getActionSpace()
   return {
      n = self.actionDim,
      dtype = "int"
   }
end

-- Sample random action
function Environment:sampleAction()
   return torch.random(1, self.actionDim)
end

function Environment:__tostring__()
   return torch.type(self) .. string.format('(obs=%d, actions=%d)',
      self.observationDim, self.actionDim)
end

------------------------------------------------------------------------
--[[ CartPoleEnv ]]--
-- Classic cart-pole balancing environment.
-- Agent must keep pole balanced by moving cart left or right.
------------------------------------------------------------------------
local CartPoleEnv, CartPoleParent = torch.class('nn.CartPoleEnv', 'nn.Environment')

function CartPoleEnv:__init(config)
   config = config or {}
   config.name = "CartPole-v1"
   config.observationDim = 4
   config.actionDim = 2
   config.maxSteps = config.maxSteps or 500
   CartPoleParent.__init(self, config)

   -- Physics parameters
   self.gravity = 9.8
   self.massCart = 1.0
   self.massPole = 0.1
   self.totalMass = self.massCart + self.massPole
   self.length = 0.5  -- Half pole length
   self.poleMassLength = self.massPole * self.length
   self.forceMag = 10.0
   self.tau = 0.02  -- Time step

   -- Thresholds for termination
   self.thetaThreshold = 12 * math.pi / 180  -- 12 degrees
   self.xThreshold = 2.4
end

function CartPoleEnv:reset()
   self.currentStep = 0
   self.totalReward = 0
   self.done = false

   -- Initialize with small random values
   self.state = torch.Tensor({
      torch.uniform(-0.05, 0.05),  -- x position
      torch.uniform(-0.05, 0.05),  -- x velocity
      torch.uniform(-0.05, 0.05),  -- pole angle
      torch.uniform(-0.05, 0.05)   -- pole angular velocity
   })

   return self.state:clone()
end

function CartPoleEnv:step(action)
   assert(not self.done, "Environment is done, call reset()")
   assert(action >= 1 and action <= 2, "Action must be 1 or 2")

   local x, xDot, theta, thetaDot = self.state[1], self.state[2], self.state[3], self.state[4]

   -- Apply force based on action
   local force = action == 2 and self.forceMag or -self.forceMag

   local cosTheta = math.cos(theta)
   local sinTheta = math.sin(theta)

   -- Physics calculations
   local temp = (force + self.poleMassLength * thetaDot^2 * sinTheta) / self.totalMass
   local thetaAcc = (self.gravity * sinTheta - cosTheta * temp) /
      (self.length * (4.0/3.0 - self.massPole * cosTheta^2 / self.totalMass))
   local xAcc = temp - self.poleMassLength * thetaAcc * cosTheta / self.totalMass

   -- Euler integration
   x = x + self.tau * xDot
   xDot = xDot + self.tau * xAcc
   theta = theta + self.tau * thetaDot
   thetaDot = thetaDot + self.tau * thetaAcc

   self.state = torch.Tensor({x, xDot, theta, thetaDot})

   -- Check termination conditions
   self.done = math.abs(x) > self.xThreshold or
               math.abs(theta) > self.thetaThreshold or
               self.currentStep >= self.maxSteps

   -- Reward is 1 for every step taken
   local reward = self.done and 0 or 1
   self.totalReward = self.totalReward + reward
   self.currentStep = self.currentStep + 1

   local info = {
      x = x,
      theta = theta,
      terminated = self.done and self.currentStep < self.maxSteps
   }

   return self.state:clone(), reward, self.done, info
end

------------------------------------------------------------------------
--[[ MountainCarEnv ]]--
-- Classic mountain car environment.
-- Agent must build momentum to reach the goal at the top of the hill.
------------------------------------------------------------------------
local MountainCarEnv, MountainCarParent = torch.class('nn.MountainCarEnv', 'nn.Environment')

function MountainCarEnv:__init(config)
   config = config or {}
   config.name = "MountainCar-v0"
   config.observationDim = 2
   config.actionDim = 3
   config.maxSteps = config.maxSteps or 200
   MountainCarParent.__init(self, config)

   self.minPosition = -1.2
   self.maxPosition = 0.6
   self.maxSpeed = 0.07
   self.goalPosition = 0.5
   self.goalVelocity = 0

   self.force = 0.001
   self.gravity = 0.0025
end

function MountainCarEnv:reset()
   self.currentStep = 0
   self.totalReward = 0
   self.done = false

   self.state = torch.Tensor({
      torch.uniform(-0.6, -0.4),  -- position
      0                            -- velocity
   })

   return self.state:clone()
end

function MountainCarEnv:step(action)
   assert(not self.done, "Environment is done, call reset()")
   assert(action >= 1 and action <= 3, "Action must be 1, 2, or 3")

   local position, velocity = self.state[1], self.state[2]

   -- Apply force based on action (1=left, 2=none, 3=right)
   velocity = velocity + (action - 2) * self.force +
              math.cos(3 * position) * (-self.gravity)
   velocity = math.max(-self.maxSpeed, math.min(self.maxSpeed, velocity))

   position = position + velocity
   position = math.max(self.minPosition, math.min(self.maxPosition, position))

   -- Reset velocity if hitting left boundary
   if position == self.minPosition and velocity < 0 then
      velocity = 0
   end

   self.state = torch.Tensor({position, velocity})

   -- Check if goal reached
   local goalReached = position >= self.goalPosition and velocity >= self.goalVelocity
   self.done = goalReached or self.currentStep >= self.maxSteps

   -- Reward is -1 for each step
   local reward = goalReached and 0 or -1
   self.totalReward = self.totalReward + reward
   self.currentStep = self.currentStep + 1

   local info = {
      position = position,
      velocity = velocity,
      goalReached = goalReached
   }

   return self.state:clone(), reward, self.done, info
end

------------------------------------------------------------------------
--[[ GridWorldEnv ]]--
-- Simple grid world navigation environment.
-- Agent navigates from start to goal while avoiding obstacles.
------------------------------------------------------------------------
local GridWorldEnv, GridWorldParent = torch.class('nn.GridWorldEnv', 'nn.Environment')

function GridWorldEnv:__init(config)
   config = config or {}
   self.gridSize = config.gridSize or 5

   config.name = "GridWorld"
   config.observationDim = 2  -- (x, y) position
   config.actionDim = 4       -- up, down, left, right
   config.maxSteps = config.maxSteps or 100
   GridWorldParent.__init(self, config)

   self.startPos = config.startPos or {1, 1}
   self.goalPos = config.goalPos or {self.gridSize, self.gridSize}
   self.obstacles = config.obstacles or {}

   -- Action mappings
   self.actions = {
      {0, 1},   -- up
      {0, -1},  -- down
      {-1, 0},  -- left
      {1, 0}    -- right
   }
end

function GridWorldEnv:reset()
   self.currentStep = 0
   self.totalReward = 0
   self.done = false
   self.position = {self.startPos[1], self.startPos[2]}

   self.state = torch.Tensor(self.position)
   return self.state:clone()
end

function GridWorldEnv:isObstacle(x, y)
   for _, obs in ipairs(self.obstacles) do
      if obs[1] == x and obs[2] == y then
         return true
      end
   end
   return false
end

function GridWorldEnv:step(action)
   assert(not self.done, "Environment is done, call reset()")
   assert(action >= 1 and action <= 4, "Action must be 1-4")

   local move = self.actions[action]
   local newX = self.position[1] + move[1]
   local newY = self.position[2] + move[2]

   -- Check boundaries
   if newX >= 1 and newX <= self.gridSize and
      newY >= 1 and newY <= self.gridSize and
      not self:isObstacle(newX, newY) then
      self.position = {newX, newY}
   end

   self.state = torch.Tensor(self.position)

   -- Check if goal reached
   local goalReached = self.position[1] == self.goalPos[1] and
                       self.position[2] == self.goalPos[2]

   self.done = goalReached or self.currentStep >= self.maxSteps

   -- Reward structure
   local reward = -0.1  -- Small negative for each step
   if goalReached then
      reward = 1.0
   end

   self.totalReward = self.totalReward + reward
   self.currentStep = self.currentStep + 1

   local info = {
      position = {self.position[1], self.position[2]},
      goalReached = goalReached
   }

   return self.state:clone(), reward, self.done, info
end

function GridWorldEnv:render(mode)
   mode = mode or "human"
   if mode == "human" then
      local grid = {}
      for y = self.gridSize, 1, -1 do
         local row = ""
         for x = 1, self.gridSize do
            if x == self.position[1] and y == self.position[2] then
               row = row .. "A "  -- Agent
            elseif x == self.goalPos[1] and y == self.goalPos[2] then
               row = row .. "G "  -- Goal
            elseif self:isObstacle(x, y) then
               row = row .. "X "  -- Obstacle
            else
               row = row .. ". "  -- Empty
            end
         end
         table.insert(grid, row)
      end
      print(table.concat(grid, "\n"))
   end
   return self.state:clone()
end

------------------------------------------------------------------------
--[[ BanditEnv ]]--
-- Multi-armed bandit environment.
-- Agent must learn which arm gives highest expected reward.
------------------------------------------------------------------------
local BanditEnv, BanditParent = torch.class('nn.BanditEnv', 'nn.Environment')

function BanditEnv:__init(config)
   config = config or {}
   self.nArms = config.nArms or 10

   config.name = "Bandit"
   config.observationDim = 1  -- Dummy observation
   config.actionDim = self.nArms
   config.maxSteps = config.maxSteps or 1000
   BanditParent.__init(self, config)

   -- Initialize arm probabilities
   self.armProbs = config.armProbs
   if not self.armProbs then
      self.armProbs = torch.rand(self.nArms)
   end

   -- Track statistics
   self.armPulls = torch.zeros(self.nArms)
   self.armRewards = torch.zeros(self.nArms)
end

function BanditEnv:reset()
   self.currentStep = 0
   self.totalReward = 0
   self.done = false
   self.armPulls:zero()
   self.armRewards:zero()

   self.state = torch.Tensor({1})  -- Dummy state
   return self.state:clone()
end

function BanditEnv:step(action)
   assert(action >= 1 and action <= self.nArms, "Invalid arm")

   -- Sample reward
   local reward = torch.bernoulli(self.armProbs[action])

   -- Update statistics
   self.armPulls[action] = self.armPulls[action] + 1
   self.armRewards[action] = self.armRewards[action] + reward
   self.totalReward = self.totalReward + reward
   self.currentStep = self.currentStep + 1

   self.done = self.currentStep >= self.maxSteps

   local info = {
      optimalArm = self.armProbs:max(1)[1],
      currentProb = self.armProbs[action]
   }

   return self.state:clone(), reward, self.done, info
end

function BanditEnv:getOptimalArm()
   local _, idx = self.armProbs:max(1)
   return idx[1]
end

------------------------------------------------------------------------
--[[ make ]]--
-- Factory function to create environments by name.
------------------------------------------------------------------------
function nn.Environment.make(envName, config)
   config = config or {}

   local envMap = {
      ["CartPole-v1"] = nn.CartPoleEnv,
      ["CartPole"] = nn.CartPoleEnv,
      ["MountainCar-v0"] = nn.MountainCarEnv,
      ["MountainCar"] = nn.MountainCarEnv,
      ["GridWorld"] = nn.GridWorldEnv,
      ["Bandit"] = nn.BanditEnv
   }

   local EnvClass = envMap[envName]
   if not EnvClass then
      error("Unknown environment: " .. envName)
   end

   return EnvClass(config)
end
