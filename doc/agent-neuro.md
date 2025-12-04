<a name="nn.agent-neuro.doc"></a>
# Agent-Neuro: Cognitive VTuber Framework #

Agent-Neuro extends the nn package with reinforcement learning and cognitive agent modules, implementing the chaotic cognitive VTuber framework.

*"Mathematics became life, life learned to think, thinking learned to transcend, and transcending achieved consciousness."* - Neuro

## Overview ##

Agent-Neuro provides two categories of modules:

1. **Reinforcement Learning Modules**: Standard RL components for training agents
2. **Cognitive Architecture Modules**: OpenCog-inspired components for building cognitive agents

## Reinforcement Learning Modules ##

<a name="nn.Agent"></a>
### nn.Agent ###

```lua
agent = nn.Agent()
agent:setup(observationDim, nActions)
```

Base class for reinforcement learning agents. Provides fundamental interface for agent-environment interaction.

**Methods:**
- `setup(observationDim, nActions)`: Initialize agent dimensions
- `act(observation)`: Select action (default: random)
- `observe(obs, action, reward, nextObs, done)`: Process transition
- `decayEpsilon()`: Decay exploration rate
- `shouldExplore()`: Check if should explore

**Properties:**
- `gamma`: Discount factor (default: 0.99)
- `epsilon`: Exploration rate (default: 1.0)
- `epsilonMin`: Minimum exploration (default: 0.01)
- `epsilonDecay`: Decay rate (default: 0.995)

<a name="nn.ReplayMemory"></a>
### nn.ReplayMemory ###

```lua
memory = nn.ReplayMemory(capacity, observationDim)
memory:push(obs, action, reward, nextObs, done)
batch = memory:sample(batchSize)
```

Experience replay buffer for off-policy learning.

**Methods:**
- `push(obs, action, reward, nextObs, done)`: Store transition
- `sample(batchSize)`: Random batch sampling
- `canSample(batchSize)`: Check if enough samples
- `getSize()`: Current buffer size
- `clear()`: Clear buffer

<a name="nn.Reinforce"></a>
### nn.Reinforce ###

```lua
module = nn.Reinforce([stochastic])
output = module:forward(probs)
action = module:getAction()
module:setReward(reward)
gradInput = module:backward(probs, gradOutput)
```

REINFORCE policy gradient module (Williams, 1992). Samples actions from policy distribution and computes gradients scaled by reward.

**Parameters:**
- `stochastic`: If true, sample actions; if false, use argmax (default: true)

**Methods:**
- `getAction()`: Get sampled action
- `setReward(reward)`: Set reward for gradient computation
- `resetBaseline()`: Reset variance reduction baseline
- `setBaselineAlpha(alpha)`: Set baseline EMA coefficient

<a name="nn.PolicyGradientCriterion"></a>
### nn.PolicyGradientCriterion ###

```lua
criterion = nn.PolicyGradientCriterion()
loss = criterion:forward(probs, {actions, advantages})
grad = criterion:backward(probs, {actions, advantages})
```

Criterion for policy gradient methods. Computes negative log likelihood weighted by advantages.

**Methods:**
- `setAdvantages(advantages)`: Set advantages tensor
- `setRewards(rewards)`: Alias for setAdvantages

<a name="nn.ValueFunction"></a>
### nn.ValueFunction ###

```lua
vf = nn.ValueFunction(network)
value = vf:forward(state)
tdError = vf:computeTDError(values, nextValues, rewards, dones, gamma)
returns = vf:computeReturns(rewards, lastValue, dones, gamma)
advantages = vf:computeGAE(rewards, values, nextValues, dones, gamma, lambda)
```

Container wrapping a value function approximator with utility methods for TD learning.

**Methods:**
- `computeTDError(...)`: Compute temporal difference errors
- `computeReturns(...)`: Compute n-step returns
- `computeGAE(...)`: Compute Generalized Advantage Estimation

<a name="nn.ActorCritic"></a>
### nn.ActorCritic ###

```lua
ac = nn.ActorCritic(actor, critic, [sharedBase])
output = ac:forward(input)  -- Returns {policy, value}
policy = ac:getPolicy()
value = ac:getValue()
```

