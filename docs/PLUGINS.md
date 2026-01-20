# Hytale Server Mod API Documentation

This document outlines the modding API discovered from the decompiled Hytale server source code.

## Table of Contents

- [Overview](#overview)
- [Core Plugin Structure](#core-plugin-structure)
- [Plugin Lifecycle](#plugin-lifecycle)
- [Available APIs](#available-apis)
- [Key Files](#key-files)
- [Example Plugins](#example-plugins)
- [Usage Patterns](#usage-patterns)

## Overview

The Hytale server uses a plugin-based modding system where mods extend `JavaPlugin` and have access to various registries for commands, events, entities, blocks, assets, and more. The system follows an ECS (Entity Component System) architecture with components, systems, and registries.

## Core Plugin Structure

### Base Classes

- **[PluginBase.java](decompiled/com/hypixel/hytale/server/core/plugin/PluginBase.java)** - Abstract base class providing all plugin APIs
- **[JavaPlugin.java](decompiled/com/hypixel/hytale/server/core/plugin/JavaPlugin.java)** - Base class for all plugins, extends PluginBase
- **[PluginManager.java](decompiled/com/hypixel/hytale/server/core/plugin/PluginManager.java)** - Manages plugin loading, dependencies, and lifecycle

### Plugin Manifest

- **[PluginManifest.java](decompiled/com/hypixel/hytale/common/plugin/PluginManifest.java)** - Defines plugin metadata:
  - Group, name, version
  - Dependencies (required/optional)
  - Server version requirements
  - Main class specification
  - Asset pack inclusion flags

## Plugin Lifecycle

Plugins implement three main lifecycle methods:

1. **`setup()`** - Called during plugin setup phase
   - Register commands, events, assets, codecs
   - Register components and systems
   - Set up initial configuration

2. **`start()`** - Called after setup completes
   - Initialize runtime state
   - Start background tasks
   - Perform final initialization

3. **`shutdown()`** - Called when plugin is disabled
   - Save state
   - Clean up resources
   - Unregister handlers

## Available APIs

### Registries Available Through PluginBase

All registries are accessed via methods on `PluginBase`:

#### Command System
- **`getCommandRegistry()`** - Register custom commands
  - See: [CommandRegistry.java](decompiled/com/hypixel/hytale/server/core/command/system/CommandRegistry.java)

#### Event System
- **`getEventRegistry()`** - Register event handlers
  - Supports priorities (EARLY, NORMAL, LATE)
  - Supports global and keyed events
  - Supports async events
  - See: [EventRegistry.java](decompiled/com/hypixel/hytale/event/EventRegistry.java)

#### Entity System
- **`getEntityRegistry()`** - Register custom entity types
- **`getEntityStoreRegistry()`** - Register entity components
  - See: [EntityModule.java](decompiled/com/hypixel/hytale/server/core/modules/entity/EntityModule.java) for entity registration API

#### Block System
- **`getBlockStateRegistry()`** - Register custom block states
- **`getChunkStoreRegistry()`** - Register chunk components

#### Asset System
- **`getAssetRegistry()`** - Register custom assets (items, blocks, etc.)
  - Supports asset loading dependencies
  - Supports custom asset types

#### Codec System
- **`getCodecRegistry()`** - Register custom serialization codecs
  - Multiple overloads for different codec types
  - Supports polymorphic type registration

#### Task System
- **`getTaskRegistry()`** - Register scheduled tasks

### Other APIs

- **`getLogger()`** - Plugin-specific logger
- **`getDataDirectory()`** - Plugin data directory (Path)
- **`getBasePermission()`** - Base permission string for the plugin
- **`withConfig()`** - Configuration management
- **`getClientFeatureRegistry()`** - Register client-side features

## Key Files

### Core Plugin Infrastructure

| File | Purpose |
|------|---------|
| [PluginBase.java](decompiled/com/hypixel/hytale/server/core/plugin/PluginBase.java) | Base class with all plugin APIs |
| [JavaPlugin.java](decompiled/com/hypixel/hytale/server/core/plugin/JavaPlugin.java) | Plugin base class |
| [PluginManager.java](decompiled/com/hypixel/hytale/server/core/plugin/PluginManager.java) | Plugin loading and management |
| [PluginManifest.java](decompiled/com/hypixel/hytale/common/plugin/PluginManifest.java) | Plugin metadata structure |

### Registry APIs

| File | Purpose |
|------|---------|
| [CommandRegistry.java](decompiled/com/hypixel/hytale/server/core/command/system/CommandRegistry.java) | Command registration API |
| [EventRegistry.java](decompiled/com/hypixel/hytale/event/EventRegistry.java) | Event registration API |
| [EntityModule.java](decompiled/com/hypixel/hytale/server/core/modules/entity/EntityModule.java) | Entity registration API |

## Example Plugins

### BlockTickPlugin
**File:** [BlockTickPlugin.java](decompiled/com/hypixel/hytale/builtin/blocktick/BlockTickPlugin.java)

Demonstrates:
- Codec registration (`TickProcedure.CODEC.register()`)
- Global event registration (`registerGlobal()`)
- System registration (`ChunkStore.REGISTRY.registerSystem()`)
- Interface implementation (`IBlockTickProvider`)

```java
@Override
protected void setup() {
    TickProcedure.CODEC.register("BasicChance", BasicChanceBlockGrowthProcedure.class, ...);
    this.getEventRegistry().registerGlobal(EventPriority.EARLY, ChunkPreLoadProcessEvent.class, ...);
    ChunkStore.REGISTRY.registerSystem(new ChunkBlockTickSystem.PreTick());
}
```

### ShopPlugin
**File:** [ShopPlugin.java](decompiled/com/hypixel/hytale/builtin/adventure/shop/ShopPlugin.java)

Demonstrates:
- Asset registration (`getAssetRegistry().register()`)
- Codec registry usage (`getCodecRegistry()`)
- Lifecycle methods (`start()`, `shutdown()`)

```java
@Override
protected void setup() {
    this.getAssetRegistry().register(
        HytaleAssetStore.builder(ShopAsset.class, new DefaultAssetMap())
            .setPath()
            .setCodec(ShopAsset.CODEC)
            .setKeyFunction(ShopAsset::getId)
            .loadsAfter(Item.class)
            .build()
    );
    this.getCodecRegistry(ChoiceElement.CODEC)
        .register("ShopElement", ShopElement.class, ShopElement.CODEC);
}
```

### BlockSpawnerPlugin
**File:** [BlockSpawnerPlugin.java](decompiled/com/hypixel/hytale/builtin/blockspawner/BlockSpawnerPlugin.java)

Demonstrates:
- Component registration (`getChunkStoreRegistry().registerComponent()`)
- System registration (`getChunkStoreRegistry().registerSystem()`)
- Command registration (`getCommandRegistry().registerCommand()`)

```java
@Override
protected void setup() {
    this.getCommandRegistry().registerCommand(new BlockSpawnerCommand());
    this.blockSpawnerComponentType = this.getChunkStoreRegistry()
        .registerComponent(BlockSpawner.class, "BlockSpawner", BlockSpawner.CODEC);
    this.getChunkStoreRegistry().registerSystem(new BlockSpawnerSystem());
}
```

### InstancesPlugin
**File:** [InstancesPlugin.java](decompiled/com/hypixel/hytale/builtin/instances/InstancesPlugin.java)

Demonstrates:
- Multiple component types
- Resource registration (`registerResource()`)
- Event registration with priorities
- Codec registry for polymorphic types

### ConnectedBlocksModule
**File:** [ConnectedBlocksModule.java](decompiled/com/hypixel/hytale/server/core/universe/world/connectedblocks/ConnectedBlocksModule.java)

Demonstrates:
- Asset registration with event handling
- Codec registration for custom types
- Event-based asset updates

## Usage Patterns

### Basic Plugin Structure

```java
public class MyPlugin extends JavaPlugin {
    public MyPlugin(@Nonnull final JavaPluginInit init) {
        super(init);
    }
    
    @Override
    protected void setup() {
        // Register commands, events, assets, etc.
    }
    
    @Override
    protected void start() {
        // Initialize runtime state
    }
    
    @Override
    protected void shutdown() {
        // Cleanup
    }
}
```

### Registering Commands

```java
this.getCommandRegistry().registerCommand(new MyCommand());
```

### Registering Events

```java
// Global event
this.getEventRegistry().registerGlobal(
    EventPriority.EARLY, 
    PlayerJoinEvent.class, 
    this::onPlayerJoin
);

// Keyed event
this.getEventRegistry().register(
    ChunkLoadEvent.class,
    chunkId,
    this::onChunkLoad
);
```

### Registering Assets

```java
this.getAssetRegistry().register(
    HytaleAssetStore.builder(MyAsset.class, new DefaultAssetMap())
        .setPath()
        .setCodec(MyAsset.CODEC)
        .setKeyFunction(MyAsset::getId)
        .loadsAfter(Item.class)
        .build()
);
```

### Registering Components

```java
// Entity component
ComponentType<EntityStore, MyEntityComponent> entityComponent = 
    this.getEntityStoreRegistry().registerComponent(
        MyEntityComponent.class,
        "MyEntityComponent",
        MyEntityComponent.CODEC
    );

// Chunk component
ComponentType<ChunkStore, MyChunkComponent> chunkComponent = 
    this.getChunkStoreRegistry().registerComponent(
        MyChunkComponent.class,
        "MyChunkComponent",
        MyChunkComponent.CODEC
    );
```

### Registering Systems

```java
// Entity system
this.getEntityStoreRegistry().registerSystem(new MyEntitySystem());

// Chunk system
this.getChunkStoreRegistry().registerSystem(new MyChunkSystem());
```

### Registering Codecs

```java
// For polymorphic type registration
this.getCodecRegistry(MyBaseCodec.CODEC)
    .register("MyType", MyClass.class, MyClass.CODEC)
    .register("AnotherType", AnotherClass.class, AnotherClass.CODEC);
```

### Registering Entities

```java
// Via EntityModule (typically accessed through a module)
EntityModule.get().registerEntity(
    "myentity",
    MyEntity.class,
    world -> new MyEntity(world),
    MyEntity.CODEC
);
```

## Plugin Loading

Plugins are loaded from:
- `mods/` directory (default)
- Additional directories specified via command-line options
- Built-in plugins from `builtin/` directory
- Plugins in classpath

The [PluginManager.java](decompiled/com/hypixel/hytale/server/core/plugin/PluginManager.java) handles:
- Dependency resolution
- Load order determination
- Plugin state management
- Classloader isolation

## Notes

- Plugins have isolated classloaders (see `PluginClassLoader`)
- Plugins can be enabled/disabled via server config
- Plugin state is tracked: NONE → SETUP → START → ENABLED → SHUTDOWN → DISABLED
- All registrations are automatically cleaned up on plugin shutdown
- Plugins can include asset packs embedded in their JAR files
