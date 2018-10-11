copyArray = (array) ->
  copiedArray = []
  for element in array
    if element?.constructor is Array
      copiedArray.push(copyArray(element))
    else
      copiedArray.push(element)
  copiedArray

cloneObj = (obj) ->
  return obj if obj is null or typeof obj isnt "object" 
  copy = obj.constructor()
  for attr of obj
    copy[attr] = obj[attr] if obj.hasOwnProperty(attr)
  copy

class Chromosome

  factors: {
    a: 1
    b: 2
    c: 3
    d: 4   
  }

  chairCapacity: 30

  minValue: 0
  maxValue: 30
  valueSet: {}
  # only to save index where (and if) on the chromosome was operated on
  crossoverPoint: null
  mutationPoint: null

  # array with gens
  code: null

  constructor: ->
    @code = Array(Object.keys(@factors).length)
    # copy array
    @valueSet = cloneObj(Object.getPrototypeOf(@).valueSet)
    for i in [1..@code.length]
      code = @randomValueFor(i-1)
      @code[i-1] = code
      

  clone: ->
    c = new Chromosome()
    for key of @
      if Object.prototype.hasOwnProperty.call(@,key)
        c[key] = @[key]
    c.code = @code.slice()
    return c

  hasOptimalSolution: ->
    return false
    # return Math.floor(@fitness()) is 1

  randomValueFor: (index = 0) ->
    valueSet = @valueSet
    map = { 0: 'a', 1: 'b', 2: 'c', 3: 'd' }
    if valueSet
      valueSet = valueSet[map[index]]
      i = Math.floor(Math.random() * (Object.keys(valueSet).length))
      return Object.keys(valueSet)[i]
    else
      throw Error('No valueSet found')

  totalRevenue: ->
    @valueSet.a[@code[0]] + @valueSet.b[@code[1]] + @valueSet.c[@code[2]] + @valueSet.d[@code[3]]

  evaluateRequestedChairs: ->
    #F_obj[1] = Abs(( 12 + 2*05 + 3*23 + 4*08 ) - 30)
    sum = 0
    allValuesCount = 0
    @code.forEach (value, i) =>
      factor = @factors[Object.keys(@factors)[i]]
      sum += value * factor
      allValuesCount += value
    return Math.abs(sum - @chairCapacity)# + (Math.log(allValuesCount)/Math.exp(1))

  fitness: ->
    # fitness values is here: 1 -> optimal, > 0 -> not optimal 
    # the fittest chromosomes have higher probability to be selected for the next generation
    return ( 1 ) / ( 1 + @evaluateRequestedChairs() ) - ( ( 1 / @totalRevenue() ) )
  toString: (marker = '', index = 0, offset = 0)  ->
    # returns a nicer to read function string
    # ↓
    code = @code.slice() # copy array
    if marker
      code.splice(index, 0, marker)
      "( #{code.join(' ')} )"
    else
      parts = for c in code
        String(c)
      "( #{parts.join(' ')} )"
  toStringVerbose: (marker = '', index = 0, offset = 0) ->
    s = @toString(marker, index, offset)
    s.substring(0, s.length-1) + "{ rev: #{@totalRevenue()} capDev: #{@evaluateRequestedChairs()} } )"
  asObjectiveFunction: (usingNumericValues = true) ->
    sum = []
    i = 0
    for name of @factors
      value = if usingNumericValues then @code[i] else name
      sum.push("(#{@factors[name]} * #{value})")
      i++
    return "#{sum.join(' + ')} - #{@chairCapacity}"
  probability: (totalFitness) ->
    # P = Fitness / Total
    return @fitness() / totalFitness
  randomCrossoverPoint: (length = @code.length) ->
    # is between 1 and length-2
    # 'a' | 'b' | 'c' | 'd' | 'e'  -> | possible crossover point
    # between 0 and 2 for [a,b,c] 
    Math.round((Math.random()*(length)))
  createDescendantsBySingleCrossoverPoint: (secondChromosome, k = null) ->
    if k is null
      k = @randomCrossoverPoint()
    # 1st child
    code = @code.slice(0, k).concat(secondChromosome.code.slice(k))
    c1 = new Chromosome()
    c1.code = code
    c1.crossoverPoint = k
    # 2nd child
    code = secondChromosome.code.slice(0, k).concat(@code.slice(k))
    c2 = new Chromosome()
    c2.code = code
    c2.crossoverPoint = k
    return [ c1, c2 ]
  # deprecated, not the usual way
  createDescendantBySingleCrossoverPoint: (secondChromosome, k = null) ->
    if k is null
      k = @randomCrossoverPoint()
    code = @code.slice(0, k).concat(secondChromosome.code.slice(k))
    c = new Chromosome()
    c.code = code
    c.crossoverPoint = k
    return c