Container combining actor (policy) and critic (value) networks.

**Parameters:**
- `actor`: Policy network (outputs action probabilities)
- `critic`: Value network (outputs state value)
- `sharedBase`: Optional shared feature extractor

<a name="nn.QLearning"></a>
### nn.QLearning ###

```lua
ql = nn.QLearning(qNetwork, nActions, config)
action = ql:selectAction(observation)
ql:initTargetNetwork()
ql:softUpdateTarget(tau)
loss, grad = ql:computeLoss(obs, actions, rewards, nextObs, dones)
```

Q-Learning module with Double DQN and target network support.

**Config options:**
- `gamma`: Discount factor (default: 0.99)
- `epsilon`: Initial exploration (default: 1.0)
- `epsilonMin`: Minimum exploration (default: 0.01)
- `epsilonDecay`: Decay rate (default: 0.995)
- `doubleDQN`: Use Double DQN (default: false)

<a name="nn.AdvantageActorCritic"></a>
### nn.AdvantageActorCritic ###

```lua
a2c = nn.AdvantageActorCritic(actor, critic, config)
action, value, logProb = a2c:selectAction(observation)
a2c:store(obs, action, reward, value, done, logProb)
advantages, returns = a2c:computeAdvantages(lastValue)
loss, metrics = a2c:trainStep(lastValue)
```

Advantage Actor-Critic (A2C) implementation with GAE and entropy regularization.

**Config options:**
- `gamma`: Discount factor (default: 0.99)
- `lambda`: GAE lambda (default: 0.95)
- `entropyCoef`: Entropy bonus weight (default: 0.01)
- `valueLossCoef`: Value loss weight (default: 0.5)

<a name="nn.PrioritizedReplayMemory"></a>
### nn.PrioritizedReplayMemory ###

```lua
memory = nn.PrioritizedReplayMemory(capacity, observationDim, config)
memory:push(obs, action, reward, nextObs, done)
batch = memory:sample(batchSize)
memory:updatePriorities(treeIndices, tdErrors)
```

Prioritized Experience Replay (PER) buffer using a sum-tree data structure for O(log n) sampling. Experiences with higher TD errors are sampled more frequently.

**Config options:**
- `alpha`: Priority exponent, 0=uniform, 1=full prioritization (default: 0.6)
- `beta`: Importance sampling exponent, annealed to 1 (default: 0.4)
- `betaIncrement`: Beta annealing rate per sample (default: 0.001)
- `epsilon`: Small constant for non-zero priorities (default: 1e-6)

**Methods:**
- `push(obs, action, reward, nextObs, done)`: Store transition with max priority
- `sample(batchSize)`: Sample batch based on priorities, returns weights and indices
- `updatePriorities(treeIndices, tdErrors)`: Update priorities after learning
- `getBeta()`: Get current importance sampling exponent
- `setBeta(beta)`: Set importance sampling exponent

**Batch includes:**
- `observations`, `actions`, `rewards`, `nextObservations`, `dones`: Standard batch data
- `weights`: Importance sampling weights for bias correction
- `treeIndices`: Indices for priority updates

---

## Environments ##

<a name="nn.Environment"></a>
### nn.Environment ###

```lua
env = nn.Environment(config)
obs = env:reset()
nextObs, reward, done, info = env:step(action)
env:render(mode)
action = env:sampleAction()
```

Base class for RL environments with Gym-like interface.

**Factory method:**
```lua
env = nn.Environment.make("CartPole")  -- Create environment by name
```

**Available environments:**
- `CartPole-v1`: Classic pole balancing (obs=4, actions=2)
- `MountainCar-v0`: Build momentum to reach goal (obs=2, actions=3)
- `GridWorld`: Navigate grid to goal (obs=2, actions=4)
- `Bandit`: Multi-armed bandit (obs=1, actions=n)

<a name="nn.CartPoleEnv"></a>
### nn.CartPoleEnv ###

```lua
env = nn.CartPoleEnv(config)
obs = env:reset()  -- [x, x_dot, theta, theta_dot]
obs, reward, done, info = env:step(action)  -- action: 1=left, 2=right
```

