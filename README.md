## よく使うコマンド早見表

| やりたいこと | コマンド |
|------------|---------|
| 普通に実行 | `bash scripts/build.sh` |
| コンパイルのみ | `bash scripts/build.sh build` |
| ランダムテスト | `bash scripts/build.sh debug` |
| ストレステスト100回 | `bash scripts/stress_test.sh -n 100 -o aout.txt` |
| インタラクティブ | `bash scripts/interactive.sh` |
| インタラクティブ（5回） | `bash scripts/interactive.sh -n 5` |
| クリーンアップ | `bash scripts/clean.sh` |
| AtCoder Library展開してコピー | `bash scripts/copy.sh` |
| AtCoder Library展開してコピー（軽量版） | `bash scripts/copy.sh -l` |
| AtCoder Library展開してファイル出力 | `bash scripts/deploy.sh` |

---

## コンパイル環境

このプロジェクトはAtCoder C++ 23 (gcc 14.2.0) 環境に可能な限り合わせています。

### 使用されるコンパイルフラグ
```bash
-DATCODER
-DONLINE_JUDGE
-DNOMINMAX
-std=gnu++23
-O2
-Wall
-Wextra
-march=native
-mtune=native
-pthread
-I./
-Wno-pragmas
-fconstexpr-depth=2147483647
-fconstexpr-loop-limit=2147483647
-fconstexpr-ops-limit=4294967295
```

---

## コマンド一覧

### 1. 基本的な実行

#### シンプルに実行（ain.txt → aout.txt）
```bash
bash scripts/build.sh
```

#### 結果を確認
```bash
cat aout.txt
```

---

### 2. ビルドのみ / 実行のみ

#### コンパイルのみ
```bash
bash scripts/build.sh build
```

#### コンパイル＆実行（I/Oリダイレクトなし）
```bash
bash scripts/build.sh run
```

#### テスト実行（ain.txt → aout.txt, aerr.log）
```bash
bash scripts/build.sh test
```

---

### 3. テスト生成＋実行

#### 1回だけテスト生成して実行
```bash
bash scripts/build.sh debug
```

#### 複数回実行（例: 10回）
```bash
bash scripts/gen_run.sh -g templates/testcase_generate.cpp -s main.cpp -n 10 -o aout.txt -e aerr.log
```

---

### 4. ストレステスト

#### 100ケース実行（デフォルト）
```bash
bash scripts/stress_test.sh -n 100 -o aout.txt
```

#### 200ケース実行
```bash
bash scripts/stress_test.sh -n 200 -o aout.txt
```

#### カスタム設定
```bash
bash scripts/stress_test.sh -g templates/testcase_generate.cpp -m main.cpp -r templates/main_greedy.cpp -n 100 -o aout.txt
```

#### 結果確認
```bash
cat aout.txt
```

**出力内容:**
- AC/WA数のサマリー
- WAケースの入力データ
- main.cppの出力
- main_greedy.cppの出力（期待値）

---

### 5. インタラクティブ問題

#### インタラクティブ実行（1回）
```bash
bash scripts/interactive.sh
```

#### インタラクティブ実行（複数回）
```bash
bash scripts/interactive.sh -n 5
```

main.cppとinteractive_judge.cppが対話形式で実行されます。
ビルドも自動で行われるため、別途ビルドコマンドを実行する必要はありません。

---

## 典型的なワークフロー

### パターン1: 通常の問題を解く

1. **入力を作成**
```bash
echo "5" > ain.txt
```

2. **main.cppを編集**（コードを書く）

3. **実行**
```bash
bash scripts/build.sh
```

4. **結果確認**
```bash
cat aout.txt
```

---

### パターン2: ランダムテストで動作確認

1. **templates/testcase_generate.cppを編集**（テストケース生成ロジックを書く）

2. **main.cppを編集**（解答を書く）

3. **テスト実行**
```bash
bash scripts/build.sh debug
```

4. **結果確認**
```bash
cat aout.txt
```

---

### パターン3: ストレステストでバグ検出

1. **main.cppを編集**（テストしたい解答）

2. **templates/main_greedy.cppを編集**（確実に正解する愚直解）

3. **templates/testcase_generate.cppを編集**（ランダムテストケース生成）

4. **ストレステスト実行**
```bash
bash scripts/stress_test.sh -n 100 -o aout.txt
```

5. **結果確認**
```bash
cat aout.txt
```

6. **WAがあれば、aout.txtに詳細が出力される**
   - どの入力でWAになったか
   - main.cppの出力
   - main_greedy.cppの出力（正解）

---

## オンラインジャッジへの提出

### AtCoderへの提出

このプロジェクトで作成した **main.cpp** はAtCoderにそのまま提出できます。

#### 提出前チェックリスト
- [ ] ファイル名が `main.cpp` であることを確認
- [ ] `#include <atcoder/all>` などのライブラリが正しく使われているか確認
- [ ] ローカルでテストが通ることを確認（`bash scripts/build.sh`）
- [ ] 可能であればストレステストを実行（`bash scripts/stress_test.sh -n 100 -o aout.txt`）

---

### Codeforces等への提出

Codeforcesや他のオンラインジャッジでは `#include <atcoder/all>` が使えません。
以下のコマンドでAtCoder Libraryを展開したコードをクリップボードにコピーできます。

#### 方法1: クリップボードに直接コピー（推奨）
```bash
bash scripts/copy.sh
```
- AtCoder Libraryが展開された完全なコードがクリップボードにコピーされます
- そのままブラウザで Cmd+V で貼り付けて提出できます

#### 方法2: ファイルに出力してからコピー
```bash
bash scripts/deploy.sh
```
- `deploy.cpp` に展開されたコードが出力されます
- 同時にクリップボードにもコピーされます
- ファイルを確認してから提出したい場合に便利です

#### 他のファイルを展開する場合
```bash
bash scripts/copy.sh other_file.cpp
bash scripts/deploy.sh other_file.cpp output.cpp
```

---

## Tips

### 入力ファイルを複数行で作成
```bash
cat > ain.txt << EOF
5
1 2 3 4 5
EOF
```

### 出力とエラーを同時に確認
```bash
bash scripts/build.sh && cat aout.txt && cat aerr.log
```

### 一時ファイルのクリーンアップ
```bash
bash scripts/clean.sh
```

### C++23の機能を使う
このプロジェクトはC++23をサポートしています（gcc 14.2.0以降が必要）。
利用できない場合は自動的にC++20にフォールバックします。

```cpp
// C++23の例: std::print (利用可能な場合)
#include <print>
std::print("Hello, {}!\n", "AtCoder");
```

---

## 注意事項

- **ain.txt**, **aout.txt**, **aerr.log**は自動的に上書きされます
- テストの一時ファイルは`tmp/`ディレクトリに保存されます
- ビルド成果物は`build/`ディレクトリに保存されます
- コンパイルエラーは**aerr.log**に色付きで出力されます（warningはターミナルのみに表示）
- 実行時エラーも**aerr.log**に出力されます
- コンパイルフラグは`scripts/compile_flags.sh`で管理されています

---

## トラブルシューティング

### コンパイルエラーが出る
```bash
cat aerr.log  # エラー内容を確認
```

### C++23が使えない
システムのg++バージョンを確認：
```bash
g++ --version
```
gcc 14.2.0以降が必要です。利用できない場合は自動的にC++20にフォールバックします。

### ストレステストでWAが出る
```bash
cat aout.txt  # 詳細な差分を確認
cat tmp/test_1.in  # 最初のWAケースの入力を確認
```

### スクリプトが動作しない
```bash
chmod +x scripts/*.sh  # 実行権限を付与
```
