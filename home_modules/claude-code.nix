{
  pkgs,
  ...
}:
let
  version = "2.1.63";

  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";

  platforms = {
    "aarch64-darwin" = {
      slug = "darwin-arm64";
      hash = "sha256:2e8667322e0bd104087df2a8857f176acc75d7091aa02828825dfeb4a5708531";
    };
    "x86_64-linux" = {
      slug = "linux-x64";
      hash = "sha256:734447e461bb92f0ffd5f683bb6216c35a3c16e8dd84be8d150b43605d39b0d1";
    };
  };

  platform = platforms.${pkgs.stdenv.hostPlatform.system};
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.stdenv.mkDerivation {
      pname = "claude-code";
      inherit version;
      src = pkgs.fetchurl {
        url = "${baseUrl}/${version}/${platform.slug}/claude";
        hash = platform.hash;
      };
      dontUnpack = true;
      dontFixup = true;
      installPhase = ''
        mkdir -p $out/bin
        install -m755 $src $out/bin/claude
      '';
    };
    mcpServers = {
      figma-desktop = {
        type = "http";
        url = "http://127.0.0.1:3845/mcp";
      };
      effect-docs = {
        command = "npx";
        args = [
          "-y"
          "effect-mcp@latest"
        ];
        env = { };
        type = "stdio";
      };
      docs-dedalus = {
        type = "http";
        url = "https://docs.dedaluslabs.ai/mcp";
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
      - Unless stated otherwisem, Typescript is only used in the React frontend. Furthermore, we heavily make use of two libraries to write it:
        the BaseUI Headless Component Library and Effect-TS. Use the Claude skill for fetching llms.txt when working with these libraries.
        For Effect-TS, there is an MCP server to fetch documentation.
      - If Typescript was to be used for the Bun backend, we will use Elysia.js and Effect-TS. Use the Claude skill for fetching llms.txt when
        working with these libraries. For Effect-TS, there is an MCP server to fetch documentation.

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
      - The way components are designed in the Figma file is such that there is a one-to-one correspondence.
      between a Figma frame and a BaseUI component tag. The Figma frames are named accordingly for your clarity.
      - Icons used in the Figma file are either from HeroIcons or from Radix Icons. I want you to map icons used in Figma
      to their respective icons in the HeroIcons React libraries or their RadixIcons React libraries. Use the Claude skill for
      fetching icon documentation when working with these libraries.
      - Try to reuse existing components whenever possible. I will try to call out when I want you to reuse components, but
      when I don't, try to exercise your own initiative. For example, if you see that the Figma file has designs for a Progress
      component and we already have one, try to see if it can be reused.
      - Try not to nest text inside a <p> when working with text inside a component, unless you need proper textual hierarchy within
      a component. For example,
        - Wrapping <button> text with a <p> is unnecessary. It's better to do it without <p> tags and put the
        TailwindCSS semantic classes inside the parent component.
        - For a <div> card with header and description text, tags to establish a textual hierarchy, like <h1> for the heeader, and <p>
        for the description text is fine.

      If the Figma file is not provided, clarify if it is a backend-only feature.
    '';
    skills = {
      fetch_llms_txt = ''
        ---
        name: fetch_llms_txt
        description: Fetch llms.txt documentation when CLAUDE.md instructions or user requires to work with specific libraries.
        ---

        When the user or CLAUDE.md instructions require you to work with an external library (like BaseUI, Effect-TS, Elysia-JS), automatically:

        1. Identify the official website for the mentioned library
        2. Use WebFetch to retrieve the llms.txt file from `https://[framework-site]/llms.txt`
        3. If llms.txt exists, summarize what documentation is available
        4. Ask if they want you to fetch specific documentation URLs from the llms.txt

        Examples:
        - CLAUDE.md instructions specify "we heavily make use of Base-UI and Effect-TS in the frontend" -> fetch https://base-ui.com/llms.txt and 
          fetch https://effect.website/llms.txt
        - CLAUDE.md instructions specify "we heavily make use of Effect-TS and Elysia-JS in the backend" -> fetch https://effect.website/llms.txt and
          fetch https://elysiajs.com/llms.txt

        If llms.txt doesn't exist or the framework website is unclear, inform the user and offer to search for documentation instead.
      '';
      fetch_icons_docs = ''
        ---
        name: fetch_icons_docks
        description: Fetch HeroIcons or RadixIcons documentation.
        ---

        When the user or CLAUDE.md instructions require you to work with an external React icon library (like HeroIcons, RadixIcons), automatically:

        1. Identify the official website for the icon library
        2. Use WebFetch to retrieve the documentations

        Examples:

        During a Figma design conversion to code via Figma MCP, an icon from an icon design file was used ->
        1. Identify the name of the icon, and the library it comes from
        2. Fetch the website of the library
        3. Search for the icon name, and the corresponding React component of the icon to use.
      '';
      typescript_style = ''
        ---
        name: typescript-style
        description: This skill should be used when writing TypeScript code, reviewing TypeScript code, or discussing TypeScript patterns. Enforces opinionated TypeScript conventions for module structure, type definitions, error handling, and code style.
        version: 0.1.0
        ---

        # TypeScript Style Guide

        ## Module System

        - Always use ES module syntax (`import`/`export`).
        - Use barrel exports (`index.ts`) for project subfolders (e.g., `components`, `pages`, `effects`).
        - Import from project subfolders without relative paths: `import ... from 'file'`, not `import ... from './file'`.
        - In `tsconfig.json`, `compilerOptions.paths` must always be `{ "*": ["./app/*"] }`.

        ## Type Definitions

        - Define arrays as `Array<type>`, never `type[]`.
        - Never use type assertions (`... as type`).
        - Function return types must explicitly document all possible outcomes, including errors.

        ## Error Handling

        Errors are values, not exceptions. Return errors as union types rather than throwing.

        ### Core Rules

        1. **If a function can fail, use the `Result` type.** Define it as a plain union alias:
           ```typescript
           type Result<T, E extends Error> = T | E

           function getUser(id: string): Promise<Result<User, NotFoundError | NetworkError>>
           ```

        2. **Narrow with `instanceof`.** Use `instanceof Error` checks to narrow types before accessing success values:
           ```typescript
           const user = await getUser(id)
           if (user instanceof NotFoundError) return
           if (user instanceof NetworkError) return
           console.log(user.username) // TypeScript knows user is User
           ```

        3. **Keep control flow linear.** Structure error checks as early returns, not nested try-catch blocks:
           ```typescript
           const config = parseConfig(input)
           if (config instanceof Error) return config
           const db = connectDB(config.dbUrl)
           if (db instanceof Error) return db
           ```

        4. **Define custom error classes** by extending `Error`:
           ```typescript
           class NotFoundError extends Error {
             constructor(public id: string) {
               super(`User ''${id} not found`)
             }
           }
           ```

        5. **Wrap throwing library code** to convert exceptions into returnable errors:
           ```typescript
           function trySync<T>(fn: () => T): Error | T {
             try { return fn() } catch (e) { return e instanceof Error ? e : new Error(String(e)) }
           }

           function parseConfig(input: string): ParseError | Config {
             const result = trySync(() => JSON.parse(input))
             if (result instanceof Error) return new ParseError({ reason: result.message })
             return result
           }
           ```

        6. **Use ts-pattern for exhaustive pattern matching** when handling multiple error variants or any discriminated type:
           ```typescript
           import { match } from 'ts-pattern'

           const message = match(error)
             .with(P.instanceOf(NotFoundError), e => `User ''${e.id} not found`)
             .with(P.instanceOf(NetworkError), e => `Failed to reach ''${e.url}`)
             .otherwise(e => `Unexpected: ''${e.message}`)
           ```
           ts-pattern works on any type — errors, strings, objects, discriminated unions — not just errors.

        7. **Use `await using` for resource cleanup** with `AsyncDisposableStack` (TypeScript 5.2+) for Go-like defer semantics:
           ```typescript
           async function processOrder(orderId: string) {
             await using cleanup = new AsyncDisposableStack()
             const db = await connectDb()
             cleanup.defer(() => db.close())
             // db automatically closes when scope exits
           }
           ```

        ### Handling Multiple Error Types

        When consuming a function that returns multiple error types, choose the simplest construct that fits:

        - **Sequential `instanceof` early returns** for straightforward cases with 2-3 error types.
        - **`switch` on a discriminant** (e.g., `error.name` or a tag field) when all branches are type-restricted and you want exhaustiveness.
        - **`match` from ts-pattern** when the logic per branch is complex or expression-based.

        Prefer the lightest tool that keeps the code readable. Don't reach for `matchError` when a simple `if`/early-return suffices, and don't chain five `instanceof` checks when a `switch` or `match` would be clearer.

        ### What NOT to Do

        - Do not use `try`/`catch` for expected error paths. Reserve `try`/`catch` only for truly unexpected exceptions at top-level boundaries.
        - `Result` is a plain union alias, not a wrapper class. Do not use libraries like `neverthrow` or `fp-ts` that provide `Result` as a container object with `.map()`, `.flatMap()`, `.unwrap()` methods.
        - Do not throw errors for control flow. Return them.

        ## Async Patterns

        - **Prefer `.then()` chains over `async`/`await`.** Promise chains read as data transformations and compose naturally with combinators. Use `.then()` as the default.
        - **Use `.then()` where `await` isn't available**, such as inside `.map()` or other combinator callbacks.
        - **Parallelise independent calls.** If two async operations don't depend on each other, use `Promise.all` rather than sequential `await`. Only sequence calls when one depends on the result of another.

        ### When Throwing is Acceptable

        - **Inside contained boundaries** like `Promise.allSettled` callbacks, throwing is fine — the settlement boundary catches the error, so it never escapes untyped. Prefer this over verbose `instanceof` chains inside short lambdas.
        - **Custom error classes are for programmatic handling.** When errors are only being reported as data (e.g., collected into a `failed` array for display), a plain `{ url: string, error: string }` is sufficient. Don't create a custom error class just to carry a message.

        ## Validation

        - Use **Zod** for schema validation. Define the schema once and derive the TypeScript type from it with `z.infer<typeof Schema>` — never duplicate a type and its validation logic separately.
        - Use `safeParse` over `parse` — it returns a discriminated union (success/failure) rather than throwing, which aligns with the error-as-values pattern.
        - Let Zod collect all validation errors, not just the first.

        ## Functions and Abstraction

        - **Functions solve DRY, not decomposition.** Only extract logic into a function when it is reused in multiple places. One-off logic should stay inline where it is read.
        - **Avoid premature extraction.** Breaking single-use logic into small helper functions fragments the reading flow and makes code harder to follow. Inline code is easier to read top-to-bottom.
        - **Prefer named interfaces over inline object types.** Even when a type is used once, a named interface is clearer. Define the interface, then reference it in the return type.

        ## Function Signatures

        - **Accept wide, return narrow.** Functions should accept a broad range of input types (via generics, unions, or base types) but return specific, concrete types.
        - **Use generics over `any`.** Never use `any` — use generics to preserve type information through the call.

        ## Iteration

        - Prefer functional combinators (`.map()`, `.filter()`, `.reduce()`, `.flatMap()`, etc.) over imperative `for` loops, `forEach`, and manual index tracking.
        - Chain combinators for multi-step transformations rather than accumulating into mutable variables.
      '';
    };
  };
}
