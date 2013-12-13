/*
 *  メイン関数モジュール
 */
module dlife.main;

import sdl;

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

/// 初期配置時のライフの割合の分母
/// 2を指定した場合、2セルに1つの割合でランダムにライフを生成する
enum LIFE_DENOMINATOR = 2;

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

    // 時間計測
    auto watch = FpsWatch(FPS);

    // ライフゲームワールドの生成
    auto world = new World(WINDOW_WIDTH, WINDOW_HEIGHT);

    // ランダムにライフを配置
    foreach(y; 0 .. WINDOW_HEIGHT) {
        foreach(x; 0 .. WINDOW_WIDTH) {
            if(uniform(0, LIFE_DENOMINATOR) == 0) {
                world.addLife(x, y);
            }
        }
    }

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
        enforceSDL(SDL_SetRenderDrawColor(renderer, Uint8.max, Uint8.max, Uint8.max, Uint8.max));
        SDL_RenderClear(renderer);

        // 描画色を設定
        enforceSDL(SDL_SetRenderDrawColor(renderer, 0, 0, 0, Uint8.max));

        // 全ライフの描画
        foreach(x, y; world) {
            enforceSDL(SDL_RenderDrawPoint(renderer, cast(int) x, cast(int) y));
        }

        // 描画結果表示
        SDL_RenderPresent(renderer);

        // 次のフレーム開始時刻まで待つ
        watch.waitNextFrame();

        // 1秒分描画したら、FPSを表示する
        if(watch.totalFrames >= FPS) {
            SDL_SetWindowTitle(window, toStringz(format("FPS:%f", watch.actualFps)));

            // FPS計測のリセット
            watch.resetFps();
        }
    }
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

