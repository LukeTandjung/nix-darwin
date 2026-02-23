{
  pkgs,
  ...
}:
let
  version = "2.1.50";

  denoTargets = {
    "aarch64-darwin" = "aarch64-apple-darwin";
    "x86_64-linux" = "x86_64-unknown-linux-gnu";
  };

  hashes = {
    "aarch64-darwin" = "sha256-ivshwgonybQq+nPP0x4kfpM4GKG9wEsg3Us3UBu2Hjw=";
    "x86_64-linux" = "sha256-gT6CLl+BPyJZPs0daQippMEDV/gSaXEVqAzzQ0m9awo=";
  };
in
{
  programs.claude-code = {
    enable = true;
    package = pkgs.stdenv.mkDerivation {
      pname = "claude-code-compiled";
      inherit version;
      dontUnpack = true;
      dontPatchELF = true;
      dontStrip = true;
      nativeBuildInputs = [
        pkgs.deno
        pkgs.cacert
      ];
      outputHashAlgo = "sha256";
      outputHashMode = "recursive";
      outputHash = hashes.${pkgs.stdenv.hostPlatform.system};
      buildPhase = ''
        export DENO_DIR=$TMPDIR/deno
        export HOME=$TMPDIR
        export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        deno compile --allow-all \
          --target ${denoTargets.${pkgs.stdenv.hostPlatform.system}} \
          --output claude \
          "npm:@anthropic-ai/claude-code@${version}"
      '';
      installPhase = ''
        mkdir -p $out/bin
        install -m755 claude $out/bin/claude
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
    };
  };
}