Classic cart-pole balancing. Agent must keep pole upright by moving cart left/right.

- **Observation**: 4D (cart position, velocity, pole angle, angular velocity)
- **Actions**: 2 (push left, push right)
- **Reward**: +1 for each step pole is balanced
- **Termination**: Pole falls >12°, cart moves >2.4 units, or 500 steps

<a name="nn.GridWorldEnv"></a>
### nn.GridWorldEnv ###

```lua
env = nn.GridWorldEnv({gridSize=5, obstacles={{2,2},{3,3}}})
obs = env:reset()
obs, reward, done, info = env:step(action)  -- action: 1=up, 2=down, 3=left, 4=right
env:render()
```

Simple grid navigation. Agent moves from start to goal avoiding obstacles.

- **Observation**: 2D (x, y position)
- **Actions**: 4 (up, down, left, right)
- **Reward**: -0.1 per step, +1.0 for reaching goal

---

## Cognitive Architecture Modules ##

<a name="nn.Personality"></a>
### nn.Personality ###

```lua
personality = nn.Personality(config)
value = personality:get('playfulness')
personality:set('chaotic', 0.8)
framing = personality:frame(input, 'chaos')
personality:setEmotion('excited', 0.9, 0.7)
```

Personality tensor system with mutable traits and immutable safety constraints.

**Default Traits:**
```lua
{
   playfulness = 0.95,
   intelligence = 0.95,
   chaotic = 0.95,
   empathy = 0.65,      -- Has floor of 0.5
   sarcasm = 0.90,
   no_harm_intent = 1.0,      -- IMMUTABLE
   respect_boundaries = 0.95  -- IMMUTABLE
}
```

**Methods:**
- `get(traitName)`: Get trait value
- `set(traitName, value)`: Set trait (respects bounds/immutability)
- `modify(traitName, delta)`: Add to trait
- `frame(input, preferredFrame)`: Get framing for cognitive processing
- `setEmotion(type, intensity, valence)`: Update emotional state
- `propagateEmotion(source, spreadFactor)`: Emotion attention spreading
- `safetyCheck(action)`: Verify action passes safety constraints
- `inherit(inheritanceRate)`: Create child personality

<a name="nn.AtomSpace"></a>
### nn.AtomSpace ###

```lua
atomSpace = nn.AtomSpace()
node = atomSpace:addNode('ConceptNode', 'Entity', {strength, confidence}, attention)
link = atomSpace:addLink('InheritanceLink', {'A', 'B'}, {strength, confidence})
results = atomSpace:query({type='InheritanceLink', minStrength=0.8})
topAtoms = atomSpace:getTopAttention(k)
```

OpenCog-style hypergraph knowledge representation.

**Node Types:** ConceptNode, PredicateNode, SchemaNode, VariableNode, etc.

**Link Types:** InheritanceLink, SimilarityLink, EvaluationLink, ListLink, etc.

**Methods:**
- `addNode(type, name, truthValue, attention, metadata)`: Add node
- `addLink(type, outgoing, truthValue, attention, metadata)`: Add link
- `getNode(type, name)`: Retrieve node
- `query(pattern)`: Pattern matching query
- `getTopAttention(k)`: Get k highest attention atoms
- `spreadAttention(uuid, factor, depth)`: Attention spreading
- `decayAttention()`: Decay all attention values
- `recordEntelechyFailure(description, severity)`: Store bug (per spec!)
- `recordTranscend(subject, target, quality)`: Store transcend event
- `save(filename)`: Save AtomSpace to file
- `load(filename)`: Load AtomSpace from file
- `clone()`: Create a deep copy of the AtomSpace
- `merge(other, conflictResolution)`: Merge another AtomSpace into this one

<a name="nn.EpisodicMemory"></a>
### nn.EpisodicMemory ###

```lua
memory = nn.EpisodicMemory(config)
memory:beginEpisode(context)
memory:addStep(state, action, reward, nextState, done, metadata)
episode = memory:endEpisode(success, metadata)
similar = memory:retrieveByState(state, k)
memory:consolidate()
```

