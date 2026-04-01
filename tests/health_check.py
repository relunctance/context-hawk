#!/usr/bin/env python3
"""
context-hawk health check script
周期性运行，检查 bug 和改进点，有问题则输出报告
"""

import sys
import os
import traceback

# Add hawk to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def test_imports():
    """测试所有模块能否正常导入"""
    print("=== 1. 模块导入测试 ===")
    try:
        from hawk.memory import MemoryManager, MemoryItem
        from hawk.compression import MemoryCompressor
        from hawk.compressor import ContextCompressor
        from hawk.config import Config
        from hawk.extractor import extract_memories
        print("✅ 所有模块导入成功")
        return True
    except Exception as e:
        print(f"❌ 模块导入失败: {e}")
        traceback.print_exc()
        return False


def test_memory_manager():
    """测试 MemoryManager 基本操作"""
    print("\n=== 2. MemoryManager 测试 ===")
    try:
        from hawk.memory import MemoryManager
        import tempfile

        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            db_path = f.name

        mm = MemoryManager(db_path=db_path)
        initial_count = len(mm.memories)

        # store
        id1 = mm.store("测试记忆A", category="fact", importance=0.8)
        id2 = mm.store("测试记忆B", category="preference", importance=0.5)
        print(f"✅ store: 新增2条, id1={id1[:8]}, id2={id2[:8]}")

        # recall
        results = mm.recall("测试记忆A")
        print(f"✅ recall: 检索到 {len(results)} 条")

        # access
        item = mm.access(id1)
        print(f"✅ access: access_count={item.access_count}")

        # count
        counts = mm.count()
        print(f"✅ count: {counts}")

        # cleanup
        os.unlink(db_path)
        print("✅ 清理完成")
        return True
    except Exception as e:
        print(f"❌ MemoryManager 测试失败: {e}")
        traceback.print_exc()
        return False


def test_compression():
    """测试 MemoryCompressor 基本操作"""
    print("\n=== 3. MemoryCompressor 测试 ===")
    try:
        from hawk.compression import MemoryCompressor
        from hawk.memory import MemoryManager
        import tempfile

        with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
            db_path = f.name

        mm = MemoryManager(db_path=db_path)
        id1 = mm.store("测试记忆C" * 50, category="fact", importance=0.8)  # 长文本
        id2 = mm.store("测试记忆D", category="fact", importance=0.2)  # 低价值

        mc = MemoryCompressor(db_path=db_path)

        # audit
        report = mc.audit()
        print(f"✅ audit: total={report['total']}, avg_imp={report['avg_importance']}")
        print(f"   候选: summarize={len(report['candidates']['to_summarize'])}, "
              f"delete={len(report['candidates']['to_delete'])}, "
              f"promote={len(report['candidates']['to_promote'])}, "
              f"archive={len(report['candidates']['to_archive'])}")

        # compress_all dry_run
        result = mc.compress_all("summarize", dry_run=True)
        print(f"✅ compress_all(summarize, dry_run): processed={result['processed']}")

        result = mc.compress_all("delete", dry_run=True)
        print(f"✅ compress_all(delete, dry_run): processed={result['processed']}")

        os.unlink(db_path)
        print("✅ 清理完成")
        return True
    except Exception as e:
        print(f"❌ MemoryCompressor 测试失败: {e}")
        traceback.print_exc()
        return False


def test_context_compressor():
    """测试 ContextCompressor"""
    print("\n=== 4. ContextCompressor 测试 ===")
    try:
        from hawk.compressor import ContextCompressor

        cc = ContextCompressor()

        conversation = [
            {"role": "user", "content": "你好"},
            {"role": "assistant", "content": "你好，有什么可以帮你的？"},
            {"role": "user", "content": "我想学习Python"},
            {"role": "assistant", "content": "好的，Python是一门很棒的语言。建议从基础语法开始。"},
        ]

        # test simple
        result = cc.compress(conversation, max_tokens=100, strategy="simple")
        print(f"✅ simple compress: ratio={result['compression_ratio']}, tokens={result['compressed_tokens']}")

        # test smart
        result = cc.compress(conversation, max_tokens=100, strategy="smart")
        print(f"✅ smart compress: ratio={result['compression_ratio']}, tokens={result['compressed_tokens']}")

        return True
    except Exception as e:
        print(f"❌ ContextCompressor 测试失败: {e}")
        traceback.print_exc()
        return False


def test_config():
    """测试 Config"""
    print("\n=== 5. Config 测试 ===")
    try:
        from hawk.config import Config
        cfg = Config()
        print(f"✅ Config: db_path={cfg.get('db_path')}, embedding_model={cfg.get('embedding_model')}")
        return True
    except Exception as e:
        print(f"❌ Config 测试失败: {e}")
        traceback.print_exc()
        return False


def main():
    print("=" * 50)
    print("context-hawk Health Check")
    print("=" * 50)

    results = []
    results.append(("模块导入", test_imports()))
    results.append(("MemoryManager", test_memory_manager()))
    results.append(("MemoryCompressor", test_compression()))
    results.append(("ContextCompressor", test_context_compressor()))
    results.append(("Config", test_config()))

    print("\n" + "=" * 50)
    print("SUMMARY")
    print("=" * 50)
    all_pass = True
    for name, ok in results:
        status = "✅ PASS" if ok else "❌ FAIL"
        print(f"  {status}  {name}")
        if not ok:
            all_pass = False

    if all_pass:
        print("\n✅ 所有测试通过")
        return 0
    else:
        print("\n⚠️ 部分测试失败，请检查上述输出")
        return 1


if __name__ == "__main__":
    sys.exit(main())
