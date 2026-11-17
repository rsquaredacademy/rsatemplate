# rsatemplate 0.1.1

* `fix_site()` writes a managed block of Netlify `_redirects` rules that return
  404 for agent-instruction and repository files (AGENTS, GEMINI, CLAUDE,
  README, CONTRIBUTING, package.json, build scripts), and also removes rendered
  GEMINI and CLAUDE pages. Rules outside the block are preserved.

# rsatemplate 0.1.0

* First version.
