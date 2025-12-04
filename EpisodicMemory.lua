------------------------------------------------------------------------
--[[ EpisodicMemory ]]--
-- Long-term episodic memory for cognitive agents.
-- Stores complete episodes with semantic indexing, similarity-based
-- retrieval, and memory consolidation mechanisms.
-- Inspired by hippocampal memory systems and episodic control.
------------------------------------------------------------------------
local EpisodicMemory = torch.class('nn.EpisodicMemory')

function EpisodicMemory:__init(config)
   config = config or {}

   self.maxEpisodes = config.maxEpisodes or 1000
   self.maxStepsPerEpisode = config.maxStepsPerEpisode or 1000
   self.embeddingDim = config.embeddingDim or 64
   self.similarityThreshold = config.similarityThreshold or 0.8
   self.consolidationRate = config.consolidationRate or 0.1
   self.forgettingRate = config.forgettingRate or 0.01

   -- Episode storage
   self.episodes = {}
   self.episodeCount = 0
   self.currentEpisode = nil

   -- Semantic index for fast retrieval
   self.semanticIndex = {}

   -- Memory statistics
   self.totalRetrievals = 0
   self.totalConsolidations = 0

   -- Importance scoring weights
   self.importanceWeights = {
      reward = config.rewardWeight or 0.4,
      novelty = config.noveltyWeight or 0.3,
      recency = config.recencyWeight or 0.2,
      frequency = config.frequencyWeight or 0.1
   }
end

-- Start a new episode
function EpisodicMemory:beginEpisode(context)
   self.currentEpisode = {
      id = self.episodeCount + 1,
      context = context or {},
      steps = {},
      startTime = os.time(),
      endTime = nil,
      totalReward = 0,
      importance = 1.0,
      retrievalCount = 0,
      tags = {},
      embedding = nil
   }
end

-- Add a step to the current episode
function EpisodicMemory:addStep(state, action, reward, nextState, done, metadata)
   if not self.currentEpisode then
      self:beginEpisode()
   end

   if #self.currentEpisode.steps >= self.maxStepsPerEpisode then
      return false
   end

   local step = {
      state = state:clone(),
      action = action,
      reward = reward,
      nextState = nextState:clone(),
      done = done,
      metadata = metadata or {},
      timestamp = os.time()
   }

   table.insert(self.currentEpisode.steps, step)
   self.currentEpisode.totalReward = self.currentEpisode.totalReward + reward

   return true
end

-- End the current episode and store it
function EpisodicMemory:endEpisode(success, metadata)
   if not self.currentEpisode then
      return nil
   end

   self.currentEpisode.endTime = os.time()
   self.currentEpisode.success = success or false
   self.currentEpisode.metadata = metadata or {}

   -- Compute episode embedding (simple mean of state embeddings)
   self:computeEpisodeEmbedding()

   -- Compute importance score
   self:computeImportance()

   -- Store episode
   self.episodeCount = self.episodeCount + 1

   -- Handle capacity limit with importance-based removal
   if #self.episodes >= self.maxEpisodes then
      self:removeLowestImportance()
   end

   table.insert(self.episodes, self.currentEpisode)
   self:updateSemanticIndex(self.currentEpisode)

   local episode = self.currentEpisode
   self.currentEpisode = nil

   return episode
end

