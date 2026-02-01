# Hytale Server Architecture Documentation

This document outlines the software architecture discovered from the decompiled Hytale server source code.

## Table of Contents

- [Overview](#overview)
- [Core Architecture Patterns](#core-architecture-patterns)
- [Entity Component System (ECS)](#entity-component-system-ecs)
- [Plugin System](#plugin-system)
- [Module System](#module-system)
- [Registry Pattern](#registry-pattern)
- [Event-Driven Architecture](#event-driven-architecture)
- [Network Architecture](#network-architecture)
- [Serialization System](#serialization-system)
- [Resource Management](#resource-management)
- [Spatial Data Structures](#spatial-data-structures)
- [Command System](#command-system)
- [Dependency Management](#dependency-management)
- [Performance Optimizations](#performance-optimizations)

## Overview

The Hytale server uses a **layered, modular architecture** built on several key patterns:

- **Primary Pattern**: Entity Component System (ECS) for game entity management
- **Modularity**: Plugin-based system with isolated classloaders
- **Extensibility**: Registry pattern for dynamic registration
- **Performance**: Data-oriented design with archetype-based storage
- **Type Safety**: Extensive use of Java generics throughout

## Core Architecture Patterns

### 1. Entity Component System (ECS)

The core game logic follows a data-oriented ECS architecture where:
- **Components** = Data (no logic)
- **Systems** = Logic (process components)
- **Entities** = Collections of components

### 2. Plugin-Based Architecture

All functionality is organized into plugins that can be:
- Loaded/unloaded dynamically
- Isolated via separate classloaders
- Dependent on other plugins
- Enabled/disabled via configuration

### 3. Registry Pattern

Centralized registries manage:
- Components
- Systems
- Commands
- Events
- Assets
- Codecs

### 4. Event-Driven Architecture

Multiple event systems handle:
- ECS events (component changes)
- World events (chunk loading, etc.)
- Plugin lifecycle events
- User interactions

## Entity Component System (ECS)

The Hytale server uses a **data-oriented Entity Component System (ECS)** architecture for managing game entities. This is the core pattern that drives all entity-related logic.

**📖 For a detailed explanation of the ECS architecture, see [ECS.md](./ECS.md)**

### Quick Overview

The ECS architecture separates data (Components) from logic (Systems):

- **Components** = Pure data (no logic)
- **Systems** = Pure logic (process components)
- **Entities** = Collections of components (represented by `Ref<ECS_TYPE>`)

### Key Concepts

- **Archetypes** - Unique combinations of component types
- **ArchetypeChunk** - Stores all entities with the same archetype for performance
- **Store** - Manages the entire ECS world (entities, components, systems)
- **Query System** - Efficiently finds entities matching component combinations
- **Command Buffer** - Defers structural changes for thread safety

### Key Classes

- `Component<ECS_TYPE>` - Base interface for all components
- `Store<ECS_TYPE>` - ECS world manager
- `ArchetypeChunk<ECS_TYPE>` - Component storage by archetype
- `QuerySystem<ECS_TYPE>` - Systems that query entities
- `ArchetypeTickingSystem<ECS_TYPE>` - Systems that process archetypes
- `ComponentRegistry<ECS_TYPE>` - Component and system registration

**Location:** `com.hypixel.hytale.component.*`

## Plugin System

### Plugin Base Classes

**PluginBase** - Abstract base providing all plugin APIs:
- Registry access methods
- Logger access
- Configuration management
- Data directory access

**JavaPlugin** - Concrete base class for all plugins:
- Extends `PluginBase`
- Implements plugin lifecycle
- Provides initialization context

**Location:**
- `com.hypixel.hytale.server.core.plugin.PluginBase`
- `com.hypixel.hytale.server.core.plugin.JavaPlugin`

### Plugin Manager

`PluginManager` handles plugin lifecycle:

**Responsibilities:**
- Plugin discovery and loading
- Dependency resolution
- Load order determination
- State management (NONE → SETUP → START → ENABLED → SHUTDOWN → DISABLED)
- Classloader isolation

**Plugin States:**
1. `NONE` - Not loaded
2. `SETUP` - Setup phase (registration)
3. `START` - Starting phase
4. `ENABLED` - Running
5. `SHUTDOWN` - Shutting down
6. `DISABLED` - Disabled

**Location:** `com.hypixel.hytale.server.core.plugin.PluginManager`

### Plugin Lifecycle

Plugins implement three main lifecycle methods:

1. **`setup()`** - Registration phase
   - Register commands, events, assets
   - Register components and systems
   - Set up configuration

2. **`start()`** - Initialization phase
   - Initialize runtime state
   - Start background tasks
   - Final initialization

3. **`shutdown()`** - Cleanup phase
   - Save state
   - Clean up resources
   - Unregister handlers

### Plugin Isolation

- **PluginClassLoader**: Each plugin has isolated classloader
- **Bridge ClassLoader**: Shared API access
- **Classloader Isolation**: Prevents plugin conflicts

**Location:** `com.hypixel.hytale.server.core.plugin.PluginClassLoader`

### Plugin Manifest

`PluginManifest` defines plugin metadata:

- Group, name, version
- Dependencies (required/optional)
- Server version requirements
- Main class specification
- Asset pack inclusion flags
- Author information

**Location:** `com.hypixel.hytale.common.plugin.PluginManifest`

## Module System

The server is organized into functional modules:

### Core Modules

- **EntityModule** - Entity registration and management
- **ItemModule** - Item system
- **BlockModule** - Block system
- **InteractionModule** - Interaction system
- **BlockHealthModule** - Block health system
- **BlockSetModule** - Block set management
- **CameraModule** - Camera system
- **CollisionModule** - Collision detection
- **DebugModule** - Debug functionality
- **EntityStatsModule** - Entity statistics
- **EntityUIModule** - Entity UI system
- **I18nModule** - Internationalization
- **PhysicsModule** - Physics system
- **PrefabSpawnerModule** - Prefab spawning
- **ProjectileModule** - Projectile system
- **ServerPlayerListModule** - Server player list
- **SingleplayerModule** - Singleplayer functionality
- **SplitVelocityModule** - Velocity splitting
- **TimeModule** - Time management
- **AccessControlModule** - Access control
- **MigrationModule** - Data migrations

### Module Structure

Each module provides:
- Component registrations
- System registrations
- Registry access
- Module-specific APIs

**Location:** `com.hypixel.hytale.server.core.modules.*`

## Registry Pattern

Centralized registries manage extensible systems:

### Component Registry

- Registers component types
- Manages component metadata
- Provides component access

### System Registry

- Registers systems
- Manages system dependencies
- Controls execution order

### Command Registry

- Registers commands
- Handles command execution
- Provides command discovery

**Location:** `com.hypixel.hytale.server.core.command.system.CommandRegistry`

### Event Registry

- Registers event handlers
- Supports priorities (EARLY, NORMAL, LATE)
- Supports global and keyed events
- Supports async events

**Location:** `com.hypixel.hytale.event.EventRegistry`

### Asset Registry

- Registers game assets (items, blocks, etc.)
- Supports asset loading dependencies
- Supports custom asset types
- Manages asset lifecycle

**Location:** `com.hypixel.hytale.server.core.plugin.registry.AssetRegistry`

### Codec Registry

- Registers serialization codecs
- Supports polymorphic type registration
- Type-safe serialization

**Location:** `com.hypixel.hytale.server.core.plugin.registry.CodecMapRegistry`

## Event-Driven Architecture

### ECS Events

**EcsEvent** - Base class for ECS events:
- Component change events
- Entity lifecycle events
- System events

**Event Types:**
- `EntityEventType` - Entity-specific events
- `WorldEventType` - World-level events

**Location:** `com.hypixel.hytale.component.system.EcsEvent`

### Plugin Events

**PluginEvent** - Plugin lifecycle events:
- `PluginSetupEvent` - Plugin setup phase
- Custom plugin events

**Location:** `com.hypixel.hytale.server.core.plugin.event.*`

### Event Priorities

Events support three priority levels:
- `EARLY` - Execute before normal handlers
- `NORMAL` - Default priority
- `LATE` - Execute after normal handlers

### Event Registration

```java
// Global event
eventRegistry.registerGlobal(
    EventPriority.EARLY,
    PlayerJoinEvent.class,
    this::onPlayerJoin
);

// Keyed event (chunk-specific)
eventRegistry.register(
    ChunkLoadEvent.class,
    chunkId,
    this::onChunkLoad
);
```

## Network Architecture

### Custom Protocol

Hytale uses a **custom binary protocol** (not protobuf):
- Custom packet serialization
- Frame-based protocol
- Compression support (Zstd)
- Protocol versioning

**Key Classes:**
- `PacketIO` - Packet serialization/deserialization
- `PacketDecoder` - Netty decoder
- `PacketEncoder` - Netty encoder
- `PacketRegistry` - Packet type registry

**Location:** `com.hypixel.hytale.protocol.io.*`

### Transport Layer

**Transport Abstraction:**
- `TCPTransport` - TCP transport
- `QUICTransport` - QUIC transport
- `Transport` - Base transport interface

**Location:** `com.hypixel.hytale.server.core.io.transport.*`

### Netty Integration

Uses Netty for networking:
- `HytaleChannelInitializer` - Channel setup
- `PlayerChannelHandler` - Player connection handler
- `RateLimitHandler` - Rate limiting
- `LatencySimulationHandler` - Latency simulation

**Location:** `com.hypixel.hytale.server.core.io.netty.*`

### Packet Handlers

Handler chain pattern:
- `IPacketHandler` - Base handler interface
- `InitialPacketHandler` - Initial connection
- `GamePacketHandler` - Game packets
- `InventoryPacketHandler` - Inventory packets

**Location:** `com.hypixel.hytale.server.core.io.handlers.*`

## Serialization System

### Codec Pattern

Custom codec system for type-safe serialization:

**Codec Interface:**
```java
public interface Codec<T> {
    T decode(ByteBuf buf, int offset);
    void encode(T value, ByteBuf buf);
}
```

**Location:** `com.hypixel.hytale.codec.Codec`

### Codec Types

- **KeyedCodec** - Key-value serialization
- **BuilderCodec** - Builder pattern serialization
- **ArrayCodec** - Array serialization
- **Polymorphic Codecs** - Inheritance hierarchies

### Protocol Codecs

Specialized codecs for network protocol:
- `ProtocolCodecs` - Protocol-specific codecs
- `ColorCodec` - Color serialization
- `ShapeCodecs` - Shape serialization

**Location:** `com.hypixel.hytale.server.core.codec.protocol.*`

## Resource Management

### Resource System

**Resource** - Shared data accessible to systems:
- Type-safe resource registration
- Resource lifecycle management
- Thread-safe access

**ResourceType** - Type-safe resource type:
- Generic type parameter
- Resource factory
- Resource cleanup

**Location:** `com.hypixel.hytale.component.Resource`

### Resource Storage

**IResourceStorage** - Storage abstraction:
- `EmptyResourceStorage` - No-op implementation
- Custom storage implementations

**Location:** `com.hypixel.hytale.component.IResourceStorage`

## Spatial Data Structures

### KD-Tree

Efficient spatial queries using KD-tree:
- `KDTree` - KD-tree implementation
- `SpatialSystem` - System using spatial queries
- `SpatialResource` - Spatial data resource

**Location:** `com.hypixel.hytale.component.spatial.KDTree`

### Morton Codes

Spatial indexing using Morton codes:
- `MortonCode` - Morton code utilities
- Used for spatial partitioning

**Location:** `com.hypixel.hytale.component.spatial.MortonCode`

### Spatial System

**SpatialSystem** - Handles spatial queries:
- Entity spatial queries
- Efficient neighbor finding
- Spatial updates

**Location:** `com.hypixel.hytale.component.spatial.SpatialSystem`

## Command System

### Command Registry

Centralized command registration:
- Command discovery
- Command execution
- Permission checking

**Location:** `com.hypixel.hytale.server.core.command.system.CommandRegistry`

### Command Pattern

Commands implement command interface:
- `PluginCommand` - Plugin command base
- Custom command implementations

**Location:** `com.hypixel.hytale.server.core.plugin.commands.PluginCommand`

## Dependency Management

### System Dependencies

**Dependency Graph** - Manages system dependencies:
- `Dependency` - Base dependency class
- `SystemDependency` - System-to-system dependency
- `SystemGroupDependency` - Group dependency
- `SystemTypeDependency` - Type dependency

**Location:** `com.hypixel.hytale.component.dependency.*`

### System Groups

**SystemGroup** - Groups systems for execution:
- Execution order control
- Dependency management
- Group-based dependencies

**Location:** `com.hypixel.hytale.component.SystemGroup`

### Order Management

**Order** - Execution order:
- `BEFORE` - Execute before dependency
- `AFTER` - Execute after dependency

**OrderPriority** - Priority within order:
- Integer-based priority
- Fine-grained control

**Location:** `com.hypixel.hytale.component.dependency.Order`

## Performance Optimizations

### Archetype-Based Storage

- Components grouped by archetype
- Reduces memory fragmentation
- Enables batch processing
- Cache-friendly access patterns

### Parallel Processing

- Parallel system execution
- `ParallelTask` for concurrent operations
- Thread-safe command buffers

**Location:** `com.hypixel.hytale.component.task.ParallelTask`

### Spatial Optimization

- KD-tree for spatial queries
- Morton codes for spatial indexing
- Efficient neighbor finding

### Command Buffers

- Deferred operations
- Batch processing
- Thread safety

**Location:** `com.hypixel.hytale.component.CommandBuffer`

## Key Architectural Decisions

### 1. ECS Over OOP

Uses ECS instead of traditional OOP for:
- Better performance (data-oriented)
- Easier parallelization
- More flexible composition
- Better cache locality

### 2. Plugin Isolation

Isolated classloaders for:
- Plugin safety
- Version independence
- Dynamic loading/unloading
- Dependency management

### 3. Registry Pattern

Centralized registries for:
- Dynamic registration
- Extensibility
- Discovery
- Lifecycle management

### 4. Custom Protocol

Custom binary protocol instead of protobuf for:
- Performance optimization
- Game-specific needs
- Compression control
- Protocol versioning

### 5. Type Safety

Extensive use of generics for:
- Compile-time safety
- Better IDE support
- Reduced runtime errors
- Clearer APIs

## File Structure

```
com.hypixel.hytale/
├── component/          # ECS core
│   ├── system/        # System implementations
│   ├── query/         # Query system
│   ├── spatial/       # Spatial data structures
│   └── dependency/    # Dependency management
├── server.core/
│   ├── plugin/        # Plugin system
│   ├── modules/       # Core modules
│   ├── command/       # Command system
│   ├── io/            # Network layer
│   └── universe/      # World management
├── protocol/          # Network protocol
│   └── io/            # Protocol I/O
└── codec/             # Serialization
```

## Summary

The Hytale server architecture is:

- **Data-Oriented**: ECS architecture for performance
- **Modular**: Plugin-based with isolated classloaders
- **Extensible**: Registry pattern for dynamic registration
- **Type-Safe**: Extensive use of generics
- **Performant**: Archetype-based storage, parallel processing, spatial optimization
- **Event-Driven**: Multiple event systems for loose coupling
- **Custom**: Custom protocol and serialization for game-specific needs

This architecture enables a highly performant, extensible game server that can support complex game mechanics while maintaining good performance and allowing for community modding through plugins.
