"""
markdown_importer.py — 用户 markdown 记忆文件导入器

功能：
- 扫描 ~/.openclaw/memory/ 下的所有 .md 文件
- 按 ## / ### 分块，保留结构
- 转 embeddings → 存入 LanceDB
- 与 hawk 记忆系统无缝融合
"""

import os
import glob
import hashlib
import re
from pathlib import Path
from dataclasses import dataclass
from typing import Optional
from datetime import datetime


@dataclass
class Chunk:
    """一个记忆块"""
    source_file: str       # 来源文件
    chunk_id: str         # 唯一ID（文件hash+chunk序号）
    title: str            # 所属标题
    heading: str          # 当前章节标题
    content: str           # 内容
    file_mtime: float    # 文件修改时间


class MarkdownImporter:
    """
    把用户的 .md 记忆文件导入到 LanceDB
    与 MemoryManager 共享同一个 LanceDB 表
    """

    def __init__(self, memory_dir: str = "~/.openclaw/memory"):
        self.memory_dir = os.path.expanduser(memory_dir)

    def scan(self) -> list[Chunk]:
        """
        扫描 memory_dir 下所有 .md 文件
        返回所有分块
        """
        chunks = []
        pattern = os.path.join(self.memory_dir, "*.md")
        files = glob.glob(pattern)

        for filepath in files:
            file_chunks = self._parse_file(filepath)
            chunks.extend(file_chunks)

        return chunks

    def _parse_file(self, filepath: str) -> list[Chunk]:
        """解析单个 md 文件，按章节分块"""
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        # 获取文件修改时间
        mtime = os.path.getmtime(filepath)
        filename = os.path.basename(filepath)

        # 提取文件级标题（第一个 # 标题）
        title = ""
        title_match = re.search(r'^# (.+)$', content, re.MULTILINE)
        if title_match:
            title = title_match.group(1).strip()

        # 按 ## 分块（保留 # 和 ## 两级结构）
        sections = re.split(r'^## (.+)$', content, flags=re.MULTILINE)

        chunks = []
        chunk_idx = 0

        # sections[0] 是 # 标题之后、第一个 ## 之前的内容（一般是引言）
        intro = sections[0].strip()
        if intro:
            chunk_id = self._make_chunk_id(filename, 0, intro)
            chunks.append(Chunk(
                source_file=filename,
                chunk_id=chunk_id,
                title=title,
                heading="",
                content=intro,
                file_mtime=mtime,
            ))
            chunk_idx += 1

        # sections[1], sections[2], ... 分别是 ## 标题 和 对应内容
        i = 1
        while i < len(sections) - 1:
            heading = sections[i].strip()
            body = sections[i + 1].strip()
            if heading and body:
                # 进一步按 ### 分小节
                sub_sections = re.split(r'^### (.+)$', body, flags=re.MULTILINE)
                if len(sub_sections) > 1:
                    # 有 ### 结构
                    sub_intro = sub_sections[0].strip()
                    if sub_intro:
                        chunk_id = self._make_chunk_id(filename, chunk_idx, sub_intro)
                        chunks.append(Chunk(
                            source_file=filename,
                            chunk_id=chunk_id,
                            title=title,
                            heading=heading,
                            content=sub_intro,
                            file_mtime=mtime,
                        ))
                        chunk_idx += 1

                    for j in range(1, len(sub_sections) - 1):
                        sub_heading = sub_sections[j].strip()
                        sub_body = sub_sections[j + 1].strip()
                        if sub_heading and sub_body:
                            chunk_id = self._make_chunk_id(filename, chunk_idx, sub_body)
                            chunks.append(Chunk(
                                source_file=filename,
                                chunk_id=chunk_id,
                                title=title,
                                heading=f"{heading} / {sub_heading}",
                                content=sub_body.strip(),
                                file_mtime=mtime,
                            ))
                            chunk_idx += 1
                else:
                    # 无 ###，直接分块
                    chunk_id = self._make_chunk_id(filename, chunk_idx, body)
                    chunks.append(Chunk(
                        source_file=filename,
                        chunk_id=chunk_id,
                        title=title,
                        heading=heading,
                        content=body.strip(),
                        file_mtime=mtime,
                    ))
                    chunk_idx += 1
            i += 2

        return chunks

    def _make_chunk_id(self, filename: str, idx: int, content: str) -> str:
        """生成唯一 chunk ID"""
        raw = f"{filename}:{idx}:{content[:50]}"
        return hashlib.sha256(raw.encode()).hexdigest()[:16]

    def embed_and_store(self, chunks: list[Chunk], table_name: str = "memory_chunks"):
        """
        将 chunks 转为 embeddings 存入 LanceDB
        需要 MemoryManager 已初始化
        """
        try:
            import lancedb
            from openai import OpenAI
        except ImportError as e:
            raise RuntimeError(
                f"缺少依赖: {e}\n请运行: python3.12 -m pip install lancedb openai"
            )

        # 初始化 OpenAI embeddings
        api_key = os.environ.get("OPENAI_API_KEY")
        if not api_key:
            raise RuntimeError("请设置 OPENAI_API_KEY 环境变量")
        client = OpenAI(api_key=api_key)

        # 连接到 LanceDB
        db_path = os.path.expanduser("~/.hawk/lancedb")
        os.makedirs(db_path, exist_ok=True)
        db = lancedb.connect(db_path)

        # 创建/覆盖表
        schema = lancedb.schema([
            ("chunk_id", "string"),
            ("source_file", "string"),
            ("title", "string"),
            ("heading", "string"),
            ("content", "string"),
            ("file_mtime", "float64"),
            ("imported_at", "float64"),
            ("vector", "vector(1536)"),
        ])
        if table_name in db.table_names():
            db.drop_table(table_name)
        table = db.create_table(table_name, schema=schema)

        # 批量 embedding
        BATCH = 20
        for i in range(0, len(chunks), BATCH):
            batch = chunks[i:i + BATCH]
            texts = [c.content for c in batch]

            # 调用 OpenAI embeddings
            resp = client.embeddings.create(
                model="text-embedding-3-small",
                input=texts,
            )
            vectors = [item.embedding for item in resp.data]

            rows = [
                {
                    "chunk_id": c.chunk_id,
                    "source_file": c.source_file,
                    "title": c.title,
                    "heading": c.heading,
                    "content": c.content,
                    "file_mtime": c.file_mtime,
                    "imported_at": datetime.now().timestamp(),
                    "vector": vec,
                }
                for c, vec in zip(batch, vectors)
            ]
            table.add(rows)

        return len(chunks)

    def import_all(self) -> dict:
        """
        一键导入所有记忆文件
        返回导入统计
        """
        chunks = self.scan()
        if not chunks:
            return {"files": 0, "chunks": 0}

        count = self.embed_and_store(chunks)

        files = set(c.source_file for c in chunks)
        return {
            "files": len(files),
            "chunks": count,
        }


# CLI 入口
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="导入 markdown 记忆文件到 hawk")
    parser.add_argument("--memory-dir", default="~/.openclaw/memory",
                        help="记忆文件目录")
    parser.add_argument("--dry-run", action="store_true",
                        help="仅扫描，不导入")
    args = parser.parse_args()

    importer = MarkdownImporter(memory_dir=args.memory_dir)

    print(f"扫描目录: {importer.memory_dir}")
    chunks = importer.scan()
    print(f"发现 {len(chunks)} 个记忆块")

    if args.dry_run:
        for c in chunks[:5]:
            print(f"  [{c.source_file}] {c.heading or c.title}: {c.content[:60]}...")
        return

    result = importer.import_all()
    print(f"导入完成: {result['files']} 个文件, {result['chunks']} 个块")
