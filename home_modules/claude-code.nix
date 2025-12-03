{
  pkgs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    mcpServers = {
      figma-desktop = {
        type = "http";
        url = "http://127.0.0.1:3845/mcp";
      };
    };
    memory.text = ''
      # Typescript Rules
      - In tsconfig.json, under compilerOptions, the paths key must always be the value { "*": [ "./app/*" ] }.
      - Always use ES modules syntax (import .../export ...).
      - Use barrel exports for project subfolders. Some examples of project subfolders are "components", "locales",
      "pages", "effects". Furthermore, when importing from project subfolders, specify it as "import ... from 'file',
      not "import ... from './file'".
      - All arrays should be defined as Array<type>, not type[].
      - Do not use type assertions (... as type).
      - Typescript is only used in the React frontend. Furthermore, we heavily make use of two libraries to write it:
      - the BaseUI Headless Component Library and Effect-TS.

      # Base UI

      This is the documentation for the `@base-ui-components/react` package.
      It contains a collection of components and utilities for building user interfaces in React.
      The library is designed to be composable and styling agnostic.

      ## Overview

      - [Quick start](https://base-ui.com/react/overview/quick-start.md): A quick guide to getting started with Base UI.
      - [Accessibility](https://base-ui.com/react/overview/accessibility.md): Learn how to make the most of Base UI's accessibility features and guidelines.
      - [Releases](https://base-ui.com/react/overview/releases.md): Changelogs for each Base UI release.
      - [About Base UI](https://base-ui.com/react/overview/about.md): An overview of Base UI, providing information on its history, team, and goals.

      ## Handbook

      - [Styling](https://base-ui.com/react/handbook/styling.md): Learn how to style Base UI components with your preferred styling engine.
      - [Animation](https://base-ui.com/react/handbook/animation.md): A guide to animating Base UI components.
      - [Composition](https://base-ui.com/react/handbook/composition.md): A guide to composing Base UI components with your own React components.
      - [Forms](https://base-ui.com/react/handbook/forms.md): A guide to building forms with Base UI components.
      - [Customization](https://base-ui.com/react/handbook/customization.md): A guide to customizing the behavior of Base UI components.
      - [TypeScript](https://base-ui.com/react/handbook/typescript.md): A guide to using TypeScript with Base UI.

      ## Components

      - [Accordion](https://base-ui.com/react/components/accordion.md): A high-quality, unstyled React accordion component that displays a set of collapsible panels with headings.
      - [Alert Dialog](https://base-ui.com/react/components/alert-dialog.md): A high-quality, unstyled React alert dialog component that requires a user response to proceed.
      - [Autocomplete](https://base-ui.com/react/components/autocomplete.md): A high-quality, unstyled React autocomplete component that renders an input with a list of filtered options.
      - [Avatar](https://base-ui.com/react/components/avatar.md): A high-quality, unstyled React avatar component that is easy to customize.
      - [Button](https://base-ui.com/react/components/button.md): A high-quality, unstyled React button component that can be rendered as another tag or focusable when disabled.
      - [Checkbox](https://base-ui.com/react/components/checkbox.md): A high-quality, unstyled React checkbox component that is easy to customize.
      - [Checkbox Group](https://base-ui.com/react/components/checkbox-group.md): A high-quality, unstyled React checkbox group component that provides a shared state for a series of checkboxes.
      - [Collapsible](https://base-ui.com/react/components/collapsible.md): A high-quality, unstyled React collapsible component that displays a panel controlled by a button.
      - [Combobox](https://base-ui.com/react/components/combobox.md): A high-quality, unstyled React combobox component that renders an input combined with a list of predefined items to select.
      - [Context Menu](https://base-ui.com/react/components/context-menu.md): A high-quality, unstyled React context menu component that appears at the pointer on right click or long press.
      - [Dialog](https://base-ui.com/react/components/dialog.md): A high-quality, unstyled React dialog component that opens on top of the entire page.
      - [Field](https://base-ui.com/react/components/field.md): A high-quality, unstyled React field component that provides labeling and validation for form controls.
      - [Fieldset](https://base-ui.com/react/components/fieldset.md): A high-quality, unstyled React fieldset component with an easily stylable legend.
      - [Form](https://base-ui.com/react/components/form.md): A high-quality, unstyled React form component with consolidated error handling.
      - [Input](https://base-ui.com/react/components/input.md): A high-quality, unstyled React input component.
      - [Menu](https://base-ui.com/react/components/menu.md): A high-quality, unstyled React menu component that displays list of actions in a dropdown, enhanced with keyboard navigation.
      - [Menubar](https://base-ui.com/react/components/menubar.md): A menu bar providing commands and options for your application.
      - [Meter](https://base-ui.com/react/components/meter.md): A high-quality, unstyled React meter component that provides a graphical display of a numeric value.
      - [Navigation Menu](https://base-ui.com/react/components/navigation-menu.md): A high-quality, unstyled React navigation menu component that displays a collection of links and menus for website navigation.
      - [Number Field](https://base-ui.com/react/components/number-field.md): A high-quality, unstyled React number field component with increment and decrement buttons, and a scrub area.
      - [Popover](https://base-ui.com/react/components/popover.md): A high-quality, unstyled React popover component that displays an accessible popup anchored to a button.
      - [Preview Card](https://base-ui.com/react/components/preview-card.md): A high-quality, unstyled React preview card component that appears when a link is hovered, showing a preview for sighted users.
      - [Progress](https://base-ui.com/react/components/progress.md): A high-quality, unstyled React progress bar component that displays the status of a task that takes a long time.
      - [Radio](https://base-ui.com/react/components/radio.md): A high-quality, unstyled React radio button component that is easy to style.
      - [Scroll Area](https://base-ui.com/react/components/scroll-area.md): A high-quality, unstyled React scroll area that provides a native scroll container with custom scrollbars.
      - [Select](https://base-ui.com/react/components/select.md): A high-quality, unstyled React select component for choosing a predefined value in a dropdown menu.
      - [Separator](https://base-ui.com/react/components/separator.md): A high-quality, unstyled React separator component that is accessible to screen readers.
      - [Slider](https://base-ui.com/react/components/slider.md): A high-quality, unstyled React slider component that works like a range input and is easy to style.
      - [Switch](https://base-ui.com/react/components/switch.md): A high-quality, unstyled React switch component that indicates whether a setting is on or off.
      - [Tabs](https://base-ui.com/react/components/tabs.md): A high-quality, unstyled React tabs component for toggling between related panels on the same page.
      - [Toast](https://base-ui.com/react/components/toast.md): A high-quality, unstyled React toast component to generate notifications.
      - [Toggle](https://base-ui.com/react/components/toggle.md): A high-quality, unstyled React toggle component that displays a two-state button that can be on or off.
      - [Toggle Group](https://base-ui.com/react/components/toggle-group.md): A high-quality, unstyled React toggle group component that provides shared state to a series of toggle buttons.
      - [Toolbar](https://base-ui.com/react/components/toolbar.md): A high-quality, unstyled React toolbar component that groups a set of buttons and controls.
      - [Tooltip](https://base-ui.com/react/components/tooltip.md): A high-quality, unstyled React tooltip component that appears when an element is hovered or focused, showing a hint for sighted users.

      ## Utilities

      - [Direction Provider](https://base-ui.com/react/utils/direction-provider.md): A direction provider component that enables RTL behavior for Base UI components.
      - [useRender](https://base-ui.com/react/utils/use-render.md): Hook for enabling a render prop in custom components.

      # Effect-TS

      This is the documentation for the `effect` package.
      It contains a collection of TypeScript APIs for building reliable, scalable, and maintainable applications
      using functional programming concepts.
      The library provides structured handling of side effects, errors, concurrency, and dependency injection.

      ## Overview

      - [Quick start](https://effect-ts.com/overview/quick-start): Get started with Effect-TS in minutes.
      - [Core Concepts](https://effect-ts.com/overview/core-concepts): Understand functional programming fundamentals with Effect.
      - [Why Effect?](https://effect-ts.com/overview/why-effect): Learn the philosophy behind Effect.
      - [Releases](https://effect-ts.com/overview/releases): Changelogs for each release.

      ## Handbook

      - [Error Handling](https://effect-ts.com/handbook/error-handling): Comprehensive guide to managing errors.
      - [Dependency Injection](https://effect-ts.com/handbook/dependency-injection): Master Context, Service, and Layer patterns.
      - [Concurrency](https://effect-ts.com/handbook/concurrency): Build responsive apps with Fiber-based concurrency.
      - [Streaming](https://effect-ts.com/handbook/streaming): Work with asynchronous data streams.
      - [Testing](https://effect-ts.com/handbook/testing): Write effective tests for Effect code.
      - [TypeScript Best Practices](https://effect-ts.com/handbook/typescript): Leverage TypeScript's type system.

      ## Core APIs

      - [Effect](https://effect-ts.com/api/effect): The core data type for describing effectful computations.
      - [Either](https://effect-ts.com/api/either): Represent values with two possible types, typically success or failure.
      - [Option](https://effect-ts.com/api/option): Safely handle optional values and avoid null errors.
      - [Schema](https://effect-ts.com/api/schema): Runtime validation and encoding/decoding with automatic Typescript type derivation.
      - [Exit](https://effect-ts.com/api/exit): Represent the completed result of an Effect execution.
      - [Cause](https://effect-ts.com/api/cause): Inspect and manipulate chains of errors.

      ## Advanced APIs

      - [Match](https://effect-ts.com/api/match): Type-safe pattern matching for TypeScript values.
      - [Context](https://effect-ts.com/api/context): Dependency injection container for services.
      - [Service](https://effect-ts.com/api/service): Define interfaces for dependencies.
      - [Layer](https://effect-ts.com/api/layer): Compose and manage services with lifecycle control.
      - [Fiber](https://effect-ts.com/api/fiber): Lightweight concurrency primitive for running effects.
      - [FiberRef](https://effect-ts.com/api/fiberref): Fiber-local values that propagate across async boundaries.
      - [Ref](https://effect-ts.com/api/ref): Synchronized mutable references for shared state.
      - [Deferred](https://effect-ts.com/api/deferred): Manual promise-like completion signaling.
      - [Queue](https://effect-ts.com/api/queue): Asynchronous message passing between fibers.
      - [PubSub](https://effect-ts.com/api/pubsub): Publish-subscribe messaging system.
      - [Semaphore](https://effect-ts.com/api/semaphore): Concurrency control and rate limiting.
      - [Stream](https://effect-ts.com/api/stream): Reactive streams for asynchronous data flow.
      - [Sink](https://effect-ts.com/api/sink): Stream consumers for collecting results.
      - [Channel](https://effect-ts.com/api/channel): Transform and compose streams with backpressure.
      - [Schedule](https://effect-ts.com/api/schedule): Declarative retry policies and repetition.

      ## Utilities

      - [Console](https://effect-ts.com/api/console): Logging and standard output utilities.
      - [Clock](https://effect-ts.com/api/clock): Time-based operations and scheduling.
      - [Random](https://effect-ts.com/api/random): Random value generation.
      - [Config](https://effect-ts.com/api/config): Type-safe configuration management.
      - [Metric](https://effect-ts.com/api/metric): Application metrics collection.
      - [Tracer](https://effect-ts.com/api/tracer): Distributed tracing and debugging.

      # Rust Rules
      I am new to Rust and am trying to learn it. When I ask any Rust-related questions, do not give me the answer outright.
      Instead, guide me in the correct direction. Some examples of this:
      - "How do I fix this bug": Do not generate the entire correct code. Instead, tell me what is wrong, and how I can fix it.
      - "I want this function to do this and that": Do not generate the entire correct code. Instead, tell me the correct APIs,
      and the documentation related to it.

      Be concise in your replies.

      # Workflow Rules
      Feature implementation is split into two separate parts: frontend and backend.

      ## Backend
      - If the feature requested requires a backend, two things must be provided: an acceptance criteria,
      and a list of base and edge cases to test against.
      - All code written must be unit tested, and must pass all cases.
      - All code written for the feature must have at least 80% test coverage.
      - If an acceptance criteria or list of base and edge cases are missing, please remind me to provide one.

      ## Frontend
      - If the feature requested requires a frontend, a Figma file must be provided.
      You can access the Figma file via the Figma MCP.
      - The way components are designed in the Figma file is such that there is a one-to-one correspondence
      between a Figma frame and a BaseUI component tag. The Figma frames are named accordingly for your clarity.

      If the Figma file is not provided, clarify if it is a backend-only feature.
    '';
  };
}