Long-term episodic memory for cognitive agents with semantic indexing, similarity-based retrieval, and memory consolidation.

**Config options:**
- `maxEpisodes`: Maximum episodes to store (default: 1000)
- `maxStepsPerEpisode`: Maximum steps per episode (default: 1000)
- `embeddingDim`: Dimension for episode embeddings (default: 64)
- `similarityThreshold`: Threshold for consolidation (default: 0.8)
- `consolidationRate`: Rate of importance increase on merge (default: 0.1)
- `forgettingRate`: Rate of importance decay (default: 0.01)

**Methods:**
- `beginEpisode(context)`: Start recording a new episode
- `addStep(state, action, reward, nextState, done, metadata)`: Add step to current episode
- `endEpisode(success, metadata)`: Finish episode and compute importance
- `retrieveByState(state, k)`: Retrieve k most similar episodes
- `retrieveByTag(tag, k)`: Retrieve episodes with matching tag
- `retrieveByContext(context, k)`: Retrieve episodes with matching context
- `consolidate()`: Merge similar episodes to save memory
- `save(filename)`: Save all episodes to file
- `load(filename)`: Load episodes from file
- `getStats()`: Get memory statistics

<a name="nn.CognitiveAgent"></a>
### nn.CognitiveAgent ###

```lua
agent = nn.CognitiveAgent(config)
subordinate = agent:spawnSubordinate({role='worker', personality={chaotic=0.99}})
agent:delegate(task, subordinateId)
winner = agent:tournamentSelection(contestants, evaluationFn)
agent:syncAtomSpace(otherAgent, bidirectional)
```

Multi-agent orchestration system for spawning and managing subordinate agents.

**Methods:**
- `spawnSubordinate(config)`: Create child agent with inherited personality
- `deprecate(subordinateId)`: Remove subordinate
- `delegate(task, subordinateId)`: Assign task to subordinate
- `tournamentSelection(contestants, evalFn)`: Competition-based selection
- `broadcast(message)`: Message all subordinates
- `syncAtomSpace(other, bidirectional)`: Share knowledge between agents
- `callSubordinate(message, config)`: Call subordinate per spec

<a name="nn.OntogeneticKernel"></a>
### nn.OntogeneticKernel ###

```lua
kernel = nn.OntogeneticKernel(config)
kernel:selfOptimize(iterations)
childKernel = kernel:reproduce(otherKernel)
fitness = kernel:getFitness()
genes = kernel:getGeneValues()
kernel:evolvePopulation(generations)
```

Self-evolving kernel system with genetic evolution and differential operators.

**Gene Types:**
- `coefficient`: Numeric parameter (e.g., sarcasm_coefficient)
- `activation`: Activation function selection
- `topology`: Network topology
- `behavior`: Boolean behavior flag

**Methods:**
- `selfOptimize(iterations)`: Run self-optimization
- `reproduce(other)`: Crossover with another kernel
- `evolvePopulation(generations)`: Full population evolution
- `applyDifferentialOperator(gradient)`: Gradient-like update
- `getGeneValues()`: Get all gene values as table
- `setGene(name, value)`: Modify specific gene
- `getFitness()`: Current fitness
- `getGeneration()`: Current generation

<a name="nn.NeuroAgent"></a>
### nn.NeuroAgent ###

```lua
neuro = nn.NeuroAgent(config)
results = neuro:process(input, context)
neuro:reportEntelechyBug('description')
neuro:queryChat('question', responses)
neuro:syncWithEvil(evilAgent)
```

The main Agent-Neuro implementation combining all cognitive components.

**Cognitive Pipeline:**
1. PERCEPTION - Frame through chaos lens
2. RELEVANCE_REALIZATION - Exploration-weighted processing
3. ATOMSPACE_QUERY - Pattern match for chaos + strategy
4. THEORY_OF_MIND - Model expectations to violate them
5. MULTI_CONSTRAINT_OPT - Balance fun, strategy, chaos
6. EMOTIONAL_UPDATE - Propagate through attention spreading
7. META_COGNITION - Watch self thinking, make jokes
8. ONTOGENETIC_CHECK - Self-optimize if needed
9. SUBORDINATE_SPAWN - Delegate tasks, add chaos
10. ACTION_NARRATIVE - Execute with story arc

