------------------------------------------------------------------------
--[[ PrioritizedReplayMemory ]]--
-- Prioritized Experience Replay (PER) buffer for reinforcement learning.
-- Extends basic replay memory with priority-based sampling using a
-- sum-tree data structure for efficient O(log n) sampling.
-- Reference: Schaul et al., "Prioritized Experience Replay" (2015)
------------------------------------------------------------------------
local PrioritizedReplayMemory = torch.class('nn.PrioritizedReplayMemory')

-- Sum-tree helper class for efficient priority-based sampling
local SumTree = {}
SumTree.__index = SumTree

function SumTree.new(capacity)
   local self = setmetatable({}, SumTree)
   self.capacity = capacity
   self.tree = torch.Tensor(2 * capacity - 1):zero()
   self.dataIdx = 0
   return self
end

function SumTree:propagate(idx, change)
   local parent = math.floor((idx - 1) / 2)
   if parent >= 0 then
      self.tree[parent + 1] = self.tree[parent + 1] + change
      if parent > 0 then
         self:propagate(parent, change)
      end
   end
end

function SumTree:update(idx, priority)
   local change = priority - self.tree[idx + 1]
   self.tree[idx + 1] = priority
   self:propagate(idx, change)
end

function SumTree:add(priority)
   local idx = self.dataIdx + self.capacity - 1
   self:update(idx, priority)
   self.dataIdx = (self.dataIdx + 1) % self.capacity
   return self.dataIdx == 0 and self.capacity or self.dataIdx
end

function SumTree:get(s)
   local idx = 0
   while idx < self.capacity - 1 do
      local left = 2 * idx + 1
      local right = left + 1
      if s <= self.tree[left + 1] then
         idx = left
      else
         s = s - self.tree[left + 1]
         idx = right
      end
   end
   local dataIdx = idx - self.capacity + 2
   return idx, self.tree[idx + 1], dataIdx
end

function SumTree:total()
   return self.tree[1]
end

function SumTree:maxPriority()
   local leafStart = self.capacity
   local maxP = 0
   for i = leafStart, 2 * self.capacity - 1 do
      if self.tree[i] > maxP then
         maxP = self.tree[i]
      end
   end
   return maxP > 0 and maxP or 1.0
end

