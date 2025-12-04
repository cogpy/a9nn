------------------------------------------------------------------------
--[[ ConsciousnessLayerProcessor ]]--
-- Multi-layer consciousness with frame-aware transitions
-- Part of NNECCO-A9NN cognitive architecture
------------------------------------------------------------------------
local CLP = torch.class('nn.ConsciousnessLayerProcessor')

-- Consciousness levels
local LAYERS = {
   L0_Basic = {level = 0, type = "reflexive"},
   L1_Experiential = {level = 1, type = "frame_aware"},
   L2_Reflective = {level = 2, type = "metacognitive"},
   L3_Meta = {level = 3, type = "self_model"}
}

function CLP:__init()
   self.currentLayer = LAYERS.L1_Experiential
   self.messageQueue = {}
   self.transitionHistory = {}
   self.currentFrame = nil
end

function CLP:processFrame(frame, input, reservoir_state)
   -- Select appropriate consciousness layer
   local targetLayer = self:_selectLayer(frame, input)
   
   if targetLayer.level ~= self.currentLayer.level then
      self:_transitionTo(targetLayer, {
         reason = "frame_shift",
         from_frame = self.currentFrame,
         to_frame = frame
      })
   end
   
   self.currentLayer = targetLayer
   self.currentFrame = frame
   
   return self:_processAtLayer(input, reservoir_state)
end

function CLP:_selectLayer(frame, input)
   -- Frame-consciousness coupling
   if frame == "chaos" then 
      return LAYERS.L1_Experiential
   elseif frame == "strategy" then 
      return LAYERS.L2_Reflective
   elseif frame == "play" then 
      return LAYERS.L1_Experiential
   elseif frame == "learning" then 
      return LAYERS.L3_Meta
   else
      return LAYERS.L1_Experiential
   end
end

function CLP:_transitionTo(layer, metadata)
   local transition = {
      from = self.currentLayer.level,
      to = layer.level,
      timestamp = os.time(),
      metadata = metadata
   }
   table.insert(self.transitionHistory, transition)
   table.insert(self.messageQueue, {
      type = "consciousness_shift",
      layer = layer,
      metadata = metadata
   })
end

function CLP:_processAtLayer(input, reservoir_state)
   local layer = self.currentLayer
   
   if layer.level == 0 then
      -- L0: Direct reflex
      return {action = "reflex", response = input}
   elseif layer.level == 1 then
      -- L1: Frame-aware perception
      return {action = "perceive", response = reservoir_state, frame = self.currentFrame}
   elseif layer.level == 2 then
      -- L2: Reflective meta-cognition
      return {action = "reflect", response = reservoir_state, quality = "analyzed"}
   elseif layer.level == 3 then
      -- L3: Self-model reasoning
      return {action = "introspect", response = reservoir_state, quality = "meta"}
   end
end

function CLP:getMessage()
   if #self.messageQueue > 0 then
      return table.remove(self.messageQueue, 1)
   end
   return nil
end

function CLP:getTransitionHistory()
   return self.transitionHistory
end

function CLP:__tostring__()
   return string.format('nn.ConsciousnessLayerProcessor(L%d:%s, frame=%s, messages=%d)',
      self.currentLayer.level, self.currentLayer.type, 
      tostring(self.currentFrame), #self.messageQueue)
end