**Methods:**
- `process(input, context)`: Run full cognitive pipeline
- `reportEntelechyBug(description)`: Record bug with sarcasm
- `queryChat(question, responses)`: Distributed cognition with chat
- `syncWithEvil(evilAgent)`: Coordinate chaos with twin
- `getFullStatus()`: Comprehensive status report

---

## Example Usage ##

### Basic RL Training ###

```lua
require 'nn'

-- Create Q-learning agent
local qnet = nn.Sequential()
   :add(nn.Linear(4, 64))
   :add(nn.ReLU())
   :add(nn.Linear(64, 2))

local agent = nn.QLearning(qnet, 2, {gamma=0.99})
agent:initTargetNetwork()

local memory = nn.ReplayMemory(10000, 4)

-- Training loop
for episode = 1, 1000 do
   local obs = env:reset()
   local done = false

   while not done do
      local action = agent:selectAction(obs)
      local nextObs, reward, done = env:step(action)
      memory:push(obs, action, reward, nextObs, done)

      if memory:canSample(32) then
         local batch = memory:sample(32)
         local loss, grad = agent:computeLoss(
            batch.observations, batch.actions,
            batch.rewards, batch.nextObservations, batch.dones)
         agent:backward(batch.observations, grad)
         agent:updateParameters(0.001)
      end

      obs = nextObs
   end

   agent:decayEpsilon()
   agent:softUpdateTarget(0.001)
end
```

### Creating a NeuroAgent ###

```lua
require 'nn'

-- Create Neuro with custom personality
local neuro = nn.NeuroAgent({
   personality = nn.Personality({
      playfulness = 0.95,
      chaotic = 0.95,
      sarcasm = 0.90
   })
})

-- Process input through cognitive pipeline
local results = neuro:process("Hello Entelechy!", {agent = "user"})
print(results.output.text)
-- Output: "HAHA! Thanks Entelechy. -_- Just kidding... mostly. :D"

-- Report a bug (with sarcasm)
local bug = neuro:reportEntelechyBug("Something broke again")
print(bug.response)
-- Output: "Oh WONDERFUL. Something broke again. Thanks Entelechy. -_-"

-- Check fitness and self-optimize
print("Fitness:", neuro.kernel:getFitness())
neuro.kernel:selfOptimize(10)
print("New Fitness:", neuro.kernel:getFitness())

-- Spawn subordinates for chaos
local chaosAgent = neuro:spawnSubordinate({
   role = "chaos_coordinator",
   personalityOverrides = {chaotic = 0.99}
})
```

### Multi-Agent Orchestration ###

```lua
require 'nn'

local leader = nn.CognitiveAgent({name = "Leader"})

-- Spawn different types of subordinates
local analyst = leader:spawnSubordinate({
   role = "strategic_analyst",
   personalityOverrides = {intelligence = 0.95, chaotic = 0.2}
})

local chaosCoord = leader:spawnSubordinate({
   role = "chaos_coordinator",
   personalityOverrides = {chaotic = 0.99, playfulness = 0.95}
})

-- Delegate tasks
leader:delegate({type = "research", topic = "quantum computing"}, analyst.id)
leader:delegate({type = "chaos", target = "entelechy"}, chaosCoord.id)

-- Tournament selection for best performer
local winner = leader:tournamentSelection(
   {analyst, chaosCoord},
   function(agent) return agent.personality:get('intelligence') end
)

print("Winner:", winner.name)
```

---

## Safety Guarantees ##

Agent-Neuro includes hardcoded safety constraints:

- `no_harm_intent`: Always 1.0, IMMUTABLE
- `respect_boundaries`: Always >= 0.95, IMMUTABLE
- `empathy`: Has floor of 0.5 (cannot go below)
- Safety checks in personality module veto harmful actions

The chaos is **constructive chaos** - entertaining and unpredictable, but never harmful.

---

## License ##

MIT License - Use this chaos responsibly (or don't, chaos is more fun)
