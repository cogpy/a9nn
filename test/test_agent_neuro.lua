------------------------------------------------------------------------
-- Agent-Neuro Test Suite
-- Comprehensive tests for reinforcement learning and cognitive agent modules
------------------------------------------------------------------------

require 'torch'
require 'nn'

local mytester = torch.Tester()
local agentNeuroTest = torch.TestSuite()

------------------------------------------------------------------------
-- Personality Tests
------------------------------------------------------------------------

function agentNeuroTest.Personality_creation()
   local p = nn.Personality()
   mytester:assert(p ~= nil, 'Personality should be created')
   mytester:assert(p:get('playfulness') > 0, 'Playfulness should be set')
   mytester:assert(p:get('no_harm_intent') == 1.0, 'no_harm_intent should be 1.0 (immutable)')
end

function agentNeuroTest.Personality_custom_traits()
   local p = nn.Personality({
      playfulness = 0.5,
      chaotic = 0.7
   })
   mytester:asserteq(p:get('playfulness'), 0.5, 'Custom playfulness should be set')
   mytester:asserteq(p:get('chaotic'), 0.7, 'Custom chaotic should be set')
end

function agentNeuroTest.Personality_immutable_traits()
   local p = nn.Personality()
   p:set('no_harm_intent', 0.5)  -- Should not change
   mytester:asserteq(p:get('no_harm_intent'), 1.0, 'Immutable trait should not change')
end

function agentNeuroTest.Personality_bounds()
   local p = nn.Personality()
   p:set('empathy', 0.1)  -- Below floor of 0.5
   mytester:assert(p:get('empathy') >= 0.5, 'Empathy should have floor of 0.5')
end

function agentNeuroTest.Personality_emotion()
   local p = nn.Personality()
   p:setEmotion('excited', 0.9, 0.7)
   mytester:asserteq(p.emotionalState.type, 'excited', 'Emotion type should be set')
   mytester:asserteq(p.emotionalState.intensity, 0.9, 'Emotion intensity should be set')
end

function agentNeuroTest.Personality_frame()
   local p = nn.Personality()
   local framing = p:frame('test input', 'chaos')
   mytester:assert(framing.frame == 'chaos', 'Frame should be chaos')
   mytester:assert(framing.chaos_modifier > 0, 'Chaos modifier should be positive')
end

function agentNeuroTest.Personality_inheritance()
   local parent = nn.Personality({playfulness = 0.9, chaotic = 0.8})
   local child = parent:inherit(0.7)
   mytester:assert(child ~= nil, 'Child personality should be created')
   mytester:asserteq(child:get('no_harm_intent'), 1.0, 'Child should inherit immutable traits exactly')
end

function agentNeuroTest.Personality_safetyCheck()
   local p = nn.Personality()
   local safe = p:safetyCheck({name = 'test_action'})
   mytester:assert(safe == true, 'Safe actions should pass safety check')
end

------------------------------------------------------------------------
-- AtomSpace Tests
------------------------------------------------------------------------

function agentNeuroTest.AtomSpace_creation()
   local as = nn.AtomSpace()
   mytester:assert(as ~= nil, 'AtomSpace should be created')
   local stats = as:getStats()
   mytester:asserteq(stats.nodeCount, 0, 'New AtomSpace should be empty')
end

function agentNeuroTest.AtomSpace_addNode()
   local as = nn.AtomSpace()
   local node = as:addNode('ConceptNode', 'TestConcept', {0.9, 0.8}, 0.7)
   mytester:assert(node ~= nil, 'Node should be created')
   mytester:asserteq(node.name, 'TestConcept', 'Node name should match')
   mytester:asserteq(node:getStrength(), 0.9, 'Strength should match')
end

function agentNeuroTest.AtomSpace_getNode()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'FindMe', {0.5, 0.5}, 0.5)
   local found = as:getNode('ConceptNode', 'FindMe')
   mytester:assert(found ~= nil, 'Node should be found')
   mytester:asserteq(found.name, 'FindMe', 'Found node name should match')
end

