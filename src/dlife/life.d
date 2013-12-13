module dlife.life;

/**
 *  ライフゲームの世界を表すクラス
 *  端が繋がったトーラス状の世界をシミュレートする。
 */
class World {

    ///
    unittest {
        // 10 * 10セルの世界を生成
        auto world = new World(10, 10);

        // 座標(1, 1)にライフを配置
        world.addLife(1, 1);
        assert(world.isAlive(1, 1));

        // 少し離れた場所にブリンカー配置
        world.addLife(4, 4);
        world.addLife(4, 5);
        world.addLife(4, 6);

        // 次の時刻へ
        world.next();

        // 1つだけだと死亡
        assert(!world.isAlive(1, 1));

        // ブリンカーは生存、横方向に2セル誕生
        assert(world.isAlive(3, 5));
        assert(world.isAlive(4, 5));
        assert(world.isAlive(5, 5));

        // 縦方向の2セルは死亡
        assert(!world.isAlive(4, 4));
        assert(!world.isAlive(4, 6));
    }

    /**
     *  Params:
     *      width = 幅
     *      height = 高さ
     */
    this(size_t width, size_t height) @safe {
        width_ = width;
        height_ = height;
        world_ = createWorld();
    }

    /**
     *  指定座標にライフを追加する
     *
     *  Params:
     *      x = ライフ追加先のX座標
     *      y = ライフ追加先のY座標
     */
    void addLife(size_t x, size_t y) @safe nothrow
    in {
        assert(x < width_);
        assert(y < height_);
    } body {
        world_[y][x] = true;
    }

    /**
     *  指定座標にライフが生存しているか返す
     *
     *  Params:
     *      x = 確認する位置のX座標
     *      y = 確認する位置のY座標
     */
    bool isAlive(size_t x, size_t y) const nothrow pure @safe
    in {
        assert(x < width_);
        assert(y < height_);
    } body {
        return world_[y][x];
    }

    /**
     *  世界を次の時刻に進める
     */
    void next() @safe {
        auto nextWorld = createWorld();

        // 全セルの生存チェック。結果を新しい世界に設定
        foreach(y, row; world_) {
            foreach(x, life; row) {
                nextWorld[y][x] = isAliveNext(x, y, life);
            }
        }

        // 新しい世界に移行
        world_ = nextWorld;
    }

private:

    enum {
        ALIVE_COUNT = 2, /// この数だけ周囲のセルにライフがあれば生き残れる
        BORN_COUNT = 3, /// この数だけ周囲のセルにライフがあれば新たに生まれる
    }

    /**
     *  世界の情報を新規生成する
     *
     *  Returns:
     *      新しい世界の情報
     */
    bool[][] createWorld() @safe {
        bool[][] world;
        world.length = height_;
        foreach(ref row; world) {
            row.length = width_;
        }
        return world;
    }

    /**
     *  次の時刻に指定座標にライフが存在するか
     *
     *  Params:
     *      x = 確認対象の位置のX座標
     *      y = 確認対象の位置のY座標
     *      life = 現在ライフが存在するかどうか
     */
    bool isAliveNext(size_t x, size_t y, bool life) const pure nothrow @safe {
        // 周囲の座標を計算。端だった場合はラップ
        immutable l = (x == 0) ? right : x - 1;
        immutable t = (y == 0) ?  bottom : y - 1;
        immutable r = (x == right) ? 0 : x + 1;
        immutable b = (y == bottom) ? 0 : y + 1;

        // 前後左右のセルのライフを数える
        size_t count = 0;
        foreach(row; [t, y, b]) {
            foreach(col; [l, x, r]) {
                if(isAlive(col, row)) {
                    ++count;
                }
            }
        }

        // 自セル分は除く
        if(life) {
            --count;
        }

        // 新たに誕生する場合か、既にライフが存在して生き残れる場合はtrue
        if(count == BORN_COUNT) {
            return true;
        } else if(life && count == ALIVE_COUNT) {
            return true;
        } else {
            return false;
        }
    }

    /// 右端の座標を返す
    @property size_t right() const pure nothrow @safe {return width_ - 1;}

    /// 下端の座標を返す
    @property size_t bottom() const pure nothrow @safe {return height_ - 1;}

    /// 幅
    immutable size_t width_;

    /// 高さ
    immutable size_t height_;

    /// 世界全体の情報
    bool[][] world_;
}

