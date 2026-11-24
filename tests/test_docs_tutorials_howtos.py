"""Automated tests validating mongodb-training scripts, Compose configs, datasets, and docs."""

from __future__ import annotations

import configparser
import json
import os
import pathlib
import re
import shutil
import subprocess
import unittest
from urllib.parse import unquote

try:
    import yaml
except ImportError:  # pragma: no cover - optional only on stripped runtimes
    yaml = None

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS_EN_DIR = REPO_ROOT / "docs"
DOCS_FR_DIR = REPO_ROOT / "docs" / "fr"
LEGACY_DOCS_DIR = REPO_ROOT / "documentation"

EN_QUADRANTS = ("01-tutorials", "02-how-to-guides", "03-reference", "04-explanation")
FR_QUADRANTS = ("01-tutoriels", "02-guides-pratiques", "03-reference", "04-explications")

INTACT_SHELL_SCRIPTS = (
    "datasets/import.sh",
    "docker/sharded/init-scripts/init-cluster.sh",
    "docker/sharded/init-scripts/init-datadir.sh",
    "docker/sharded/init-scripts/init-keyfile.sh",
    "scripts/backups_pitr/mongo_backup.sh",
    "scripts/backups_pitr/mongo_restore.sh",
    "scripts/create_admin_user.sh",
    "scripts/create_aliases.sh",
    "scripts/create_arbitrer.sh",
    "scripts/create_db_users.sh",
    "scripts/create_instance.sh",
    "scripts/inject_sample_databses.sh",
    "scripts/install_mongodb_8.0.sh",
    "scripts/logical_backup.sh",
    "scripts/logical_restore.sh",
    "scripts/pitr_backup.sh",
    "scripts/rm_mongodb_instance.sh",
)

INTACT_YAML_FILES = (
    "docker/standalone/compose.yaml",
    "docker/sharded/docker-compose.yml",
    "docker/sharded/data/config/mongod.conf",
    "playbooks/add_swapfile.yaml",
    "playbooks/install_docker.yaml",
    "playbooks/install_mongod.yaml",
    "playbooks/run_script.yaml",
)

FENCE_RE = re.compile(r"^\s*(`{3,}|~{3,})")
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\n]+)\)")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
ASCII_BOX_RE = re.compile(r"[┌┐└┘├┤┬┴┼═║╔╗╚╝]|^\s*\+[-+]+\+\s*$", re.M)
MERMAID_TYPES = (
    "graph ",
    "flowchart ",
    "sequenceDiagram",
    "classDiagram",
    "stateDiagram",
    "erDiagram",
    "gantt",
    "pie",
    "gitGraph",
)


def _posix_bash() -> str | None:
    """Return a native POSIX bash path on Unix systems, avoiding Windows WSL wrapper noise."""
    if os.name != "posix":
        return None
    return shutil.which("bash")


def _iter_repo_markdown() -> list[pathlib.Path]:
    """Return every Markdown file tracked or created inside the repository."""
    return sorted(REPO_ROOT.rglob("*.md"))


def _github_anchor_slug(heading_text: str) -> str:
    """Compute a GitHub-style heading slug keeping Unicode letters and hyphens."""
    cleaned = re.sub(r"`([^`]+)`", r"\1", heading_text.strip().lower())
    out: list[str] = []
    for ch in cleaned:
        if ch.isalnum() or ch == "_":
            out.append(ch)
        elif ch in (" ", "-"):
            out.append("-")
    return "".join(out)


