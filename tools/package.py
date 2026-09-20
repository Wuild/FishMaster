"""Validate addon sources or explicitly build a local release ZIP."""
import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def validate():
    included = set()

    def include(path):
        path = path.resolve()
        if not path.is_relative_to(ROOT):
            raise ValueError(f"Include escapes repository: {path}")
        if not path.is_file():
            raise FileNotFoundError(path)
        if path in included:
            return
        included.add(path)
        if path.suffix == ".xml":
            document = ET.parse(path)
            for element in document.iter():
                relative = element.attrib.get("file")
                if element.tag.rsplit("}", 1)[-1] in ("Script", "Include") and relative:
                    include(path.parent / relative.replace("\\", "/"))

    toc = ROOT / "FishMaster.toc"
    include(toc)
    source = toc.read_text(encoding="utf-8-sig")
    for line in source.splitlines():
        if line.strip() and not line.startswith("#"):
            include(ROOT / line.strip())
    for path in (ROOT / "images").iterdir():
        if path.is_file():
            include(path)
    include(ROOT / "LICENSE")
    include(ROOT / "README.md")
    version = re.search(r"^## Version:\s*(.+)$", source, re.M).group(1).strip()
    return included, version


def release_metadata(tag):
    match = re.fullmatch(r"v?(\d+\.\d+\.\d+)(?:-([0-9A-Za-z]+(?:[.-][0-9A-Za-z]+)*))?", tag)
    if not match:
        raise ValueError(f"Expected a version tag such as 2.0.1 or v2.0.1-beta.1: {tag!r}")
    version = tag.removeprefix("v")
    prerelease = match.group(2)
    # Forever identifies the supported client, not a prerelease channel.
    if prerelease == "forever":
        prerelease = None
    elif prerelease and prerelease.startswith("forever-"):
        prerelease = prerelease[len("forever-"):]
    release_type = "release" if not prerelease else (
        "alpha" if prerelease.split(".")[0].split("-")[0].lower() == "alpha" else "beta")
    return version, release_type


def versioned_toc(source, version):
    return re.sub(r"(?m)^## Version:[^\r\n]*", lambda _: f"## Version: {version}", source)


def build(tag):
    version, release_type = release_metadata(tag)
    included, _ = validate()
    output = ROOT / "dist" / f"FishMaster-{version}.zip"
    output.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):
            member = "FishMaster/" + path.relative_to(ROOT).as_posix()
            if path.name == "FishMaster.toc":
                archive.writestr(member, versioned_toc(path.read_text(encoding="utf-8-sig"), version))
            else:
                archive.write(path, member)
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert "FishMaster/FishMaster.toc" in archive.namelist()
    print(f"{output} ({len(included)} files)")
    return output, release_type


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", action="store_true", help="Create a release ZIP")
    parser.add_argument("--version", help="Release version (required with --build)")
    args = parser.parse_args()
    if args.build:
        if not args.version:
            parser.error("--build requires --version")
        build(args.version)
    else:
        included, version = validate()
        print(f"Validated FishMaster {version}: {len(included)} files; no artifacts generated")
