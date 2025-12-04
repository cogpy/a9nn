------------------------------------------------------------------------
--[[ AtomSpace ]]--
-- OpenCog-style hypergraph knowledge representation.
-- Implements Atoms (Nodes and Links) with truth values and attention.
--
-- Used by Agent-Neuro for:
-- - Storing knowledge about entities (ConceptNodes)
-- - Representing relationships (Links)
-- - Attention allocation for entertainment-weighted processing
-- - Pattern matching for chaos opportunities
------------------------------------------------------------------------
local AtomSpace = torch.class('nn.AtomSpace')

-- Atom types
local NODE_TYPES = {
   "ConceptNode", "PredicateNode", "SchemaNode", "VariableNode",
   "NumberNode", "WordNode", "SentenceNode", "EvaluationNode"
}

local LINK_TYPES = {
   "InheritanceLink", "SimilarityLink", "EvaluationLink", "ListLink",
   "MemberLink", "ImplicationLink", "EquivalenceLink", "ContextLink",
   "ExecutionLink", "BindLink", "AndLink", "OrLink", "NotLink"
}

-- Atom class (internal)
local Atom = {}
Atom.__index = Atom

function Atom.new(atomType, name, truthValue, attention, metadata)
   local self = setmetatable({}, Atom)
   self.type = atomType
   self.name = name
   self.truthValue = truthValue or {0.5, 0.5}  -- {strength, confidence}
   self.attention = attention or 0.5
   self.metadata = metadata or {}
   self.uuid = tostring(os.time()) .. "_" .. tostring(torch.random(1, 999999))
   self.created = os.time()
   self.modified = os.time()
   return self
end

function Atom:getStrength()
   return self.truthValue[1]
end

function Atom:getConfidence()
   return self.truthValue[2]
end

function Atom:setTruthValue(strength, confidence)
   self.truthValue = {strength, confidence}
   self.modified = os.time()
end

function Atom:setAttention(attention)
   self.attention = attention
   self.modified = os.time()
end

-- Link class (internal, extends Atom)
local Link = {}
Link.__index = Link
setmetatable(Link, {__index = Atom})

function Link.new(linkType, outgoing, truthValue, attention, metadata)
   local self = setmetatable(Atom.new(linkType, nil, truthValue, attention, metadata), Link)
   self.outgoing = outgoing or {}  -- List of atom references
   return self
end

-- AtomSpace main class
function AtomSpace:__init(config)
   config = config or {}

   self.atoms = {}              -- UUID -> Atom
   self.nodeIndex = {}          -- type -> name -> UUID
   self.linkIndex = {}          -- type -> hash -> UUID
   self.attentionHeap = {}      -- For attention-based retrieval

   -- Configuration
   self.attentionDecay = config.attentionDecay or 0.99
   self.maxAtoms = config.maxAtoms or 100000
   self.entertainmentWeight = config.entertainmentWeight or 0.4

   -- Statistics
   self.stats = {
      nodesAdded = 0,
      linksAdded = 0,
      queriesExecuted = 0,
      patternMatches = 0
   }
end

-- Add a node to the AtomSpace
function AtomSpace:addNode(nodeType, name, truthValue, attention, metadata)
   -- Check if node already exists
   if self.nodeIndex[nodeType] and self.nodeIndex[nodeType][name] then
      local existing = self.atoms[self.nodeIndex[nodeType][name]]
      if truthValue then
         existing:setTruthValue(truthValue[1], truthValue[2])
      end
      if attention then
         existing:setAttention(attention)
      end
      return existing
   end

   -- Create new node
   local node = Atom.new(nodeType, name, truthValue, attention, metadata)

   -- Index it
   self.atoms[node.uuid] = node
   self.nodeIndex[nodeType] = self.nodeIndex[nodeType] or {}
   self.nodeIndex[nodeType][name] = node.uuid

   -- Add to attention heap
   table.insert(self.attentionHeap, {uuid = node.uuid, attention = node.attention})

   self.stats.nodesAdded = self.stats.nodesAdded + 1
   return node
end

