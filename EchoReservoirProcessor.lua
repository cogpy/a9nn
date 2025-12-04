------------------------------------------------------------------------
--[[ EchoReservoirProcessor ]]--
-- Echo State Network reservoir computing with Lua/Torch tensors
-- Implements spectral radius control and parallel processing
-- Part of NNECCO-A9NN cognitive architecture
------------------------------------------------------------------------
local ESRP, parent = torch.class('nn.EchoReservoirProcessor', 'nn.Module')

function ESRP:__init(config)
   parent.__init(self)
   
   config = config or {}
   self.reservoirSize = config.reservoirSize or 847
   self.inputDim = config.inputDim or 768
   self.outputDim = config.outputDim or 256
   self.spectralRadius = config.spectralRadius or 0.9
   self.leakRate = config.leakRate or 0.3
   self.inputScaling = config.inputScaling or 1.0
   
   -- Initialize reservoir weights
   self.W_reservoir = torch.randn(self.reservoirSize, self.reservoirSize)
   local initialRadius = self:_computeSpectralRadius()
   if initialRadius > 0 then
      self.W_reservoir:mul(self.spectralRadius / initialRadius)
   end
   
   self.W_input = torch.randn(self.reservoirSize, self.inputDim)
   self.W_input:mul(self.inputScaling)
   
   self.W_output = torch.randn(self.outputDim, self.reservoirSize)
   
   -- Reservoir state
   self.state = torch.zeros(self.reservoirSize)
   self.output = torch.zeros(self.outputDim)
end

function ESRP:updateOutput(input)
   -- input: tensor of shape (inputDim)
   local inputVec = input:view(-1)
   local preActivation = torch.mv(self.W_reservoir, self.state) + torch.mv(self.W_input, inputVec)
   self.state = self.state:mul(1 - self.leakRate) + torch.tanh(preActivation):mul(self.leakRate)
   self.output = torch.mv(self.W_output, self.state)
   return self.output
end

function ESRP:_computeSpectralRadius()
   -- Compute spectral radius (largest absolute eigenvalue)
   local success, eigenvalues = pcall(function()
      return torch.eig(self.W_reservoir, 'N')
   end)
   
   if success then
      local real = eigenvalues:select(2, 1)
      local imag = eigenvalues:select(2, 2)
      local magnitudes = torch.sqrt(torch.pow(real, 2) + torch.pow(imag, 2))
      return magnitudes:max()
   else
      -- Fallback to approximate method
      return torch.abs(self.W_reservoir):max()
   end
end

function ESRP:adaptParameters(emotionalArousal, frame)
   -- Adapt based on emotional state and cognitive frame
   local frameRadii = {
      chaos = 0.95,
      strategy = 0.85,
      play = 0.90,
      social = 0.80
   }
   
   local targetRadius = frameRadii[frame] or 0.9
   
   -- Rescale reservoir weights to new spectral radius
   if self.spectralRadius ~= targetRadius then
      local currentRadius = self:_computeSpectralRadius()
      if currentRadius > 0 then
         self.W_reservoir:mul(targetRadius / currentRadius)
      end
      self.spectralRadius = targetRadius
   end
   
   -- Adjust input scaling based on emotional arousal
   if type(emotionalArousal) == "number" then
      self.inputScaling = 1.0 + 0.3 * emotionalArousal
      self.W_input:mul(self.inputScaling / (1.0 + 0.3 * (emotionalArousal - 0.5)))
   end
end

function ESRP:reset()
   self.state:zero()
   self.output:zero()
end

function ESRP:updateGradInput(input, gradOutput)
   -- Placeholder for backward pass
   self.gradInput = self.gradInput or input:clone()
   self.gradInput:resizeAs(input):zero()
   return self.gradInput
end

function ESRP:__tostring__()
   return string.format('nn.EchoReservoirProcessor(%d -> %d -> %d, spectral=%.2f, leak=%.2f)',
      self.inputDim, self.reservoirSize, self.outputDim, self.spectralRadius, self.leakRate)
end