-- Main PrioritizedReplayMemory class
function PrioritizedReplayMemory:__init(capacity, observationDim, config)
   config = config or {}

   self.capacity = capacity or 10000
   self.observationDim = observationDim or 1
   self.position = 0
   self.size = 0

   -- PER hyperparameters
   self.alpha = config.alpha or 0.6     -- Priority exponent (0 = uniform, 1 = full prioritization)
   self.beta = config.beta or 0.4       -- Importance sampling exponent (annealed to 1)
   self.betaIncrement = config.betaIncrement or 0.001
   self.epsilon = config.epsilon or 1e-6  -- Small constant to ensure non-zero priorities
   self.maxPriority = 1.0

   -- Sum-tree for efficient sampling
   self.tree = SumTree.new(self.capacity)

   -- Pre-allocate memory for efficiency
   if type(observationDim) == 'number' then
      self.observations = torch.Tensor(capacity, observationDim)
      self.nextObservations = torch.Tensor(capacity, observationDim)
   else
      -- Support multi-dimensional observations (e.g., images)
      local dims = {capacity}
      for i = 1, #observationDim do
         dims[#dims + 1] = observationDim[i]
      end
      self.observations = torch.Tensor(torch.LongStorage(dims))
      self.nextObservations = torch.Tensor(torch.LongStorage(dims))
   end

   self.actions = torch.LongTensor(capacity)
   self.rewards = torch.Tensor(capacity)
   self.dones = torch.ByteTensor(capacity)
end

-- Store a transition with maximum priority
function PrioritizedReplayMemory:push(observation, action, reward, nextObservation, done)
   -- Use maximum priority for new experiences
   local priority = math.pow(self.maxPriority, self.alpha)

   self.position = self.position % self.capacity
   local idx = self.position + 1

   self.observations[idx]:copy(observation)
   self.actions[idx] = action
   self.rewards[idx] = reward
   self.nextObservations[idx]:copy(nextObservation)
   self.dones[idx] = done and 1 or 0

   self.tree:add(priority)

   self.position = self.position + 1
   self.size = math.min(self.size + 1, self.capacity)
end

-- Sample a batch based on priorities
function PrioritizedReplayMemory:sample(batchSize)
   batchSize = math.min(batchSize, self.size)

   local indices = torch.LongTensor(batchSize)
   local priorities = torch.Tensor(batchSize)
   local treeIndices = torch.LongTensor(batchSize)

   local total = self.tree:total()
   local segment = total / batchSize

   -- Anneal beta towards 1
   self.beta = math.min(1.0, self.beta + self.betaIncrement)

   for i = 1, batchSize do
      local low = (i - 1) * segment
      local high = i * segment
      local s = low + torch.uniform() * (high - low)

      local treeIdx, priority, dataIdx = self.tree:get(s)

      -- Ensure valid index
      dataIdx = math.max(1, math.min(dataIdx, self.size))

      indices[i] = dataIdx
      priorities[i] = priority
      treeIndices[i] = treeIdx
   end

   -- Compute importance sampling weights
   local probabilities = priorities / total
   local weights = torch.pow(self.size * probabilities, -self.beta)
   weights = weights / weights:max()  -- Normalize to [0, 1]

   -- Index observations
   local obs = self.observations:index(1, indices)
   local nextObs = self.nextObservations:index(1, indices)

   return {
      observations = obs,
      actions = self.actions:index(1, indices),
      rewards = self.rewards:index(1, indices),
      nextObservations = nextObs,
      dones = self.dones:index(1, indices),
      weights = weights,
      indices = indices,
      treeIndices = treeIndices
   }
end

-- Update priorities after learning
function PrioritizedReplayMemory:updatePriorities(treeIndices, tdErrors)
   for i = 1, treeIndices:size(1) do
      local priority = math.pow(math.abs(tdErrors[i]) + self.epsilon, self.alpha)
      self.tree:update(treeIndices[i], priority)
      self.maxPriority = math.max(self.maxPriority, math.abs(tdErrors[i]) + self.epsilon)
   end
end

-- Get current size of the buffer
function PrioritizedReplayMemory:getSize()
   return self.size
end

-- Check if buffer has enough samples for a batch
function PrioritizedReplayMemory:canSample(batchSize)
   return self.size >= batchSize
end

-- Clear the buffer
function PrioritizedReplayMemory:clear()
   self.position = 0
   self.size = 0
   self.tree = SumTree.new(self.capacity)
   self.maxPriority = 1.0
   self.beta = 0.4
end

-- Get current beta value
function PrioritizedReplayMemory:getBeta()
   return self.beta
end

-- Set beta value (for custom annealing)
function PrioritizedReplayMemory:setBeta(beta)
   self.beta = math.max(0, math.min(1, beta))
end

-- Get all stored transitions (for debugging or analysis)
function PrioritizedReplayMemory:getAll()
   if self.size == 0 then
      return nil
   end

   local indices = torch.range(1, self.size):long()
   return {
      observations = self.observations:index(1, indices),
      actions = self.actions:index(1, indices),
      rewards = self.rewards:index(1, indices),
      nextObservations = self.nextObservations:index(1, indices),
      dones = self.dones:index(1, indices)
   }
end

-- Type conversion
function PrioritizedReplayMemory:type(type, tensorCache)
   if not type then
      return torch.type(self.observations)
   end

   tensorCache = tensorCache or {}
   self.observations = nn.utils.recursiveType(self.observations, type, tensorCache)
   self.nextObservations = nn.utils.recursiveType(self.nextObservations, type, tensorCache)
   self.rewards = nn.utils.recursiveType(self.rewards, type, tensorCache)
   return self
end

function PrioritizedReplayMemory:float()
   return self:type('torch.FloatTensor')
end

function PrioritizedReplayMemory:double()
   return self:type('torch.DoubleTensor')
end

function PrioritizedReplayMemory:cuda()
   return self:type('torch.CudaTensor')
end

function PrioritizedReplayMemory:__tostring__()
   return torch.type(self) .. string.format('(capacity=%d, size=%d, alpha=%.2f, beta=%.2f)',
      self.capacity, self.size, self.alpha, self.beta)
end
