import random
import math
import statistics
import os
import subprocess

GENOME_LENGTH = 50
POP_SIZE = 20
ELITE_SIZE = 5
GENERATIONS = 10
MUTATION_RATE = 0.1 # prob of mutating each gene
CX_RATE = 1 # prob of applying crossover
MUTATION_INTENSITY = 1 # stddev of a Gaussian distribution with mean 0
N_EVAL = 3

# Create random individual
def create_individual():
    return [random.uniform(-1,1) for _ in range(GENOME_LENGTH)]


# Compute fitness by evaluating the robot (N_EVAL times)
def fitness(individual):
    os.environ["GENOME"] = ",".join(map(str,individual))
    fvalue = []
    for _ in range(N_EVAL):
        proc = subprocess.Popen(
            ["argos3", "-c", "evaluate-controller-nn.argos"],
            stdout=subprocess.PIPE,
            text=True
        )
        for line in proc.stdout:
            if "FITNESS:" in line:
                fitness = str(line.strip().split(":")[1])
                fitness = float(fitness.replace(",", "."))
        fvalue.append(fitness)
    fitness = statistics.mean(fvalue)
    #fitness = min(fvalue)
    return fitness


# Selection: tournament
# Randomly pick 2 individuals and return the one with the highest fitness
def select_tournament(population, fitness_values):
    i = random.randrange(len(population))
    j = random.randrange(len(population))
    if fitness_values[i] >= fitness_values[j]:
        return population[i]
    else:
        return population[j]


# Selection: roulette wheel (proportional)
def select_proportional(population,fitness_values):
    total_fitness = sum(fitness_values)
    r = random.random() * total_fitness
    if r > total_fitness:
        r = total_fitness
    i = 0
    mysum = fitness_values[i]
    while mysum <= r:
        i += 1
        mysum += fitness_values[i]
    return population[i]


# Crossover: linear combination
def crossover(parent1, parent2):
    if random.random() <= CX_RATE:
        alpha = random.random()
        return [
            alpha * x + (1 - alpha) * y
            for x,y in zip(parent1,parent2)
        ]
    else:
        return parent1 if random.random() <= 0.5 else parent2


# Mutation: Gaussian noise
# each gene has a probability MUTATION_RATE to be changed
# random.random() : rnd number uniformly distributed in [0,1]
# random.gauss(0,MUTATION_INTENSITY) : rnd number in normal distrib with mean=0 and stddev=MUTATION_INTENSITY
def mutate(individual):
    return [
        gene + random.gauss(0, MUTATION_INTENSITY)
        if random.random() < MUTATION_RATE
        else gene
        for gene in individual
    ]



def print_stats(pop,fv):
    idx = max(range(POP_SIZE), key=lambda i: fv[i])
    best = pop[idx]
    print("Gen", gen, ": Best fitness =", round(fv[idx],4))
    print("Best solution:", best)
    print("\n")

# Main GA loop
population = [create_individual() for _ in range(POP_SIZE)]

#print("Random solution:", population[0])

# REPLACEMENT
for gen in range(GENERATIONS):
    fitness_values = [fitness(i) for i in population]
    print_stats(population,fitness_values)
    new_population = []
    for _ in range(POP_SIZE):
        parent1 = select_proportional(population,fitness_values)
        parent2 = select_proportional(population,fitness_values)
        child = crossover(parent1, parent2)
        child = mutate(child)
        new_population.append(child)
    population = new_population
    
# ELITISM
#for gen in range(GENERATIONS):
#    fitness_values = [fitness(i) for i in population]
#    print_stats(population, fitness_values)
#    
#    # Sort by fitness descending and keep ELITE_SIZE best
#    sorted_pop = sorted(zip(fitness_values, population), key=lambda x: x[0], reverse=True)
#    elites = [ind for _, ind in sorted_pop[:ELITE_SIZE]]
#    
#    # Generate new offspring to fill the rest of the population
#    new_population = elites[:]  # start with elites
#    while len(new_population) < POP_SIZE:
#        parent1 = select_proportional(population, fitness_values)
#        parent2 = select_proportional(population, fitness_values)
#        #parent1 = select_tournament(population,fitness_values)
#        #parent2 = select_tournament(population,fitness_values)
#        child = crossover(parent1, parent2)
#        child = mutate(child)
#        new_population.append(child)
#    
#    population = new_population