def _split_fenced_blocks(text: str) -> tuple[list[tuple[int, str]], list[tuple[int, str, str]], bool]:
    """Return non-code lines, fenced blocks (start_line, lang, content), and unclosed status."""
    non_code: list[tuple[int, str]] = []
    blocks: list[tuple[int, str, str]] = []
    in_fence = False
    fence_char = ""
    fence_len = 0
    fence_lang = ""
    fence_start = 0
    buf: list[str] = []

    for lineno, line in enumerate(text.splitlines(), 1):
        stripped = line.lstrip()
        m = FENCE_RE.match(line)
        if not in_fence:
            if m:
                marker = m.group(1)
                in_fence = True
                fence_char = marker[0]
                fence_len = len(marker)
                fence_lang = stripped[fence_len:].strip().split()[0].lower() if stripped[fence_len:].strip() else ""
                fence_start = lineno
                buf = []
                continue
            non_code.append((lineno, line))
        else:
            if stripped.startswith(fence_char * fence_len) and stripped[fence_len:].strip() == "":
                blocks.append((fence_start, fence_lang, "\n".join(buf)))
                in_fence = False
                buf = []
            else:
                buf.append(line)

    return non_code, blocks, in_fence


class TestInfraConfigsAndScripts(unittest.TestCase):
    """Validate MongoDB training shell scripts, Compose specs, playbooks, and datasets."""

    def test_shell_scripts_syntax_and_cli_usage(self) -> None:
        """Validate intact shell scripts with bash -n and verify offline CLI usage helpers."""
        for rel in INTACT_SHELL_SCRIPTS:
            self.assertTrue((REPO_ROOT / rel).is_file(), f"Missing script: {rel}")

        bash_bin = _posix_bash()
        if bash_bin is None:
            self.skipTest("POSIX bash required for bash -n syntax and CLI usage checks.")

        for rel in INTACT_SHELL_SCRIPTS:
            res = subprocess.run(
                [bash_bin, "-n", str(REPO_ROOT / rel)],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, f"bash -n failed for {rel}: {res.stderr}")

        # Exercise non-destructive CLI usage branches on training scripts
        help_res = subprocess.run(
            [bash_bin, str(REPO_ROOT / "scripts" / "inject_sample_databses.sh"), "--help"],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertIn("--repo-url", help_res.stdout)
        self.assertIn("--mongo-db", help_res.stdout)

        for script_rel, expected_usage in (
            ("scripts/create_admin_user.sh", "Usage:"),
            ("scripts/create_db_users.sh", "Usage:"),
            ("scripts/create_arbitrer.sh", "sudo"),
            ("scripts/create_instance.sh", "sudo"),
        ):
            out = subprocess.run(
                [bash_bin, str(REPO_ROOT / script_rel)],
                capture_output=True,
                text=True,
                check=False,
            )
            combined = out.stdout + out.stderr
            self.assertEqual(out.returncode, 1, f"{script_rel} unexpectedly succeeded with no args")
            self.assertIn(expected_usage, combined, f"Missing usage output in {script_rel}")

    def test_yaml_compose_configs_and_docker_compose_validation(self) -> None:
        """Validate YAML syntax across Compose/Ansible files and run docker compose config -q."""
        if yaml is None:
            self.skipTest("PyYAML not installed in current Python runtime.")

        parsed: dict[str, dict] = {}
        for rel in INTACT_YAML_FILES:
            p = REPO_ROOT / rel
            self.assertTrue(p.is_file(), f"Missing YAML file: {rel}")
            data = yaml.safe_load(p.read_text(encoding="utf-8"))
            self.assertIsNotNone(data, f"Empty YAML in {rel}")
            parsed[rel] = data

        standalone = parsed["docker/standalone/compose.yaml"]
        self.assertIn("mongo", standalone["services"])
        self.assertIn("mongo-express", standalone["services"])

        sharded = parsed["docker/sharded/docker-compose.yml"]
        for expected_service in (
            "config-server-1",
            "shard1-replica-1",
            "shard2-replica-1",
            "mongos-router-1",
            "mongos-router-2",
            "mongo-setup",
        ):
            self.assertIn(expected_service, sharded["services"])

        mongod_conf = parsed["docker/sharded/data/config/mongod.conf"]
        self.assertEqual(mongod_conf["net"]["port"], 27017)
        self.assertEqual(mongod_conf["security"]["authorization"], "enabled")

        if os.name == "posix" and shutil.which("docker"):
            chk1 = subprocess.run(
                ["docker", "compose", "-f", str(REPO_ROOT / "docker/standalone/compose.yaml"), "config", "-q"],
                capture_output=True,
                text=True,
                check=False,
            )
            if chk1.returncode == 0 or "is not a docker command" not in chk1.stderr:
                self.assertEqual(chk1.returncode, 0, chk1.stderr)
                chk2 = subprocess.run(
                    [
                        "docker",
                        "compose",
                        "--env-file",
                        str(REPO_ROOT / "docker/sharded/.env_example"),
                        "-f",
                        str(REPO_ROOT / "docker/sharded/docker-compose.yml"),
                        "config",
                        "-q",
                    ],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                self.assertEqual(chk2.returncode, 0, chk2.stderr)

    def test_datasets_ndjson_inventory_and_js_init_scripts(self) -> None:
        """Validate every NDJSON record in datasets/*.json, Ansible inventory, and JS init braces."""
        expected_counts = {
            "books.json": 150,
            "orders.json": 1000,
            "stocks.json": 42,
        }
        for filename, count in expected_counts.items():
            path = REPO_ROOT / "datasets" / filename
            lines = [ln for ln in path.read_text(encoding="utf-8").splitlines() if ln.strip()]
            self.assertEqual(len(lines), count, f"Unexpected line count in {filename}")
            for idx, ln in enumerate(lines, 1):
                obj = json.loads(ln)
                self.assertIsInstance(obj, dict, f"Line {idx} in {filename} is not a JSON object")

        inv = configparser.ConfigParser(allow_no_value=True)
        inv.read(REPO_ROOT / "inventory" / "hosts.ini", encoding="utf-8")
        for group in ("app", "mongodb", "proxy"):
            self.assertIn(group, inv.sections())

        for js_name in ("init-replica-sets.js", "init-users.js"):
            js_text = (REPO_ROOT / "docker/sharded/init-scripts" / js_name).read_text(encoding="utf-8")
            self.assertEqual(js_text.count("{"), js_text.count("}"), f"Unbalanced braces in {js_name}")


class TestDocsDiataxisAndDiagrams(unittest.TestCase):
    """Validate documentation links, fences, Mermaid, STE/STF, Diataxis, and FR/EN separation."""

    def test_markdown_fences_links_ascii_and_mermaid(self) -> None:
        """Verify all MD files have closed fences, valid links/anchors, no box trees, and valid Mermaid."""
        mds = _iter_repo_markdown()
        self.assertGreaterEqual(len(mds), 74)

        all_mermaid: list[tuple[pathlib.Path, int, str]] = []
        errors: list[str] = []

        for md in mds:
            rel = md.relative_to(REPO_ROOT).as_posix()
            text = md.read_text(encoding="utf-8")
            non_code, blocks, unclosed = _split_fenced_blocks(text)
            if unclosed:
                errors.append(f"{rel}: unclosed fenced code block")

            if "https://www.google.com/search" in text:
                errors.append(f"{rel}: contains broken google search TOC URL")
            if "bouton **Apply**" in text or "mode **Agent**" in text:
                errors.append(f"{rel}: contains stray editor prompt tail")
            if "votre_utilisateur/votre_repo" in text:
                errors.append(f"{rel}: contains placeholder GitHub URL")
            if ASCII_BOX_RE.search(text):
                errors.append(f"{rel}: contains ASCII or Unicode box-drawing diagram")

            # Collect heading slugs in this file
            slugs: set[str] = set()
            for _, line in non_code:
                hm = HEADING_RE.match(line)
                if hm:
                    slugs.add(_github_anchor_slug(hm.group(2)))

            # Check internal links and anchors
            for lineno, line in non_code:
                for match in LINK_RE.finditer(line):
                    raw_target = match.group(1).strip().split()[0]
                    if raw_target.startswith(("http://", "https://", "mailto:")):
                        continue
                    if raw_target.startswith("#"):
                        if raw_target[1:] not in slugs:
                            errors.append(f"{rel}:{lineno}: broken local anchor {raw_target}")
                        continue
                    file_part, _, frag = raw_target.partition("#")
                    resolved = (md.parent / unquote(file_part)).resolve()
                    if not (resolved.is_file() or resolved.is_dir()):
                        errors.append(f"{rel}:{lineno}: broken relative link {raw_target}")
                    elif frag and resolved.is_file() and resolved.suffix.lower() == ".md":
                        t_non_code, _, _ = _split_fenced_blocks(resolved.read_text(encoding="utf-8"))
                        t_slugs = {
                            _github_anchor_slug(m.group(2))
                            for _, ln in t_non_code
                            if (m := HEADING_RE.match(ln)) is not None
                        }
                        if frag not in t_slugs:
                            errors.append(f"{rel}:{lineno}: broken anchor #{frag} in {file_part}")

            # Validate Mermaid blocks
            for start_line, lang, code in blocks:
                first_tok = code.strip().splitlines()[0].strip() if code.strip() else ""
                if lang == "mermaid":
                    all_mermaid.append((md, start_line, code))
                    if not any(first_tok.startswith(prefix) for prefix in MERMAID_TYPES):
                        errors.append(f"{rel}:{start_line}: unrecognized Mermaid diagram header '{first_tok}'")
                    if code.count("[") != code.count("]") or code.count("{") != code.count("}"):
                        errors.append(f"{rel}:{start_line}: unbalanced brackets in Mermaid block")
                elif any(first_tok.startswith(prefix) for prefix in MERMAID_TYPES):
                    errors.append(f"{rel}:{start_line}: untagged Mermaid diagram block")

            # Enforce non-indented ```mermaid fences
            for lineno, line in enumerate(text.splitlines(), 1):
                if line.lstrip().startswith("```mermaid") and not line.startswith("```mermaid"):
                    errors.append(f"{rel}:{lineno}: indented ```mermaid fence")

        self.assertGreaterEqual(len(all_mermaid), 20)
        self.assertEqual(errors, [], "\n".join(errors))

    def test_en_and_fr_diataxis_quadrants_and_isolation(self) -> None:
        """Verify EN docs/ and FR docs/fr/ Diataxis portals, boundaries, and language isolation."""
        for base, quadrants in ((DOCS_EN_DIR, EN_QUADRANTS), (DOCS_FR_DIR, FR_QUADRANTS)):
            self.assertTrue((base / "index.md").is_file(), f"Missing {base}/index.md")
            for q in quadrants:
                qdir = base / q
                self.assertTrue(qdir.is_dir(), f"Missing {qdir}")
                self.assertTrue((qdir / "index.md").is_file(), f"Missing {qdir}/index.md")
                pages = [p for p in qdir.glob("*.md") if p.name != "index.md"]
                self.assertTrue(pages, f"Expected non-index pages in {qdir}")

        # Verify known upstream issues are documented in both Reference pages
        for ref_file in (
            DOCS_EN_DIR / "03-reference" / "scripts-compose-and-known-issues.md",
            DOCS_FR_DIR / "03-reference" / "scripts-compose-et-anomalies.md",
        ):
            ref_txt = ref_file.read_text(encoding="utf-8")
            self.assertIn("scripts/create_mongos.sh", ref_txt)
            self.assertIn("playbooks/config_system.yml", ref_txt)
            self.assertIn("scripts/logical_backup.sh", ref_txt)

        # Enforce root README.md (EN) and README.fr.md (FR) language isolation
        en_readme, _, _ = _split_fenced_blocks((REPO_ROOT / "README.md").read_text(encoding="utf-8"))
        en_prose = "\n".join(line for _, line in en_readme if "README.fr.md" not in line and "Portail FR" not in line)
        self.assertNotRegex(en_prose, r"\b(Voici|sauvegardes|dépôt|utilisez|démarrer|travaux pratiques)\b")

        fr_readme, _, _ = _split_fenced_blocks((REPO_ROOT / "README.fr.md").read_text(encoding="utf-8"))
        fr_prose = "\n".join(line for _, line in fr_readme if "README.md" not in line and "English Docs Portal" not in line)
        self.assertNotRegex(fr_prose, r"\b(Hands-on|Overview|Quickstart|Unknown|Prerequisites|Rollback)\b")

        # Enforce EN docs/ (excluding docs/fr/) contains no French procedural words
        for md in sorted(DOCS_EN_DIR.rglob("*.md")):
            if "fr" in md.relative_to(DOCS_EN_DIR).parts:
                continue
            non_code, _, _ = _split_fenced_blocks(md.read_text(encoding="utf-8"))
            prose = "\n".join(
                line for _, line in non_code if "fr/index.md" not in line and "README.fr.md" not in line
            )
            self.assertNotRegex(
                prose,
                r"\b(Procédure|Vérification|Étape\s+\d+|sauvegarde|dépôt|exécuter)\b",
                f"French text leaked into {md.relative_to(REPO_ROOT)}",
            )

    def test_how_to_guides_ste_and_stf_structural_rules(self) -> None:
        """Enforce ASD-STE100 on EN How-Tos and ASD-STF100 on FR Guides Pratiques."""
        en_guides = [
            p for p in (DOCS_EN_DIR / "02-how-to-guides").glob("*.md") if p.name != "index.md"
        ]
        fr_guides = [
            p for p in (DOCS_FR_DIR / "02-guides-pratiques").glob("*.md") if p.name != "index.md"
        ]
        self.assertTrue(en_guides)
        self.assertTrue(fr_guides)

        for md in en_guides:
            non_code, _, _ = _split_fenced_blocks(md.read_text(encoding="utf-8"))
            body = "\n".join(line for _, line in non_code)
            self.assertRegex(body, r"(?im)^##\s+Validation")
            self.assertRegex(body, r"(?im)^##\s+Rollback")
            for lineno, line in non_code:
                s = line.strip()
                if not s or s.startswith(("#", "|", "NOTE:", ">")):
                    continue
                self.assertNotIn(";", s, f"{md.name}:{lineno}: semicolon violates STE")
                self.assertNotRegex(s, r"\b(should|would|may|might|shall)\b", f"{md.name}:{lineno}: banned modal")
                clean = re.sub(r"`[^`]+`|\[([^\]]+)\]\([^)]+\)", r"\1", re.sub(r"^\d+\.\s+|^-\s+", "", s))
                for sent in [part.strip() for part in re.split(r"(?<=[.!?])\s+", clean) if part.strip()]:
                    words = [w for w in sent.split() if re.search(r"[A-Za-z0-9]", w)]
                    self.assertLessEqual(len(words), 20, f"{md.name}:{lineno} exceeds 20 words: {sent}")

        for md in fr_guides:
            non_code, _, _ = _split_fenced_blocks(md.read_text(encoding="utf-8"))
            body = "\n".join(line for _, line in non_code)
            self.assertRegex(body, r"(?im)^##\s+Vérification")
            self.assertRegex(body, r"(?im)^##\s+Retour Arrière")
            for lineno, line in non_code:
                s = line.strip()
                if not s or s.startswith(("#", "|", "NOTE:", ">")):
                    continue
                self.assertNotIn(";", s, f"{md.name}:{lineno}: semicolon violates STF")
                self.assertNotRegex(
                    s,
                    r"\b(devrait|pourrait|serait|faudrait|contrôler|contrôlez|inspecter|inspectez)\b",
                    f"{md.name}:{lineno}: banned STF token",
                )
                clean = re.sub(r"`[^`]+`|\[([^\]]+)\]\([^)]+\)", r"\1", re.sub(r"^\d+\.\s+|^-\s+", "", s))
                for sent in [part.strip() for part in re.split(r"(?<=[.!?])\s+", clean) if part.strip()]:
                    words = [w for w in sent.split() if re.search(r"[A-Za-z0-9À-ÿ]", w)]
                    self.assertLessEqual(len(words), 20, f"{md.name}:{lineno} exceeds 20 words: {sent}")


if __name__ == "__main__":
    unittest.main()