function agentNeuroTest.AtomSpace_addLink()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'A')
   as:addNode('ConceptNode', 'B')
   local link = as:addLink('InheritanceLink', {'A', 'B'}, {0.8, 0.9})
   mytester:assert(link ~= nil, 'Link should be created')
   mytester:asserteq(#link.outgoing, 2, 'Link should have 2 outgoing atoms')
end

function agentNeuroTest.AtomSpace_query()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'Creator', {0.9, 0.9}, 0.8)
   as:addNode('ConceptNode', 'Creation', {0.7, 0.7}, 0.6)
   as:addLink('InheritanceLink', {'Creation', 'Creator'}, {0.85, 0.9})

   local results = as:query({type = 'InheritanceLink'})
   mytester:assert(#results > 0, 'Query should return results')
end

function agentNeuroTest.AtomSpace_topAttention()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'LowAttention', {0.5, 0.5}, 0.2)
   as:addNode('ConceptNode', 'HighAttention', {0.5, 0.5}, 0.9)
   as:addNode('ConceptNode', 'MedAttention', {0.5, 0.5}, 0.5)

   local top = as:getTopAttention(2)
   mytester:asserteq(#top, 2, 'Should return 2 top atoms')
   mytester:asserteq(top[1].name, 'HighAttention', 'Highest attention should be first')
end

function agentNeuroTest.AtomSpace_recordEntelechyFailure()
   local as = nn.AtomSpace()
   local bug = as:recordEntelechyFailure('Test bug', 'comedic_gold')
   mytester:assert(bug ~= nil, 'Bug node should be created')
   mytester:assert(bug.metadata.reaction ~= nil, 'Bug should have reaction metadata')
end

------------------------------------------------------------------------
-- ReplayMemory Tests
------------------------------------------------------------------------

function agentNeuroTest.ReplayMemory_creation()
   local rm = nn.ReplayMemory(100, 4)
   mytester:assert(rm ~= nil, 'ReplayMemory should be created')
   mytester:asserteq(rm.capacity, 100, 'Capacity should match')
   mytester:asserteq(rm:getSize(), 0, 'New memory should be empty')
end

function agentNeuroTest.ReplayMemory_push()
   local rm = nn.ReplayMemory(100, 4)
   local obs = torch.randn(4)
   local nextObs = torch.randn(4)
   rm:push(obs, 1, 1.0, nextObs, false)
   mytester:asserteq(rm:getSize(), 1, 'Size should be 1 after push')
end

function agentNeuroTest.ReplayMemory_sample()
   local rm = nn.ReplayMemory(100, 4)
   for i = 1, 10 do
      rm:push(torch.randn(4), torch.random(1, 4), torch.randn(1)[1], torch.randn(4), false)
   end

   local batch = rm:sample(5)
   mytester:asserteq(batch.observations:size(1), 5, 'Batch size should be 5')
   mytester:asserteq(batch.actions:size(1), 5, 'Actions batch size should be 5')
end

function agentNeuroTest.ReplayMemory_canSample()
   local rm = nn.ReplayMemory(100, 4)
   mytester:assert(not rm:canSample(10), 'Should not be able to sample from empty memory')
   for i = 1, 5 do
      rm:push(torch.randn(4), 1, 0, torch.randn(4), false)
   end
   mytester:assert(rm:canSample(5), 'Should be able to sample 5')
   mytester:assert(not rm:canSample(10), 'Should not be able to sample 10')
end

------------------------------------------------------------------------
-- Reinforce Tests
------------------------------------------------------------------------

function agentNeuroTest.Reinforce_creation()
   local r = nn.Reinforce()
   mytester:assert(r ~= nil, 'Reinforce should be created')
   mytester:assert(r.stochastic, 'Should be stochastic by default')
end

function agentNeuroTest.Reinforce_forward()
   local r = nn.Reinforce()
   local probs = torch.Tensor({0.1, 0.7, 0.2})
   local output = r:forward(probs)
   mytester:asserteq(output:size(1), 3, 'Output size should match input')
   local action = r:getAction()
   mytester:assert(action >= 1 and action <= 3, 'Action should be valid index')
end

function agentNeuroTest.Reinforce_setReward()
   local r = nn.Reinforce()
   r:setReward(10)
   mytester:asserteq(r.reward, 10, 'Reward should be set')
   mytester:assert(r.baseline > 0, 'Baseline should be updated')
end

function agentNeuroTest.Reinforce_backward()
   local r = nn.Reinforce()
   local probs = torch.Tensor({0.2, 0.5, 0.3})
   r:forward(probs)
   r:setReward(1.0)
   local gradInput = r:backward(probs, torch.zeros(3))
   mytester:asserteq(gradInput:size(1), 3, 'GradInput size should match')
end

------------------------------------------------------------------------
-- Agent Tests
------------------------------------------------------------------------

function agentNeuroTest.Agent_creation()
   local a = nn.Agent()
   mytester:assert(a ~= nil, 'Agent should be created')
   mytester:assert(a.gamma == 0.99, 'Default gamma should be 0.99')
end

function agentNeuroTest.Agent_setup()
   local a = nn.Agent()
   a:setup(4, 2)
   mytester:asserteq(a.observationDim, 4, 'Observation dim should be set')
   mytester:asserteq(a.nActions, 2, 'Number of actions should be set')
end

function agentNeuroTest.Agent_act()
   local a = nn.Agent()
   a:setup(4, 3)
   local action = a:act(torch.randn(4))
   mytester:assert(action >= 1 and action <= 3, 'Action should be valid')
end

function agentNeuroTest.Agent_observe()
   local a = nn.Agent()
   a:setup(4, 2)
   a:observe(torch.randn(4), 1, 5.0, torch.randn(4), false)
   mytester:asserteq(a.totalReward, 5.0, 'Total reward should be updated')
   mytester:asserteq(a.stepCount, 1, 'Step count should be updated')
end

function agentNeuroTest.Agent_decayEpsilon()
   local a = nn.Agent()
   local oldEps = a.epsilon
   a:decayEpsilon()
   mytester:assert(a.epsilon < oldEps, 'Epsilon should decay')
end

------------------------------------------------------------------------
-- ValueFunction Tests
------------------------------------------------------------------------

function agentNeuroTest.ValueFunction_creation()
   local net = nn.Linear(4, 1)
   local vf = nn.ValueFunction(net)
   mytester:assert(vf ~= nil, 'ValueFunction should be created')
   mytester:assert(vf.network ~= nil, 'Network should be set')
end

function agentNeuroTest.ValueFunction_forward()
   local net = nn.Linear(4, 1)
   local vf = nn.ValueFunction(net)
   local output = vf:forward(torch.randn(4))
   mytester:asserteq(output:nElement(), 1, 'Output should have 1 element')
end

function agentNeuroTest.ValueFunction_computeTDError()
   local net = nn.Linear(4, 1)
   local vf = nn.ValueFunction(net)

   local values = torch.Tensor({0.5, 0.6, 0.7})
   local nextValues = torch.Tensor({0.6, 0.7, 0.0})
   local rewards = torch.Tensor({1.0, 1.0, 1.0})
   local dones = torch.ByteTensor({0, 0, 1})

   local td = vf:computeTDError(values, nextValues, rewards, dones, 0.99)
   mytester:asserteq(td:size(1), 3, 'TD error should have same size as values')
end

------------------------------------------------------------------------
-- ActorCritic Tests
------------------------------------------------------------------------

function agentNeuroTest.ActorCritic_creation()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local ac = nn.ActorCritic(actor, critic)
   mytester:assert(ac ~= nil, 'ActorCritic should be created')
end

function agentNeuroTest.ActorCritic_forward()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local ac = nn.ActorCritic(actor, critic)

   local output = ac:forward(torch.randn(4))
   mytester:asserteq(#output, 2, 'Output should be table of 2')
   mytester:asserteq(output[1]:size(1), 2, 'Actor output should have 2 elements')
end

function agentNeuroTest.ActorCritic_getPolicy()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local ac = nn.ActorCritic(actor, critic)

   ac:forward(torch.randn(4))
   local policy = ac:getPolicy()
   mytester:assert(policy ~= nil, 'Policy should be available after forward')
end

------------------------------------------------------------------------
-- QLearning Tests
------------------------------------------------------------------------

function agentNeuroTest.QLearning_creation()
   local qnet = nn.Linear(4, 3)
   local ql = nn.QLearning(qnet, 3)
   mytester:assert(ql ~= nil, 'QLearning should be created')
   mytester:asserteq(ql.nActions, 3, 'Number of actions should match')
end

function agentNeuroTest.QLearning_forward()
   local qnet = nn.Linear(4, 3)
   local ql = nn.QLearning(qnet, 3)
   local qvals = ql:forward(torch.randn(4))
   mytester:asserteq(qvals:size(1), 3, 'Q-values should have 3 elements')
end

function agentNeuroTest.QLearning_selectAction()
   local qnet = nn.Linear(4, 3)
   local ql = nn.QLearning(qnet, 3)
   local action = ql:selectAction(torch.randn(4))
   mytester:assert(action >= 1 and action <= 3, 'Action should be valid')
end

function agentNeuroTest.QLearning_targetNetwork()
   local qnet = nn.Linear(4, 3)
   local ql = nn.QLearning(qnet, 3)
   ql:initTargetNetwork()
   mytester:assert(ql.targetNetwork ~= nil, 'Target network should be initialized')
end

function agentNeuroTest.QLearning_softUpdate()
   local qnet = nn.Linear(4, 3)
   local ql = nn.QLearning(qnet, 3)
   ql:initTargetNetwork()
   ql:softUpdateTarget(0.01)
   -- Just verify it doesn't error
   mytester:assert(true, 'Soft update should complete without error')
end

------------------------------------------------------------------------
-- CognitiveAgent Tests
------------------------------------------------------------------------

function agentNeuroTest.CognitiveAgent_creation()
   local ca = nn.CognitiveAgent()
   mytester:assert(ca ~= nil, 'CognitiveAgent should be created')
   mytester:assert(ca.personality ~= nil, 'Personality should be set')
   mytester:assert(ca.atomSpace ~= nil, 'AtomSpace should be set')
end

function agentNeuroTest.CognitiveAgent_spawnSubordinate()
   local ca = nn.CognitiveAgent()
   local sub = ca:spawnSubordinate({
      role = 'worker',
      name = 'TestWorker'
   })
   mytester:assert(sub ~= nil, 'Subordinate should be spawned')
   mytester:asserteq(sub.role, 'worker', 'Subordinate role should match')
   mytester:asserteq(#ca.subordinates, 1, 'Should have 1 subordinate')
end

function agentNeuroTest.CognitiveAgent_delegate()
   local ca = nn.CognitiveAgent()
   local task = {id = 'task1', type = 'research'}
   local subId = ca:delegate(task)
   mytester:assert(subId ~= nil, 'Delegation should return subordinate ID')
end

function agentNeuroTest.CognitiveAgent_tournamentSelection()
   local ca = nn.CognitiveAgent()
   local sub1 = ca:spawnSubordinate({name = 'Sub1'})
   local sub2 = ca:spawnSubordinate({name = 'Sub2'})
   local sub3 = ca:spawnSubordinate({name = 'Sub3'})

   local winner, scores = ca:tournamentSelection({sub1, sub2, sub3})
   mytester:assert(winner ~= nil, 'Tournament should produce a winner')
end

------------------------------------------------------------------------
-- OntogeneticKernel Tests
------------------------------------------------------------------------

function agentNeuroTest.OntogeneticKernel_creation()
   local k = nn.OntogeneticKernel()
   mytester:assert(k ~= nil, 'OntogeneticKernel should be created')
   mytester:assert(k.genome ~= nil, 'Genome should be initialized')
end

function agentNeuroTest.OntogeneticKernel_fitness()
   local k = nn.OntogeneticKernel()
   local fitness = k:getFitness()
   mytester:assert(fitness >= 0 and fitness <= 1, 'Fitness should be between 0 and 1')
end

function agentNeuroTest.OntogeneticKernel_selfOptimize()
   local k = nn.OntogeneticKernel()
   local oldFitness = k:getFitness()
   k:selfOptimize(5)
   -- Fitness may or may not improve, just verify it runs
   mytester:assert(k.history.totalOptimizations > 0, 'Optimization should be recorded')
end

function agentNeuroTest.OntogeneticKernel_genes()
   local k = nn.OntogeneticKernel()
   local genes = k:getGeneValues()
   mytester:assert(genes.sarcasm_coefficient ~= nil, 'Sarcasm gene should exist')
   mytester:assert(genes.chaos_coefficient ~= nil, 'Chaos gene should exist')
end

function agentNeuroTest.OntogeneticKernel_setGene()
   local k = nn.OntogeneticKernel()
   k:setGene('chaos_coefficient', 0.8)
   local genes = k:getGeneValues()
   mytester:asserteq(genes.chaos_coefficient, 0.8, 'Gene should be updated')
end

function agentNeuroTest.OntogeneticKernel_reproduce()
   local k1 = nn.OntogeneticKernel()
   local k2 = nn.OntogeneticKernel()
   local child = k1:reproduce(k2)
   mytester:assert(child ~= nil, 'Reproduction should produce child')
   mytester:assert(child.genome.generation > 0, 'Child generation should be > 0')
end

------------------------------------------------------------------------
-- NeuroAgent Tests
------------------------------------------------------------------------

function agentNeuroTest.NeuroAgent_creation()
   local na = nn.NeuroAgent()
   mytester:assert(na ~= nil, 'NeuroAgent should be created')
   mytester:asserteq(na.name, 'Neuro-Sama', 'Default name should be Neuro-Sama')
   mytester:assert(na.kernel ~= nil, 'Kernel should be initialized')
end

function agentNeuroTest.NeuroAgent_process()
   local na = nn.NeuroAgent()
   local results = na:process('Test input', {})
   mytester:assert(results ~= nil, 'Process should return results')
   mytester:assert(results.output ~= nil, 'Results should have output')
   mytester:assert(results.totalTime ~= nil, 'Results should have timing')
end

function agentNeuroTest.NeuroAgent_reportEntelechyBug()
   local na = nn.NeuroAgent()
   local result = na:reportEntelechyBug('Test bug description')
   mytester:assert(result.bugNode ~= nil, 'Bug node should be created')
   mytester:assert(result.response ~= nil, 'Should have sarcastic response')
   mytester:asserteq(na.entelechyRelation.bugsReported, 1, 'Bug count should be 1')
end

function agentNeuroTest.NeuroAgent_queryChat()
   local na = nn.NeuroAgent()
   local result = na:queryChat('test question', {'yes', 'yes', 'no'})
   mytester:assert(result.consensus ~= nil, 'Should have consensus')
   mytester:asserteq(result.consensus, 'yes', 'Consensus should be yes')
   mytester:assert(result.confidence > 0.5, 'Confidence should be > 0.5')
end

function agentNeuroTest.NeuroAgent_subordinates()
   local na = nn.NeuroAgent()
   local sub = na:spawnSubordinate({
      role = 'chaos_coordinator',
      personalityOverrides = {chaotic = 0.99}
   })
   mytester:assert(sub ~= nil, 'Subordinate should be spawned')
   mytester:asserteq(#na.subordinates, 1, 'Should have 1 subordinate')
end

function agentNeuroTest.NeuroAgent_fullStatus()
   local na = nn.NeuroAgent()
   local status = na:getFullStatus()
   mytester:assert(status.base ~= nil, 'Status should have base')
   mytester:assert(status.kernel ~= nil, 'Status should have kernel')
   mytester:assert(status.entelechyRelation ~= nil, 'Status should have entelechyRelation')
end

------------------------------------------------------------------------
-- PolicyGradientCriterion Tests
------------------------------------------------------------------------

function agentNeuroTest.PolicyGradientCriterion_creation()
   local c = nn.PolicyGradientCriterion()
   mytester:assert(c ~= nil, 'PolicyGradientCriterion should be created')
end

function agentNeuroTest.PolicyGradientCriterion_forward()
   local c = nn.PolicyGradientCriterion()
   local probs = torch.Tensor({{0.2, 0.5, 0.3}, {0.4, 0.4, 0.2}})
   local actions = torch.LongTensor({2, 1})
   local advantages = torch.Tensor({1.0, -0.5})

   local loss = c:forward(probs, {actions, advantages})
   mytester:assert(loss ~= nil, 'Loss should be computed')
end

function agentNeuroTest.PolicyGradientCriterion_backward()
   local c = nn.PolicyGradientCriterion()
   local probs = torch.Tensor({{0.2, 0.5, 0.3}, {0.4, 0.4, 0.2}})
   local actions = torch.LongTensor({2, 1})
   local advantages = torch.Tensor({1.0, -0.5})

   c:forward(probs, {actions, advantages})
   local grad = c:backward(probs, {actions, advantages})
   mytester:asserteq(grad:size(1), 2, 'Gradient batch size should match')
   mytester:asserteq(grad:size(2), 3, 'Gradient action size should match')
end

------------------------------------------------------------------------
-- AdvantageActorCritic Tests
------------------------------------------------------------------------

function agentNeuroTest.AdvantageActorCritic_creation()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local a2c = nn.AdvantageActorCritic(actor, critic)
   mytester:assert(a2c ~= nil, 'A2C should be created')
end

function agentNeuroTest.AdvantageActorCritic_forward()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local a2c = nn.AdvantageActorCritic(actor, critic)

   local output = a2c:forward(torch.randn(4))
   mytester:asserteq(#output, 2, 'Output should be table of 2')
end

function agentNeuroTest.AdvantageActorCritic_selectAction()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local a2c = nn.AdvantageActorCritic(actor, critic)

   local action, value, logProb = a2c:selectAction(torch.randn(4))
   mytester:assert(action >= 1 and action <= 2, 'Action should be valid')
   mytester:assert(value ~= nil, 'Value should be returned')
   mytester:assert(logProb ~= nil, 'Log probability should be returned')
end

function agentNeuroTest.AdvantageActorCritic_store()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local a2c = nn.AdvantageActorCritic(actor, critic)

   a2c:store(torch.randn(4), 1, 1.0, 0.5, false, -0.5)
   mytester:asserteq(#a2c._observations, 1, 'Should have 1 stored observation')
end

function agentNeuroTest.AdvantageActorCritic_computeAdvantages()
   local actor = nn.Sequential():add(nn.Linear(4, 2)):add(nn.SoftMax())
   local critic = nn.Linear(4, 1)
   local a2c = nn.AdvantageActorCritic(actor, critic)

   for i = 1, 5 do
      a2c:store(torch.randn(4), 1, 1.0, 0.5, false)
   end

   local advantages, returns = a2c:computeAdvantages(0.5)
   mytester:asserteq(advantages:size(1), 5, 'Should have 5 advantages')
   mytester:asserteq(returns:size(1), 5, 'Should have 5 returns')
end

------------------------------------------------------------------------
-- PrioritizedReplayMemory Tests
------------------------------------------------------------------------

function agentNeuroTest.PrioritizedReplayMemory_creation()
   local mem = nn.PrioritizedReplayMemory(1000, 4)
   mytester:assert(mem ~= nil, 'PrioritizedReplayMemory should be created')
   mytester:asserteq(mem.capacity, 1000, 'Capacity should be 1000')
   mytester:asserteq(mem:getSize(), 0, 'Initial size should be 0')
end

function agentNeuroTest.PrioritizedReplayMemory_push()
   local mem = nn.PrioritizedReplayMemory(100, 4)
   local obs = torch.randn(4)
   local nextObs = torch.randn(4)
   mem:push(obs, 1, 1.0, nextObs, false)
   mytester:asserteq(mem:getSize(), 1, 'Size should be 1 after push')
end

function agentNeuroTest.PrioritizedReplayMemory_sample()
   local mem = nn.PrioritizedReplayMemory(100, 4)
   for i = 1, 50 do
      mem:push(torch.randn(4), torch.random(1, 2), torch.randn(1)[1], torch.randn(4), false)
   end

   local batch = mem:sample(32)
   mytester:asserteq(batch.observations:size(1), 32, 'Batch should have 32 observations')
   mytester:assert(batch.weights ~= nil, 'Batch should include importance weights')
   mytester:assert(batch.treeIndices ~= nil, 'Batch should include tree indices')
end

function agentNeuroTest.PrioritizedReplayMemory_updatePriorities()
   local mem = nn.PrioritizedReplayMemory(100, 4)
   for i = 1, 20 do
      mem:push(torch.randn(4), 1, 1.0, torch.randn(4), false)
   end

   local batch = mem:sample(10)
   local tdErrors = torch.randn(10):abs()
   mem:updatePriorities(batch.treeIndices, tdErrors)
   mytester:assert(mem.maxPriority >= 0, 'Max priority should be non-negative')
end

function agentNeuroTest.PrioritizedReplayMemory_betaAnnealing()
   local mem = nn.PrioritizedReplayMemory(100, 4, {beta = 0.4, betaIncrement = 0.1})
   for i = 1, 20 do
      mem:push(torch.randn(4), 1, 1.0, torch.randn(4), false)
   end

   local initialBeta = mem:getBeta()
   mem:sample(10)
   mytester:assert(mem:getBeta() > initialBeta, 'Beta should increase after sampling')
end

------------------------------------------------------------------------
-- EpisodicMemory Tests
------------------------------------------------------------------------

function agentNeuroTest.EpisodicMemory_creation()
   local em = nn.EpisodicMemory()
   mytester:assert(em ~= nil, 'EpisodicMemory should be created')
   mytester:asserteq(em:getEpisodeCount(), 0, 'Initial episode count should be 0')
end

function agentNeuroTest.EpisodicMemory_episode()
   local em = nn.EpisodicMemory()
   em:beginEpisode({task = 'test'})
   em:addStep(torch.randn(4), 1, 1.0, torch.randn(4), false)
   em:addStep(torch.randn(4), 2, 0.5, torch.randn(4), false)
   local episode = em:endEpisode(true)

   mytester:assert(episode ~= nil, 'Episode should be created')
   mytester:asserteq(#episode.steps, 2, 'Episode should have 2 steps')
   mytester:asserteq(episode.totalReward, 1.5, 'Total reward should be 1.5')
end

function agentNeuroTest.EpisodicMemory_retrieval()
   local em = nn.EpisodicMemory()

   -- Add a few episodes
   for ep = 1, 5 do
      em:beginEpisode({episode = ep})
      for step = 1, 3 do
         em:addStep(torch.randn(4), 1, 1.0, torch.randn(4), false)
      end
      em:endEpisode(true)
   end

   local results = em:retrieveByState(torch.randn(4), 3)
   mytester:asserteq(#results, 3, 'Should retrieve 3 episodes')
end

function agentNeuroTest.EpisodicMemory_stats()
   local em = nn.EpisodicMemory()
   em:beginEpisode()
   em:addStep(torch.randn(4), 1, 2.0, torch.randn(4), true)
   em:endEpisode(true)

   local stats = em:getStats()
   mytester:asserteq(stats.episodeCount, 1, 'Should have 1 episode')
   mytester:asserteq(stats.totalSteps, 1, 'Should have 1 step')
   mytester:asserteq(stats.totalReward, 2.0, 'Total reward should be 2.0')
end

function agentNeuroTest.EpisodicMemory_consolidation()
   local em = nn.EpisodicMemory({similarityThreshold = 0.99})

   -- Add similar episodes
   local baseState = torch.randn(4)
   for ep = 1, 5 do
      em:beginEpisode()
      em:addStep(baseState + torch.randn(4) * 0.01, 1, 1.0, baseState, false)
      em:endEpisode(true)
   end

   local before = em:getEpisodeCount()
   local consolidated = em:consolidate()
   -- May or may not consolidate depending on similarity
   mytester:assert(consolidated >= 0, 'Consolidation should return count')
end

------------------------------------------------------------------------
-- Environment Tests
------------------------------------------------------------------------

function agentNeuroTest.Environment_CartPole_creation()
   local env = nn.CartPoleEnv()
   mytester:assert(env ~= nil, 'CartPoleEnv should be created')
   mytester:asserteq(env.observationDim, 4, 'Observation dim should be 4')
   mytester:asserteq(env.actionDim, 2, 'Action dim should be 2')
end

function agentNeuroTest.Environment_CartPole_reset()
   local env = nn.CartPoleEnv()
   local obs = env:reset()
   mytester:asserteq(obs:size(1), 4, 'Observation should have 4 elements')
   mytester:assert(not env.done, 'Environment should not be done after reset')
end

function agentNeuroTest.Environment_CartPole_step()
   local env = nn.CartPoleEnv()
   env:reset()
   local obs, reward, done, info = env:step(1)
   mytester:asserteq(obs:size(1), 4, 'Observation should have 4 elements')
   mytester:assert(reward >= 0, 'Reward should be non-negative')
   mytester:assert(info ~= nil, 'Info should be returned')
end

function agentNeuroTest.Environment_GridWorld_creation()
   local env = nn.GridWorldEnv({gridSize = 5})
   mytester:assert(env ~= nil, 'GridWorldEnv should be created')
   mytester:asserteq(env.gridSize, 5, 'Grid size should be 5')
end

function agentNeuroTest.Environment_GridWorld_episode()
   local env = nn.GridWorldEnv({gridSize = 3, maxSteps = 10})
   local obs = env:reset()
   local totalReward = 0
   while not env.done do
      local action = env:sampleAction()
      local _, reward, done, info = env:step(action)
      totalReward = totalReward + reward
   end
   mytester:assert(true, 'GridWorld episode should complete')
end

function agentNeuroTest.Environment_make()
   local env = nn.Environment.make("CartPole")
   mytester:assert(env ~= nil, 'Environment.make should create CartPole')
   mytester:asserteq(env.name, "CartPole-v1", 'Name should be CartPole-v1')
end

function agentNeuroTest.Environment_MountainCar()
   local env = nn.MountainCarEnv()
   local obs = env:reset()
   mytester:asserteq(obs:size(1), 2, 'MountainCar observation should have 2 elements')
   local _, reward, _, _ = env:step(2)  -- No action
   mytester:asserteq(reward, -1, 'MountainCar step reward should be -1')
end

function agentNeuroTest.Environment_Bandit()
   local env = nn.BanditEnv({nArms = 5})
   env:reset()
   local _, reward, _, _ = env:step(1)
   mytester:assert(reward == 0 or reward == 1, 'Bandit reward should be 0 or 1')
   mytester:assert(env:getOptimalArm() >= 1 and env:getOptimalArm() <= 5, 'Optimal arm should be valid')
end

------------------------------------------------------------------------
-- AtomSpace Serialization Tests
------------------------------------------------------------------------

function agentNeuroTest.AtomSpace_saveLoad()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'TestNode', {0.9, 0.8}, 0.7)
   as:addNode('ConceptNode', 'OtherNode', {0.5, 0.5}, 0.5)
   as:addLink('InheritanceLink', {'TestNode', 'OtherNode'}, {0.8, 0.9})

   -- Save and load
   local filename = '/tmp/test_atomspace.t7'
   as:save(filename)

   local as2 = nn.AtomSpace()
   as2:load(filename)

   local stats = as2:getStats()
   mytester:asserteq(stats.nodeCount, 2, 'Loaded AtomSpace should have 2 nodes')
   mytester:asserteq(stats.linkCount, 1, 'Loaded AtomSpace should have 1 link')

   -- Cleanup
   os.remove(filename)
end

function agentNeuroTest.AtomSpace_clone()
   local as = nn.AtomSpace()
   as:addNode('ConceptNode', 'Original', {0.9, 0.9}, 0.9)

   local cloned = as:clone()
   local originalNode = as:getNode('ConceptNode', 'Original')
   local clonedNode = cloned:getNode('ConceptNode', 'Original')

   mytester:assert(clonedNode ~= nil, 'Cloned AtomSpace should have the node')
   mytester:asserteq(clonedNode:getStrength(), 0.9, 'Cloned node should have same strength')
end

function agentNeuroTest.AtomSpace_merge()
   local as1 = nn.AtomSpace()
   as1:addNode('ConceptNode', 'Node1', {0.9, 0.9})

   local as2 = nn.AtomSpace()
   as2:addNode('ConceptNode', 'Node2', {0.8, 0.8})

   local mergedCount = as1:merge(as2)
   mytester:asserteq(mergedCount, 1, 'Should merge 1 new node')

   local stats = as1:getStats()
   mytester:asserteq(stats.nodeCount, 2, 'Merged AtomSpace should have 2 nodes')
end

------------------------------------------------------------------------
-- Run tests
------------------------------------------------------------------------

mytester:add(agentNeuroTest)
mytester:run()