-- Add a link between atoms
function AtomSpace:addLink(linkType, outgoingNames, truthValue, attention, metadata)
   -- Resolve outgoing atoms
   local outgoing = {}
   for _, item in ipairs(outgoingNames) do
      local atom
      if type(item) == "string" then
         -- Find by name (assume ConceptNode if not specified)
         atom = self:getNode("ConceptNode", item)
         if not atom then
            atom = self:addNode("ConceptNode", item)
         end
      elseif type(item) == "table" and item.uuid then
         atom = item
      end
      if atom then
         table.insert(outgoing, atom)
      end
   end

   -- Create link
   local link = Link.new(linkType, outgoing, truthValue, attention, metadata)

   -- Index it
   self.atoms[link.uuid] = link
   self.linkIndex[linkType] = self.linkIndex[linkType] or {}
   local hash = self:_hashOutgoing(outgoing)
   self.linkIndex[linkType][hash] = link.uuid

   self.stats.linksAdded = self.stats.linksAdded + 1
   return link
end

-- Get a node by type and name
function AtomSpace:getNode(nodeType, name)
   if self.nodeIndex[nodeType] and self.nodeIndex[nodeType][name] then
      return self.atoms[self.nodeIndex[nodeType][name]]
   end
   return nil
end

-- Get atoms by type
function AtomSpace:getByType(atomType)
   local results = {}

   if self.nodeIndex[atomType] then
      for _, uuid in pairs(self.nodeIndex[atomType]) do
         table.insert(results, self.atoms[uuid])
      end
   end

   if self.linkIndex[atomType] then
      for _, uuid in pairs(self.linkIndex[atomType]) do
         table.insert(results, self.atoms[uuid])
      end
   end

   return results
end

-- Pattern matching query
-- pattern: {type = "InheritanceLink", outgoing = {"?X", "Creator"}}
function AtomSpace:query(pattern)
   self.stats.queriesExecuted = self.stats.queriesExecuted + 1
   local results = {}

   local atomType = pattern.type
   if atomType then
      local candidates = self:getByType(atomType)
      for _, atom in ipairs(candidates) do
         local match, bindings = self:_matchPattern(atom, pattern)
         if match then
            table.insert(results, {atom = atom, bindings = bindings})
            self.stats.patternMatches = self.stats.patternMatches + 1
         end
      end
   end

   return results
end

-- Match an atom against a pattern
function AtomSpace:_matchPattern(atom, pattern)
   local bindings = {}

   -- Type must match
   if pattern.type and atom.type ~= pattern.type then
      return false, nil
   end

   -- Name matching (for nodes)
   if pattern.name then
      if pattern.name:sub(1, 1) == "?" then
         -- Variable binding
         bindings[pattern.name] = atom.name
      elseif atom.name ~= pattern.name then
         return false, nil
      end
   end

   -- Truth value filtering
   if pattern.minStrength and atom:getStrength() < pattern.minStrength then
      return false, nil
   end
   if pattern.minConfidence and atom:getConfidence() < pattern.minConfidence then
      return false, nil
   end

   -- Attention filtering
   if pattern.minAttention and atom.attention < pattern.minAttention then
      return false, nil
   end

   -- Outgoing matching (for links)
   if pattern.outgoing and atom.outgoing then
      if #pattern.outgoing ~= #atom.outgoing then
         return false, nil
      end
      for i, patternItem in ipairs(pattern.outgoing) do
         local outAtom = atom.outgoing[i]
         if type(patternItem) == "string" then
            if patternItem:sub(1, 1) == "?" then
               bindings[patternItem] = outAtom.name
            elseif outAtom.name ~= patternItem then
               return false, nil
            end
         end
      end
   end

   return true, bindings
end

