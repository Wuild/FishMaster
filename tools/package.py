"""Build the installable Forever addon using the actual TOC/XML load graph."""
from pathlib import Path
import re
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def build():
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
    output = ROOT / "dist" / f"FishMaster-{version}.zip"
    output.parent.mkdir(exist_ok=True)
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(included):
            archive.write(path, "FishMaster/" + path.relative_to(ROOT).as_posix())
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert "FishMaster/FishMaster.toc" in archive.namelist()
    print(f"{output} ({len(included)} files)")
    return output


if __name__ == "__main__":
    build()
