/*
 *  メイン関数モジュール
 */
module dlife.main;

import sdl.all;

import std.random;
import std.stdio;
import std.string;

import dlife.life;

/// ウィンドウの幅
enum WINDOW_WIDTH = 640;

/// ウィンドウの高さ
enum WINDOW_HEIGHT = 480;

/// 秒間フレーム数(希望)
enum FPS = 60;

/// FPS再計算時間
enum FPS_REFRESH_MILLS = 500;

/// 初期配置時のライフの割合の分母
/// 2を指定した場合、2セルに1つの割合でランダムにライフを生成する
enum LIFE_DENOMINATOR = 2;

/// 点描画用バッファサイズ
enum POINT_BUFFER_SIZE = 100000;

/// フレームクリア時のアルファ
/// 数字が小さいほど残像が長く残る
enum ALPHA_ON_CLEAR = 8; //SDL_ALPHA_OPAQUE;

/// 画面全体を指す矩形
immutable SCREEN_RECT = SDL_Rect(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);

/**
 *  メイン関数
 *
 *  Params:
 *      args = コマンドライン引数
 */
void main(string[] args) {
    // SDL初期化。最後に終了。
    enforceSDL(SDL_Init(SDL_INIT_EVERYTHING));
    scope(exit) SDL_Quit();

    // ウィンドウを生成する
    auto window = enforceSDL(SDL_CreateWindow(
                toStringz(args[0]),     // とりあえずプロセス名
                SDL_WINDOWPOS_CENTERED, // 中央表示
                SDL_WINDOWPOS_CENTERED, // 中央表示
                WINDOW_WIDTH,
                WINDOW_HEIGHT,
                SDL_WINDOW_SHOWN));     // 最初から表示

    // スコープ終了時にウィンドウを破棄
    scope(exit) SDL_DestroyWindow(window);

    // レンダラー生成
    auto renderer = enforceSDL(SDL_CreateRenderer(
                window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC));
    scope(exit) SDL_DestroyRenderer(renderer);

    // 画面クリア
    enforceSDL(SDL_SetRenderDrawColor(renderer, Uint8.max, Uint8.max, Uint8.max, Uint8.max));
    SDL_RenderClear(renderer);

    // 点バッファ生成
    auto buffer = PointBuffer(renderer, POINT_BUFFER_SIZE);

    // 世界生成
    auto world = createWorld(WINDOW_WIDTH, WINDOW_HEIGHT, LIFE_DENOMINATOR);

    // 時間計測開始
    auto watch = FpsWatch(FPS);

    // メインループ
    for(bool quit = false; !quit;) {
        // フレーム開始時刻
        immutable startTicks = SDL_GetTicks();

        // キューに溜まったイベントを処理
        for(SDL_Event e; SDL_PollEvent(&e);) {
            if(!processEvent(e)) {
                quit = true;
            }
        }

        // 時刻を進める
        world.next();

        // 画面クリア
        enforceSDL(SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND));
        enforceSDL(SDL_SetRenderDrawColor(renderer, Uint8.max, Uint8.max, Uint8.max, ALPHA_ON_CLEAR));
        enforceSDL(SDL_RenderFillRect(renderer, &SCREEN_RECT));


        // 描画色を設定
        enforceSDL(SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE));
        enforceSDL(SDL_SetRenderDrawColor(renderer, 0, 0, 0, Uint8.max));

        // 全ライフの描画
        foreach(x, y; world) {
            buffer.add(x, y);
        }

        // 残りのバッファのフラッシュ
        buffer.flush();

        // 描画結果表示
        SDL_RenderPresent(renderer);

        // 次のフレーム開始時刻まで待つ
        watch.waitNextFrame();

        // 指定ミリ秒分描画したら、FPSを表示する
        if(watch.totalElapse >= FPS_REFRESH_MILLS) {
            SDL_SetWindowTitle(window, toStringz(format("FPS:%f", watch.actualFps)));

            // FPS計測のリセット
            watch.resetFps();
        }
    }
}

/**
 *  世界の生成
 *
 *  Params:
 *      width = 世界の幅
 *      height = 世界の高さ
 *      denom = セルに対するライフの割合の分母。
 *              例えば、2セルにつき1ライフの割合で配置したい場合は
 *              2を指定する。
 */
World createWorld(size_t width, size_t height, int denom) {
    // ランダムにライフを配置
    auto world = new World(width, height);
    foreach(y; 0 .. height) {
        foreach(x; 0 .. width) {
            if(uniform(0, denom) == 0) {
                world.addLife(x, y);
            }
        }
    }
    return world;
}

/**
 *  イベントを処理する。
 *
 *  Params:
 *      e = 発生したイベント
 *  Returns:
 *      処理を継続する場合はtrue。終了する場合はfalse。
 */
bool processEvent(const ref SDL_Event e) {
    switch(e.type) {
        // 終了イベント
        case SDL_QUIT:
            return false;
        // マウスクリック。終了する。
        case SDL_MOUSEBUTTONDOWN:
            return false;
        // 上記以外。無視して継続
        default:
            return true;
    }
}

/// 点描画用バッファ
struct PointBuffer {

    /**
     *  Params:
     *      renderer = 描画対象レンダラ
     *      size = バッファサイズ
     */
    this(SDL_Renderer* renderer, size_t size) @safe {
        renderer_ = renderer;
        buffer_.length = size;
    }

    /**
     *  点の追加
     *
     *  Params:
     *      x = 追加する点のX座標
     *      y = 追加する点のY座標
     */
    void add(size_t x, size_t y) {
        // 既にバッファがいっぱいだった場合はフラッシュ
        if(buffer_.length == end_) {
            flush();
        }

        // バッファに追加
        buffer_[end_] = SDL_Point(cast(int) x, cast(int) y);
        ++end_;
    }

    /// バッファ内容を全て書き出す
    void flush() {
        enforceSDL(SDL_RenderDrawPoints(renderer_, buffer_.ptr, cast(int) end_));
        end_ = 0;
    }

private:

    /// バッファ
    SDL_Point[] buffer_;

    /// バッファ使用済み終端
    size_t end_ = 0;

    /// 描画先レンダラ
    SDL_Renderer* renderer_;
}

