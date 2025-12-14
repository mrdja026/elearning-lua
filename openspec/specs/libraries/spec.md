# libraries Specification

## Purpose
TBD - created by archiving change add-slab-docs. Update Purpose after archive.
## Requirements
### Requirement: Slab GUI Library

The system SHALL include the Slab immediate mode GUI library for building editor interfaces.

#### Scenario: Slab availability
- **WHEN** a developer needs a full-featured GUI toolkit
- **THEN** Slab SHALL be available at `libraries/Slab`

#### Scenario: Slab initialization
- **WHEN** using Slab in a LÖVE2D project
- **THEN** the developer SHALL initialize with `Slab.Initialize(args)` in `love.load`

#### Scenario: Slab update loop
- **WHEN** the application update runs
- **THEN** `Slab.Update(dt)` SHALL be called before any Slab UI code

#### Scenario: Slab draw
- **WHEN** the application draw runs
- **THEN** `Slab.Draw()` SHALL be called after all other drawing

#### Scenario: Slab basic usage
- **WHEN** creating a window with Slab
- **THEN** the pattern SHALL be `Slab.BeginWindow()`, UI calls, `Slab.EndWindow()`

### Requirement: JSON Library

The system SHALL include a JSON parsing library for loading and saving story data.

#### Scenario: JSON availability
- **WHEN** a developer needs JSON parsing
- **THEN** json SHALL be available at `libraries/json.lua`

#### Scenario: JSON encoding
- **WHEN** converting Lua tables to JSON
- **THEN** `json.encode(table)` SHALL return a JSON string

#### Scenario: JSON decoding
- **WHEN** parsing JSON strings
- **THEN** `json.decode(string)` SHALL return a Lua table

### Requirement: Library Selection Guide

The system SHALL provide guidance on which GUI library to use.

#### Scenario: Choose Slab
- **WHEN** needing file dialogs, color pickers, tree views, or complex layouts
- **THEN** Slab SHALL be the recommended choice

#### Scenario: Current implementation
- **WHEN** reviewing the Creator Studio implementation
- **THEN** it SHALL use Slab for its full-featured GUI capabilities