-- Compute episode embedding from states
function EpisodicMemory:computeEpisodeEmbedding()
   if not self.currentEpisode or #self.currentEpisode.steps == 0 then
      return
   end

   -- Get first state dimensions
   local firstState = self.currentEpisode.steps[1].state
   local stateDim = firstState:nElement()
   local targetDim = math.min(stateDim, self.embeddingDim)

   -- Compute mean state as embedding
   local embedding = torch.Tensor(targetDim):zero()
   for _, step in ipairs(self.currentEpisode.steps) do
      local stateFlat = step.state:view(-1)
      for i = 1, targetDim do
         embedding[i] = embedding[i] + stateFlat[i]
      end
   end
   embedding:div(#self.currentEpisode.steps)

   -- Add reward information to embedding
   local rewardSignal = self.currentEpisode.totalReward / math.max(1, #self.currentEpisode.steps)
   embedding[1] = embedding[1] + rewardSignal * 0.1

   self.currentEpisode.embedding = embedding
end

-- Compute importance score for an episode
function EpisodicMemory:computeImportance()
   if not self.currentEpisode then
      return
   end

   local ep = self.currentEpisode

   -- Reward component (normalized)
   local rewardScore = math.tanh(ep.totalReward / math.max(1, #ep.steps))

   -- Novelty component (based on similarity to existing episodes)
   local noveltyScore = 1.0
   if ep.embedding and #self.episodes > 0 then
      local maxSimilarity = 0
      for _, other in ipairs(self.episodes) do
         if other.embedding then
            local sim = self:cosineSimilarity(ep.embedding, other.embedding)
            maxSimilarity = math.max(maxSimilarity, sim)
         end
      end
      noveltyScore = 1.0 - maxSimilarity
   end

   -- Recency (starts at 1.0, decays over time)
   local recencyScore = 1.0

   -- Frequency (retrieval count normalized)
   local frequencyScore = math.tanh(ep.retrievalCount / 10.0)

   ep.importance = self.importanceWeights.reward * rewardScore +
                   self.importanceWeights.novelty * noveltyScore +
                   self.importanceWeights.recency * recencyScore +
                   self.importanceWeights.frequency * frequencyScore
end

-- Cosine similarity between embeddings
function EpisodicMemory:cosineSimilarity(a, b)
   if not a or not b then return 0 end
   local minDim = math.min(a:nElement(), b:nElement())
   local aView = a:narrow(1, 1, minDim)
   local bView = b:narrow(1, 1, minDim)

   local dot = aView:dot(bView)
   local normA = aView:norm()
   local normB = bView:norm()

   if normA == 0 or normB == 0 then return 0 end
   return dot / (normA * normB)
end

-- Update semantic index for fast retrieval
function EpisodicMemory:updateSemanticIndex(episode)
   -- Index by tags
   for _, tag in ipairs(episode.tags or {}) do
      if not self.semanticIndex[tag] then
         self.semanticIndex[tag] = {}
      end
      table.insert(self.semanticIndex[tag], episode.id)
   end

   -- Index by context keys
   for key, _ in pairs(episode.context or {}) do
      local indexKey = "context:" .. key
      if not self.semanticIndex[indexKey] then
         self.semanticIndex[indexKey] = {}
      end
      table.insert(self.semanticIndex[indexKey], episode.id)
   end
end

-- Remove episode with lowest importance
function EpisodicMemory:removeLowestImportance()
   if #self.episodes == 0 then return end

   -- Apply forgetting decay to all episodes
   for _, ep in ipairs(self.episodes) do
      ep.importance = ep.importance * (1.0 - self.forgettingRate)
   end

   -- Find and remove lowest importance
   local minIdx = 1
   local minImportance = self.episodes[1].importance
   for i, ep in ipairs(self.episodes) do
      if ep.importance < minImportance then
         minIdx = i
         minImportance = ep.importance
      end
   end

   table.remove(self.episodes, minIdx)
end

-- Retrieve similar episodes based on state
function EpisodicMemory:retrieveByState(state, k)
   k = k or 5
   self.totalRetrievals = self.totalRetrievals + 1

   if #self.episodes == 0 then
      return {}
   end

   -- Create query embedding
   local stateFlat = state:view(-1)
   local targetDim = math.min(stateFlat:nElement(), self.embeddingDim)
   local queryEmbedding = stateFlat:narrow(1, 1, targetDim):clone()

   -- Find most similar episodes
   local similarities = {}
   for i, ep in ipairs(self.episodes) do
      if ep.embedding then
         local sim = self:cosineSimilarity(queryEmbedding, ep.embedding)
         table.insert(similarities, {episode = ep, similarity = sim, index = i})
      end
   end

   -- Sort by similarity
   table.sort(similarities, function(a, b) return a.similarity > b.similarity end)

   -- Return top-k
   local results = {}
   for i = 1, math.min(k, #similarities) do
      local item = similarities[i]
      item.episode.retrievalCount = (item.episode.retrievalCount or 0) + 1
      table.insert(results, item)
   end

   return results
end

-- Retrieve episodes by tag
function EpisodicMemory:retrieveByTag(tag, k)
   k = k or 10
   local episodeIds = self.semanticIndex[tag] or {}

   local results = {}
   for _, id in ipairs(episodeIds) do
      for _, ep in ipairs(self.episodes) do
         if ep.id == id then
            table.insert(results, ep)
            break
         end
      end
   end

   -- Sort by importance and return top-k
   table.sort(results, function(a, b) return a.importance > b.importance end)
   local topK = {}
   for i = 1, math.min(k, #results) do
      topK[i] = results[i]
   end

   return topK
end

-- Retrieve episodes by context match
function EpisodicMemory:retrieveByContext(context, k)
   k = k or 5
   local results = {}

   for _, ep in ipairs(self.episodes) do
      local matchScore = 0
      local matchCount = 0
      for key, value in pairs(context) do
         if ep.context and ep.context[key] then
            matchCount = matchCount + 1
            if ep.context[key] == value then
               matchScore = matchScore + 1
            end
         end
      end
      if matchCount > 0 then
         table.insert(results, {
            episode = ep,
            matchScore = matchScore / matchCount
         })
      end
   end

   table.sort(results, function(a, b) return a.matchScore > b.matchScore end)

   local topK = {}
   for i = 1, math.min(k, #results) do
      topK[i] = results[i].episode
   end

   return topK
end

-- Consolidate memories (merge similar episodes)
function EpisodicMemory:consolidate()
   if #self.episodes < 2 then return 0 end

   local consolidated = 0
   local toRemove = {}

   for i = 1, #self.episodes - 1 do
      if not toRemove[i] then
         for j = i + 1, #self.episodes do
            if not toRemove[j] then
               local epA = self.episodes[i]
               local epB = self.episodes[j]

               if epA.embedding and epB.embedding then
                  local sim = self:cosineSimilarity(epA.embedding, epB.embedding)

                  if sim > self.similarityThreshold then
                     -- Merge into episode with higher importance
                     if epA.importance >= epB.importance then
                        self:mergeEpisodes(epA, epB)
                        toRemove[j] = true
                     else
                        self:mergeEpisodes(epB, epA)
                        toRemove[i] = true
                     end
                     consolidated = consolidated + 1
                  end
               end
            end
         end
      end
   end

   -- Remove merged episodes
   local newEpisodes = {}
   for i, ep in ipairs(self.episodes) do
      if not toRemove[i] then
         table.insert(newEpisodes, ep)
      end
   end
   self.episodes = newEpisodes

   self.totalConsolidations = self.totalConsolidations + consolidated
   return consolidated
end

-- Merge two episodes
function EpisodicMemory:mergeEpisodes(target, source)
   -- Increase importance
   target.importance = target.importance + source.importance * self.consolidationRate

   -- Merge tags
   for _, tag in ipairs(source.tags or {}) do
      local found = false
      for _, t in ipairs(target.tags or {}) do
         if t == tag then found = true; break end
      end
      if not found then
         target.tags = target.tags or {}
         table.insert(target.tags, tag)
      end
   end

   -- Update retrieval count
   target.retrievalCount = (target.retrievalCount or 0) + (source.retrievalCount or 0)

   -- Average embeddings
   if target.embedding and source.embedding then
      local minDim = math.min(target.embedding:nElement(), source.embedding:nElement())
      for i = 1, minDim do
         target.embedding[i] = (target.embedding[i] + source.embedding[i]) / 2
      end
   end
end

-- Get episode count
function EpisodicMemory:getEpisodeCount()
   return #self.episodes
end

-- Get memory statistics
function EpisodicMemory:getStats()
   local totalSteps = 0
   local totalReward = 0
   local avgImportance = 0

   for _, ep in ipairs(self.episodes) do
      totalSteps = totalSteps + #ep.steps
      totalReward = totalReward + ep.totalReward
      avgImportance = avgImportance + ep.importance
   end

   if #self.episodes > 0 then
      avgImportance = avgImportance / #self.episodes
   end

   return {
      episodeCount = #self.episodes,
      totalSteps = totalSteps,
      totalReward = totalReward,
      avgImportance = avgImportance,
      totalRetrievals = self.totalRetrievals,
      totalConsolidations = self.totalConsolidations
   }
end

-- Clear all memories
function EpisodicMemory:clear()
   self.episodes = {}
   self.episodeCount = 0
   self.currentEpisode = nil
   self.semanticIndex = {}
   self.totalRetrievals = 0
   self.totalConsolidations = 0
end

-- Save memories to file
function EpisodicMemory:save(filename)
   local data = {
      episodes = {},
      episodeCount = self.episodeCount,
      semanticIndex = self.semanticIndex,
      totalRetrievals = self.totalRetrievals,
      totalConsolidations = self.totalConsolidations,
      config = {
         maxEpisodes = self.maxEpisodes,
         embeddingDim = self.embeddingDim,
         similarityThreshold = self.similarityThreshold
      }
   }

   -- Serialize episodes (convert tensors to tables)
   for _, ep in ipairs(self.episodes) do
      local serialized = {
         id = ep.id,
         context = ep.context,
         startTime = ep.startTime,
         endTime = ep.endTime,
         totalReward = ep.totalReward,
         importance = ep.importance,
         retrievalCount = ep.retrievalCount,
         tags = ep.tags,
         success = ep.success,
         metadata = ep.metadata,
         steps = {}
      }

      if ep.embedding then
         serialized.embedding = ep.embedding:totable()
      end

      for _, step in ipairs(ep.steps) do
         table.insert(serialized.steps, {
            state = step.state:totable(),
            action = step.action,
            reward = step.reward,
            nextState = step.nextState:totable(),
            done = step.done,
            metadata = step.metadata,
            timestamp = step.timestamp
         })
      end

      table.insert(data.episodes, serialized)
   end

   torch.save(filename, data)
end

-- Load memories from file
function EpisodicMemory:load(filename)
   local data = torch.load(filename)

   self.episodeCount = data.episodeCount
   self.semanticIndex = data.semanticIndex
   self.totalRetrievals = data.totalRetrievals
   self.totalConsolidations = data.totalConsolidations

   if data.config then
      self.maxEpisodes = data.config.maxEpisodes or self.maxEpisodes
      self.embeddingDim = data.config.embeddingDim or self.embeddingDim
      self.similarityThreshold = data.config.similarityThreshold or self.similarityThreshold
   end

   -- Deserialize episodes
   self.episodes = {}
   for _, serialized in ipairs(data.episodes) do
      local ep = {
         id = serialized.id,
         context = serialized.context,
         startTime = serialized.startTime,
         endTime = serialized.endTime,
         totalReward = serialized.totalReward,
         importance = serialized.importance,
         retrievalCount = serialized.retrievalCount,
         tags = serialized.tags,
         success = serialized.success,
         metadata = serialized.metadata,
         steps = {}
      }

      if serialized.embedding then
         ep.embedding = torch.Tensor(serialized.embedding)
      end

      for _, stepData in ipairs(serialized.steps) do
         table.insert(ep.steps, {
            state = torch.Tensor(stepData.state),
            action = stepData.action,
            reward = stepData.reward,
            nextState = torch.Tensor(stepData.nextState),
            done = stepData.done,
            metadata = stepData.metadata,
            timestamp = stepData.timestamp
         })
      end

      table.insert(self.episodes, ep)
   end
end

function EpisodicMemory:__tostring__()
   return torch.type(self) .. string.format('(episodes=%d/%d, retrievals=%d)',
      #self.episodes, self.maxEpisodes, self.totalRetrievals)
end