class SolvingCombinationWithGeneticAlgorithm
  numberOfChromosomes: 6
  population: []
  parents: []
  pairs: []
  selectedParentsIndex: []
  crossoverRate: 0.25
  mutationRate: 0.1
  constructor: (options = {}) ->
    # apply options
    for attr of options
      @[attr] = options[attr]
    @population = []
    @parents = []
    @pairs = []
    @selectedParentsIndex = []
    return @
  initPopulation: ->
    @population = for i in [0..@numberOfChromosomes-1]
      c = new Chromosome()
      c.pos = i
      c
    return @
  populationAsString: ->
    s = for c in @population
      c.toString()
    s.join(' | ')
  fitness: ->
    for chromosome in @population
      chromosome.fitness()
  totalFitness: ->
    @fitness().reduce (prev, curr, i, array) ->
      prev + curr
  probabilities: ->
    totalFitness = @totalFitness()
    for chromosome in @population
      chromosome.probability(totalFitness)
  cumulativeProbability: ->
    probabilities = @probabilities()
    probs = []
    probabilities.forEach (prob, i) ->
      cprob = if i>0 then probs[i-1] + prob else probabilities[0]
      probs.push(cprob)
    return probs
  selectNextGenerationByRouletteWheel: (randomNumbers = @randomNumbers()) ->
    nextGeneration = []
    cumulativeProbabilities = @cumulativeProbability()
    chromosomes = @population
    for randomProb, i in randomNumbers
      # initially select first
      winner = chromosomes[0]
      for j in [0..cumulativeProbabilities.length-2]
        if randomProb > cumulativeProbabilities[j] and randomProb <= cumulativeProbabilities[j+1]
          winner = chromosomes[j+1]
          break
      winner.pos = i
      nextGeneration.push(winner)
    nextGeneration
  selectPairsByCrossoverRate: (crossoverRate = @crossoverRate) ->
    parents = []
    r = []
    rMap = {}
    pairs = []
    @selectedParents = []
    # R[1] = 0.191
    # R[2] = 0.259
    # R[3] = 0.760
    # …
    indexes = []
    for chromosome, i in @population
      randomR = Math.random() # between 0 and 1
      if randomR < crossoverRate
        parents.push(chromosome)
        # @selectedParentsIndex.push(i)
        @selectedParents.push(chromosome)
        r.push(randomR)
        rMap[randomR] = { chromosome, i }
    r.sort()
    @parents = parents
    parents = @parents.slice() # copy array
    j = @population.length
    for randomR in r
      #              parent#1          parent#2
      parent_1 = parents.shift()
      parent_2 = rMap[randomR].chromosome
      pair = [ parent_1, parent_2 ]
      pairs.push(pair)
      
    return @pairs = pairs
      
  assignChildrenToPopulation: (children) ->
    for child in children
      @population[child.pos] = child
    @population
  mutatePopulation: (mutationRate = @mutationRate) ->
    totalGen = @population[0].code.length * @population.length
    numberOfMutations = mutationRate * totalGen
    for chromosome, i in @population
      for gene, j in chromosome.code
        rand = (Math.random()*(totalGen-1))+1
        if rand < numberOfMutations
          # which gene should be mutate?
          pos = Math.floor(Math.random()*chromosome.code.length)
          chromosome.mutationPoint = j
          chromosome.code[j] = chromosome.randomValueFor(j)
    @population
  round: (number, decimal = 10000) ->
    Math.round(number*decimal)/decimal
  randomNumbers: ->
    for chromosome in @population
      Math.random()
window.SolvingCombinationWithGeneticAlgorithm = SolvingCombinationWithGeneticAlgorithm
window.Chromosome = Chromosome
