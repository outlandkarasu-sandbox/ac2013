/*
 *  メイン関数モジュール
 */
module dlife.main;

import sdl;

import std.stdio;
import std.string;

/// ウィンドウの幅
enum WINDOW_WIDTH = 640;

/// ウィンドウの高さ
enum WINDOW_HEIGHT = 480;

/// 秒間フレーム数(希望)
enum FPS = 60;

/// 1フレーム当たりミリ秒数
enum MILLS_PER_FRAME = 1000 / FPS;

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

        // 次のフレーム開始時刻まで待つ
        immutable elapse = SDL_GetTicks() - startTicks;
        SDL_Delay(elapse < MILLS_PER_FRAME ? MILLS_PER_FRAME - elapse : 0);
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