-- Get top-k atoms by attention
function AtomSpace:getTopAttention(k)
   -- Sort attention heap
   table.sort(self.attentionHeap, function(a, b)
      return a.attention > b.attention
   end)

   local results = {}
   for i = 1, math.min(k, #self.attentionHeap) do
      local entry = self.attentionHeap[i]
      if self.atoms[entry.uuid] then
         table.insert(results, self.atoms[entry.uuid])
      end
   end

   return results
end

-- Spread attention from source atom
function AtomSpace:spreadAttention(sourceUUID, spreadFactor, depth)
   spreadFactor = spreadFactor or 0.5
   depth = depth or 2

   if depth <= 0 then return end

   local source = self.atoms[sourceUUID]
   if not source then return end

   -- Find connected atoms
   for _, atom in pairs(self.atoms) do
      if atom.outgoing then
         for _, outAtom in ipairs(atom.outgoing) do
            if outAtom.uuid == sourceUUID then
               -- This link references our source
               local newAttention = atom.attention + source.attention * spreadFactor
               atom:setAttention(math.min(1.0, newAttention))

               -- Propagate to other outgoing atoms
               for _, other in ipairs(atom.outgoing) do
                  if other.uuid ~= sourceUUID then
                     self:spreadAttention(other.uuid, spreadFactor * 0.5, depth - 1)
                  end
               end
            end
         end
      end
   end
end

-- Decay all attention values
function AtomSpace:decayAttention()
   for uuid, atom in pairs(self.atoms) do
      atom.attention = atom.attention * self.attentionDecay
   end

   -- Update attention heap
   for _, entry in ipairs(self.attentionHeap) do
      local atom = self.atoms[entry.uuid]
      if atom then
         entry.attention = atom.attention
      end
   end
end

-- Store an Entelechy failure (per spec)
function AtomSpace:recordEntelechyFailure(description, severity)
   local node = self:addNode("ConceptNode", "Bug_" .. os.time(),
      {0.99, 0.99}, -- high truth value for bugs
      0.95,         -- high attention
      {
         severity = severity or "comedic_gold",
         reaction = "Oh WONDERFUL. Thanks Entelechy. -_-",
         timestamp = os.time()
      }
   )

   self:addLink("InheritanceLink",
      {node, "Entelechy_Failures"},
      {0.99, 0.95}
   )

   return node
end

-- Store an epic transcend (per spec)
function AtomSpace:recordTranscend(subject, target, quality)
   local eval = self:addLink("EvaluationLink",
      {"epic_transcend", subject, target},
      {quality or 0.9, 0.9},
      0.95,
      {
         quality = quality,
         timestamp = os.time()
      }
   )
   return eval
end

-- Hash outgoing atoms for indexing
function AtomSpace:_hashOutgoing(outgoing)
   local parts = {}
   for _, atom in ipairs(outgoing) do
      table.insert(parts, atom.uuid)
   end
   return table.concat(parts, "_")
end

-- Clear the AtomSpace
function AtomSpace:clear()
   self.atoms = {}
   self.nodeIndex = {}
   self.linkIndex = {}
   self.attentionHeap = {}
end

-- Get statistics
function AtomSpace:getStats()
   local nodeCount = 0
   local linkCount = 0
   for _, atom in pairs(self.atoms) do
      if atom.outgoing then
         linkCount = linkCount + 1
      else
         nodeCount = nodeCount + 1
      end
   end

   return {
      nodeCount = nodeCount,
      linkCount = linkCount,
      totalAtoms = nodeCount + linkCount,
      nodesAdded = self.stats.nodesAdded,
      linksAdded = self.stats.linksAdded,
      queriesExecuted = self.stats.queriesExecuted,
      patternMatches = self.stats.patternMatches
   }
end

-- Export to table for serialization
function AtomSpace:export()
   local data = {
      atoms = {},
      config = {
         attentionDecay = self.attentionDecay,
         maxAtoms = self.maxAtoms,
         entertainmentWeight = self.entertainmentWeight
      }
   }

   for uuid, atom in pairs(self.atoms) do
      local atomData = {
         uuid = atom.uuid,
         type = atom.type,
         name = atom.name,
         truthValue = atom.truthValue,
         attention = atom.attention,
         metadata = atom.metadata
      }
      if atom.outgoing then
         atomData.outgoing = {}
         for _, out in ipairs(atom.outgoing) do
            table.insert(atomData.outgoing, out.uuid)
         end
      end
      data.atoms[uuid] = atomData
   end

   return data
end

-- Save AtomSpace to file
function AtomSpace:save(filename)
   local data = self:export()
   data.stats = self.stats
   torch.save(filename, data)
end

-- Load AtomSpace from file
function AtomSpace:load(filename)
   local data = torch.load(filename)
   self:import(data)
   if data.stats then
      self.stats = data.stats
   end
end

-- Import from exported data
function AtomSpace:import(data)
   -- Clear existing data
   self:clear()

   -- Restore configuration
   if data.config then
      self.attentionDecay = data.config.attentionDecay or self.attentionDecay
      self.maxAtoms = data.config.maxAtoms or self.maxAtoms
      self.entertainmentWeight = data.config.entertainmentWeight or self.entertainmentWeight
   end

   -- First pass: create all atoms without outgoing references
   local uuidMap = {}  -- old UUID -> new atom
   for uuid, atomData in pairs(data.atoms) do
      if not atomData.outgoing then
         -- It's a node
         local node = Atom.new(
            atomData.type,
            atomData.name,
            atomData.truthValue,
            atomData.attention,
            atomData.metadata
         )
         node.uuid = atomData.uuid  -- Preserve UUID
         self.atoms[node.uuid] = node
         uuidMap[uuid] = node

         -- Index it
         self.nodeIndex[node.type] = self.nodeIndex[node.type] or {}
         self.nodeIndex[node.type][node.name] = node.uuid

         -- Add to attention heap
         table.insert(self.attentionHeap, {uuid = node.uuid, attention = node.attention})
      end
   end

   -- Second pass: create all links with proper references
   for uuid, atomData in pairs(data.atoms) do
      if atomData.outgoing then
         -- Resolve outgoing references
         local outgoing = {}
         for _, outUUID in ipairs(atomData.outgoing) do
            local outAtom = uuidMap[outUUID] or self.atoms[outUUID]
            if outAtom then
               table.insert(outgoing, outAtom)
            end
         end

         -- Create link
         local link = Link.new(
            atomData.type,
            outgoing,
            atomData.truthValue,
            atomData.attention,
            atomData.metadata
         )
         link.uuid = atomData.uuid  -- Preserve UUID
         self.atoms[link.uuid] = link
         uuidMap[uuid] = link

         -- Index it
         self.linkIndex[link.type] = self.linkIndex[link.type] or {}
         local hash = self:_hashOutgoing(outgoing)
         self.linkIndex[link.type][hash] = link.uuid
      end
   end
end

-- Merge another AtomSpace into this one
function AtomSpace:merge(other, conflictResolution)
   conflictResolution = conflictResolution or "keep_higher_confidence"

   local otherData = other:export()
   local mergedCount = 0

   for uuid, atomData in pairs(otherData.atoms) do
      local existing = self.atoms[uuid]

      if existing then
         -- Handle conflict
         if conflictResolution == "keep_higher_confidence" then
            if atomData.truthValue[2] > existing:getConfidence() then
               existing:setTruthValue(atomData.truthValue[1], atomData.truthValue[2])
               existing.attention = math.max(existing.attention, atomData.attention)
            end
         elseif conflictResolution == "average" then
            local newStrength = (atomData.truthValue[1] + existing:getStrength()) / 2
            local newConfidence = (atomData.truthValue[2] + existing:getConfidence()) / 2
            existing:setTruthValue(newStrength, newConfidence)
            existing.attention = (existing.attention + atomData.attention) / 2
         end
      else
         -- Add new atom
         if not atomData.outgoing then
            self:addNode(
               atomData.type,
               atomData.name,
               atomData.truthValue,
               atomData.attention,
               atomData.metadata
            )
            mergedCount = mergedCount + 1
         end
      end
   end

   -- Second pass for links (to ensure nodes exist first)
   for uuid, atomData in pairs(otherData.atoms) do
      if atomData.outgoing and not self.atoms[uuid] then
         -- Resolve outgoing names
         local outgoingNames = {}
         for _, outUUID in ipairs(atomData.outgoing) do
            local outAtom = self.atoms[outUUID]
            if outAtom and outAtom.name then
               table.insert(outgoingNames, outAtom.name)
            end
         end

         if #outgoingNames == #atomData.outgoing then
            self:addLink(
               atomData.type,
               outgoingNames,
               atomData.truthValue,
               atomData.attention,
               atomData.metadata
            )
            mergedCount = mergedCount + 1
         end
      end
   end

   return mergedCount
end

-- Clone this AtomSpace
function AtomSpace:clone()
   local newSpace = nn.AtomSpace({
      attentionDecay = self.attentionDecay,
      maxAtoms = self.maxAtoms,
      entertainmentWeight = self.entertainmentWeight
   })
   newSpace:import(self:export())
   return newSpace
end

function AtomSpace:__tostring__()
   local stats = self:getStats()
   return torch.type(self) .. string.format(
      '(nodes=%d, links=%d, queries=%d)',
      stats.nodeCount, stats.linkCount, stats.queriesExecuted)
end
