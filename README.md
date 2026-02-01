# Hytale Server Decompiled Code Documentation

## 📦 Server Version

**HytaleServer.jar SHA256:** `bac376d8b6ff608443d76925f855825749f020bd3f74b7bbf6c8bde6a8fbc45e`

This documentation is based on the decompiled source code from the server jar file with the checksum above. All architectural analysis, API documentation, and code examples reflect this specific version of the Hytale server.

## 🚀 Setup

To decompile the Hytale server code:

1. **Place the JAR file**: Copy `HytaleServer.jar` to the root directory of this project
2. **Run the decompile script**: Execute `./decompile.sh` from the project root

The script will decompile the JAR file and place the output in the `decompiled/` directory.

**Note**: Make sure you have `procyon-decompiler` installed. On Arch Linux, you can install it with:
```bash
pacman -S procyon-decompiler
```

## ⚖️ Legal Status

**Decompiling the Hytale server is legal and officially recommended** by Hypixel Studios. According to their [Modding Strategy and Status](https://hytale.com/news/2025/11/hytale-modding-strategy-and-status) announcement (November 2025), the server code is intentionally **not obfuscated**, allowing modders to decompile and inspect how systems work under the hood. This decompiled code can be used to understand the implementation, guide plugin development, and contribute improvements once the official shared-source server is released.

---

This repository contains documentation and analysis of the decompiled Hytale server source code.

## 📚 Documentation

### [Architecture Documentation](docs/ARCHITECTURE.md)
Comprehensive overview of the Hytale server architecture, including:
- Core architecture patterns
- Plugin system
- Module system
- Registry pattern
- Event-driven architecture
- Network architecture
- Serialization system
- Resource management
- Spatial data structures
- Command system
- Dependency management
- Performance optimizations

### [Entity Component System (ECS)](docs/ECS.md)
In-depth explanation of the ECS architecture:
- Core concepts (Components, Entities, Systems)
- Archetypes and ArchetypeChunk
- Store management
- Query system
- System execution
- Command buffers
- Performance optimizations
- Real code examples

### [Plugin API Documentation](docs/PLUGINS.md)
Complete guide to the plugin/modding API:
- Plugin structure and lifecycle
- Available registries and APIs
- Command system
- Event system
- Entity system
- Asset system
- Codec system
- Usage patterns and examples

## 🎮 Official Modding Strategy and Status

> **Source**: [Hytale Modding Strategy and Status](https://hytale.com/news/2025/11/hytale-modding-strategy-and-status) (November 2025)

### Guiding Principles

Hytale is being built **with modding at its core**. The developers aim for everything in the game—blocks, items, NPCs, world generation, behaviors, and more—to be data- or code-driven and modifiable.

Key design tenets:
- **Server-side first**: All modding is handled by the server (which includes single-player, treated as a local server). Players shouldn't need to juggle different client mods just to play on modded servers.
- **One community, one client**: Client mods aren't planned; the client is meant to stay stable, consistent, and secure. Modding variation comes via server-side plugins, asset packs, etc.
- **Long-term modding**: This isn't a feature added on—it's a foundational layer. Support, tools, and evolution are serious commitments.
- **Safe, secure modding**: Enabling creativity while managing the risks associated with untrusted content.

### Current State of Modding (as of Nov 2025)

Modding tools and systems are usable but have rough edges, gaps, and inconsistencies. Modding is categorized into four main types:

1. **Server Plugins** – Java (.jar) plugins, giving deep control over gameplay and server logic.
2. **Data Assets** – JSON files for content like blocks, items, world generation, NPC behavior.
3. **Art Assets** – Models, textures, sounds, animations; supported modeling in Blockbench.
4. **Save Files / Prefabs** – Worlds themselves, plus reusable builds and prefabricated structures.

### Visual vs. Text-Based Scripting

- **No plans for text-based scripting (e.g., Lua)**: The team sees it as problematic due to complexity, fragmentation, and the risk that designers still end up worrying about low-level programming.
- **Visual scripting** is the chosen alternative: Similar to Unreal Engine's Blueprints—designers can create behaviors visually; programmers can build new nodes or support performance-critical code. The goal is to expose behavior in a way that's both expressive and performant.

### Available Tooling

These modding tools are available now, though some feel "beta":

- **Hytale Asset Editor**: For data assets like blocks, items; doesn't yet cover everything.
- **Blockbench plugin**: For modeling, texture work, animations.
- **Asset Graph Editor**: Used internally, handles world generation, brush tools for creative mode, NPCs, etc. Not polished yet.
- **Machinima tools**: Used for cinematic trailers. They work but need more refinement.
- **Creative Tools**: Suite for building/editing worlds, placing prefabs, using brushes. Early-stage but available.

### Short-Term Improvement Priorities

- **Shared server source code**: Releasing in 1–2 months where legally possible. To clarify how things work under the hood and allow you to contribute or better understand systems.
- **Better distribution flow**: Sharing mods, asset packs, worlds. Right now, packaging, dependency management, and versioning are rough. They want to streamline that.
- **UI framework consolidation**: Three UI systems are currently in use; they plan to standardize on NoesisGUI.
- **Stability**: Critical work on crash fixes, data-loss issues, and savefile integrity. Emphasis on backups, preparing for rough spots.

### Long-Term Vision

- Empowering modders to do almost everything: content creation, server logic, adventure "mini-game"-type systems, custom worlds, etc. Modding tools aren't just functional—they should be powerful and deep.
- Transparent iteration: expose systems, open up sourcecode when possible, communicate with the community.
- Balancing flexibility with safety: making decisions that allow modders to push boundaries without exposing players to serious security risks.

### What to Expect as a Modder Right Now

- You'll run into missing features and limitations (world-gen, UI, etc.). But you can start building content.
- Visual scripting and asset/data work are your best moves early on. Use supported tools like Blockbench.
- Be ready to give feedback. The team is explicitly asking for input on what blocks creators, what tools are frustrating, etc.
- Backups are critical—data loss is still a possible issue. Treat your early builds like experiments.

## 🏗️ Project Structure

```
.
├── docs/                   # Documentation files
│   ├── ARCHITECTURE.md     # Architecture overview
│   ├── ECS.md              # ECS detailed explanation
│   └── PLUGINS.md          # Plugin API documentation
├── decompiled/             # Decompiled Java source code
│   └── com/hypixel/hytale/ # Main package structure
└── README.md               # This file
```

## 🔍 Key Discoveries

### Architecture Highlights

- **ECS Architecture**: Data-oriented Entity Component System for efficient entity management
- **Plugin System**: Modular plugin architecture with isolated classloaders
- **Custom Protocol**: Binary protocol optimized for game networking (not protobuf)
- **Performance**: Archetype-based storage, parallel processing, spatial optimizations
- **Type Safety**: Extensive use of Java generics throughout

### Technology Stack

- **Language**: Java
- **Networking**: Netty (TCP/QUIC support)
- **Serialization**: Custom codec system
- **Error Tracking**: Sentry integration
- **Compression**: Zstd

## 📖 Quick Start

1. **Understanding the Architecture**: Start with [ARCHITECTURE.md](docs/ARCHITECTURE.md)
2. **Learning ECS**: Read [ECS.md](docs/ECS.md) for detailed ECS explanation
3. **Creating Plugins**: See [PLUGINS.md](docs/PLUGINS.md) for plugin development guide

## 🔗 Related Files

- Decompiled source code: `decompiled/com/hypixel/hytale/`
- Core ECS implementation: `decompiled/com/hypixel/hytale/component/`
- Plugin system: `decompiled/com/hypixel/hytale/server/core/plugin/`
- Network layer: `decompiled/com/hypixel/hytale/server/core/io/`

## 📝 Notes

- This documentation is based on decompiled source code
- Code may be obfuscated or incomplete in some areas
- Documentation reflects the discovered architecture and APIs
- For official Hytale documentation, refer to official sources

## 🤝 Contributing

If you discover additional architectural patterns or APIs, please update the relevant documentation files.

---

**Disclaimer**: This documentation is for educational and research purposes only. The decompiled code is provided as-is for analysis of the Hytale server architecture.
