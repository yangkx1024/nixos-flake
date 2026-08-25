{pkgs, ...}: let
  # The nixpkgs herdr package generates the skill at build time via
  # `herdr --skill`, so it always matches the installed binary's CLI surface.
  # https://herdr.dev/docs/agent-skill
  skill = "${pkgs.herdr}/share/herdr/skills/herdr/SKILL.md";
in {
  home.file = {
    ".claude/skills/herdr/SKILL.md".source = skill;
    ".codex/skills/herdr/SKILL.md".source = skill;
  };
}
