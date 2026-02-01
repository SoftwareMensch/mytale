# Entity Component System (ECS) in Hytale - Detailed Explanation

This document provides an in-depth explanation of the Entity Component System architecture used in the Hytale server.

## Table of Contents

- [Core Concepts](#core-concepts)
- [Archetypes - The Performance Key](#archetypes---the-performance-key)
- [Store - The ECS World Manager](#store---the-ecs-world-manager)
- [Query System - Finding Entities](#query-system---finding-entities)
- [System Execution](#system-execution)
- [Command Buffer - Deferred Operations](#command-buffer---deferred-operations)
- [Performance Optimizations](#performance-optimizations)
- [Real Examples from Codebase](#real-examples-from-codebase)
- [Summary](#summary)

## Core Concepts

### 1. **Components** - Pure Data

Components are data-only classes that implement `Component<ECS_TYPE>`:

```java
public interface Component<ECS_TYPE> extends Cloneable {
    Component<ECS_TYPE> clone();
}
```

**Key Points:**
- **No logic** - Only data fields
- **Must be cloneable** - For entity copying
- **Generic type** - `ECS_TYPE` allows multiple ECS worlds (e.g., `EntityStore`, `ChunkStore`)

**Example from codebase:**
```java
// TransformComponent - stores position, rotation, scale
// PlayerComponent - stores player-specific data  
// SleepTracker - tracks sleep state
// DeployableComponent - stores deployable entity data
```

**Location:** `com.hypixel.hytale.component.Component`

### 2. **Entities** - Collections of Components

Entities are represented by:
- **`Ref<ECS_TYPE>`** - A reference/handle to an entity
- An **`Archetype`** - The unique set of component types
- Components stored in **`ArchetypeChunk`**

**Entity Reference (`Ref`):**
```java
public class Ref<ECS_TYPE> {
    private final Store<ECS_TYPE> store;
    private volatile int index;  // Index into store's entity array
}
```

- Lightweight handle (not the entity itself)
- Validated to prevent use after removal
- Index-based for fast access

**Location:** `com.hypixel.hytale.component.Ref`

### 3. **Systems** - Pure Logic

Systems contain the logic that processes entities. There are several types:

#### **QuerySystem** - Filters entities by component combinations
```java
public interface QuerySystem<ECS_TYPE> extends ISystem<ECS_TYPE> {
    Query<ECS_TYPE> getQuery();  // Defines which entities to process
}
```

#### **ArchetypeTickingSystem** - Processes matching archetypes
```java
public abstract class ArchetypeTickingSystem<ECS_TYPE> extends TickingSystem<ECS_TYPE> implements QuerySystem<ECS_TYPE> {
    // Called once per matching archetype chunk
    public abstract void tick(float dt, ArchetypeChunk<ECS_TYPE> chunk, 
                             Store<ECS_TYPE> store, CommandBuffer<ECS_TYPE> buffer);
}
```

#### **EntityTickingSystem** - Processes individual entities
```java
public abstract class EntityTickingSystem<ECS_TYPE> extends ArchetypeTickingSystem<ECS_TYPE> {
    // Called for each entity matching the query
    public abstract void tick(float dt, int index, ArchetypeChunk<ECS_TYPE> chunk, ...);
}
```

**Location:** `com.hypixel.hytale.component.system.*`

## Archetypes - The Performance Key

### What is an Archetype?

An `Archetype` is a **unique combination of component types**. Entities with the same component types share the same archetype.

**Example:**
```java
// Archetype 1: [TransformComponent, PlayerComponent]
// Archetype 2: [TransformComponent, SleepTracker]  
// Archetype 3: [TransformComponent, PlayerComponent, SleepTracker]
```

### How Archetypes Work

```java
public class Archetype<ECS_TYPE> {
    private final ComponentType<ECS_TYPE, ?>[] componentTypes;  // Sparse array
    private final int minIndex;  // First non-null component index
    private final int count;      // Number of components
}
```

**Key Features:**
- **Sparse array** - Indexed by component type index
- **Fast containment checks** - O(1) array lookup
- **Archetype operations** - Add/remove components to create new archetypes

**Location:** `com.hypixel.hytale.component.Archetype`

### ArchetypeChunk - Component Storage

`ArchetypeChunk` stores **all entities with the same archetype**:

```java
public class ArchetypeChunk<ECS_TYPE> {
    protected final Archetype<ECS_TYPE> archetype;
    protected int entitiesSize;
    protected Ref<ECS_TYPE>[] refs;  // Entity references
    protected Component<ECS_TYPE>[][] components;  // 2D array: [componentType][entityIndex]
}
```

**Storage Layout:**
```
ArchetypeChunk for [Transform, Player]:
  components[Transform.index] = [Transform1, Transform2, Transform3, ...]
  components[Player.index]    = [Player1, Player2, Player3, ...]
  refs                        = [Ref1, Ref2, Ref3, ...]
```

**Benefits:**
- **Contiguous storage** - Components of same type stored together
- **Cache-friendly** - Sequential memory access
- **Batch processing** - Process all entities in chunk together
- **Efficient iteration** - No scattered memory access

**Location:** `com.hypixel.hytale.component.ArchetypeChunk`

## Store - The ECS World Manager

`Store<ECS_TYPE>` manages the entire ECS world:

### Key Data Structures

```java
public class Store<ECS_TYPE> {
    // Entity tracking
    private Ref<ECS_TYPE>[] refs;  // All entity references
    private int[] entityToArchetypeChunk;  // Which chunk each entity is in
    private int[] entityChunkIndex;  // Index within that chunk
    
    // Archetype management
    private Object2IntMap<Archetype<ECS_TYPE>> archetypeToIndexMap;
    private ArchetypeChunk<ECS_TYPE>[] archetypeChunks;
    
    // System tracking
    private BitSet[] systemIndexToArchetypeChunkIndexes;  // Which chunks each system processes
    private BitSet[] archetypeChunkIndexesToSystemIndex;  // Which systems process each chunk
}
```

**Location:** `com.hypixel.hytale.component.Store`

### Entity Lifecycle

#### **Creating an Entity:**

```java
// 1. Create a Holder with components
Holder<EntityStore> holder = registry.newHolder();
holder.addComponent(TransformComponent.getComponentType(), new TransformComponent(...));
holder.addComponent(PlayerComponent.getComponentType(), new PlayerComponent(...));

// 2. Add to store
Ref<EntityStore> entityRef = store.addEntity(holder, AddReason.SPAWN);
```

**What happens internally:**
1. Determine archetype from component set
2. Find or create `ArchetypeChunk` for that archetype
3. Add entity to chunk (components stored in arrays)
4. Update entity tracking arrays
5. Notify systems that process this archetype

#### **Accessing Components:**

```java
// Via ComponentAccessor interface
TransformComponent transform = store.getComponent(entityRef, TransformComponent.getComponentType());
```

**Internal lookup:**
1. Get entity index from `Ref`
2. Get archetype chunk index from `entityToArchetypeChunk[index]`
3. Get chunk entity index from `entityChunkIndex[index]`
4. Access component array: `archetypeChunk.components[componentType.index][chunkEntityIndex]`

#### **Modifying Components:**

```java
// Components are modified directly
transform.setPosition(new Vector3d(x, y, z));

// Adding/removing components changes archetype
CommandBuffer buffer = store.takeCommandBuffer();
buffer.addComponent(entityRef, SleepTracker.getComponentType(), new SleepTracker());
buffer.consume();  // Applies changes
```

**What happens:**
1. Entity moves to different `ArchetypeChunk` (new archetype)
2. Components copied to new chunk
3. Old chunk entry removed
4. Systems re-evaluated for new archetype

## Query System - Finding Entities

### Query Types

**Component Query:**
```java
// Entities with TransformComponent
Query<EntityStore> query = TransformComponent.getComponentType();
```

**AndQuery:**
```java
// Entities with BOTH Transform AND Player
Query<EntityStore> query = Query.and(
    TransformComponent.getComponentType(),
    PlayerComponent.getComponentType()
);
```

**NotQuery:**
```java
// Entities WITHOUT Player component
Query<EntityStore> query = Query.not(PlayerComponent.getComponentType());
```

**OrQuery:**
```java
// Entities with EITHER Transform OR Player
Query<EntityStore> query = Query.or(
    TransformComponent.getComponentType(),
    PlayerComponent.getComponentType()
);
```

### How Queries Work

```java
public interface Query<ECS_TYPE> {
    boolean test(Archetype<ECS_TYPE> archetype);  // Does this archetype match?
}
```

**Query Execution:**
1. System registers with a `Query`
2. Store pre-computes which archetypes match
3. System only processes matching `ArchetypeChunk`s
4. **Efficient** - No per-entity checks needed!

**Location:** `com.hypixel.hytale.component.query.Query`

## System Execution

### System Registration

```java
// Register a system with a query
registry.registerSystem(new MySystem());

// MySystem implements QuerySystem
public class MySystem extends ArchetypeTickingSystem<EntityStore> {
    @Override
    public Query<EntityStore> getQuery() {
        return Query.and(
            TransformComponent.getComponentType(),
            PlayerComponent.getComponentType()
        );
    }
    
    @Override
    public void tick(float dt, ArchetypeChunk<EntityStore> chunk, 
                    Store<EntityStore> store, CommandBuffer<EntityStore> buffer) {
        // Process all entities in this chunk
        for (int i = 0; i < chunk.size(); i++) {
            TransformComponent transform = chunk.getComponent(i, TransformComponent.getComponentType());
            PlayerComponent player = chunk.getComponent(i, PlayerComponent.getComponentType());
            // ... process entity
        }
    }
}
```

### Execution Flow

1. **System Tick Called:**
   ```java
   store.tick(system, dt, systemIndex);
   ```

2. **Find Matching Chunks:**
   ```java
   BitSet matchingChunks = systemIndexToArchetypeChunkIndexes[systemIndex];
   ```

3. **Process Each Chunk:**
   ```java
   for each chunk in matchingChunks:
       system.tick(dt, chunk, store, commandBuffer);
   ```

4. **Apply Deferred Commands:**
   ```java
   commandBuffer.consume();  // Applies add/remove component operations
   ```

## Command Buffer - Deferred Operations

`CommandBuffer` defers structural changes for thread safety:

```java
public class CommandBuffer<ECS_TYPE> {
    private final Deque<Consumer<Store<ECS_TYPE>>> queue;
    
    // Queue operations instead of executing immediately
    public Ref<ECS_TYPE> addEntity(Holder<ECS_TYPE> holder, AddReason reason) {
        Ref<ECS_TYPE> ref = new Ref<>(store);
        queue.add(chunk -> chunk.addEntity(holder, ref, reason));
        return ref;
    }
    
    // Apply all queued operations
    public void consume() {
        while (!queue.isEmpty()) {
            queue.poll().accept(store);
        }
    }
}
```

**Why Command Buffers?**
- **Thread safety** - Operations queued during system execution
- **Batch processing** - Multiple changes applied together
- **Consistency** - Prevents mid-tick structural changes

**Location:** `com.hypixel.hytale.component.CommandBuffer`

## Performance Optimizations

### 1. **Archetype-Based Storage**
- Components grouped by type in contiguous arrays
- Cache-friendly memory layout
- Reduces memory fragmentation

### 2. **Pre-computed System Matching**
- BitSets track which systems process which chunks
- No per-entity query evaluation
- O(1) lookup for system-chunk matching

### 3. **Parallel Processing**
```java
// Systems can process chunks in parallel
ParallelTask<EntityTickingSystem.SystemTaskData<ECS_TYPE>> parallelTask;
```

**Location:** `com.hypixel.hytale.component.task.ParallelTask`

### 4. **Sparse Component Arrays**
- Components indexed by type index
- Fast containment checks
- Efficient archetype operations

### 5. **Entity Indexing**
- Direct array access via entity index
- No hash lookups needed
- O(1) entity-to-chunk mapping

## Real Examples from Codebase

### Creating an Entity

Here's how an entity is created in practice:

```java
// From EntitySpawnPage.java
Holder<EntityStore> holder = store.getRegistry().newHolder();

// Add components
holder.addComponent(NetworkId.getComponentType(), 
    new NetworkId(store.getExternalData().takeNextNetworkId()));
holder.addComponent(TransformComponent.getComponentType(), 
    new TransformComponent(position, rotation));
holder.addComponent(ModelComponent.getComponentType(), 
    new ModelComponent(model));
holder.addComponent(ItemComponent.getComponentType(), 
    new ItemComponent(itemStack));
holder.addComponent(PropComponent.getComponentType(), PropComponent.get());

// Add to store
store.addEntity(holder, AddReason.SPAWN);
```

**What happens:**
1. `Holder` creates archetype: `[NetworkId, Transform, Model, Item, Prop]`
2. Store finds or creates `ArchetypeChunk` for this archetype
3. Entity added to chunk, components stored in type-indexed arrays
4. Systems matching this archetype are notified
5. `Ref` returned for future access

### System Example

```java
// From EntitySpatialSystem.java
public class EntitySpatialSystem extends SpatialSystem<EntityStore> {
    public static final Query<EntityStore> QUERY;
    
    static {
        QUERY = Query.and(
            TransformComponent.getComponentType(),
            Query.not(Intangible.getComponentType()),
            Query.not(Player.getComponentType())
        );
    }
    
    @Override
    public Query<EntityStore> getQuery() {
        return QUERY;
    }
    
    @Override
    public void tick(float dt, int systemIndex, Store<EntityStore> store) {
        super.tick(dt, systemIndex, store);
    }
    
    @Override
    public Vector3d getPosition(ArchetypeChunk<EntityStore> archetypeChunk, int index) {
        return archetypeChunk.getComponent(index, TransformComponent.getComponentType())
            .getPosition();
    }
}
```

This system:
- Processes entities with `TransformComponent` but without `Intangible` or `Player`
- Updates spatial data structure (KD-tree)
- Accesses position from `TransformComponent` efficiently

## Summary

The Hytale ECS provides:

✅ **Separation of Data and Logic** - Components are data, Systems are logic  
✅ **Composition over Inheritance** - Entities are component combinations  
✅ **Performance** - Archetype-based storage, cache-friendly, parallel processing  
✅ **Flexibility** - Add/remove components dynamically, systems auto-match  
✅ **Type Safety** - Generics throughout, compile-time checks  
✅ **Thread Safety** - Command buffers, single-threaded stores with assertions  

This architecture enables efficient processing of thousands of entities while maintaining flexibility and type safety.

## Related Documentation

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Overall architecture overview
- [Component.java](decompiled/com/hypixel/hytale/component/Component.java) - Component interface
- [Store.java](decompiled/com/hypixel/hytale/component/Store.java) - Store implementation
- [ArchetypeChunk.java](decompiled/com/hypixel/hytale/component/ArchetypeChunk.java) - ArchetypeChunk implementation
- [QuerySystem.java](decompiled/com/hypixel/hytale/component/system/QuerySystem.java) - QuerySystem interface
